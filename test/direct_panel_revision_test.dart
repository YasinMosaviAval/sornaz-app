import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/social_direct.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/chat_message_bubble.dart';
import 'native_panel_test.dart' show reply;
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'panel groups preserve granted sections and scope gallery categories',
    () {
      final keys = [
        'dashboard',
        'account',
        'chat',
        'awards',
        'badges',
        'branches',
        'branch-types',
        'gallery',
        'users',
        'roles',
        'lessons',
        'course-levels',
        'schedules',
        'classrooms',
        'finance',
      ];
      final menus = panelNavigation([
        for (final key in keys)
          {
            'key': key,
            'label': key,
            'actions': {'list': {}},
          },
      ]);
      List<Json> leaves(List<Json> items) => [
        for (final item in items)
          if (item['children'] is List)
            ...leaves(objects(item['children']))
          else
            item,
      ];
      final items = leaves(menus);
      expect(
        items.any((i) => ['chat', 'account', 'permissions'].contains(i['key'])),
        false,
      );
      expect(items.where((i) => i['key'] == 'gallery'), hasLength(4));
      expect(
        items.firstWhere((i) => i['key'] == 'awards')['label'],
        'پاداش‌ها و جوایز',
      );
      expect(
        menus.map((i) => i['key']),
        containsAll([
          'achievements-menu',
          'branches-menu',
          'access-menu',
          'gallery-menu',
          'lessons-menu',
          'classes-menu',
          'schedule-menu',
        ]),
      );
      final cover = items.firstWhere((i) => i['label'] == 'کاور');
      expect(cover['where'], {'category': 'cover'});
      expect(cover['initialParams'], {'collection': 'cover'});
      expect(
        items.where((i) => i['key'] != 'gallery').map((i) => i['key']).toSet(),
        keys.where((k) => !['account', 'chat', 'gallery'].contains(k)).toSet(),
      );
    },
  );
  testWidgets(
    'direct tabs preserve rows and do not refetch while switching or idle',
    (tester) async {
      var calls = 0;
      final api = SocialApi(
        'token',
        client: MockClient((r) async {
          calls++;
          return reply([
            {
              'id': 1,
              'type': 'direct',
              'title': 'Private member',
              'lastMessage': 'Hello',
              'unread': 1,
            },
            {
              'id': 2,
              'type': 'group',
              'title': 'Music group',
              'lastMessage': 'Welcome',
              'unread': 0,
            },
          ]);
        }),
      );
      await tester.pumpWidget(fixture.host(DirectPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Private member'), findsOneWidget);
      expect(find.text('Music group'), findsNothing);
      await tester.tap(find.text('گروهی'));
      await tester.pumpAndSettle();
      expect(find.text('Music group'), findsOneWidget);
      expect(find.text('Private member'), findsNothing);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'message has centered daily headers and compact independent actions',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData')
            copied = call.arguments['text'];
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      var reads = 0;
      final posts = <String>[];
      final payloads = <Json>[];
      final api = PanelApi(
        'token',
        client: MockClient((r) async {
          if (r.method == 'POST') {
            posts.add(r.url.path);
            final encoded = r.body
                .split('name="payload_b64"')
                .last
                .trim()
                .split(RegExp(r'\s'))
                .first;
            payloads.add(
              object(jsonDecode(utf8.decode(base64Decode(encoded)))),
            );
            return reply({'liked': true, 'likes': 1});
          }
          if (r.url.path.endsWith('/chat/list'))
            return reply({
              'conversations': [
                {'id': 9, 'title': 'Destination'},
              ],
            });
          reads++;
          return reply({
            'messages': [
              {
                'id': 1,
                'body': 'First message',
                'mine': true,
                'createdAt': '2026-09-21T09:01:00+03:30',
              },
              {
                'id': 2,
                'body': 'Second message',
                'mine': true,
                'createdAt': '2026-09-21T10:02:00+03:30',
              },
              {
                'id': 3,
                'body': 'Other day',
                'mine': false,
                'createdAt': '2026-09-22T11:03:00+03:30',
              },
            ],
          });
        }),
      );
      await tester.pumpWidget(
        fixture.host(
          PanelConversationPage(
            api: api,
            conversation: const {'id': 1, 'title': 'Chat'},
            section: const {
              'actions': {
                'like': {},
                'edit-message': {
                  'label': 'Edit',
                  'fields': [
                    {'key': 'body', 'type': 'multiline'},
                  ],
                },
                'forward': {
                  'label': 'Forward',
                  'fields': [
                    {
                      'key': 'conversationIds',
                      'type': 'multi',
                      'options': {'source': 'conversations'},
                    },
                  ],
                },
                'delete-message': {},
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-day-2026-09-21')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-day-2026-09-22')), findsOneWidget);
      expect(
        tester.getCenter(find.byKey(const ValueKey('chat-day-2026-09-22'))).dx,
        400,
      );
      final bubble = find.byWidgetPredicate(
        (w) => w is ChatMessageBubble && w.message['id'] == 2,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('message-body-2')),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: bubble, matching: find.byTooltip('پسندیدن پیام')),
      );
      await tester.pumpAndSettle();
      expect(posts.single, endsWith('/chat/like'));
      expect(reads, 1);
      await tester.tap(
        find.descendant(of: bubble, matching: find.byTooltip('کپی پیام')),
      );
      await tester.pumpAndSettle();
      expect(copied, 'Second message');
      await tester.tap(
        find.descendant(
          of: bubble,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ارسال در چت دیگر'), findsOneWidget);
      expect(find.text('پاک کردن پیام'), findsOneWidget);
      expect(find.text('ویرایش پیام'), findsNothing);
      await tester.tap(find.text('ارسال در چت دیگر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Destination'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.save_outlined));
      await tester.pumpAndSettle();
      expect(posts.last, endsWith('/chat/forward'));
      expect(payloads.last['conversationIds'], [9]);
      await tester.tap(
        find.descendant(of: bubble, matching: find.byTooltip('ویرایش پیام')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Second message',
      );
      await tester.enterText(find.byType(TextField), 'Edited message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(find.text('Edited message'), findsOneWidget);
      expect(payloads.last['body'], 'Edited message');
      await tester.tap(
        find.descendant(
          of: bubble,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('پاک کردن پیام'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(posts.last, endsWith('/chat/delete-message'));
      expect(find.text('Edited message'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
