import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:sornaz/screens/Social/social_activity.dart';
import 'package:sornaz/screens/Social/social_api.dart';

void main() {
  test('stage counts activity notifications and conversations separately', () {
    final notifications = <Json>[
      {'kind': 'comment', 'read_at': null},
      {'kind': 'like', 'read_at': 'read'},
      {'kind': 'post', 'read_at': null},
      {'kind': 'message', 'read_at': null},
    ];
    expect(unreadStageActivityCount(notifications), 2);
    expect(
      unreadConversationCount([
        {'id': 1, 'unread': 4},
        {'id': 2, 'unread': 1},
        {'id': 3, 'unread': 0},
      ]),
      2,
    );
  });

  testWidgets('stage notifications do not show direct messages', (
    tester,
  ) async {
    final api = SocialApi(
      'token',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 200,
            'data': {
              'success': true,
              'data': [
                {
                  'id': 1,
                  'kind': 'message',
                  'actor': {'name': 'User'},
                  'body': 'sent a message',
                  'created_at': 'today',
                },
                {
                  'id': 2,
                  'kind': 'comment',
                  'actor': {'name': 'User'},
                  'body': 'commented',
                  'created_at': 'today',
                },
                {
                  'id': 3,
                  'kind': 'follow',
                  'actor': {'name': 'User'},
                  'body': 'followed',
                  'created_at': 'today',
                },
              ],
            },
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: NotificationsPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.textContaining('sent a message'), findsNothing);
    expect(find.textContaining('commented'), findsOneWidget);
    expect(find.textContaining('followed'), findsOneWidget);
    api.dispose();
  });
}
