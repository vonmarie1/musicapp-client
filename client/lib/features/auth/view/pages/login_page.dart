import 'package:client/features/auth/repositories/auth_remote_repository.dart';
import 'package:client/features/auth/view/widgets/auth_login_button.dart';
import 'package:client/features/auth/view/widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Log in.',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            CustomField(
              hintText: 'Email',
              controller: emailController,
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            CustomField(
              hintText: 'Password',
              controller: passwordController,
              prefixIcon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 30),
            AuthLoginButton(
              onTap: () async {
                final res = await AuthRemoteRepository().login(
                  email: emailController.text,
                  password: passwordController.text,
                );
                final val = switch (res) {
                  Left(value: final l) => l,
                  Right(value: final r) => r,
                };
                print(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
