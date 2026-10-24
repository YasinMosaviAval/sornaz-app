import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_schedule_week.dart';
import 'package:sornaz/screens/Site/panel_schedule_cancellation.dart';
import 'package:sornaz/screens/Site/panel_table_contract.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

const session = <String, dynamic>{
  'id': 12,
  'termId': 2,
  'title': 'جلسه پیانو',
  'date': '2026-10-17',
  'day': 'شنبه',
  'startTime': '09:00',
  'endTime': '10:30',
  'branchId': 1,
  'branchName': 'شعبه نمونه',
  'classroomId': 4,
  'classroom': 'کلاس پیانو',
  'lesson': 'پیانو',
  'mode': 'in_person',
  'status': 'در انتظار برگزاری',
  'statusCode': 'upcoming',
  'canCancel': true,
};
const branches = [
  {'id': 1, 'name': 'شعبه نمونه'},
];
const rooms = [
  {'id': 4, 'branchId': 1, 'name': 'کلاس پیانو'},
  {'id': 5, 'branchId': 1, 'name': 'کلاس خالی'},
];

class ScheduleApi extends PanelApi {
  ScheduleApi() : super('test');
  bool failSave = false, closed = false;
  Json? submitted;
  Map<String, String>? submittedParams;
  final availabilityRequests = <Map<String, String>>[];
  final listRequests = <Map<String, String>>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    if (path == '/schedules/week-bounds')
      return {'firstDate': '2026-10-17', 'lastDate': '2026-11-14'};
    if (path == '/schedules/list') {
      listRequests.add({...?query});
      return {
        'schedules':
            query?['branch'] != 'academy' &&
                (query?['date'] == null || query?['date'] == '2026-10-17')
            ? [session]
            : [],
        'branches': branches,
        'classrooms': rooms,
        'timeRanges': [
          {'start': '09:00', 'end': '10:30'},
          {'start': '14:00', 'end': '15:30'},
        ],
        'total':
            query?['branch'] != 'academy' &&
                (query?['date'] == null || query?['date'] == '2026-10-17')
            ? 1
            : 0,
        'perPage': 100,
      };
    }
    if (path == '/schedules/term-context')
      return {
        'terms': [
          {
            'id': 2,
            'branchId': 1,
            'classroomId': 4,
            'repeatType': 'week',
            'sessions': [session],
          },
        ],
      };
    if (path == '/schedules/available-times') {
      availabilityRequests.add({...?query});
      return {
        'times': closed ? [] : ['09:00', '11:00'],
        'closed': closed,
      };
    }
    return {};
  }

  @override
  Future<Json> refresh(String path, [Map<String, String>? query]) =>
      get(path, query);
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    if (failSave)
      throw const SocialException('زمان انتخاب‌شده دیگر آزاد نیست.');
    submitted = values;
    submittedParams = params;
    return {};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  void wide(WidgetTester tester) {
    tester.view.physicalSize = const Size(1800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('calendar status uses website labels in list and details', () {
    for (final entry in {
      'upcoming': 'در انتظار برگزاری',
      'cancellation_pending': 'لغو در انتظار تأیید',
      'held': 'برگزار شده',
    }.entries) {
      final row = panelDisplayRow('schedules', {
        'statusCode': entry.key,
        'status': entry.value,
      }, {});
      expect(panelTableValue(row, 'status'), entry.value);
    }
    expect(
      panelTableValue(
        panelDisplayRow('schedules', {'statusCode': 'canceled'}, {}),
        'status',
      ),
      'لغو شده',
    );
  });
  testWidgets('calendar tabs retain both exports with an empty weekly view', (
    tester,
  ) async {
    wide(tester);
    final api = ScheduleApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      fixture.host(
        PanelResourcePage(
          api: api,
          section: {
            'key': 'schedules',
            'label': 'تقویم کلاس‌ها',
            'rows': 'schedules',
            'actions': {
              'list': {},
              'week-bounds': {'hidden': true},
              'cancel': {
                'label': 'لغو و جبرانی',
                'method': 'POST',
                'row': true,
              },
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(PanelScheduleWeek), findsOneWidget);
    final tabs = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabs.tabs.map((tab) => (tab as Tab).text), [
      'همه',
      'آموزشگاه',
      'شعبه نمونه',
    ]);
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text('آموزشگاه')),
    );
    await tester.pumpAndSettle();
    expect(api.listRequests.last['branch'], 'academy');
    expect(
      tester.widget<PanelScheduleWeek>(find.byType(PanelScheduleWeek)).rows,
      isEmpty,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.text('شعبه نمونه'),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.listRequests.last['branch'], '1');
    await tester.tap(find.byKey(const ValueKey('schedule-view-table')));
    await tester.pumpAndSettle();
    expect(find.text('upcoming'), findsNothing);
    expect(find.text('در انتظار برگزاری'), findsOneWidget);
    expect(find.text('لغو و جبرانی'), findsOneWidget);
    expect(find.byTooltip('خروجی اکسل'), findsOneWidget);
    expect(find.byTooltip('خروجی PDF'), findsOneWidget);
    await tester.tap(find.text('نمایش برنامه هفتگی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('کلاس × بازه زمانی'));
    await tester.pumpAndSettle();
    final week = tester.widget<PanelScheduleWeek>(
      find.byType(PanelScheduleWeek),
    );
    week.changeWeek!(DateTime(2026, 11, 7));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PanelScheduleWeek>(find.byType(PanelScheduleWeek)).rows,
      isEmpty,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.ancestor(
              of: find.text('کلاس × بازه زمانی'),
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );
    expect(find.byTooltip('خروجی اکسل'), findsOneWidget);
    expect(find.byTooltip('خروجی PDF'), findsOneWidget);
    await tester.tap(find.text('نمایش جدولی'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('جزئیات'));
    await tester.tap(find.byTooltip('جزئیات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('upcoming'), findsNothing);
    expect(find.textContaining('در انتظار برگزاری'), findsWidgets);
  });
  testWidgets(
    'calendar controls appear once outside multiple organization cards',
    (tester) async {
      wide(tester);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelScheduleWeek(
                rows: const [],
                start: DateTime(2026, 10, 17),
                open: (_) {},
                data: const {
                  'branches': [
                    {'id': 1, 'name': 'One'},
                    {'id': 2, 'name': 'Two'},
                  ],
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(
        find.descendant(
          of: find.byType(Card),
          matching: find.byType(ChoiceChip),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Card),
          matching: find.byIcon(Icons.swap_horiz),
        ),
        findsNothing,
      );
      final scrolls = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scrolls.where((s) => s.scrollDirection == Axis.horizontal).length,
        4,
      );
    },
  );
  testWidgets('weekly branch matrix supports layouts empty axes and swapping', (
    tester,
  ) async {
    wide(tester);
    Json? opened;
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: SingleChildScrollView(
            child: PanelScheduleWeek(
              rows: const [session],
              start: DateTime(2026, 10, 17),
              open: (value) => opened = value,
              data: const {
                'branches': branches,
                'classrooms': rooms,
                'timeRanges': [
                  {'start': '09:00', 'end': '10:30'},
                  {'start': '14:00', 'end': '15:30'},
                ],
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('کلاس / روز'), findsOneWidget);
    expect(find.text('کلاس خالی'), findsNothing);
    await tester.tap(find.text('نمایش کلاس‌های خالی'));
    await tester.pumpAndSettle();
    expect(find.text('کلاس خالی'), findsOneWidget);
    await tester.tap(find.text('کلاس × بازه زمانی'));
    await tester.pumpAndSettle();
    expect(find.text('کلاس / بازه زمانی'), findsOneWidget);
    await tester.tap(find.text('نمایش بازه‌های زمانی خالی'));
    await tester.pumpAndSettle();
    expect(find.textContaining('14:00'), findsOneWidget);
    await tester.tap(find.text('جابه‌جایی سطر و ستون'));
    await tester.pumpAndSettle();
    expect(find.text('بازه زمانی / کلاس'), findsOneWidget);
    await tester.tap(find.text('روز هفته × بازه زمانی'));
    await tester.pumpAndSettle();
    expect(find.text('بازه زمانی / روز'), findsOneWidget);
    await tester.tap(find.text('جلسه پیانو'));
    await tester.pumpAndSettle();
    expect(opened?['id'], 12);
  });
  testWidgets(
    'cancellation preserves reason on rejection and submits checked duration and scope',
    (tester) async {
      wide(tester);
      final api = ScheduleApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      PanelScheduleCancellation(api: api, session: session),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(api.availabilityRequests.single['date'], '2026-10-24');
      expect(api.availabilityRequests.single['duration'], '90');
      await tester.enterText(find.byType(TextField).first, 'بیماری مدرس');
      api.failSave = true;
      await tester.tap(find.text('ثبت لغو و جلسه جبرانی'));
      await tester.pumpAndSettle();
      expect(find.text('بیماری مدرس'), findsOneWidget);
      expect(find.textContaining('دیگر آزاد نیست'), findsOneWidget);
      api.failSave = false;
      await tester.tap(find.text('ثبت لغو و جلسه جبرانی'));
      await tester.pumpAndSettle();
      expect(api.submitted, {
        'reason': 'بیماری مدرس',
        'makeupDate': '2026-10-24',
        'startTime': '09:00',
        'endTime': '10:30',
      });
      expect(api.submittedParams, {'termId': '2', 'id': '12'});
      expect(find.byType(PanelScheduleCancellation), findsNothing);
    },
  );
  testWidgets('closed makeup dates cannot be submitted', (tester) async {
    wide(tester);
    final api = ScheduleApi()..closed = true;
    addTearDown(api.dispose);
    await tester.pumpWidget(fixture.host(const SizedBox()));
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: PanelScheduleCancellation(api: api, session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('شعبه یا آموزشگاه در این تاریخ تعطیل است.'),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('ثبت لغو و جلسه جبرانی'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(save.onPressed, isNull);
    expect(api.submitted, isNull);
  });
}
