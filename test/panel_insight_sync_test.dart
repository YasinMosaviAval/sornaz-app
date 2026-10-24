import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_insight_charts.dart';
import 'package:sornaz/screens/Site/panel_insight_data.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;
import 'panel_parity_completion_test.dart' show ExportPicker;

class InsightApi extends PanelApi {
  InsightApi() : super('fixture');
  final reads = <(String, Map<String, String>)>[];
  final writes = <(String, Json)>[];
  bool conflict = false, receptionist = false, failHeatmap = false;
  Completer<Json>? delayed;
  String status = 'open';
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    reads.add((path, {...?query}));
    if (path == '/schedules/week-bounds')
      return {'firstDate': '2026-10-24', 'lastDate': '2026-10-24'};
    if (path == '/schedules/heatmap') {
      if (delayed != null) return delayed!.future;
      if (failHeatmap) throw const SocialException('Unavailable', 500);
      return {
        'heatmap': [
          {
            'date': '2026-10-24',
            'startTime': '09:30',
            'endTime': '11:00',
            'count': 23,
          },
        ],
      };
    }
    if (path == '/schedules/list')
      return {
        'schedules': [],
        'total': query?['date'] == null ? 23 : 0,
        'perPage': 10,
      };
    if (path == '/courses/list') return {};
    return {
      'terms': [
        {
          'id': 8,
          'status_code': status,
          'status': status == 'open' ? 'باز' : 'در حال برگزاری',
        },
      ],
      'permissions': {'isReceptionist': receptionist},
    };
  }

  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    files = const {},
  }) async {
    writes.add((action, {...values}));
    if (conflict) {
      status = 'ongoing';
      throw const SocialException('Changed by another user', 409);
    }
    return {};
  }
}

Json termSection({bool modern = true}) => {
  'key': 'terms',
  'rows': 'terms',
  'label': 'ترم‌ها',
  'presentation': {
    'version': 2,
    'columns': [
      {'key': 'status', 'label': 'وضعیت', 'action': 'status'},
    ],
    'rowActions': [],
    'filters': [],
  },
  'actions': {
    'list': {'method': 'GET'},
    'status': {'method': 'POST', 'row': true},
    if (modern)
      'set-status': {
        'method': 'POST',
        'row': true,
        'fields': [
          {
            'key': 'status',
            'options': {
              'open': 'باز',
              'suspended': 'تعلیق شده',
              'ongoing': 'در حال برگزاری',
            },
          },
        ],
      },
  },
};
void wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(1800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('native charts render and export a real PNG on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final picker = ExportPicker();
    FilePicker? previous;
    try {
      previous = FilePicker.platform;
    } catch (_) {
      /* No picker is registered by this isolated fixture. */
    }
    FilePicker.platform = picker;
    addTearDown(() {
      if (previous != null) FilePicker.platform = previous;
    });
    await tester.pumpWidget(
      fixture.host(
        const Scaffold(
          body: SingleChildScrollView(
            child: PanelInsightCharts(
              section: 'students',
              rows: [
                {
                  'id': 1,
                  'lessonId': 2,
                  'lessonName': 'Piano',
                  'deliveryModes': ['online', 'in_person'],
                },
              ],
              data: {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('ذخیره نمودار PNG'));
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && picker.bytes == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    });
    await tester.pumpAndSettle();
    expect(picker.name, 'students-chart.png');
    expect(picker.bytes?.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'failed summary is explicit and late responses cannot update a disposed calendar',
    (tester) async {
      wide(tester);
      final api = InsightApi()..failHeatmap = true;
      addTearDown(api.dispose);
      final section = <String, dynamic>{
        'key': 'schedules',
        'rows': 'schedules',
        'label': 'تقویم',
        'actions': {
          'list': {'method': 'GET'},
          'heatmap': {'method': 'GET', 'hidden': true},
        },
      };
      await tester.pumpWidget(
        fixture.host(PanelResourcePage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('نمایش جدولی'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(PanelInsightCharts),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('دریافت آمار نقشه حرارتی ناموفق'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.image_outlined),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      api.failHeatmap = false;
      api.delayed = Completer<Json>();
      await tester.pumpWidget(
        fixture.host(PanelResourcePage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('نمایش جدولی'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      api.delayed!.complete({'heatmap': []});
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'point shares use account balance, preserve specialized and never rewrite negative balances',
    () {
      final balance = <String, dynamic>{
        'general': -4,
        'professional': 12,
        'specialized': 7,
      };
      final result = panelPointDistribution(balance);
      expect(result.values, {
        'general': 0,
        'professional': 12,
        'specialized': 7,
      });
      expect(result.negative, isTrue);
      expect(balance['general'], -4);
      expect(
        panelPointDistribution({
          'general': 'NaN',
          'professional': 'Infinity',
        }).values.values.every((n) => n == 0),
        isTrue,
      );
    },
  );
  test(
    'contract charts count each person once per matching real contract type',
    () {
      final rows = <Json>[
        {
          'id': 1,
          'user_id': 7,
          'contracts': [
            {'contractId': 1, 'type': 'teacher'},
            {'contractId': 2, 'type': 'teacher'},
            {'contractId': 3, 'type': 'manager'},
          ],
        },
        {'id': 2, 'user_id': 7, 'contractId': 4, 'type': 'teacher'},
        {'id': 3, 'user_id': 9, 'contractId': 5, 'type': 'teacher'},
        {'id': 4, 'contractId': 6, 'type': 'student'},
        {'id': 5, 'type': 'owner'},
      ];
      final result = panelContractDistribution(rows);
      expect(result.values, {'manager': 1, 'teacher': 2});
      expect(result.people, 2);
      expect(panelContractDistribution(rows, type: 'teacher').values, {
        'teacher': 2,
      });
    },
  );
  test(
    'student lesson modes deduplicate registrations by person and lesson, not current page',
    () {
      final result = panelLessonDistribution('students', [
        {
          'id': 1,
          'user_id': 8,
          'lessonId': 1,
          'lessonName': 'Piano',
          'deliveryModes': ['in_person', 'online'],
        },
        {
          'id': 2,
          'user_id': 8,
          'lessonId': 1,
          'lessonName': 'Piano',
          'deliveryModes': ['online'],
        },
        {
          'id': 3,
          'user_id': 9,
          'lessonId': 1,
          'lessonName': 'Piano',
          'deliveryModes': ['online'],
        },
        {'id': 4, 'user_id': 10, 'lessonId': 2, 'deliveryModes': []},
      ], {});
      expect(result.groups.single.inPerson, {'8'});
      expect(result.groups.single.online, {'8', '9'});
      expect(result.counted, 2);
      expect(result.unknown, 1);
    },
  );
  test(
    'student term charts use recorded modes, distinct terms and legacy classroom fallback',
    () {
      final term = <String, dynamic>{
        'id': 1,
        'courseId': 4,
        'students': [
          {'id': 8},
        ],
        'sessions': [
          {'deliveryMode': 'online', 'classroomId': 2},
          {'deliveryMode': 'in_person'},
        ],
      };
      final result = panelLessonDistribution(
        'terms',
        [
          term,
          term,
          {
            'id': 2,
            'courseId': 4,
            'classroomId': 2,
            'students': [
              {'id': 8},
            ],
          },
          {'id': 3, 'courseId': 4, 'students': []},
          {
            'id': 4,
            'courseId': 4,
            'students': [
              {'id': 9},
            ],
          },
        ],
        {
          'courses': [
            {'id': 4, 'lessonId': 3, 'instrument': 'Piano'},
          ],
          'classrooms': [
            {'id': 2, 'deliveryMode': 'in_person'},
          ],
        },
      );
      expect(result.counted, 2);
      expect(result.unknown, 1);
      expect(result.groups.single.online, {'1'});
      expect(result.groups.single.inPerson, {'1', '2'});
    },
  );
  test(
    'heatmap counts overlapping hours, distinct sessions and weighted full-result groups',
    () {
      final row = <String, dynamic>{
        'id': 1,
        'date': '2026-10-24',
        'startTime': '09:30',
        'endTime': '11:00',
      };
      final result = panelHeatmapData([
        row,
        row,
        {
          'date': '2026-10-25',
          'startTime': '23:00',
          'endTime': '24:00',
          'count': 3,
        },
        {'date': 'bad', 'startTime': '10:00', 'endTime': '11:00'},
      ]);
      expect(result.sessions, 4);
      expect(result.unknown, 1);
      expect(result.cells[0][9], 1);
      expect(result.cells[0][10], 1);
      expect(result.cells[0][11], 0);
      expect(result.cells[1][23], 3);
    },
  );
  test(
    'admin user workspace includes only authorized role and permission tabs',
    () {
      Json section(String key) => {'key': key};
      final catalog = [
        'roles',
        'permissions',
        'users',
        'members',
        'member-schedules',
        'employee-leaves',
      ].map(section).toList();
      expect(
        objects(
          panelSectionWithTabs(section('members'), catalog)['pageTabs'],
        ).map((s) => s['key']),
        [
          'roles',
          'permissions',
          'users',
          'members',
          'member-schedules',
          'employee-leaves',
        ],
      );
      expect(
        objects(
          panelSectionWithTabs(section('members'), [
            section('members'),
          ])['pageTabs'],
        ).length,
        1,
      );
    },
  );
  for (final conflict in [false, true]) {
    testWidgets(
      'explicit term status sends previous status; conflict=$conflict',
      (tester) async {
        wide(tester);
        final api = InsightApi()..conflict = conflict;
        addTearDown(api.dispose);
        await tester.pumpWidget(
          fixture.host(PanelResourcePage(api: api, section: termSection())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('باز'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تعلیق شده'));
        await tester.pumpAndSettle();
        expect(api.writes.single.$1, 'set-status');
        expect(api.writes.single.$2, {
          'status': 'suspended',
          'fromStatus': 'open',
        });
        if (conflict) expect(find.text('در حال برگزاری'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'receptionist cannot open status selector and old APIs retain legacy behavior',
    (tester) async {
      wide(tester);
      final api = InsightApi()..receptionist = true;
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(PanelResourcePage(api: api, section: termSection())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('باز'));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
      expect(api.writes, isEmpty);
      await tester.pumpWidget(const SizedBox());
      api.receptionist = false;
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(api: api, section: termSection(modern: false)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('باز'));
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, 'status');
      expect(api.writes.single.$2, isEmpty);
    },
  );
  testWidgets(
    'point chart is based on complete balance and uses native pie and export control',
    (tester) async {
      await tester.pumpWidget(
        fixture.host(
          const Scaffold(
            body: PanelInsightCharts(
              section: 'my-points',
              rows: [
                {'points': 9999},
              ],
              data: {
                'balance': {'general': 10, 'professional': 3, 'specialized': 7},
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.textContaining('تخصصی'), findsOneWidget);
      expect(find.textContaining('9999'), findsNothing);
      expect(find.byTooltip('ذخیره نمودار PNG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'calendar summary covers all pages and errors never fall back to a misleading page total',
    (tester) async {
      wide(tester);
      final api = InsightApi();
      addTearDown(api.dispose);
      final section = <String, dynamic>{
        'key': 'schedules',
        'rows': 'schedules',
        'label': 'تقویم',
        'actions': {
          'list': {'method': 'GET'},
          'heatmap': {'method': 'GET', 'hidden': true},
        },
      };
      await tester.pumpWidget(
        fixture.host(PanelResourcePage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      expect(api.reads.where((r) => r.$1 == '/schedules/heatmap'), isEmpty);
      await tester.tap(find.text('نمایش جدولی'));
      await tester.pumpAndSettle();
      expect(
        api.reads.where((r) => r.$1 == '/schedules/heatmap'),
        hasLength(1),
      );
      final summary = api.reads
          .lastWhere((r) => r.$1 == '/schedules/heatmap')
          .$2;
      expect(summary.containsKey('page'), isFalse);
      expect(summary.containsKey('perPage'), isFalse);
      await tester.scrollUntilVisible(
        find.byType(PanelInsightCharts),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('۲۳ جلسه مستقل'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
