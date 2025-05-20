import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SongInfo {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnail;

  SongInfo({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnail,
  });
}

class AudioProvider extends ChangeNotifier {
  YoutubePlayerController? _controller;
  String? _currentVideoId;
  String? _currentTitle;
  String? _currentArtist;
  String? _currentThumbnail;
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _isVideoMode = false;
  String _errorMessage = '';

  // Playlist management
  List<SongInfo> _playlist = [];
  int _currentIndex = -1;

  // Getters
  YoutubePlayerController? get controller => _controller;
  set controller(YoutubePlayerController? value) {
    _controller = value;
    notifyListeners();
  }

  YoutubePlayerController? get videoController =>
      _controller; // Alias for compatibility
  String? get currentVideoId => _currentVideoId;
  String? get currentTitle => _currentTitle;
  String? get currentArtist => _currentArtist;
  String? get currentThumbnail => _currentThumbnail;
  bool get isPlaying => _isPlaying;
  bool get isVideoMode => _isVideoMode;
  String get errorMessage => _errorMessage;
  List<SongInfo> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Add a song to the playlist
  void addToPlaylist(SongInfo song) {
    _playlist.add(song);
    notifyListeners();
  }

  // Set the entire playlist
  void setPlaylist(List<SongInfo> songs, {int initialIndex = 0}) {
    print(
        '📋 Setting playlist with ${songs.length} songs, initial index: $initialIndex');

    _playlist = songs;
    _currentIndex = initialIndex < songs.length ? initialIndex : 0;

    if (_playlist.isNotEmpty && _currentIndex >= 0) {
      final song = _playlist[_currentIndex];
      print('🎵 Initial song: ${song.title}');

      setCurrentSong(
        videoId: song.videoId,
        title: song.title,
        artist: song.artist,
        thumbnail: song.thumbnail,
      );
    }

    notifyListeners();
  }

  // Play a specific song from the playlist
  void playFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      final song = _playlist[index];

      setCurrentSong(
        videoId: song.videoId,
        title: song.title,
        artist: song.artist,
        thumbnail: song.thumbnail,
      );
    }
  }

  // Play the next song in the playlist
  void playNext() {
    if (_currentIndex < _playlist.length - 1) {
      print(
          '⏭️ Playing next song, moving from index $_currentIndex to ${_currentIndex + 1}');
      _currentIndex++;
      final song = _playlist[_currentIndex];

      // Store current controller settings
      final wasPlaying = _controller?.value.isPlaying ?? true;

      // Set the new song
      setCurrentSong(
        videoId: song.videoId,
        title: song.title,
        artist: song.artist,
        thumbnail: song.thumbnail,
      );

      // Ensure it's playing if the previous song was playing
      if (wasPlaying && _controller != null) {
        _controller!.play();
      }

      print('✅ Now playing: ${song.title} (index: $_currentIndex)');
    } else {
      print(
          '⚠️ End of playlist reached, current index: $_currentIndex, playlist size: ${_playlist.length}');
    }
  }

  // Play the previous song in the playlist
  void playPrevious() {
    if (_currentIndex > 0) {
      print(
          '⏮️ Playing previous song, moving from index $_currentIndex to ${_currentIndex - 1}');
      _currentIndex--;
      final song = _playlist[_currentIndex];

      // Store current controller settings
      final wasPlaying = _controller?.value.isPlaying ?? true;

      // Set the new song
      setCurrentSong(
        videoId: song.videoId,
        title: song.title,
        artist: song.artist,
        thumbnail: song.thumbnail,
      );

      // Ensure it's playing if the previous song was playing
      if (wasPlaying && _controller != null) {
        _controller!.play();
      }

      print('✅ Now playing: ${song.title} (index: $_currentIndex)');
    } else {
      print('⚠️ Beginning of playlist reached, current index: $_currentIndex');
    }
  }

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
    _isVideoMode = false;
    _errorMessage = '';

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

  // Toggle video/audio mode
  Future<void> togglePlaybackMode() async {
    if (_isDisposed || _currentVideoId == null) return;

    _isVideoMode = !_isVideoMode;
    _errorMessage = '';

    try {
      final currentTime = _controller?.value.position;
      final wasPlaying = _controller?.value.isPlaying ?? false;

      // Clean up old controller
      if (_controller != null) {
        _controller!.removeListener(_onPlayerStateChange);
        _controller!.dispose();
      }

      // Create new controller with updated settings
      _controller = YoutubePlayerController(
        initialVideoId: _currentVideoId!,
        flags: YoutubePlayerFlags(
          autoPlay: wasPlaying,
          mute: false,
          hideControls: !_isVideoMode,
          hideThumbnail: !_isVideoMode,
          enableCaption: false,
          forceHD: _isVideoMode,
        ),
      );

      _controller!.addListener(_onPlayerStateChange);

      // Seek to the previous position
      if (currentTime != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (!_isDisposed && _controller != null) {
            _controller!.seekTo(currentTime);
            if (wasPlaying) {
              _controller!.play();
            }
          }
        });
      }
    } catch (e) {
      _errorMessage = 'Error toggling mode: $e';
      print('❌ Error in togglePlaybackMode: $e');
    }

    notifyListeners();
  }

  // Call this when going to background
  void enterBackground() {
    if (_isDisposed || _controller == null) return;
    // This method is called when the music player page is closed
    // but we want to keep playing in the background
    notifyListeners();
  }

  // Call this when returning to foreground
  void exitBackground() {
    if (_isDisposed || _controller == null) return;
    notifyListeners();
  }

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
