import 'package:client/features/auth/view/pages/background_player.dart';
import 'package:client/provider/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/view/pages/createaccount_page.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const MyApp(),
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
      builder: (context, child) {
        // Wrap the entire app with a stack that includes the background player
        return Stack(
          children: [
            child!,
            const BackgroundPlayer(), // This stays alive throughout the app
          ],
        );
      },
      home: const CreateAccount(),
    );
  }
}
