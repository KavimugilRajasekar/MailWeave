import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait — Android-only app.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge immersive UI.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Check whether the user has already seen the intro.
  final prefs = await SharedPreferences.getInstance();
  final bool introSeen = prefs.getBool('intro_seen') ?? false;

  runApp(MailWeaveApp(introSeen: introSeen));
}

class MailWeaveApp extends StatelessWidget {
  const MailWeaveApp({super.key, required this.introSeen});

  final bool introSeen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MailWeave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E6DA4),
          brightness: Brightness.light,
        ),
        fontFamily: 'Comfortaa',
      ),
      // Show the intro only on first launch; go straight home afterwards.
      home: introSeen ? const HomeScreen() : const IntroScreen(),
    );
  }
}
