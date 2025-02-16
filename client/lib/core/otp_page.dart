// import 'package:client/features/auth/repositories/auth_remote_repository.dart';
// import 'package:flutter/material.dart';

// class OTPVerificationPage extends StatefulWidget {
//   final String email;

//   OTPVerificationPage({required this.email});

//   @override
//   _OTPVerificationPageState createState() => _OTPVerificationPageState();
// }

// class _OTPVerificationPageState extends State<OTPVerificationPage> {
//   final TextEditingController otpController = TextEditingController();
//   final AuthRemoteRepository authRepo = AuthRemoteRepository();

//   void verifyOTP() async {
//     bool isVerified =
//         await authRepo.verifyOTP(widget.email, otpController.text);
//     if (isVerified) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("OTP Verified!")),
//       );
//       Navigator.pushNamed(context, '/home');
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Invalid OTP")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("OTP Verification")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text("Enter the OTP sent to ${widget.email}"),
//             TextField(
//               controller: otpController,
//               decoration: InputDecoration(labelText: "OTP"),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: verifyOTP,
//               child: Text("Verify OTP"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
