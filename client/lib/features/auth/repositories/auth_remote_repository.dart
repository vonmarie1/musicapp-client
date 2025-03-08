import 'dart:convert';
import 'package:client/core/theme/constants/server_constans.dart';
import 'package:http/http.dart' as http;

class AuthRemoteRepository {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<Map<String, dynamic>> signUp(
      {required String name,
      required String email,
      required String password}) async {
    final response = await http.post(
      Uri.parse("${ServerConstants.serverURL}/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Sign-up failed: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }
}
