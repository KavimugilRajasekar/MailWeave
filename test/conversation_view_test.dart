import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailweave/models/email_thread.dart';
import 'package:mailweave/models/inbox_category.dart';
import 'package:mailweave/services/gmail_service.dart';
import 'package:mailweave/services/mail_cache.dart';
import 'package:mailweave/services/secure_storage.dart';
import 'package:mailweave/widgets/email/conversation_card.dart';
import 'package:mailweave/widgets/email/conversation_list.dart';
import 'package:mailweave/widgets/email/email_message_card.dart';
import 'package:mailweave/widgets/email/email_tree_view.dart';

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

/// Verifies the conversation list actually renders a fetched thread and that
/// expanding a conversation reveals its branching reply tree. Uses the real
/// GmailService reading fake Gmail JSON (no mock emails in production code).
void main() {
  testWidgets('conversation list renders and expands a tree', (tester) async {
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

    // One conversation on page 1, collapsed (no tree yet).
    expect(find.byType(ConversationCard), findsOneWidget);
    expect(find.byType(EmailTreeView), findsNothing);

    // Expand it -> the reply tree renders all three message cards.
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    expect(find.byType(EmailTreeView), findsOneWidget);
    expect(find.byType(EmailMessageCard), findsNWidgets(3));
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
      MaterialApp(home: Scaffold(body: ConversationCard(thread: thread))),
    );

    final subjectTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.data == subject);
    expect(subjectTexts, isNotEmpty);
    expect(subjectTexts.first.maxLines, isNull); // no line cap -> wraps fully
  });
}
