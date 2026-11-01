import 'dart:convert';

import 'secure_storage.dart';

/// Stores per-message notes on-device (Flutter Secure Storage). All notes
/// live in a single JSON map keyed by the Gmail message id, so they survive
/// reloads and stay private to this device.
class NoteStore {
  NoteStore([SecureKeyValueStore? storage])
      : _storage = storage ?? const FlutterSecureKeyValueStore();

  final SecureKeyValueStore _storage;

  static const String _key = 'mail_notes';

  Future<Map<String, String>> _readAll() async {
    final raw = await _storage.read(_key);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _writeAll(Map<String, String> notes) async {
    await _storage.write(_key, jsonEncode(notes));
  }

  Future<String?> read(String messageId) async => (await _readAll())[messageId];

  /// Saves (or, when [note] is empty, deletes) the note for [messageId].
  Future<void> write(String messageId, String note) async {
    final notes = await _readAll();
    if (note.isEmpty) {
      notes.remove(messageId);
    } else {
      notes[messageId] = note;
    }
    await _writeAll(notes);
  }
}
