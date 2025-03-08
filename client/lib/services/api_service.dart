import 'dart:convert';
import 'package:client/features/auth/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:client/core/theme/constants/server_constans.dart';
import 'package:client/features/auth/model/video_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  // Base URL from server constants
  final String baseUrl = ServerConstants.serverURL;

  // Authentication Methods
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print("Signup response: $responseData");
        return UserModel.fromMap(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ??
            "Sign-up failed with status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during signup: $e");
      throw Exception("Sign-up failed: $e");
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Login response: $responseData");
        return UserModel.fromMap(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ??
            "Login failed with status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during login: $e");
      throw Exception("Login failed: $e");
    }
  }

  // YouTube Search
  Future<Map<String, dynamic>> searchYouTube(String query) async {
    try {
      print(
          "🔄 Searching YouTube via backend: $baseUrl/search-youtube?query=$query");
      final response = await _dio.get(
        '$baseUrl/search-youtube',
        queryParameters: {'query': query},
      );

      print("📡 YouTube search response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ YouTube search successful");
        return response.data;
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in searchYouTube: $e');
      rethrow;
    }
  }

  // Get video details
  Future<VideoModel> getVideoDetails(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/youtube/video/$videoId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return VideoModel.fromMap(data);
      } else {
        throw Exception("Failed to get video details: ${response.body}");
      }
    } catch (e) {
      print("Error getting video details: $e");
      throw Exception("Failed to get video details: $e");
    }
  }

  // User profile methods
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    String? photoUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/users/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "photo_url": photoUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update profile: ${response.body}");
      }
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception("Failed to update profile: $e");
    }
  }

  // Playlist methods
  Future<List<Map<String, dynamic>>> getUserPlaylists(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users/$userId/playlists"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception("Failed to get playlists: ${response.body}");
      }
    } catch (e) {
      print("Error getting playlists: $e");
      throw Exception("Failed to get playlists: $e");
    }
  }

  Future<Map<String, dynamic>> createPlaylist({
    required String userId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/$userId/playlists"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "description": description,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create playlist: ${response.body}");
      }
    } catch (e) {
      print("Error creating playlist: $e");
      throw Exception("Failed to create playlist: $e");
    }
  }

  Future<void> addVideoToPlaylist({
    required String playlistId,
    required String videoId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/playlists/$playlistId/videos"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "video_id": videoId,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception("Failed to add video to playlist: ${response.body}");
      }
    } catch (e) {
      print("Error adding video to playlist: $e");
      throw Exception("Failed to add video to playlist: $e");
    }
  }

  // Recently played
  Future<List<Map<String, dynamic>>> getRecentlyPlayed(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users/$userId/history"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception("Failed to get history: ${response.body}");
      }
    } catch (e) {
      print("Error getting history: $e");
      throw Exception("Failed to get history: $e");
    }
  }

  // Add methods for quick picks, recently played, and recommendations
  Future<List<Map<String, dynamic>>> getQuickPicks() async {
    try {
      final response = await searchYouTube('drake, the weeknd, rnb');
      if (response.containsKey('items')) {
        return List<Map<String, dynamic>>.from(response['items']);
      }
      return [];
    } catch (e) {
      print('❌ Error getting quick picks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations() async {
    try {
      final response = await searchYouTube('recommended music playlists');
      if (response.containsKey('items')) {
        return List<Map<String, dynamic>>.from(response['items']);
      }
      return [];
    } catch (e) {
      print('❌ Error getting recommendations: $e');
      return [];
    }
  }

  Future<void> addToRecentlyPlayed(Map<String, dynamic> song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recentlyPlayed = prefs.getStringList('recentlyPlayed') ?? [];

      // Check if song already exists in the list
      final songJson = json.encode(song);
      recentlyPlayed.removeWhere((item) {
        final decodedItem = json.decode(item);
        return decodedItem['id']['videoId'] == song['id']['videoId'];
      });

      // Add the new song at the beginning of the list
      recentlyPlayed.insert(0, songJson);

      // Keep only the last 20 songs
      if (recentlyPlayed.length > 20) {
        recentlyPlayed = recentlyPlayed.sublist(0, 20);
      }

      await prefs.setStringList('recentlyPlayed', recentlyPlayed);

      // Remove the backend call for now since the endpoint is not ready
      // When the backend is ready, you can uncomment this part
      /*
    if (song['id']?['videoId'] != null) {
      await http.post(
        Uri.parse("$baseUrl/users/history"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "video_id": song['id']['videoId'],
        }),
      );
    }
    */
    } catch (e) {
      print("Error adding to recently played: $e");
      // Continue even if save fails
    }
  }

  Future<List<Map<String, dynamic>>> getRecentPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentlyPlayed = prefs.getStringList('recentlyPlayed') ?? [];

    return recentlyPlayed
        .map((song) => json.decode(song) as Map<String, dynamic>)
        .toList();
  }
}
