import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    as riverpod; // ✅ Import Riverpod for ProviderScope
import 'package:provider/provider.dart'
    as provider; // ✅ Import Provider for AudioProvider
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
          ), // ✅ Use Provider's ChangeNotifierProvider
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
      theme: AppTheme.lightThemeMode,
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/profile': (context) => ProfilePage(),
      },
      home: const CreateAccount(),
    );
  }
}
