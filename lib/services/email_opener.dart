import 'package:android_intent_plus/android_intent.dart';

/// Opens a specific Gmail conversation in the native Gmail app.
///
/// MailWeave keeps no in-app reading view — when a user wants to open an
/// email, control is handed to the Gmail app. Falls back to the browser,
/// then to the Gmail app's main screen.
class EmailOpener {
  EmailOpener._();

  static const String _gmailPackage = 'com.google.android.gm';

  /// Open the Gmail conversation [threadId] belongs to.
  static Future<void> openInGmail(String? threadId) async {
    if (threadId == null || threadId.isEmpty) {
      await _openGmailApp();
      return;
    }
    final url = 'https://mail.google.com/mail/u/0/#inbox/$threadId';
    try {
      await AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: url,
        package: _gmailPackage,
      ).launch();
    } catch (_) {
      // Gmail app not installed, or it won't handle the URL -> try the browser.
      try {
        await AndroidIntent(action: 'android.intent.action.VIEW', data: url)
            .launch();
      } catch (_) {
        await _openGmailApp();
      }
    }
  }

  static Future<void> _openGmailApp() async {
    try {
      await AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: _gmailPackage,
      ).launch();
    } catch (_) {
      // Gmail not available — nothing more we can do.
    }
  }
}
