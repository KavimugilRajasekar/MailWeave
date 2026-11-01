import 'email_message.dart';
import 'email_tree_node.dart';

import '../utils/email_tree_builder.dart';

/// A Gmail conversation (thread) and its reconstructed reply tree.
class EmailThread {
  const EmailThread({
    required this.id,
    required this.subject,
    required this.messages,
    required this.roots,
    required this.messageCount,
    required this.participants,
    required this.latestDate,
    required this.hasUnread,
    required this.hasUserReply,
    required this.hasAttachments,
    required this.snippet,
  });

  final String id;
  final String subject;
  final List<EmailMessage> messages;

  /// Root nodes of the reply tree.
  final List<EmailTreeNode> roots;

  final int messageCount;
  final List<EmailAddress> participants;
  final DateTime? latestDate;
  final bool hasUnread;
  final bool hasUserReply;
  final bool hasAttachments;
  final String snippet;

  bool get isEmpty => messages.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'messages': messages.map((m) => m.toJson()).toList(),
        'messageCount': messageCount,
        'participants': participants.map((a) => a.toJson()).toList(),
        'latestDate': latestDate?.toIso8601String(),
        'hasUnread': hasUnread,
        'hasUserReply': hasUserReply,
        'hasAttachments': hasAttachments,
        'snippet': snippet,
      };

  /// Restore a cached conversation, rebuilding its reply tree from the
  /// stored message headers.
  factory EmailThread.fromJson(Map<String, dynamic> json) {
    final messages = ((json['messages'] as List<dynamic>?) ?? const [])
        .map((m) => EmailMessage.fromJson((m as Map).cast<String, Object?>()))
        .toList();
    return EmailThread(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      messages: messages,
      roots: const EmailTreeBuilder().build(messages),
      messageCount: json['messageCount'] as int? ?? messages.length,
      participants: ((json['participants'] as List<dynamic>?) ?? const [])
          .map((e) => EmailAddress.fromJson((e as Map).cast<String, Object?>()))
          .toList(),
      latestDate: json['latestDate'] == null
          ? null
          : DateTime.tryParse(json['latestDate'] as String),
      hasUnread: json['hasUnread'] as bool? ?? false,
      hasUserReply: json['hasUserReply'] as bool? ?? false,
      hasAttachments: json['hasAttachments'] as bool? ?? false,
      snippet: json['snippet'] as String? ?? '',
    );
  }
}
