import 'package:flutter_test/flutter_test.dart';
import 'package:mailweave/models/email_message.dart';
import 'package:mailweave/models/email_tree_node.dart';
import 'package:mailweave/utils/email_tree_builder.dart';

EmailMessage _msg({
  required String id,
  String? messageId,
  String? inReplyTo,
  List<String> references = const [],
  DateTime? date,
  bool isFromCurrentUser = false,
}) {
  return EmailMessage(
    id: id,
    threadId: 't',
    messageId: messageId,
    inReplyTo: inReplyTo,
    references: references,
    subject: 's',
    from: EmailAddress(name: id, email: '$id@x.com'),
    to: const [],
    cc: const [],
    date: date,
    snippet: '',
    bodyText: '',
    unread: false,
    sent: isFromCurrentUser,
    hasAttachments: false,
    isFromCurrentUser: isFromCurrentUser,
    forwarded: false,
  );
}

List<EmailTreeNode> _allNodes(List<EmailTreeNode> roots) {
  final out = <EmailTreeNode>[];
  void walk(EmailTreeNode n) {
    out.add(n);
    n.children.forEach(walk);
  }

  for (final r in roots) {
    walk(r);
  }
  return out;
}

void main() {
  const builder = EmailTreeBuilder();
  final base = DateTime(2024, 1, 1, 9);

  test('empty conversation produces no roots', () {
    expect(builder.build(const []), isEmpty);
  });

  test('single message is a single root', () {
    final roots = builder.build([_msg(id: 'a', messageId: 'a-id', date: base)]);
    expect(roots.length, 1);
    expect(roots.first.children, isEmpty);
  });

  test('multiple sibling replies attach to the original', () {
    final roots = builder.build([
      _msg(id: 'orig', messageId: 'orig-id', date: base),
      _msg(
        id: 'alice',
        messageId: 'alice-id',
        inReplyTo: 'orig-id',
        date: base.add(const Duration(minutes: 1)),
      ),
      _msg(
        id: 'bob',
        messageId: 'bob-id',
        inReplyTo: 'orig-id',
        date: base.add(const Duration(minutes: 2)),
      ),
    ]);
    expect(roots.length, 1);
    expect(roots.first.children.length, 2);
  });

  test('nested replies chain by depth', () {
    final roots = builder.build([
      _msg(id: 'orig', messageId: 'orig-id', date: base),
      _msg(id: 'a', messageId: 'a-id', inReplyTo: 'orig-id', date: base.add(const Duration(minutes: 1))),
      _msg(id: 'b', messageId: 'b-id', inReplyTo: 'a-id', date: base.add(const Duration(minutes: 2))),
      _msg(id: 'c', messageId: 'c-id', inReplyTo: 'b-id', date: base.add(const Duration(minutes: 3))),
    ]);
    expect(roots.length, 1);
    final a = roots.first.children.single;
    final b = a.children.single;
    final c = b.children.single;
    expect(c.message.id, 'c');
    expect(c.depth, 3);
  });

  test('missing parent reference falls back to chronological previous', () {
    final roots = builder.build([
      _msg(id: 'orig', messageId: 'orig-id', date: base),
      _msg(
        id: 'orphan',
        messageId: 'orphan-id',
        inReplyTo: 'missing-id',
        date: base.add(const Duration(minutes: 1)),
      ),
    ]);
    // orphan's In-Reply-To matches nothing -> attaches to the previous message.
    expect(roots.length, 1);
    expect(roots.first.children.length, 1);
    expect(roots.first.children.first.message.id, 'orphan');
  });

  test('References chain resolves parent when In-Reply-To is absent', () {
    final roots = builder.build([
      _msg(id: 'orig', messageId: 'orig-id', date: base),
      _msg(
        id: 'r',
        messageId: 'r-id',
        references: ['orig-id', 'other-id'],
        date: base.add(const Duration(minutes: 1)),
      ),
    ]);
    expect(roots.length, 1);
    expect(roots.first.children.first.message.id, 'r');
  });

  test('duplicate Message-IDs do not crash and keep all messages', () {
    final roots = builder.build([
      _msg(id: 'a', messageId: 'dup', date: base),
      _msg(id: 'b', messageId: 'dup', inReplyTo: 'dup', date: base.add(const Duration(minutes: 1))),
      _msg(id: 'c', messageId: 'c-id', inReplyTo: 'dup', date: base.add(const Duration(minutes: 2))),
    ]);
    expect(_allNodes(roots).length, 3); // nothing discarded
  });

  test('missing Message-ID messages are still placed', () {
    final roots = builder.build([
      _msg(id: 'a', date: base), // no Message-ID
      _msg(id: 'b', messageId: 'b-id', date: base.add(const Duration(minutes: 1))),
    ]);
    expect(_allNodes(roots).length, 2);
  });

  test('no circular relationships are created', () {
    // a -> b (by In-Reply-To) and b -> a would be a cycle; the builder must
    // break it via chronological fallback rather than loop.
    final roots = builder.build([
      _msg(id: 'a', messageId: 'a-id', inReplyTo: 'b-id', date: base),
      _msg(id: 'b', messageId: 'b-id', inReplyTo: 'a-id', date: base.add(const Duration(minutes: 1))),
    ]);
    final all = _allNodes(roots);
    expect(all.length, 2); // nothing discarded
    for (final n in all) {
      EmailTreeNode? cur = n.parent;
      while (cur != null) {
        expect(identical(cur, n), isFalse, reason: 'cycle detected via ancestors');
        cur = cur.parent;
      }
    }
  });
}
