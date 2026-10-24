import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('organization first tab is branch management', () {
    final section = {'key': 'branches', 'actions': <String, dynamic>{}};
    final grouped = panelSectionWithTabs(section, [section]);
    expect(objects(grouped['pageTabs']).first['label'], 'مدیریت شعبه‌ها');
    expect(objects(grouped['pageTabs']).first['en'], 'Branch management');
  });

  testWidgets(
    'session preview preserves generated dates and shows scheduling conflicts',
    (tester) async {
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: PanelFormPage(
              title: 'Sessions',
              dialog: true,
              fields: const [
                {
                  'key': 'studentSchedule',
                  'label': 'Schedule',
                  'type': 'object',
                  'options': <Map<String, dynamic>>[],
                },
              ],
              initial: const {
                'termId': 3,
                'studentSchedule': {
                  'firstDate': '2026-10-24',
                  'classroomId': 4,
                },
              },
              data: const {},
              previewStudentSchedule: (values) async {
                expect(values['termId'], 3);
                expect(
                  (values['studentSchedule'] as Map)['firstDate'],
                  '2026-10-24',
                );
                return {
                  'sessions': [
                    {'date': '2026-10-24', 'error': 'holiday conflict'},
                  ],
                };
              },
              onSubmit: (_) async =>
                  fail('A conflicting preview must not be submitted'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('بررسی تاریخ جلسات'));
      await tester.pumpAndSettle();
      expect(find.text('2026-10-24: holiday conflict'), findsOneWidget);
      expect(find.byKey(const ValueKey('preview-session-0')), findsOneWidget);
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(
        find.text('تداخل جلسه‌ها را اصلاح و دوباره تاریخ‌ها را بررسی کنید.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'selected account uses opaque token without requesting saved identity again',
    (tester) async {
      PanelFormResult? saved;
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PanelFormPage(
                    title: 'Member',
                    dialog: true,
                    declaredOnly: true,
                    fields: const [
                      {
                        'key': 'name',
                        'label': 'نام',
                        'type': 'text',
                        'required': true,
                      },
                      {
                        'key': 'phone',
                        'label': 'موبایل',
                        'type': 'phone',
                        'required': true,
                      },
                    ],
                    data: const {},
                    initial: const {'organizationUserId': 10},
                    lookupMemberUser: (values, query) async {
                      expect(values['organizationUserId'], 10);
                      expect(query, 'exact-user');
                      return {
                        'users': [
                          {
                            'name': 'Existing account',
                            'token': 'opaque-selection',
                            'fields': {'name': true, 'phone': true},
                            'under18': false,
                          },
                        ],
                      };
                    },
                    onSubmit: (result) async => saved = result,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'exact-user');
      await tester.tap(find.text('جستجوی کاربر موجود'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Existing account'));
      await tester.pumpAndSettle();
      expect(find.text('نام'), findsNothing);
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(saved?.values['existingUserToken'], 'opaque-selection');
      expect(saved?.values.containsKey('phone'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'branch registration exposes code request and retains form inputs',
    (tester) async {
      var requests = 0;
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: PanelFormPage(
              title: 'Branch registration',
              dialog: true,
              fields: const [],
              data: const {},
              onRequestCode: (_) async {
                requests++;
              },
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('ارسال کد تأیید'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('Branch registration'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
