import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait — Android-only app.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge UI; dark icons suit the light-blue/grey theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final bool introSeen = prefs.getBool('intro_seen') ?? false;

  // Only bother checking secure storage once the intro has been seen.
  bool signedIn = false;
  if (introSeen) {
    signedIn = await AuthService().isSignedIn();
  }

  runApp(MailWeaveApp(showIntro: !introSeen, signedIn: signedIn));
}

class MailWeaveApp extends StatelessWidget {
  const MailWeaveApp({
    super.key,
    required this.showIntro,
    required this.signedIn,
  });

  final bool showIntro;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MailWeave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A9FE3),
          brightness: Brightness.light,
        ),
        fontFamily: 'Comfortaa',
      ),
      // First launch → intro. Later launches skip straight to home if the
      // user already signed in, otherwise to the login screen.
      home: showIntro
          ? const IntroScreen()
          : (signedIn ? const HomeScreen() : const LoginScreen()),
    );
  }
}
