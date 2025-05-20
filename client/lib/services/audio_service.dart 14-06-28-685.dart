import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentVideoId;

  AudioPlayer get player => _audioPlayer;
  String? get currentVideoId => _currentVideoId;

  // Initialize background audio
  static Future<void> init() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.client.audio',
      androidNotificationChannelName: 'client Audio',
      androidNotificationOngoing: true,
    );
  }

  // Play audio from YouTube video ID
  Future<void> playYouTubeAudio(
      String videoId, String title, String artist, String artworkUrl) async {
    if (_currentVideoId == videoId && _audioPlayer.playing) {
      return; // Already playing this track
    }

    _currentVideoId = videoId;

    try {
      // Get audio URL from your backend
      final audioUrl = await _getAudioUrlFromBackend(videoId);

      if (audioUrl != null) {
        // Set audio source with metadata
        final audioSource = AudioSource.uri(
          Uri.parse(audioUrl),
          tag: MediaItem(
            id: videoId,
            title: title,
            artist: artist,
            artUri: Uri.parse(artworkUrl),
          ),
        );

        await _audioPlayer.setAudioSource(audioSource);
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error playing YouTube audio: $e');
    }
  }

  // Get audio URL from your backend
  Future<String?> _getAudioUrlFromBackend(String videoId) async {
    try {
      // Replace with your actual backend endpoint
      final response = await http.get(
        Uri.parse('http://localhost:8000/get-audio-url?videoId=$videoId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['audioUrl'];
      }
    } catch (e) {
      print('Error fetching audio URL: $e');
    }
    return null;
  }

  // Control methods
  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();
  void stop() => _audioPlayer.stop();

  // Cleanup
  void dispose() {
    _audioPlayer.dispose();
  }
}
