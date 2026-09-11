import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Home/ui/pages/learning_home.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/course_cache.dart';
import 'drawer_accounts_test.dart' as fixture;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CourseCache.checked.clear();
  });
  testWidgets('empty course sections disappear and search is in the top bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = SocialApi(
      '',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {'courses': [], 'authors': []},
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      fixture.host(
        HomePage(api: api, articleLoader: () async => []),
        AppData(),
        AuthSession(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-search')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('open-home-search')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(const ValueKey('home-search')),
      ),
      findsOneWidget,
    );
    expect(find.text('دوره‌های جدید'), findsNothing);
    expect(find.text('دوره‌های به‌روزشده'), findsNothing);
    expect(find.text('برای شروع یادگیری'), findsNothing);
    expect(find.text('ابزار موسیقی'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
