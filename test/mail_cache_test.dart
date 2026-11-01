import 'package:flutter_test/flutter_test.dart';
import 'package:mailweave/models/email_message.dart';
import 'package:mailweave/models/email_thread.dart';
import 'package:mailweave/models/inbox_category.dart';
import 'package:mailweave/services/mail_cache.dart';
import 'package:mailweave/services/secure_storage.dart';
import 'package:mailweave/utils/email_tree_builder.dart';

class _MemoryStore implements SecureKeyValueStore {
  final Map<String, String> _map = {};
  @override
  Future<String?> read(String key) async => _map[key];
  @override
  Future<void> write(String key, String value) async => _map[key] = value;
  @override
  Future<void> delete(String key) async => _map.remove(key);
}

EmailMessage _m({
  required String id,
  String? messageId,
  String? inReplyTo,
  required DateTime date,
}) {
  return EmailMessage(
    id: id,
    threadId: 't1',
    messageId: messageId,
    inReplyTo: inReplyTo,
    references: const [],
    subject: 's',
    from: EmailAddress(name: id, email: '$id@x.com'),
    to: const [],
    cc: const [],
    date: date,
    snippet: '',
    bodyText: '',
    unread: false,
    sent: false,
    hasAttachments: false,
    isFromCurrentUser: false,
    forwarded: false,
  );
}

void main() {
  test('cache round-trips threads and rebuilds the reply tree', () async {
    final cache = MailCache(_MemoryStore());
    final messages = [
      _m(id: 'a', messageId: 'a@x', date: DateTime(2024, 1, 1, 9)),
      _m(id: 'b', messageId: 'b@x', inReplyTo: 'a@x', date: DateTime(2024, 1, 1, 9, 1)),
    ];
    final thread = EmailThread(
      id: 't1',
      subject: 'Hello',
      messages: messages,
      roots: const EmailTreeBuilder().build(messages),
      messageCount: 2,
      participants: const [EmailAddress(name: 'Alice', email: 'a@x.com')],
      latestDate: messages.last.date,
      hasUnread: true,
      hasUserReply: false,
      hasAttachments: false,
      snippet: 'hi',
    );

    await cache.save(InboxCategory.primary, [thread], 'p2');
    final cached = await cache.load(InboxCategory.primary);

    expect(cached, isNotNull);
    expect(cached!.threads.length, 1);
    final t = cached.threads.single;
    expect(t.id, 't1');
    expect(t.subject, 'Hello');
    expect(t.messageCount, 2);
    expect(t.hasUnread, isTrue);
    // The reply tree is rebuilt from stored headers.
    expect(t.roots.length, 1);
    expect(t.roots.first.children.length, 1);
    expect(cached.nextPageToken, 'p2');
  });

  test('load returns null when nothing is cached', () async {
    final cache = MailCache(_MemoryStore());
    expect(await cache.load(InboxCategory.social), isNull);
  });

  test('corrupt cache is ignored gracefully', () async {
    final store = _MemoryStore();
    await store.write('mail_cache_primary', '{not json');
    final cache = MailCache(store);
    expect(await cache.load(InboxCategory.primary), isNull);
  });
}
