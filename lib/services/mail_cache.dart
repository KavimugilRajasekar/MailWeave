import 'dart:convert';

import '../models/email_thread.dart';
import '../models/inbox_category.dart';
import 'secure_storage.dart';

/// A page of conversations restored from local cache.
class CachedMail {
  const CachedMail({required this.threads, this.nextPageToken});

  final List<EmailThread> threads;
  final String? nextPageToken;
}

/// Persists the organised (branched) conversations on-device using Flutter
/// Secure Storage, keyed by inbox category. The reply tree is rebuilt from
/// the stored message headers on load.
class MailCache {
  MailCache([SecureKeyValueStore? storage])
      : _storage = storage ?? const FlutterSecureKeyValueStore();

  final SecureKeyValueStore _storage;

  static const String _keyPrefix = 'mail_cache_';

  String _key(InboxCategory category) => '$_keyPrefix${category.name}';

  Future<void> save(
    InboxCategory category,
    List<EmailThread> threads,
    String? nextPageToken,
  ) async {
    final json = jsonEncode({
      'threads': threads.map((t) => t.toJson()).toList(),
      'nextPageToken': nextPageToken,
    });
    await _storage.write(_key(category), json);
  }

  Future<CachedMail?> load(InboxCategory category) async {
    final raw = await _storage.read(_key(category));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final threads = ((map['threads'] as List<dynamic>?) ?? const [])
          .map((e) => EmailThread.fromJson((e as Map).cast<String, Object?>()))
          .toList();
      if (threads.isEmpty) return null;
      return CachedMail(
        threads: threads,
        nextPageToken: map['nextPageToken'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(InboxCategory category) =>
      _storage.delete(_key(category));
}
