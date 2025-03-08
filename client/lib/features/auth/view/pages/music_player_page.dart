import 'package:client/provider/audio_provider.dart';
import 'package:client/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MusicPlayerPage extends StatefulWidget {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;

  const MusicPlayerPage({
    Key? key,
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  }) : super(key: key);

  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioProvider audioProvider;
  bool _isVideoMode = false;
  bool _isPlaying = false;
  bool _isDisposed = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // Initialize the song
    audioProvider.setCurrentSong(
      videoId: widget.videoId,
      title: widget.title,
      artist: widget.artist,
      thumbnail: widget.thumbnailUrl,
    );

    _isPlaying = audioProvider.isPlaying;
    _addToRecentlyPlayed();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Tell the provider we're going to background mode
    audioProvider.enterBackground();
    super.dispose();
  }

  Future<void> _addToRecentlyPlayed() async {
    final song = {
      'id': {'videoId': widget.videoId},
      'snippet': {
        'title': widget.title,
        'channelTitle': widget.artist,
        'thumbnails': {
          'high': {'url': widget.thumbnailUrl}
        }
      }
    };
    await _apiService.addToRecentlyPlayed(song);
  }

  // New method to switch back to audio mode when leaving the page
  void _switchToAudioMode() {
    if (_isDisposed) return;

    final currentTime = audioProvider.controller!.value.position;
    final wasPlaying = audioProvider.controller!.value.isPlaying;

    // Remove our listener
    audioProvider.controller!.removeListener(_onPlayerStateChange);

    // Create a new controller for audio-only mode
    YoutubePlayerController newController = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: wasPlaying,
        mute: false,
        hideControls: true,
        hideThumbnail: true,
      ),
    );

    // Update the provider with the new controller
    audioProvider.updateController(newController, wasPlaying);

    // Seek to the current position
    Future.delayed(Duration(milliseconds: 500), () {
      if (!audioProvider.isDisposed) {
        audioProvider.seekTo(currentTime);
      }
    });
  }

  void _onPlayerStateChange() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isPlaying = audioProvider.controller!.value.isPlaying;
      });
    }
  }

  void _togglePlaybackMode() {
    if (_isDisposed) return;

    setState(() {
      _isVideoMode = !_isVideoMode;
      final currentTime = audioProvider.controller!.value.position;
      final wasPlaying = audioProvider.controller!.value.isPlaying;

      // Remove our listener
      audioProvider.controller!.removeListener(_onPlayerStateChange);

      // Create a new controller with updated settings
      YoutubePlayerController newController = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: YoutubePlayerFlags(
          autoPlay: wasPlaying,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: true,
          enableCaption: false,
          hideControls: !_isVideoMode,
          hideThumbnail: !_isVideoMode,
        ),
      );

      // Update the controller in the provider
      audioProvider.updateController(newController, wasPlaying);

      // Get the updated controller
      //_controller = audioProvider.controller!;
      audioProvider.controller!.addListener(_onPlayerStateChange);

      // Seek to the previous position
      if (!_isDisposed && mounted) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (!_isDisposed && mounted) {
            audioProvider.controller!.seekTo(currentTime);
            if (wasPlaying) {
              audioProvider.controller!.play();
            }
          }
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_isDisposed) return;

    audioProvider.togglePlayPause();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFFFFD700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: _isVideoMode
                        ? _buildVideoPlayer()
                        : _buildMusicPlayer(),
                  ),
                  _buildControlBar(),
                ],
              ),
              // Keep the player alive even in audio mode
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 0,
                  child: Consumer<AudioProvider>(
                    builder: (context, provider, child) {
                      return provider.controller != null
                          ? YoutubePlayer(
                              controller: provider.controller!,
                              showVideoProgressIndicator: false,
                            )
                          : SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rest of the widget methods remain the same...
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.artist,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isVideoMode ? Icons.music_note : Icons.videocam,
              color: Colors.white,
            ),
            onPressed: _togglePlaybackMode,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      color: Colors.black,
      child: YoutubePlayer(
        controller: audioProvider.controller!,
        showVideoProgressIndicator: true,
        progressColors: ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildMusicPlayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 15,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.thumbnailUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 40),
        Text(
          widget.title,
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          widget.artist,
          style: GoogleFonts.roboto(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous, color: Colors.white, size: 36),
            onPressed: () {
              // Implement previous track functionality
            },
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: Colors.white, size: 36),
            onPressed: () {
              // Implement next track functionality
            },
          ),
        ],
      ),
    );
  }
}
