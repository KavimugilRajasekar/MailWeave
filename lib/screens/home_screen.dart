import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Shown after a successful OAuth sign-in. The threaded mail tree view will
/// live here; for now it's a placeholder.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Light-blue / grey theme
  static const Color _lightBlue = Color(0xFF4A9FE3);
  static const Color _greyDark = Color(0xFF37474F);
  static const Color _greyMid = Color(0xFF607D8B);

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

  /// Bottom-right, blue, circle-outlined floating button. Tappable (shows
  /// press feedback) but intentionally performs no action yet.
  Widget _menuButton() => FloatingActionButton(
    backgroundColor: Colors.transparent,
    foregroundColor: _lightBlue,
    shape: const CircleBorder(side: BorderSide(color: _lightBlue, width: 2)),
    onPressed: () {},
    child: const Icon(Icons.account_circle_outlined),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      fontFamily: 'Playwrite US Modern',
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                      color: _greyDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your threaded mail view will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                        color: _greyMid,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      // Bottom-right floating circle-outlined button (no action yet).
      floatingActionButton: _menuButton(),
    );
  }
}
