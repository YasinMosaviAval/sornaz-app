import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_profile.dart';
import 'package:sornaz/screens/Social/social_courses.dart';

Widget host(Widget child, {bool dark = false}) => ChangeNotifierProvider(
  create: (_) => AppData()..toggleDarkMode(dark),
  child: MaterialApp(
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  ),
);
http.Response jsonResponse(String body, int status) =>
    http.Response.bytes(utf8.encode(body), status);
void main() {
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('profile follows successfully without overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var following = false;
      final api = SocialApi(
        'test',
        client: MockClient((request) async {
          if (request.method == 'POST') following = true;
          final dynamic data = request.url.path.endsWith('/posts')
              ? <dynamic>[]
              : {
                  'id': 2,
                  'username': 'guitar',
                  'name': 'مدرس گیتار',
                  'bio': 'آموزش از پایه',
                  'followers': following ? 1 : 0,
                  'following': 0,
                  'courses': 0,
                  'posts': 0,
                  'isMe': false,
                  'isFollowing': following,
                  'avatar': null,
                  'cover': null,
                };
          return jsonResponse(
            jsonEncode({
              'status': 200,
              'data': {'success': true, 'data': data},
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        host(ProfilePage(api: api, userId: 2), dark: width == 430),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('دنبال کردن'));
      await tester.pumpAndSettle();
      expect(find.text('دنبال می‌کنید'), findsOneWidget);
      expect(following, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }
  testWidgets('course editor saves a real curriculum payload', (tester) async {
    Json? saved;
    final api = SocialApi(
      'test',
      client: MockClient((request) async {
        saved = object(jsonDecode(request.bodyFields['payload']!));
        return jsonResponse(
          jsonEncode({
            'status': 200,
            'data': {
              'success': true,
              'data': {...saved!, 'id': 1, 'version': 1},
            },
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(host(CourseEditorPage(api: api)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'آموزش گیتار');
    await tester.ensureVisible(find.text('افزودن فصل'));
    await tester.tap(find.text('افزودن فصل'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'فصل اول',
    );
    await tester.tap(find.text('ثبت').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ذخیره پیش‌نویس'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('ذخیره پیش‌نویس'));
    await tester.pumpAndSettle();
    expect(saved?['title'], 'آموزش گیتار');
    expect(saved?['status'], 'draft');
    expect(saved?['curriculum'][0]['title'], 'فصل اول');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
