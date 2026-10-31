import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

/// Shown after the one-time intro. Triggers Google OAuth, then routes to
/// [HomeScreen] on success. Tokens are saved securely by [AuthService].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Light-blue / grey theme
  static const Color _lightBlue = Color(0xFF4A9FE3);
  static const Color _greyDark = Color(0xFF37474F);
  static const Color _greyMid = Color(0xFF607D8B);
  static const Color _greyLight = Color(0xFFECEFF1);

  final AuthService _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await _auth.signIn();
      if (client == null) {
        if (!mounted) return;
        setState(() => _error = 'Sign-in cancelled.');
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyLight,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Centered brand content.
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Lottie.asset(
                      'assets/json/man_in_ballon.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'MailWeave',
                      style: TextStyle(
                        fontFamily: 'Playwrite US Modern',
                        fontWeight: FontWeight.w400,
                        fontSize: 32,
                        color: _greyDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in with Google to access your mail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w300,
                        fontSize: 15,
                        color: _greyMid,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Google sign-in button pinned to the bottom of the screen.
            // Outlined style (transparent fill, light-blue border) + black text.
            Positioned(
              left: 32,
              right: 32,
              bottom: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: _lightBlue, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.mail_outline),
                      label: Text(
                        _loading ? 'Signing in…' : 'Sign in with Google',
                        style: const TextStyle(
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Comfortaa',
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
