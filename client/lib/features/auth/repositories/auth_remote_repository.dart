import 'dart:convert';

import 'package:client/core/theme/constants/server_constans.dart';
import 'package:client/core/theme/failure/failure.dart';
import 'package:client/features/auth/model/user_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

class AuthRemoteRepository {
  Future<Either<UserFailure, UserModel>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final body = jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password.trim(),
      });

      print("📤 Signup Request Body: $body");

      final response = await http.post(
        Uri.parse('${ServerConstans.serverURL}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print("✅ Signup Response: ${response.body}");
      print("📩 Status Code: ${response.statusCode}");

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 201) {
        return Left(UserFailure(resBodyMap['detail']));
      }

      return Right(UserModel.fromMap(resBodyMap));
    } catch (e) {
      print("Error: $e");
      return Left(UserFailure(e.toString()));
    }
  }

  Future<Either<UserFailure, UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = jsonEncode({
        'email': email.trim(),
        'password': password.trim(),
      });

      print("📤 Login Request Body: $body");

      final response = await http.post(
        Uri.parse('${ServerConstans.serverURL}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print("✅ Response Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(UserFailure(resBodyMap['detail']));
      }
      return Right(UserModel.fromMap(resBodyMap));
    } catch (e) {
      print("Error: $e");
      return Left(UserFailure(e.toString()));
    }
  }
}
