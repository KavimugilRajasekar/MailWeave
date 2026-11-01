import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal encrypted key/value store abstraction so services that use secure
/// storage can be unit-tested with an in-memory fake (no platform plugin).
abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecureKeyValueStore] backed by [FlutterSecureStorage] (Android Keystore).
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null; // storage unavailable / not supported — treat as empty
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // best-effort persistence; ignore platform failures
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // best-effort
    }
  }
}
