import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailweave/models/email_thread.dart';
import 'package:mailweave/models/inbox_category.dart';
import 'package:mailweave/screens/conversation_tree_screen.dart';
import 'package:mailweave/services/gmail_service.dart';
import 'package:mailweave/services/mail_cache.dart';
import 'package:mailweave/services/secure_storage.dart';
import 'package:mailweave/widgets/email/conversation_card.dart';
import 'package:mailweave/widgets/email/conversation_list.dart';
import 'package:mailweave/widgets/email/tree_message_card.dart';

import 'fake_gmail.dart';

/// In-memory secure store so widget tests don't hit the platform plugin.
class _MemoryStore implements SecureKeyValueStore {
  final Map<String, String> _map = {};
  @override
  Future<String?> read(String key) async => _map[key];
  @override
  Future<void> write(String key, String value) async => _map[key] = value;
  @override
  Future<void> delete(String key) async => _map.remove(key);
}

/// Verifies the conversation list renders a fetched thread and that tapping a
/// card navigates to the full conversation-tree page. Uses the real GmailService
/// reading fake Gmail JSON (no mock emails in production code).
void main() {
  testWidgets('conversation list opens the tree page on tap', (tester) async {
    final service = GmailService(fakeGmailApi(), currentUserEmail: 'you@x.com');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationList(
            service: service,
            category: InboxCategory.primary,
            autoRefreshInterval: Duration.zero,
            cache: MailCache(_MemoryStore()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // One conversation on the list, no tree page yet.
    expect(find.byType(ConversationCard), findsOneWidget);
    expect(find.byType(ConversationTreeScreen), findsNothing);

    // Tapping the card navigates to the full conversation tree page.
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    expect(find.byType(ConversationTreeScreen), findsOneWidget);
    // The tree renders all three messages as cards.
    expect(find.byType(TreeMessageCard), findsNWidgets(3));
  });

  testWidgets('long subject wraps instead of one-line truncation', (tester) async {
    const subject =
        'A very long subject that should wrap across lines instead of being truncated to a single line with an ellipsis';
    const thread = EmailThread(
      id: 'x',
      subject: subject,
      messages: [],
      roots: [],
      messageCount: 1,
      participants: [],
      latestDate: null,
      hasUnread: false,
      hasUserReply: false,
      hasAttachments: false,
      snippet: '',
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ConversationCard(thread: thread, onOpen: () {}))),
    );

    final subjectTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.data == subject);
    expect(subjectTexts, isNotEmpty);
    expect(subjectTexts.first.maxLines, isNull); // no line cap -> wraps fully
  });
}
