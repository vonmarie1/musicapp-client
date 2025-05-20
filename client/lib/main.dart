import 'package:client/features/auth/view/pages/email_verification_page.dart';
import 'package:client/features/auth/view/pages/home_page.dart';
import 'package:client/services/audio_service.dart%2014-06-28-685.dart';
import 'package:client/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    as riverpod; // ✅ Import Riverpod for ProviderScope
import 'package:provider/provider.dart'
    as provider; // ✅ Import Provider for AudioProvider
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/view/pages/createaccount_page.dart';
import 'features/auth/view/pages/login_page.dart';
import 'features/auth/view/pages/profile_page.dart';
import 'features/auth/view/pages/signup_page.dart';
import 'core/theme/theme.dart';
import 'provider/audio_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AudioService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    riverpod.ProviderScope(
      // ✅ Needed for Riverpod
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(
            create: (_) => AudioProvider(),
          ),
          provider.ChangeNotifierProvider(
              create: (_) =>
                  AuthService()), // ✅ Use Provider's ChangeNotifierProvider
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zymphony',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in
            User user = snapshot.data!;

            if (user.emailVerified) {
              // Email is verified, go to home
              return const HomePage();
            } else {
              // Email is not verified, show verification page
              return const EmailVerificationPage();
            }
          }

          // User is not logged in
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/verify-email': (context) => EmailVerificationPage(),
      },
    );
  }
}
