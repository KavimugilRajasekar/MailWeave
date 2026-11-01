import 'dart:convert';

import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

const Map<String, String> _jsonHeader = {
  'content-type': 'application/json; charset=utf-8',
};

/// Builds a real [GmailApi] backed by an in-memory fake HTTP client that
/// returns canned, schema-accurate Gmail JSON. This exercises the actual
/// `threads.list` / `threads.get` parsing path (via googleapis) without a
/// network or a signed-in account.
GmailApi fakeGmailApi() {
  return GmailApi(MockClient((request) async {
    final segments = request.url.pathSegments;

    // users/me/threads  -> list
    if (segments.isNotEmpty && segments.last == 'threads') {
      return Response(
        jsonEncode(_listJson(request.url.queryParameters['pageToken'])),
        200,
        headers: _jsonHeader,
      );
    }

    // users/me/threads/{id} -> get
    if (segments.length >= 2 && segments[segments.length - 2] == 'threads') {
      final id = segments.last;
      return Response(jsonEncode(_threadJson(id)), 200, headers: _jsonHeader);
    }

    return Response('{}', 404, headers: _jsonHeader);
  }));
}

// ── Canned responses ────────────────────────────────────────────────────────

Map<String, Object?> _listJson(String? pageToken) {
  if (pageToken == null) {
    return {
      'threads': <Map<String, Object?>>[{'id': 't1'}],
      'nextPageToken': 'p2',
    };
  }
  return {'threads': <Map<String, Object?>>[{'id': 't2'}]};
}

Map<String, Object?> _threadJson(String id) {
  switch (id) {
    case 't1':
      return _thread('t1', [_a(), _b(), _c()]);
    case 't2':
      return _thread('t2', [_d()]);
    default:
      return {'id': id, 'messages': <Map<String, Object?>>[]};
  }
}

Map<String, Object?> _thread(String id, List<Map<String, Object?>> messages) {
  return {'id': id, 'messages': messages};
}

Map<String, Object?> _msg({
  required String id,
  String threadId = 't1',
  List<String> labelIds = const [],
  String snippet = '',
  required int internalDate,
  String? from,
  String? to,
  String? cc,
  String? subject,
  String? messageId,
  String? inReplyTo,
  String? references,
  bool attachment = false,
  String bodyText = 'Hello there',
}) {
  final headers = <Map<String, String>>[];
  void add(String n, String? v) {
    if (v != null && v.isNotEmpty) headers.add({'name': n, 'value': v});
  }
  add('From', from);
  add('To', to);
  add('Cc', cc);
  add('Subject', subject);
  add('Message-ID', messageId);
  add('In-Reply-To', inReplyTo);
  add('References', references);

  final parts = <Map<String, Object?>>[
    {
      'partId': '0',
      'mimeType': 'text/plain',
      'filename': '',
      'body': {'data': base64Encode(utf8.encode(bodyText)), 'size': bodyText.length},
    },
  ];
  if (attachment) {
    parts.add({
      'partId': '1',
      'mimeType': 'application/pdf',
      'filename': 'doc.pdf',
      'body': {'attachmentId': 'att-$id', 'size': 1000},
    });
  }

  return {
    'id': id,
    'threadId': threadId,
    if (labelIds.isNotEmpty) 'labelIds': labelIds,
    'snippet': snippet,
    'internalDate': internalDate.toString(),
    'payload': {
      'mimeType': 'multipart/mixed',
      'filename': '',
      'headers': headers,
      'parts': parts,
    },
  };
}

// Thread t1: Alice (original) -> You + Bob (sibling replies).
Map<String, Object?> _a() => _msg(
      id: 'a',
      threadId: 't1',
      labelIds: ['INBOX'],
      snippet: 'Hello there',
      internalDate: 1700000000000,
      from: 'Alice <alice@example.com>',
      to: 'you@x.com',
      subject: 'Hello',
      messageId: '<a@x>',
    );

Map<String, Object?> _b() => _msg(
      id: 'b',
      threadId: 't1',
      labelIds: ['SENT'],
      snippet: 'Hi Alice',
      internalDate: 1700000060000,
      from: 'You <you@x.com>',
      to: 'alice@example.com',
      subject: 'Re: Hello',
      messageId: '<b@x>',
      inReplyTo: '<a@x>',
      bodyText: 'Hi Alice',
    );

Map<String, Object?> _c() => _msg(
      id: 'c',
      threadId: 't1',
      labelIds: ['INBOX', 'UNREAD'],
      snippet: 'See attached',
      internalDate: 1700000120000,
      from: 'Bob <bob@example.com>',
      to: 'you@x.com',
      subject: 'Re: Hello',
      messageId: '<c@x>',
      inReplyTo: '<a@x>',
      attachment: true,
      bodyText: 'See attached',
    );

// Thread t2: a single message from Carol.
Map<String, Object?> _d() => _msg(
      id: 'd',
      threadId: 't2',
      labelIds: ['INBOX'],
      snippet: 'Meeting invite',
      internalDate: 1700000180000,
      from: 'Carol <carol@example.com>',
      to: 'you@x.com',
      subject: 'Meeting',
      messageId: '<d@x>',
      bodyText: 'Meeting invite',
    );
