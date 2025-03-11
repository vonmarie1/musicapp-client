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

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with WidgetsBindingObserver {
  late AudioProvider audioProvider;
  bool _isVideoMode = false;
  bool _isPlaying = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    audioProvider = Provider.of<AudioProvider>(context, listen: false);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to keep audio playing
    if (state == AppLifecycleState.resumed) {
      if (audioProvider.controller != null && _isPlaying) {
        audioProvider.controller!.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  void _togglePlaybackMode() {
    setState(() {
      _isVideoMode = !_isVideoMode;
    });
  }

  void _togglePlayPause() {
    audioProvider.togglePlayPause();
    setState(() {
      _isPlaying = audioProvider.isPlaying;
    });
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
              // Hidden player for audio-only mode
              if (!_isVideoMode && audioProvider.controller != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: SizedBox(
                    height: 1,
                    width: 1,
                    child: YoutubePlayer(
                      controller: audioProvider.controller!,
                      showVideoProgressIndicator: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
      child: audioProvider.controller != null
          ? YoutubePlayer(
              controller: audioProvider.controller!,
              showVideoProgressIndicator: true,
              progressColors: ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
            )
          : Center(child: CircularProgressIndicator()),
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
