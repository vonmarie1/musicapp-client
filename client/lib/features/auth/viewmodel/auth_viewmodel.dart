import 'package:client/features/auth/model/user_model.dart';
import 'package:client/features/auth/repositories/auth_remote_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  final AuthRemoteRepository _authRemoteRepository = AuthRemoteRepository();

  @override
  AsyncValue<UserModel> build() {
    return const AsyncValue.loading();
  }

  Future<void> signUpUser({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await _authRemoteRepository.signUp(
        name: name,
        email: email,
        password: password,
      );

      print("Response from signUp: $response");

      if (response is Map<String, dynamic>) {
        final user = UserModel.fromMap(response);
        state = AsyncValue.data(user);
        print("Sign-up successful: ${user.email}");
      } else {
        throw Exception("Unexpected response format: $response");
      }
    } catch (e, stackTrace) {
      print("Sign-up failed: $e");
      state = AsyncValue.error("Sign-up failed: $e", stackTrace);
    }
  }
}
