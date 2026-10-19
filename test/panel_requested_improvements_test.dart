import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_national_holiday_settings.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_section_card.dart';
import 'package:sornaz/screens/Site/panel_term_attendance.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class RequestedFixture extends PanelApi {
  RequestedFixture(this.data) : super('test');
  Json data;
  final writes = <(String, String, Json, Map<String, String>)>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async =>
      path.contains('page-guidance') ? {} : data;
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    files = const {},
  }) async {
    writes.add((section, action, values, params));
    return {};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('save label has no icon and stays on one line', (tester) async {
    await tester.pumpWidget(
      fixture.host(
        const PanelFormPage(
          dialog: true,
          title: 'ویرایش',
          fields: [
            {'key': 'name', 'label': 'نام'},
          ],
          data: {},
        ),
      ),
    );
    final button = find.widgetWithText(FilledButton, 'ذخیره تغییرات');
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.byType(Icon)),
      findsNothing,
    );
    expect(tester.widget<Text>(find.text('ذخیره تغییرات')).maxLines, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('guidance tint blends onto the actual page background', (
    tester,
  ) async {
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: PanelSectionCard(
            title: 'راهنما',
            color: Colors.blue.withValues(alpha: .2),
            children: const [Text('توضیح')],
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(PanelSectionCard));
    final card = tester.widget<Card>(find.byType(Card));
    expect(
      card.color,
      Color.alphaBlend(
        Colors.blue.withValues(alpha: .2),
        Theme.of(context).scaffoldBackgroundColor,
      ),
    );
    expect(card.color!.a, 1);
  });
  testWidgets(
    'holiday box lists academy and branches and saves their independent settings',
    (tester) async {
      final api = RequestedFixture({
        'organizations': [
          {
            'academyId': 100,
            'branchId': 0,
            'name': 'آموزشگاه',
            'allowClasses': false,
          },
          {
            'academyId': 100,
            'branchId': 101,
            'name': 'شعبه مرکزی',
            'allowClasses': true,
          },
        ],
      });
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelNationalHolidaySettings(api: api),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(CheckboxListTile, 'آموزشگاه'), findsOneWidget);
      await tester.tap(find.widgetWithText(CheckboxListTile, 'شعبه مرکزی'));
      await tester.tap(find.text('ذخیره اطلاعات'));
      await tester.pumpAndSettle();
      expect(api.writes.single.$3['organizations'], [
        {'academyId': 100, 'branchId': 0, 'allowClasses': false},
        {'academyId': 100, 'branchId': 101, 'allowClasses': false},
      ]);
      expect(find.text('تنظیمات تعطیلات رسمی ذخیره شد.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final key in ['scheduling-rules', 'organization-holidays', 'users']) {
    testWidgets(
      '$key exports follow the requested toolbar visibility even with no rows',
      (tester) async {
        final api = RequestedFixture({'items': []});
        addTearDown(api.dispose);
        await tester.pumpWidget(
          fixture.host(
            PanelResourcePage(
              api: api,
              section: {
                'key': key,
                'label': key,
                'rows': 'items',
                'actions': <String, dynamic>{},
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.table_view),
          key == 'users' ? findsNothing : findsOneWidget,
        );
        expect(
          find.byIcon(Icons.picture_as_pdf_outlined),
          key == 'users' ? findsNothing : findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('visible rows update automatically and announce the change', (
    tester,
  ) async {
    final api = RequestedFixture({
      'courses': [
        {'id': 1, 'name': 'دوره قبلی'},
      ],
    });
    addTearDown(api.dispose);
    await tester.pumpWidget(
      fixture.host(
        PanelResourcePage(
          api: api,
          section: const {
            'key': 'courses',
            'label': 'دوره‌ها',
            'rows': 'courses',
            'actions': <String, dynamic>{},
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('دوره قبلی'), findsOneWidget);
    api.data = {
      'courses': [
        {'id': 1, 'name': 'دوره تازه'},
      ],
    };
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('دوره تازه'), findsOneWidget);
    expect(find.text('دوره قبلی'), findsNothing);
    expect(find.text('تغییرات سطرها اعمال شد.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'access table uses role badges, translated status and the three website actions',
    (tester) async {
      final api = RequestedFixture({
        'users': [
          {
            'id': 1,
            'name': 'کاربر نمونه',
            'canEdit': true,
            'status': 'approved',
            'roles': [
              for (var i = 0; i < 4; i++)
                {'id': i, 'title': 'نقش $i', 'color': '#223344'},
            ],
            'permissions': [
              {'id': 1, 'title': 'دسترسی نمونه'},
            ],
          },
        ],
      });
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: const {
              'key': 'users',
              'label': 'نقش‌ها و دسترسی‌ها',
              'rows': 'users',
              'actions': {
                'roles': {'row': true},
                'permissions': {'row': true},
                'details': {'row': true},
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'نقش 0',
        '+1',
        'دسترسی نمونه',
        'تأییدشده',
        'تعیین نقش‌ها',
        'تعیین دسترسی‌ها',
        'مشاهده دسترسی‌ها',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.byIcon(Icons.table_view), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'term attendance loads real sessions and saves to the existing session endpoint',
    (tester) async {
      final api = RequestedFixture({
        'schedules': [
          {
            'id': 17,
            'title': 'جلسه نمونه',
            'date': '2026-10-19',
            'time': '09:00-10:00',
            'attendance': [
              {'id': 9, 'name': 'هنرجو', 'status': 'absent'},
            ],
          },
        ],
        'total': 1,
      });
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: PanelTermAttendance(api: api, termId: '42'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('جلسه نمونه'));
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'ذخیره تغییرات');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, 'schedules');
      expect(api.writes.single.$2, 'attendance');
      expect(api.writes.single.$4['id'], '17');
      expect(objects(api.writes.single.$3['attendance']).single['memberId'], 9);
      expect(find.text('حضور و غیاب ذخیره شد.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
