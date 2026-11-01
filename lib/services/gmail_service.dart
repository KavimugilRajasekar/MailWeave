import 'package:googleapis/gmail/v1.dart';

import '../models/email_message.dart';
import '../models/email_thread.dart';
import '../models/inbox_category.dart';
import '../utils/email_tree_builder.dart';

/// One page of conversations.
class ConversationPage {
  const ConversationPage({required this.threads, this.nextPageToken});

  final List<EmailThread> threads;
  final String? nextPageToken;
}

/// Fetches and parses Gmail conversations (threads) for the signed-in user.
///
/// Reuses an authenticated [GmailApi] client obtained from [AuthService].
/// Read-only scope only — no Gmail data is ever modified.
class GmailService {
  GmailService(this._gmail, {String? currentUserEmail})
      : currentUserEmail = currentUserEmail?.toLowerCase().trim();

  final GmailApi _gmail;
  final String? currentUserEmail;

  static const EmailTreeBuilder _treeBuilder = EmailTreeBuilder();

  /// Fetch one manageable page of conversations.
  ///
  /// Lists thread ids, then fetches each thread with `format: 'full'` so the
  /// payload (for attachment detection) and the headers needed for tree-building
  /// are available in a single request per thread — no extra calls when a
  /// conversation is later expanded.
  Future<ConversationPage> listConversations({
    String? pageToken,
    int maxResults = 15,
    InboxCategory? category,
  }) async {
    final listResp = await _gmail.users.threads.list(
      'me',
      maxResults: maxResults,
      pageToken: pageToken,
      labelIds: category == null ? null : [category.gmailLabelId],
    );

    final threadList = listResp.threads ?? const <Thread>[];
    final threads = <EmailThread>[];

    for (final t in threadList) {
      if (t.id == null) continue;
      try {
        final full = await _gmail.users.threads.get('me', t.id!, format: 'full');
        final parsed = _parseThread(full);
        if (!parsed.isEmpty) threads.add(parsed);
      } catch (_) {
        // A single thread failing shouldn't blank the whole page.
      }
    }

    return ConversationPage(
      threads: threads,
      nextPageToken: listResp.nextPageToken,
    );
  }

  EmailThread _parseThread(Thread thread) {
    final messages = <EmailMessage>[
      for (final m in thread.messages ?? const <Message>[])
        EmailMessage.fromGmailMessage(m, currentUserEmail: currentUserEmail),
    ];

    final roots = _treeBuilder.build(messages);

    return EmailThread(
      id: thread.id ?? '',
      subject: _subjectOf(messages),
      messages: messages,
      roots: roots,
      messageCount: messages.length,
      participants: _collectParticipants(messages),
      latestDate: _latestDate(messages),
      hasUnread: messages.any((m) => m.unread),
      hasUserReply: messages.any((m) => m.isFromCurrentUser),
      hasAttachments: messages.any((m) => m.hasAttachments),
      snippet: thread.snippet ?? (messages.isEmpty ? '' : messages.first.snippet),
    );
  }

  String _subjectOf(List<EmailMessage> messages) {
    for (final m in messages) {
      if (m.subject.trim().isNotEmpty) return m.subject;
    }
    return '';
  }

  List<EmailAddress> _collectParticipants(List<EmailMessage> messages) {
    final byKey = <String, EmailAddress>{};
    for (final m in messages) {
      for (final a in <EmailAddress>[m.from, ...m.to, ...m.cc]) {
        final key = (a.email ?? a.name ?? '').toLowerCase();
        if (key.isEmpty) continue;
        byKey.putIfAbsent(key, () => a);
      }
    }
    return byKey.values.toList(growable: false);
  }

  DateTime? _latestDate(List<EmailMessage> messages) {
    DateTime? latest;
    for (final m in messages) {
      final d = m.date;
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }
    return latest;
  }
}
