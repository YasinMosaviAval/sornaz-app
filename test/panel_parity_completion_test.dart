import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_dashboard.dart';
import 'package:sornaz/screens/Site/panel_parity.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_schedule_week.dart';
import 'package:sornaz/screens/Site/panel_tracking.dart';
import 'package:sornaz/screens/Site/panel_caption.dart';
import 'package:sornaz/screens/Site/panel_filter_contract.dart';
import 'package:sornaz/screens/Site/panel_table_contract.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class ParityApi extends PanelApi {
  ParityApi({this.serverPaged = false}) : super('test');
  final bool serverPaged;
  bool revoked = false;
  final calls = <Map<String, String>>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    calls.add({...?query});
    if (revoked) throw const SocialException('Access revoked', 403);
    if (path == '/schedules/list')
      return {
        'schedules': [
          for (var i = 0; i < (query?['page'] == '2' ? 1 : 2); i++)
            {
              'id': '${query?['date']}:$i:${query?['page']}',
              'date': query?['date'],
              'title': 'کلاس نمونه',
              'startTime': '09:00',
              'endTime': '10:00',
            },
        ],
        'total': 3,
        'perPage': 2,
      };
    if (serverPaged)
      return {
        'items': [
          for (var i = 0; i < 2; i++)
            {'id': i, 'name': 'ردیف ${query?['page']}-$i'},
        ],
        'total': 4,
        'perPage': 2,
      };
    return {
      'items': [
        for (var i = 0; i < 12; i++)
          {
            'id': i,
            'name': 'ردیف ${i.toString().padLeft(2, '0')}',
            'summary': 'شرح',
          },
      ],
    };
  }

  @override
  Future<Json> refresh(String path, [Map<String, String>? query]) =>
      get(path, query);
}

class ExportPicker extends FilePicker {
  Uint8List? bytes;
  String? name;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    this.bytes = bytes;
    name = fileName;
    return null;
  }
}

Json resource(String key) => {
  'key': key,
  'label': 'عنوان پنل',
  'rows': key == 'schedules' ? 'schedules' : 'items',
  'actions': {'list': {}},
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'tracking diagnostic tabs paginate and reset the selected collection',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelTrackingRaw(
                data: {
                  'sessions': [
                    for (var i = 0; i < 11; i++) {'session': 'fixture-$i'},
                  ],
                  'events': [
                    {'event_name': 'fixture-event'},
                  ],
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 10);
      await tester.tap(find.text('بعدی'));
      await tester.pumpAndSettle();
      expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 1);
      expect(find.text('fixture-10'), findsOneWidget);
      await tester.tap(find.text('رویدادها'));
      await tester.pumpAndSettle();
      expect(find.text('fixture-event'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'course level column corrections preserve the page guidance contract',
    () {
      final contract = panelTableContract({
        'key': 'course-levels',
        'presentation': {
          'version': 2,
          'guidance': {'key': 'course-levels', 'title': 'راهنما'},
        },
      });
      expect(optionalObject(contract['guidance'])['title'], 'راهنما');
      expect(objects(contract['columns']).map((c) => c['key']), [
        'name',
        'summary',
      ]);
    },
  );
  test(
    'report date boundaries include the final day and exclude unrelated dates',
    () {
      final fields = <Json>[
        {'key': 'from', 'rowPath': 'dateISO', 'operator': 'gte'},
        {'key': 'to', 'rowPath': 'dateISO', 'operator': 'lte'},
      ];
      expect(
        panelMatchesFilters(
          {'dateISO': '2026-10-17'},
          fields,
          {'from': '2026-10-01', 'to': '2026-10-17'},
        ),
        true,
      );
      expect(
        panelMatchesFilters(
          {'dateISO': '2026-10-18'},
          fields,
          {'to': '2026-10-17'},
        ),
        false,
      );
      expect(
        panelMatchesFilters(
          {'dateISO': '2026-09-30'},
          fields,
          {'from': '2026-10-01'},
        ),
        false,
      );
    },
  );
  testWidgets(
    'server sorting retrieves all pages before sorting and permission refresh hides old data',
    (tester) async {
      final api = ParityApi(serverPaged: true);
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(api: api, section: resource('course-levels')),
        ),
      );
      await tester.pumpAndSettle();
      tester.widget<DataTable>(find.byType(DataTable)).columns.first.onSort!(
        0,
        false,
      );
      await tester.pumpAndSettle();
      expect(api.calls.last['page'], '2');
      expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 4);
      expect(find.text('ردیف 2-1'), findsOneWidget);
      api.revoked = true;
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'English captions use product labels instead of database identifiers',
    (tester) async {
      late String caption;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              caption = panelCaption(context, {
                'key': 'permissionIds',
                'label': 'مجوزها',
              });
              return const SizedBox();
            },
          ),
        ),
      );
      expect(caption, 'Permissions');
    },
  );
  test(
    'session actions match cancellation state and separate approver permission',
    () {
      for (final booking in ['completed', 'held', 'rejected', 'canceled']) {
        expect(
          panelSessionAction(
            'cancel',
            {'bookingStatus': booking},
            {'canCancelSessions': true},
          ),
          false,
        );
      }
      expect(
        panelSessionAction('cancel', {}, {'canCancelSessions': true}),
        true,
      );
      expect(
        panelSessionAction(
          'cancel',
          {'cancellationStatus': 'pending'},
          {'canCancelSessions': true},
        ),
        false,
      );
      expect(
        panelSessionAction(
          'cancel-approve',
          {'cancellationStatus': 'pending'},
          {'canApproveSessionCancellations': false},
        ),
        false,
      );
      expect(
        panelSessionAction(
          'cancel-reject',
          {'cancellationStatus': 'pending'},
          {'canApproveSessionCancellations': true},
        ),
        true,
      );
      expect(
        panelSessionAction('restore', {'cancellationStatus': 'pending'}, {}),
        true,
      );
      expect(
        panelSessionAction('restore', {'cancellationStatus': 'approved'}, {}),
        false,
      );
    },
  );
  test('installment order cannot skip an unpaid installment', () {
    final invoice = {
      'installments': [
        {'id': 1, 'statusCode': 'paid'},
        {'id': 2, 'statusCode': 'pending'},
        {'id': 3, 'statusCode': 'pending'},
      ],
    };
    expect(
      panelPayableInstallment(invoice, {'id': 1, 'statusCode': 'paid'}),
      false,
    );
    expect(
      panelPayableInstallment(invoice, {'id': 2, 'statusCode': 'pending'}),
      true,
    );
    expect(
      panelPayableInstallment(invoice, {'id': 3, 'statusCode': 'pending'}),
      false,
    );
  });
  test('sort is numeric, stable and leaves source rows untouched', () {
    final rows = <Json>[
      {'id': 1, 'n': 10},
      {'id': 2, 'n': 2},
      {'id': 3, 'n': 2},
    ];
    expect(
      panelSortedRows(rows, 'n', true, (r, k) => r[k]).map((r) => r['id']),
      [2, 3, 1],
    );
    expect(rows.first['id'], 1);
    expect(panelNumber(1234567, fa: true), '۱,۲۳۴,۵۶۷');
    expect(panelDate('2026-10-17', fa: true), '۱۴۰۵/۰۷/۲۵');
    expect(panelWeekStart(DateTime(2026, 10, 19)), DateTime(2026, 10, 17));
  });
  testWidgets('local collections paginate and sort the whole collection', (
    tester,
  ) async {
    final api = ParityApi();
    await tester.pumpWidget(
      fixture.host(
        PanelResourcePage(api: api, section: resource('course-levels')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 10);
    await tester.ensureVisible(find.text('بعدی'));
    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 2);
    final table = tester.widget<DataTable>(find.byType(DataTable));
    table.columns.first.onSort!(0, false);
    await tester.pumpAndSettle();
    expect(find.text('ردیف 11'), findsOneWidget);
    expect(find.text('ردیف 00'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
    'server-paged XLSX exports every page with only website columns',
    (tester) async {
      final picker = ExportPicker();
      FilePicker.platform = picker;
      final api = ParityApi(serverPaged: true);
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(api: api, section: resource('course-levels')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.table_view));
      await tester.pumpAndSettle();
      expect(picker.name, 'course-levels.xlsx');
      final archive = ZipDecoder().decodeBytes(picker.bytes!);
      final xml = utf8.decode(
        archive.findFile('xl/worksheets/sheet1.xml')!.content,
      );
      expect(xml, contains('ردیف 1-0'));
      expect(xml, contains('ردیف 2-1'));
      expect(xml, isNot(contains('شناسه')));
      expect(xml, contains('خلاصه'));
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('weekly calendar fetches all seven dates and every server page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ParityApi();
    await tester.pumpWidget(
      fixture.host(PanelResourcePage(api: api, section: resource('schedules'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('برنامه هفتگی'));
    await tester.pumpAndSettle();
    final dates = api.calls.where((q) => q['date'] != null).toList();
    expect(dates.length, 14);
    expect(dates.map((q) => q['date']).toSet().length, 7);
    expect(
      tester
          .widget<PanelScheduleWeek>(find.byType(PanelScheduleWeek))
          .rows
          .length,
      21,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
    'dashboard and tracking display readable website fields at phone width',
    (tester) async {
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelDashboard(
                data: {
                  'stats': {'activeStudents': 12, 'monthlyIncome': '۱۰۰ تومان'},
                  'todayClasses': [
                    {
                      'time': '09:00',
                      'student': 'هنرجو',
                      'instrument': 'پیانو',
                      'teacher': 'مدرس',
                      'branch': 'شعبه',
                      'internal_metadata': 'hidden',
                    },
                  ],
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('internal_metadata'), findsNothing);
      expect(find.text('پیانو'), findsOneWidget);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelTracking(
                data: {
                  'metrics': {'sessions': 2, 'avgSessionMs': 120000},
                  'funnel': [
                    {'label': 'شروع نشست', 'value': 2},
                  ],
                  'trend': [
                    {'day': '2026-10-17', 'sessions': 2},
                  ],
                  'technical': {
                    'offline_events': 3,
                    'online_events': 2,
                    'affected_sessions': 1,
                  },
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('offline_events'), findsNothing);
      expect(find.text('قطع ارتباط'), findsOneWidget);
      expect(find.byType(PanelTrackingChart), findsNWidgets(2));
    },
  );
}
