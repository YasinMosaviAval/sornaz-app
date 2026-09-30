import 'package:sornaz/components/main_tab_scaffold.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/screens/Notation/notation_api.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'main destinations swipe, buttons select, back returns home then exits',
    (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        fixture.host(
          MainTabs(
            pages: List.generate(
              5,
              (index) => MainTabScaffold(
                index: index,
                appBar: AppBar(title: Text('header $index')),
                body: Center(child: Text('page $index')),
                bottomNavigationBar: BottomNavBarWidget(selectedIndex: index),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byType(AppBar),
        ),
        findsNothing,
      );
      expect(find.byType(BottomNavBarWidget), findsOneWidget);
      final barRect = tester.getRect(find.byType(BottomNavBarWidget));
      expect(barRect.height, 48);
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('page 1'), findsOneWidget);
      expect(tester.getRect(find.byType(BottomNavBarWidget)), barRect);
      await tester.tap(find.byIcon(Icons.tune).first);
      await tester.pumpAndSettle();
      expect(find.text('page 3'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('page 0'), findsOneWidget);
      expect(calls, isNot(contains('SystemNavigator.pop')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(calls, contains('SystemNavigator.pop'));
    },
  );
  test(
    'phone-authored sheets save offline, survive restart and stay account scoped',
    () async {
      var networkCalls = 0;
      final api = NotationApi(
        'token',
        userId: 12,
        client: MockClient((_) async {
          networkCalls++;
          throw http.ClientException('offline');
        }),
      );
      final saved = await api.request('save', {
        'sheetId': 0,
        'payload': {
          'metadata': {'title': 'Local'},
          'score': {'measures': []},
        },
      });
      expect(saved['id'], isNegative);
      expect(saved['local'], true);
      expect(saved['uploaded'], false);
      expect(networkCalls, 0);
      api.close();
      MockClient offline() =>
          MockClient((_) async => throw http.ClientException('offline'));
      final reopened = NotationApi('token', userId: 12, client: offline());
      final result = await reopened.request('get', {'sheetId': saved['id']});
      expect(result['metadata']['title'], 'Local');
      final list = await reopened.request('list', {'mode': 'mine', 'page': 1});
      expect(list['items'], hasLength(1));
      await reopened.request('create-list', {'name': 'تمرین‌ها'});
      await reopened.request('add-to-list', {
        'name': 'تمرین‌ها',
        'sheetIds': [saved['id']],
      });
      final lists = await reopened.request('list', {
        'mode': 'lists',
        'page': 1,
      });
      expect(
        lists['items'],
        contains(
          allOf(
            containsPair('title', 'تمرین‌ها'),
            containsPair('count', 1),
            containsPair('items', hasLength(1)),
          ),
        ),
      );
      expect(
        lists['items'],
        contains(
          allOf(
            containsPair('id', NotationApi.favoriteList),
            containsPair('favorite', true),
          ),
        ),
      );
      final other = NotationApi('another', userId: 13, client: offline());
      await expectLater(
        other.request('get', {'sheetId': saved['id']}),
        throwsA(isA<FormatException>()),
      );
      reopened.close();
      other.close();
    },
  );
  test('mine excludes cached public sheets owned by another user', () async {
    final api = NotationApi(
      'token',
      userId: 12,
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await api.remember({
      'id': 42,
      'owner_id': 99,
      'editable': false,
      'visibility': 'public',
      'metadata': {'title': 'Someone else'},
      'score': {'measures': []},
    });
    await api.request('save', {
      'sheetId': 0,
      'payload': {
        'metadata': {'title': 'My score'},
        'score': {'measures': []},
      },
    });
    final mine = await api.request('list', {'mode': 'mine', 'page': 1});
    final all = await api.request('list', {'mode': 'all', 'page': 1});
    expect((mine['items'] as List).map((item) => item['title']), ['My score']);
    expect((all['items'] as List).length, 2);
    api.close();
  });
  test('upload is explicit and preserves the local score id', () async {
    final requests = <http.Request>[];
    final api = NotationApi(
      'token',
      userId: 12,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 91, 'version': 4},
          }),
          200,
        );
      }),
    );
    final local = await api.request('save', {
      'sheetId': 0,
      'payload': {
        'metadata': {'title': 'Upload later'},
        'score': {'measures': []},
      },
    });
    expect(requests, isEmpty);
    final uploaded = await api.request('upload', {'sheetId': local['id']});
    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(uploaded['id'], local['id']);
    expect(uploaded['remote_id'], 91);
    expect(uploaded['uploaded'], true);
    final edited = await api.request('save', {
      'sheetId': local['id'],
      'payload': {
        'metadata': {'title': 'Edited offline'},
        'score': {'measures': []},
      },
    });
    expect(edited['uploaded'], false);
    await api.request('upload', {'sheetId': local['id']});
    expect(requests.last.url.path, endsWith('/music-sheets/91'));
    expect(jsonDecode(requests.last.body)['version'], 4);
    api.close();
  });
}
