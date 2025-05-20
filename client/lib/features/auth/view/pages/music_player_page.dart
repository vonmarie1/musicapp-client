import 'package:client/provider/audio_provider.dart';
import 'package:client/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

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

    // Initialize just the current song
    audioProvider.setCurrentSong(
      videoId: widget.videoId,
      title: widget.title,
      artist: widget.artist,
      thumbnail: widget.thumbnailUrl,
    );

    _isPlaying = audioProvider.isPlaying;
    audioProvider.controller?.addListener(_onPlayerStateChange);
    _addToRecentlyPlayed();
  }

  @override
  void dispose() {
    _isDisposed = true;
    audioProvider.controller?.removeListener(_onPlayerStateChange);
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
        initialVideoId: audioProvider.currentVideoId!,
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

      // Clean up old controller
      if (audioProvider.controller != null) {
        audioProvider.controller!.removeListener(_onPlayerStateChange);
        audioProvider.controller!.dispose();
      }

      // Set new controller
      audioProvider.controller = newController;
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
              // Hidden YouTube player for audio-only mode
              // Modified to work on iOS
              if (!_isVideoMode)
                Positioned(
                  // Position it off-screen but still active
                  bottom: Platform.isIOS ? -1000 : null, // Off-screen for iOS
                  left: Platform.isIOS ? 0 : null,
                  child: Platform.isIOS
                      // For iOS: Keep a small visible size but position off-screen
                      ? SizedBox(
                          width: 1, // Tiny but not zero
                          height: 1, // Tiny but not zero
                          child: YoutubePlayer(
                            controller: audioProvider.controller!,
                            showVideoProgressIndicator: false,
                          ),
                        )
                      // For Android: Use opacity approach
                      : Opacity(
                          opacity: 0,
                          child: SizedBox(
                            height: 0,
                            child: YoutubePlayer(
                              controller: audioProvider.controller!,
                              showVideoProgressIndicator: false,
                            ),
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
                  audioProvider.currentTitle ?? widget.title,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  audioProvider.currentArtist ?? widget.artist,
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
              audioProvider.currentThumbnail ?? widget.thumbnailUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 40),
        Text(
          audioProvider.currentTitle ?? widget.title,
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          audioProvider.currentArtist ?? widget.artist,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
            onPressed: _togglePlayPause,
          ),
        ],
      ),
    );
  }
}
