import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_profile.dart';
import 'package:sornaz/screens/Social/my_profile_page.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'social_widget_test.dart' as localized;
import 'drawer_accounts_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets('portrait profile grid and bio below cover at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = SocialApi(
        'test',
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'success': true,
              'data': request.url.path.endsWith('/posts')
                  ? List.generate(
                      6,
                      (i) => {
                        'id': i + 1,
                        'body': 'Post $i',
                        'media': null,
                        'mime': 'text/plain',
                        'author': {'id': 1, 'name': 'Name'},
                      },
                    )
                  : {
                      'id': 1,
                      'username': 'user',
                      'name': 'Name',
                      'bio': 'Biography with room below the cover',
                      'isMe': true,
                      'posts': 6,
                      'courses': 0,
                      'followers': 0,
                      'following': 0,
                      'avatar': null,
                      'cover': null,
                    },
            }),
            200,
          ),
        ),
      );
      await tester.pumpWidget(localized.host(ProfilePage(api: api, userId: 1)));
      await tester.pumpAndSettle();
      expect(find.text('ویرایش پروفایل'), findsNothing);
      expect(find.text('مدیریت دوره‌ها'), findsNothing);
      expect(find.text('ذخیره‌شده‌ها'), findsNothing);
      final bio = tester.getRect(find.byKey(const ValueKey('profile-bio')));
      final name = tester.getRect(find.text('Name'));
      expect(bio.bottom, lessThanOrEqualTo(name.top));
      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('profile-post-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
      expect(delegate.childAspectRatio, 9 / 16);
      final first = tester.getRect(
        find.byKey(const ValueKey('profile-post-1')),
      );
      final third = tester.getRect(
        find.byKey(const ValueKey('profile-post-3')),
      );
      expect(first.top, third.top);
      expect(first.width / first.height, closeTo(9 / 16, .001));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }
  testWidgets('profile FAB opens all three publishing options', (tester) async {
    final api = SocialApi(
      'test',
      client: MockClient(
        (r) async => http.Response(
          jsonEncode({
            'success': true,
            'data': r.url.path.endsWith('/posts')
                ? []
                : {
                    'id': 1,
                    'username': 'user',
                    'name': 'Name',
                    'bio': '',
                    'isMe': true,
                    'posts': 0,
                    'courses': 0,
                    'followers': 0,
                    'following': 0,
                  },
          }),
          200,
        ),
      ),
    );
    final auth = AuthSession()
      ..token = 'test'
      ..user = fixture.account(1).user;
    await tester.pumpWidget(
      fixture.host(MyProfilePage(api: api), AppData(), auth),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('پست جدید'), findsOneWidget);
    expect(find.text('استوری جدید'), findsOneWidget);
    expect(find.text('دوره جدید'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
