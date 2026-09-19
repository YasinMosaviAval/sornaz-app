import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/services/auth_api_service.dart';
import 'package:sornaz/screens/Site/academy_registration.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Home/ui/pages/learning_home.dart';
import 'package:sornaz/screens/Site/academy_search.dart';
import 'package:sornaz/screens/Site/site_api.dart';
import 'package:sornaz/screens/Site/site_panel_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'drawer_accounts_test.dart' as fixture;
import 'social_widget_test.dart' as localized;

http.Response reply(Object value, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode({'status': status, 'data': value})),
  status,
);
SiteApi optionsApi() => SiteApi(
  client: MockClient(
    (_) async => reply({
      'instruments': [
        {'id': 2, 'title': 'پیانو'},
      ],
      'cities': [
        {'id': 5, 'title': 'تهران'},
      ],
    }),
  ),
);
void main() {
  for (final type in ['human', 'academy', 'branch', 'guest']) {
    testWidgets(
      'home academy sections are restricted by account type ' + type,
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final session = AuthSession();
        if (type != 'guest')
          await session.save(
            AuthResult(
              token: 'test',
              user: AuthUser(
                id: 7,
                username: 'user',
                fullName: 'User',
                type: type,
              ),
            ),
          );
        var optionRequests = 0;
        final site = SiteApi(
          client: MockClient((_) async {
            optionRequests++;
            return reply({'instruments': [], 'cities': []});
          }),
        );
        final api = SocialApi(
          '',
          client: MockClient(
            (_) async => reply({
              'success': true,
              'data': {'courses': [], 'authors': []},
            }),
          ),
        );
        await tester.pumpWidget(
          fixture.host(
            HomePage(api: api, academyApi: site, articleLoader: () async => []),
            AppData(),
            session,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(AcademySearchCard),
          type == 'human' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(AcademyRegistrationCard),
          type == 'human' ? findsOneWidget : findsNothing,
        );
        expect(optionRequests, type == 'human' ? 1 : 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
        site.dispose();
      },
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SocialApi.locale = 'fa';
  });
  for (final width in [320.0, 430.0]) {
    testWidgets(
      'academy form searches by name, instrument and city at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = optionsApi();
        Map<String, String>? selection;
        await tester.pumpWidget(
          localized.host(
            Scaffold(
              body: SingleChildScrollView(
                child: AcademySearchCard(
                  api: api,
                  onSearch: (filters) => selection = filters,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '  سرناز  ');
        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('پیانو').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('تهران').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(selection, {'q': 'سرناز', 'instrument': '2', 'city': '5'});
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }
  testWidgets(
    'academy results preserve filters across pages and retry errors',
    (tester) async {
      var calls = 0;
      final api = SiteApi(
        client: MockClient((request) async {
          calls++;
          expect(request.url.queryParameters['q'], 'سرناز');
          expect(request.url.queryParameters['city'], '5');
          if (calls == 1) return reply({}, 503);
          final page = int.parse(request.url.queryParameters['page']!);
          return reply({
            'items': [
              {'id': page, 'name': 'Academy $page', 'city': 'Tehran'},
            ],
            'has_more': page == 1,
          });
        }),
      );
      await tester.pumpWidget(
        localized.host(
          AcademyResultsPage(
            api: api,
            filters: const {'q': 'سرناز', 'city': '5'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('آموزشگاه‌ها دریافت نشدند.'), findsOneWidget);
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Academy 1'), findsOneWidget);
      await tester.tap(find.text('نمایش بیشتر'));
      await tester.pumpAndSettle();
      expect(find.text('Academy 2'), findsOneWidget);
      expect(find.text('نمایش بیشتر'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'home replaces new courses with academy search while keeping updated courses',
    (tester) async {
      final site = optionsApi();
      final api = SocialApi(
        '',
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'courses': [
                  {
                    'id': 4,
                    'title': 'Lesson',
                    'updated_at': '2026-09-12',
                    'price': 0,
                  },
                ],
                'authors': [],
              },
            }),
            200,
          ),
        ),
      );
      final session = AuthSession();
      await session.save(fixture.account(7));
      await tester.pumpWidget(
        fixture.host(
          HomePage(api: api, academyApi: site, articleLoader: () async => []),
          AppData(),
          session,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('دوره‌های جدید'), findsNothing);
      expect(find.byType(AcademySearchCard), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('دوره‌های به‌روزشده'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text('دوره‌های به‌روزشده'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      site.dispose();
      api.dispose();
    },
  );
  testWidgets(
    'second tab is the panel, guests can join, and profile remains a separate destination',
    (tester) async {
      await tester.pumpWidget(
        fixture.host(
          const MainTabs(
            pages: [
              Center(child: Text('home body')),
              SitePanelPage(),
              SizedBox(),
              SizedBox(),
              Center(child: Text('profile body')),
            ],
          ),
          AppData(),
          AuthSession(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('دوره‌ها'), findsNothing);
      expect(find.text('پنل کاربری'), findsOneWidget);
      await tester.tap(find.text('پنل کاربری'));
      await tester.pumpAndSettle();
      expect(find.byType(JoinCommunity), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        1,
      );
      expect(find.byType(BottomNavBarWidget), findsOneWidget);
      await tester.tap(find.text('پروفایل'));
      await tester.pumpAndSettle();
      expect(find.text('profile body'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
