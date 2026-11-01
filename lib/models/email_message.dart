import 'dart:convert';

import 'package:googleapis/gmail/v1.dart';

/// One email address with an optional display name.
class EmailAddress {
  const EmailAddress({this.name, this.email});

  final String? name;
  final String? email;

  /// Parses a single address string like `"Name" <a@b.com>` or `a@b.com`.
  factory EmailAddress.parse(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return const EmailAddress();

    final lt = s.indexOf('<');
    final gt = s.indexOf('>');
    if (lt != -1 && gt != -1 && gt > lt) {
      var name = s.substring(0, lt).trim();
      if (name.startsWith('"') && name.endsWith('"')) {
        name = name.substring(1, name.length - 1);
      }
      final email = s.substring(lt + 1, gt).trim();
      return EmailAddress(name: name.isEmpty ? null : name, email: email);
    }
    return EmailAddress(email: s);
  }

  @override
  String toString() {
    if (name != null && email != null) return '$name <$email>';
    return email ?? name ?? '';
  }

  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  factory EmailAddress.fromJson(Map<String, dynamic> json) => EmailAddress(
        name: json['name'] as String?,
        email: json['email'] as String?,
      );
}

/// A single Gmail message, parsed from the Gmail API into a readable shape.
class EmailMessage {
  const EmailMessage({
    required this.id,
    required this.threadId,
    required this.messageId,
    required this.inReplyTo,
    required this.references,
    required this.subject,
    required this.from,
    required this.to,
    required this.cc,
    required this.date,
    required this.snippet,
    required this.bodyText,
    required this.unread,
    required this.sent,
    required this.hasAttachments,
    required this.isFromCurrentUser,
    required this.forwarded,
  });

  final String id;
  final String? threadId;

  /// Normalized `Message-ID` header (lowercased, angle-brackets stripped).
  final String? messageId;
  final String? inReplyTo;
  final List<String> references;

  final String subject;
  final EmailAddress from;
  final List<EmailAddress> to;
  final List<EmailAddress> cc;
  final DateTime? date;
  final String snippet;

  /// Best-effort plain-text body extracted from the payload (for the detail
  /// view). May be empty when only an HTML part is available.
  final String bodyText;

  final bool unread;
  final bool sent;
  final bool hasAttachments;
  final bool isFromCurrentUser;
  final bool forwarded;

  /// True when this message was received (not sent by the current user).
  bool get isReceived => !sent;

  /// Parses a Gmail [Message] into a readable [EmailMessage].
  factory EmailMessage.fromGmailMessage(
    Message message, {
    String? currentUserEmail,
  }) {
    final headers = _headerMap(message.payload?.headers);
    final currentUser = currentUserEmail?.toLowerCase().trim();

    final from = EmailAddress.parse(headers['from'] ?? '');
    final isFromCurrentUser = _matchesUser(from.email, currentUser);
    final date = _parseDate(message.internalDate, headers['date']);

    return EmailMessage(
      id: message.id ?? '',
      threadId: message.threadId,
      messageId: _normalizeId(headers['message-id']),
      inReplyTo: _normalizeId(headers['in-reply-to']),
      references: _normalizeReferences(headers['references']),
      subject: (headers['subject'] ?? '').trim(),
      from: from,
      to: _parseAddresses(headers['to']),
      cc: _parseAddresses(headers['cc']),
      date: date,
      snippet: (message.snippet ?? '').trim(),
      bodyText: _extractBody(message.payload),
      unread: message.labelIds?.contains('UNREAD') ?? false,
      sent: message.labelIds?.contains('SENT') ?? false,
      hasAttachments: _hasAttachments(message.payload),
      isFromCurrentUser: isFromCurrentUser,
      forwarded: _looksForwarded(headers['subject']),
    );
  }

  /// Serialise to JSON for local secure-storage caching.
  Map<String, dynamic> toJson() => {
        'id': id,
        'threadId': threadId,
        'messageId': messageId,
        'inReplyTo': inReplyTo,
        'references': references,
        'subject': subject,
        'from': from.toJson(),
        'to': to.map((a) => a.toJson()).toList(),
        'cc': cc.map((a) => a.toJson()).toList(),
        'date': date?.toIso8601String(),
        'snippet': snippet,
        'unread': unread,
        'sent': sent,
        'hasAttachments': hasAttachments,
        'isFromCurrentUser': isFromCurrentUser,
        'forwarded': forwarded,
      };

  /// Restore a cached message. `bodyText` is intentionally not cached.
  factory EmailMessage.fromJson(Map<String, dynamic> json) => EmailMessage(
        id: json['id'] as String? ?? '',
        threadId: json['threadId'] as String?,
        messageId: json['messageId'] as String?,
        inReplyTo: json['inReplyTo'] as String?,
        references:
            (json['references'] as List<dynamic>?)?.cast<String>() ?? const [],
        subject: json['subject'] as String? ?? '',
        from: json['from'] == null
            ? const EmailAddress()
            : EmailAddress.fromJson(
                (json['from'] as Map<dynamic, dynamic>).cast<String, Object?>()),
        to: ((json['to'] as List<dynamic>?) ?? const [])
            .map((e) => EmailAddress.fromJson((e as Map).cast<String, Object?>()))
            .toList(),
        cc: ((json['cc'] as List<dynamic>?) ?? const [])
            .map((e) => EmailAddress.fromJson((e as Map).cast<String, Object?>()))
            .toList(),
        date: json['date'] == null ? null : DateTime.tryParse(json['date'] as String),
        snippet: json['snippet'] as String? ?? '',
        bodyText: '',
        unread: json['unread'] as bool? ?? false,
        sent: json['sent'] as bool? ?? false,
        hasAttachments: json['hasAttachments'] as bool? ?? false,
        isFromCurrentUser: json['isFromCurrentUser'] as bool? ?? false,
        forwarded: json['forwarded'] as bool? ?? false,
      );
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Map<String, String> _headerMap(List<MessagePartHeader>? headers) {
  final map = <String, String>{};
  if (headers == null) return map;
  for (final h in headers) {
    final name = h.name?.toLowerCase() ?? '';
    final value = h.value ?? '';
    if (name.isNotEmpty) map.putIfAbsent(name, () => value);
  }
  return map;
}

bool _matchesUser(String? email, String? currentUser) {
  if (email == null || currentUser == null || currentUser.isEmpty) return false;
  return email.toLowerCase().trim() == currentUser;
}

DateTime? _parseDate(String? internalDate, String? dateHeader) {
  if (internalDate != null && internalDate.isNotEmpty) {
    final ms = int.tryParse(internalDate);
    if (ms != null) {
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
  }
  if (dateHeader != null && dateHeader.isNotEmpty) {
    try {
      return DateTime.parse(
        dateHeader
            .replaceAll(RegExp(r'\s*\(.*?\)\s*$'), '')
            .replaceAll('GMT', '+0000'),
      ).toLocal();
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Lowercases and strips angle brackets/comments to get a single, comparable id.
String? _normalizeId(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;
  final match = RegExp(r'<([^>]+)>').firstMatch(s);
  if (match != null) return match.group(1)!.trim();
  final token = s.split(RegExp(r'\s+')).first;
  return token.isEmpty ? null : token;
}

List<String> _normalizeReferences(String? raw) {
  if (raw == null) return const [];
  final ids = <String>{};
  for (final m in RegExp(r'<([^>]+)>').allMatches(raw)) {
    final id = m.group(1)?.trim().toLowerCase();
    if (id != null && id.isNotEmpty) ids.add(id);
  }
  if (ids.isEmpty) {
    for (final token in raw.split(RegExp(r'\s+'))) {
      final t = token.trim().toLowerCase();
      if (t.isNotEmpty) ids.add(t);
    }
  }
  return ids.toList();
}

List<EmailAddress> _parseAddresses(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((part) => EmailAddress.parse(part))
      .where((a) => a.email != null || a.name != null)
      .toList();
}

/// Detects attachments from the payload structure (any part carrying a
/// filename) rather than relying on an icon heuristic.
bool _hasAttachments(MessagePart? part) {
  if (part == null) return false;
  if (part.filename != null && part.filename!.isNotEmpty) return true;
  for (final child in part.parts ?? const <MessagePart>[]) {
    if (_hasAttachments(child)) return true;
  }
  return false;
}

/// Best-effort inference: a "Fwd:"/"FW:" subject suggests a forwarded message.
/// Not authoritative — headers/subjects are not always reliable.
bool _looksForwarded(String? subject) {
  if (subject == null) return false;
  final s = subject.trim().toLowerCase();
  return s.startsWith('fwd:') || s.startsWith('fw:') || s.startsWith('fwd ');
}

String _extractBody(MessagePart? part) {
  if (part == null) return '';
  if (part.mimeType == 'text/plain' && part.body?.data != null) {
    return _decodeBody(part.body!.data!);
  }
  for (final child in part.parts ?? const <MessagePart>[]) {
    final text = _extractBody(child);
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _decodeBody(String data) {
  try {
    final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
    final padded = normalized + '=' * ((4 - normalized.length % 4) % 4);
    return utf8.decode(base64.decode(padded));
  } catch (_) {
    return '';
  }
}
