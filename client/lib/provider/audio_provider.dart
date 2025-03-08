import 'package:flutter/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AudioProvider extends ChangeNotifier {
  YoutubePlayerController? _controller;
  String? _currentVideoId;
  String? _currentTitle;
  String? _currentArtist;
  String? _currentThumbnail;
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _isBackgrounded = false;

  YoutubePlayerController? get controller => _controller;
  String? get currentVideoId => _currentVideoId;
  String? get currentTitle => _currentTitle;
  String? get currentArtist => _currentArtist;
  String? get currentThumbnail => _currentThumbnail;
  bool get isPlaying => _isPlaying;
  bool get isDisposed => _isDisposed;
  // Add this method to update the controller
  void updateController(YoutubePlayerController newController, bool playing) {
    if (_isDisposed) return;

    if (_controller != null) {
      _controller!.removeListener(_onPlayerStateChange);
      _controller!.dispose();
    }

    _controller = newController;
    _controller!.addListener(_onPlayerStateChange);
    _isPlaying = playing;
    notifyListeners();
  }

  // Add this method to seek to a specific position
  void seekTo(Duration position) {
    if (_isDisposed || _controller == null) return;
    _controller!.seekTo(position);
  }

  void setCurrentSong({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnail,
  }) {
    if (_isDisposed) return;

    if (_currentVideoId == videoId && _controller != null) {
      return;
    }

    _currentVideoId = videoId;
    _currentTitle = title;
    _currentArtist = artist;
    _currentThumbnail = thumbnail;

    if (_controller != null) {
      _controller!.removeListener(_onPlayerStateChange);
      _controller!.dispose();
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        hideThumbnail: true,
        enableCaption: false,
      ),
    )..addListener(_onPlayerStateChange);

    _isPlaying = true;
    notifyListeners();
  }

  void _onPlayerStateChange() {
    if (_isDisposed) return;

    if (_controller != null) {
      _isPlaying = _controller!.value.isPlaying;
      notifyListeners();
    }
  }

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

  void enterBackground() {
    if (_isDisposed || _controller == null) return;
    _isBackgrounded = true;
    notifyListeners();
  }

  // Call this when returning to foreground
  void exitBackground() {
    if (_isDisposed || _controller == null) return;
    _isBackgrounded = false;
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
