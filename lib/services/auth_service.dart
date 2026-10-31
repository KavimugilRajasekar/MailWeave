import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

/// Handles Google OAuth sign-in for Gmail access and securely persists the
/// resulting access credentials in the platform keystore (Android Keystore via
/// [FlutterSecureStorage]) — NOT plain shared storage.
class AuthService {
  /// Secure-storage key for the serialised [AccessCredentials].
  static const String _kCredentialsKey = 'gmail_oauth_credentials';

  /// Gmail read-only scope — enough to fetch and thread messages.
  static const List<String> kScopes = <String>[
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: kScopes);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Returns true if credentials are present in secure storage.
  Future<bool> isSignedIn() async {
    final raw = await _storage.read(key: _kCredentialsKey);
    return raw != null && raw.isNotEmpty;
  }

  /// Drive the interactive Google sign-in flow, obtain an [AuthClient], and
  /// persist the credentials securely. Returns the client on success, or
  /// `null` if the user cancelled.
  Future<AuthClient?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // user cancelled
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    await _saveCredentials(client.credentials);
    return client;
  }

  /// Restore a previously-authenticated session without UI.
  /// 1. Attempt silent sign-in via the native Google Sign-In SDK (refreshes
  ///    tokens automatically).
  /// 2. Fall back to the credentials saved in secure storage.
  Future<AuthClient?> restoreClient() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        final client = await _googleSignIn.authenticatedClient();
        if (client != null) {
          await _saveCredentials(client.credentials);
          return client;
        }
      }
    } catch (_) {
      // fall through to the secure-storage fallback
    }
    return _clientFromStorage();
  }

  /// Sign out: revoke the native session and wipe secure storage.
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    await _storage.delete(key: _kCredentialsKey);
  }

  /// Convenience: a [GmailApi] client built from a restored [AuthClient].
  Future<GmailApi?> gmailApi() async {
    final client = await restoreClient();
    return client == null ? null : GmailApi(client);
  }

  // ── Secure persistence ───────────────────────────────────────────────────

  Future<void> _saveCredentials(AccessCredentials creds) async {
    final map = <String, dynamic>{
      'accessToken': {
        'type': creds.accessToken.type,
        'data': creds.accessToken.data,
      },
      'refreshToken': creds.refreshToken,
      'idToken': creds.idToken,
      'scopes': creds.scopes,
    };
    await _storage.write(key: _kCredentialsKey, value: jsonEncode(map));
  }

  Future<AuthClient?> _clientFromStorage() async {
    final raw = await _storage.read(key: _kCredentialsKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final tokenMap = map['accessToken'] as Map<String, dynamic>;
      final accessToken = AccessToken(
        (tokenMap['type'] as String?) ?? 'Bearer',
        tokenMap['data'] as String,
        // Expiry is unknown for a stored token; assume valid for ~1h as a
        // best-effort fallback. The native SDK path refreshes automatically.
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final credentials = AccessCredentials(
        accessToken,
        map['refreshToken'] as String?,
        (map['scopes'] as List<dynamic>).cast<String>(),
        idToken: map['idToken'] as String?,
      );
      // Attach the stored access token to a simple HTTP client (no auto-refresh).
      return authenticatedClient(http.Client(), credentials);
    } catch (_) {
      await _storage.delete(key: _kCredentialsKey);
      return null;
    }
  }
}
