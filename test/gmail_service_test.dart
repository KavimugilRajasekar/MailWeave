import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mailweave/models/inbox_category.dart';
import 'package:mailweave/services/gmail_service.dart';

import 'fake_gmail.dart';

/// Drives the real `googleapis` `GmailApi` against a fake HTTP client that
/// returns schema-accurate Gmail JSON. Verifies the fetch -> parse -> tree
/// pipeline end-to-end without a network or a signed-in account.
void main() {
  test('listConversations parses threads, fields, and the reply tree', () async {
    final service = GmailService(fakeGmailApi(), currentUserEmail: 'you@x.com');

    final page = await service.listConversations(maxResults: 1);
    expect(page.threads.length, 1);
    expect(page.nextPageToken, 'p2');

    final t = page.threads.single;
    expect(t.id, 't1');
    expect(t.subject, 'Hello');
    expect(t.messageCount, 3);
    expect(t.hasUnread, isTrue); // Bob's reply is unread
    expect(t.hasUserReply, isTrue); // "You" replied
    expect(t.hasAttachments, isTrue); // Bob attached a file
    expect(t.roots.length, 1);
    expect(t.roots.first.children.length, 2); // sibling replies branch off the original
  });

  test('pagination walks the next page until exhausted', () async {
    final service = GmailService(fakeGmailApi(), currentUserEmail: 'you@x.com');

    final page1 = await service.listConversations(maxResults: 1);
    expect(page1.threads.first.id, 't1');
    expect(page1.nextPageToken, 'p2');

    final page2 =
        await service.listConversations(pageToken: page1.nextPageToken, maxResults: 1);
    expect(page2.threads.first.id, 't2');
    expect(page2.threads.first.messageCount, 1);
    expect(page2.nextPageToken, isNull);
  });

  test('participants are collected and deduped', () async {
    final service = GmailService(fakeGmailApi(), currentUserEmail: 'you@x.com');
    final t = (await service.listConversations(maxResults: 1)).threads.single;
    final emails = t.participants.map((p) => p.email).toSet();
    expect(emails, containsAll(['alice@example.com', 'you@x.com', 'bob@example.com']));
  });

  test('current-user identity distinguishes sent vs received', () async {
    final service = GmailService(fakeGmailApi(), currentUserEmail: 'you@x.com');
    final t = (await service.listConversations(maxResults: 1)).threads.single;
    final sentByYou = t.messages.where((m) => m.isFromCurrentUser).toList();
    expect(sentByYou.length, 1);
    expect(sentByYou.single.sent, isTrue);
    expect(t.messages.where((m) => !m.isFromCurrentUser).length, 2);
  });

  test('category filter is passed to threads.list as labelIds', () async {
    String? seenLabelIds;
    final client = MockClient((request) async {
      if (request.url.pathSegments.last == 'threads') {
        seenLabelIds = request.url.queryParametersAll['labelIds']?.firstOrNull;
        return Response(
          jsonEncode({'threads': <Map<String, Object?>>[]}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      return Response('{}', 200, headers: const {'content-type': 'application/json'});
    });
    final service = GmailService(GmailApi(client), currentUserEmail: 'you@x.com');
    await service.listConversations(category: InboxCategory.promotions);
    expect(seenLabelIds, 'CATEGORY_PROMOTIONS');
  });
}
