import 'package:client/features/auth/view/widgets/auth_login_button.dart';
import 'package:client/features/auth/view/widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      print("✅ User logged in: ${user?.email}");

      // Check if email is verified
      if (user != null && !user.emailVerified) {
        print("❌ Email not verified");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please verify your email before logging in.')),
        );
        FirebaseAuth.instance.signOut(); // Prevent access
        return;
      }

      print("✅ Email verified, proceeding to dashboard...");

      // // Navigate to home page (or dashboard)
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const HomePage()),
      // );
    } catch (e) {
      print("❌ Login failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print("📩 Verification email resent to ${user.email}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!')),
        );
      }
    } catch (e) {
      print("❌ Error resending email: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resending email: $e')),
      );
    }
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
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
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
                await login();
              },
            ),
            TextButton(
              onPressed: resendVerificationEmail,
              child: const Text("Resend Verification Email"),
            ),
          ],
        ),
      ),
    );
  }
}
