import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_courses.dart';
import 'package:sornaz/screens/Social/course_experience.dart';
import 'package:sornaz/screens/Social/course_cache.dart';
import 'package:sornaz/screens/Social/course_metadata_editor.dart';
import 'social_widget_test.dart' as fixture;

final course = <String, dynamic>{
  'id': 7,
  'title': 'دوره رایگان',
  'description': 'توضیحات دوره',
  'price': 0,
  'status': 'published',
  'cover_id': 4,
  'owner_id': 1,
  'details': [],
  'category': '',
  'duration_seconds': 0,
  'lesson_count': 2,
  'rating': {'average': '0.0000', 'count': 0},
  'author': {'id': 1, 'name': 'Sornaz'},
  'curriculum': [
    {
      'title': 'فصل اول',
      'lessons': [
        {'post_id': 460, 'title': 'درس اول', 'locked': false},
      ],
    },
  ],
  'schedule': null,
  'access': false,
};
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CourseCache.checked.clear();
  });
  for (final offline in [false, true]) {
    testWidgets(
      'course list opens details with PHP empty metadata, offline=$offline',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (offline) {
          SharedPreferences.setMockInitialValues({
            CourseCache.key('', SocialApi.locale, '/courses?mode=catalog'):
                jsonEncode([course]),
            CourseCache.key('', SocialApi.locale, '/courses/7'): jsonEncode(
              course,
            ),
          });
        }
        final api = SocialApi(
          '',
          client: MockClient((request) async {
            if (offline) throw http.ClientException('offline');
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'status': 200,
                  'data': {
                    'success': true,
                    'data': request.url.path.endsWith('/courses')
                        ? [course]
                        : course,
                  },
                }),
              ),
              200,
            );
          }),
        );
        await tester.pumpWidget(fixture.host(CoursesPage(api: api)));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.text('دوره رایگان'), findsOneWidget);
        await tester.tap(find.text('دوره رایگان'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.byType(CourseExperience), findsOneWidget);
        expect(find.text('دوره رایگان'), findsWidgets);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }
  testWidgets('course metadata editor accepts an empty PHP array', (
    tester,
  ) async {
    final api = SocialApi(
      '',
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'status': 200,
              'data': {'success': true, 'data': course},
            }),
          ),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      fixture.host(CourseMetadataEditor(api: api, id: 7)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
