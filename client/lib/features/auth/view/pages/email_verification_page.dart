import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:client/services/auth_service.dart';
import 'home_page.dart';

class EmailVerificationPage extends StatefulWidget {
  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isLoading = false;

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      bool isVerified = await context.read<AuthService>().checkEmailVerified();
      if (isVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Email not verified yet. Please check your inbox.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check verification: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().sendVerificationEmail();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent! Check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Your Email')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      'A verification email has been sent to your email address.'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkVerification,
                    child: Text('I\'ve Verified My Email'),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: _resendVerificationEmail,
                    child: Text('Resend Verification Email'),
                  ),
                ],
              ),
      ),
    );
  }
}
