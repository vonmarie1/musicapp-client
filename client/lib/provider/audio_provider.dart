import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AudioProvider extends ChangeNotifier {
  YoutubePlayerController? _controller;
  String? _currentVideoId;
  String? _currentTitle;
  String? _currentArtist;
  String? _currentThumbnail;
  bool _isPlaying = false;
  bool _isDisposed = false;

  // Getters
  YoutubePlayerController? get controller => _controller;
  String? get currentVideoId => _currentVideoId;
  String? get currentTitle => _currentTitle;
  String? get currentArtist => _currentArtist;
  String? get currentThumbnail => _currentThumbnail;
  bool get isPlaying => _isPlaying;

  // Set current song and initialize controller
  void setCurrentSong({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnail,
  }) {
    if (_isDisposed) return;

    // If we're already playing this song, don't recreate the controller
    if (_currentVideoId == videoId && _controller != null) {
      return;
    }

    _currentVideoId = videoId;
    _currentTitle = title;
    _currentArtist = artist;
    _currentThumbnail = thumbnail;

    // Clean up old controller
    if (_controller != null) {
      _controller!.removeListener(_onPlayerStateChange);
      _controller!.dispose();
    }

    // Create new controller
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        hideThumbnail: true,
        enableCaption: false,
        forceHD: false,
      ),
    );

    _controller!.addListener(_onPlayerStateChange);
    _isPlaying = true;
    notifyListeners();
  }

  // Listen for player state changes
  void _onPlayerStateChange() {
    if (_isDisposed || _controller == null) return;

    final newIsPlaying = _controller!.value.isPlaying;
    if (_isPlaying != newIsPlaying) {
      _isPlaying = newIsPlaying;
      notifyListeners();
    }
  }

  // Toggle play/pause
  void togglePlayPause() {
    if (_isDisposed || _controller == null) return;

    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }

    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_controller != null) {
      _controller!.removeListener(_onPlayerStateChange);
      _controller!.dispose();
      _controller = null;
    }
    super.dispose();
  }
}
