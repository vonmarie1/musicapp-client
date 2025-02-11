import 'package:client/features/auth/view/widgets/auth_already_button.dart';
import 'package:client/features/auth/view/widgets/auth_create_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: NetworkImage(
                    'https://i.pinimg.com/736x/29/55/a3/2955a3f295bd994427a4782e7a8459a6.jpg'),
                fit: BoxFit.cover),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Zymphony',
                style: GoogleFonts.monoton(
                  fontSize: 50,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 10),
              const AuthCreateButton(),
              const SizedBox(height: 10),
              const AuthAlreadyButton(),
            ],
          ),
        ),
      );
}
