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
              (index) => MainTabScaffold(index:index,appBar:AppBar(title:Text('header $index')),
                body: Center(child: Text('page $index')),
                bottomNavigationBar: BottomNavBarWidget(selectedIndex: index),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of:find.byType(PageView),matching:find.byType(AppBar)),findsNothing);
      expect(find.byType(BottomNavigationBar),findsOneWidget);
      final barRect=tester.getRect(find.byType(BottomNavigationBar));
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('page 1'), findsOneWidget);
      expect(tester.getRect(find.byType(BottomNavigationBar)),barRect);
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
    'phone-authored sheets survive restart and are isolated by account',
    () async {
      final score = {
        'id': 7,
        'version': 1,
        'editable': true,
        'saved': false,
        'metadata': {'title': 'Local'},
        'score': {'measures': []},
      };
      final api = NotationApi(
        'token',
        userId: 12,
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({'success': true, 'data': score}), 200),
        ),
      );
      await api.request('save', {
        'sheetId': 0,
        'payload': {'metadata': {}, 'score': {}},
      });
      api.close();
      MockClient offline() =>
          MockClient((_) async => throw http.ClientException('offline'));
      final reopened = NotationApi('token', userId: 12, client: offline());
      final result = await reopened.request('get', {'sheetId': 7});
      expect(result['metadata']['title'], 'Local');
      final list = await reopened.request('list', {'mode': 'mine', 'page': 1});
      expect(list['items'], hasLength(1));
      final other = NotationApi('another', userId: 13, client: offline());
      await expectLater(
        other.request('get', {'sheetId': 7}),
        throwsA(isA<http.ClientException>()),
      );
      reopened.close();
      other.close();
    },
  );
}
