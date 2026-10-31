import 'package:flutter/material.dart';

/// Placeholder home screen shown after the one-time intro is completed.
/// Replace the body with real mail-fetch and thread-tree UI when ready.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MailWeave',
          style: TextStyle(
            fontFamily: 'Playwrite US Modern',
            fontWeight: FontWeight.w400,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_rounded,
              size: 96,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your inbox is coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Playwrite US Modern',
                fontWeight: FontWeight.w400,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Mail fetching and the threaded tree view\nwill live here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Comfortaa',
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
