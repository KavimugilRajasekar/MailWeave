import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

/// Placeholder home screen shown after a successful OAuth sign-in.
/// The threaded mail tree view will live here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Light-blue / grey theme
  static const Color _lightBlue = Color(0xFF4A9FE3);
  static const Color _greyDark  = Color(0xFF37474F);
  static const Color _greyMid   = Color(0xFF607D8B);

  final AuthService _auth = AuthService();
  String? _profileEmail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final gmail = await _auth.gmailApi();
      if (gmail != null) {
        final profile = await gmail.users.getProfile('me');
        if (!mounted) return;
        setState(() => _profileEmail = profile.emailAddress);
      }
    } catch (_) {
      // network or auth issue — non-fatal for the placeholder screen
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _lightBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MailWeave',
          style: TextStyle(
            fontFamily:  'Playwrite US Modern',
            fontWeight:  FontWeight.w400,
            fontSize:    22,
            color:       Colors.white,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lightBlue))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.account_tree_rounded,
                    size: 96,
                    color: _lightBlue.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _profileEmail != null
                        ? 'Welcome, $_profileEmail'
                        : 'Welcome',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily:  'Playwrite US Modern',
                      fontWeight:  FontWeight.w400,
                      fontSize:    20,
                      color:       _greyDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your threaded mail view will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily:  'Comfortaa',
                        fontWeight:  FontWeight.w300,
                        fontSize:    14,
                        color:       _greyMid,
                        height:      1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
