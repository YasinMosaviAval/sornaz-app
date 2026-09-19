import 'package:sornaz/screens/Social/my_profile_page.dart';
import 'package:sornaz/screens/Social/user_panel.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'drawer_accounts_test.dart' as accounts;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/main_tab_scaffold.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/site_panel_page.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    '100 concurrent reads plus repeated reads send only one request',
    () async {
      var calls = 0;
      final gate = Completer<void>();
      final api = PanelApi(
        'one',
        client: MockClient((_) async {
          calls++;
          await gate.future;
          return http.Response('{"items":[{"id":1}]}', 200);
        }),
      );
      final reads = List.generate(
        100,
        (_) => api.get('/courses/list', {'page': '1'}),
      );
      gate.complete();
      final values = await Future.wait(reads);
      values.first['items'].clear();
      for (var i = 0; i < 100; i++) {
        expect(
          (await api.get('/courses/list', {'page': '1'}))['items'],
          hasLength(1),
        );
      }
      expect(calls, 1);
      api.dispose();
    },
  );
  test(
    'failure blocks queued requests and repeated retries across endpoints',
    () async {
      var calls = 0;
      final api = PanelApi(
        'one',
        client: MockClient((_) async {
          calls++;
          return http.Response('busy', 429, headers: {'retry-after': '120'});
        }),
      );
      final requests = List.generate(10, (i) async {
        await expectLater(
          api.get('/resource/$i'),
          throwsA(isA<SocialException>()),
        );
      });
      await Future.wait(requests);
      for (var i = 0; i < 20; i++) {
        await expectLater(api.refresh(''), throwsA(isA<SocialException>()));
      }
      expect(calls, 1);
      api.dispose();
    },
  );
  test(
    'cache isolates locale/account, refresh is throttled, mutation invalidates',
    () async {
      var calls = 0;
      final api = PanelApi(
        'one',
        client: MockClient((_) async {
          calls++;
          return http.Response('{"items":[]}', 200);
        }),
      );
      await api.get('');
      await api.refresh('');
      await api.refresh('');
      expect(calls, 2);
      await api.act('courses', 'create');
      await api.get('');
      expect(calls, 4);
      SocialApi.locale = 'en';
      await api.get('');
      expect(calls, 5);
      SocialApi.locale = 'fa';
      api.dispose();
      await expectLater(api.get(''), throwsA(isA<SocialException>()));
      expect(calls, 5);
    },
  );
  testWidgets(
    'panel stays mounted; crossing and revisiting tabs never reloads it',
    (tester) async {
      var calls = 0, otherLoads = 0;
      final api = PanelApi(
        'one',
        client: MockClient((_) async {
          calls++;
          return http.Response('{"sections":[]}', 200);
        }),
      );
      await tester.pumpWidget(
        fixture.host(
          MainTabs(
            pages: [
              const MainTabScaffold(index: 0, body: Text('home')),
              SitePanelPage(api: api),
              _LoadProbe(onLoad: () => otherLoads++),
              const MainTabScaffold(index: 3, body: Text('tools')),
              const MainTabScaffold(index: 4, body: Text('profile')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      // A non-adjacent jump must not mount or fetch intermediate tabs.
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .onTap!(4);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(otherLoads, 0);
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .onTap!(1);
      await tester.pumpAndSettle();
      expect(calls, 1);
      for (var i = 0; i < 5; i++) {
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .onTap!(0);
        await tester.pumpAndSettle();
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .onTap!(1);
        await tester.pumpAndSettle();
      }
      expect(calls, 1);
      expect(otherLoads, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('conversation idle time does not poll the server', (
    tester,
  ) async {
    var calls = 0;
    final api = PanelApi(
      'one',
      client: MockClient((_) async {
        calls++;
        return http.Response(jsonEncode({'messages': []}), 200);
      }),
    );
    await tester.pumpWidget(
      fixture.host(
        PanelConversationPage(
          api: api,
          section: const {'actions': {}},
          conversation: const {'id': 1, 'name': 'Chat'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pump(const Duration(minutes: 2));
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
    'sending fetches only the sent range and preserves the history cursor',
    (tester) async {
      final calls = <String>[];
      final api = PanelApi(
        'one',
        client: MockClient((r) async {
          calls.add(
            r.method == 'POST' ? 'send' : r.url.queryParameters['after']!,
          );
          if (r.method == 'POST') return http.Response('{"id":1000}', 200);
          final after = r.url.queryParameters['after'];
          final ids = after == '0'
              ? List.generate(200, (i) => i + 1)
              : after == '999'
              ? [1000]
              : [201];
          return http.Response(
            jsonEncode({
              'messages': [
                for (final id in ids)
                  {'id': id, 'body': 'message $id', 'mine': true},
              ],
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        fixture.host(
          PanelConversationPage(
            api: api,
            section: const {'actions': {}},
            conversation: const {'id': 1, 'name': 'Chat'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, ['0']);
      await tester.enterText(find.byType(TextField), 'new');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(calls, ['0', 'send', '999']);
      expect(find.text('message 1000'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('panel-more-messages')));
      await tester.pumpAndSettle();
      expect(calls.last, '200');
      expect(find.text('message 1000'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'notation is in tools, feed is central, and profile is separate',
    (tester) async {
      await tester.pumpWidget(
        accounts.host(
          const MainTabs(
            initialIndex: 3,
            pages: [
              SizedBox(),
              SitePanelPage(),
              UserPanelPage(),
              MusicToolsPage(),
              MyProfilePage(),
            ],
          ),
          AppData(),
          AuthSession(),
        ),
      );
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.items.map((i) => i.label).toList(), [
        'خانه',
        'پنل کاربری',
        'صحنه',
        'ابزار موسیقی',
        'پروفایل',
      ]);
      expect(find.widgetWithText(ListTile, 'نت‌نویسی'), findsOneWidget);
      nav.onTap!(4);
      await tester.pumpAndSettle();
      expect(find.byType(MyProfilePage), findsOneWidget);
      expect(find.byType(JoinCommunity), findsOneWidget);
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .onTap!(2);
      await tester.pumpAndSettle();
      expect(find.byType(UserPanelPage), findsOneWidget);
      expect(find.byType(JoinCommunity), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _LoadProbe extends StatefulWidget {
  const _LoadProbe({required this.onLoad});
  final VoidCallback onLoad;
  @override
  State<_LoadProbe> createState() => _LoadProbeState();
}

class _LoadProbeState extends State<_LoadProbe> {
  @override
  void initState() {
    super.initState();
    widget.onLoad();
  }

  @override
  Widget build(BuildContext context) => const Text('feed');
}
