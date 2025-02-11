import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLoginButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const AuthLoginButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.yellow],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await onTap();
        },
        child: Container(
          width: 395,
          height: 55,
          alignment: Alignment.center,
          child: Text(
            'Log In',
            style: GoogleFonts.raleway(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
