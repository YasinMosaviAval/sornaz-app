import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_classroom_heatmap.dart';
import 'package:sornaz/screens/Site/panel_insight_data.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;
import 'panel_parity_completion_test.dart' show ExportPicker;

const rooms = <Json>[
  {'id': 1, 'name': 'Room 1', 'statusValue': 'available'},
  {'id': 2, 'name': 'Room 2', 'statusValue': 'available'},
  {'id': 3, 'name': 'Closed', 'statusValue': 'unavailable'},
];
const bookings = <Json>[
  {
    'classroomId': 1,
    'date': '2026-10-24',
    'startTime': '09:30',
    'endTime': '11:00',
  },
  {
    'classroomId': 1,
    'date': '2026-10-24',
    'startTime': '09:45',
    'endTime': '10:00',
  },
  {
    'classroomId': 2,
    'date': '2026-10-24',
    'startTime': '09:00',
    'endTime': '10:00',
  },
  {
    'classroomId': 3,
    'date': '2026-10-24',
    'startTime': '09:00',
    'endTime': '10:00',
  },
  {
    'classroomId': 99,
    'date': '2026-10-24',
    'startTime': '09:00',
    'endTime': '10:00',
  },
];

class OccupancyApi extends PanelApi {
  OccupancyApi() : super('fixture');
  final reads = <Map<String, String>>[];
  Completer<Json>? delayed;
  bool fail = false;
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    expect(path, '/classrooms/heatmap');
    reads.add({...?query});
    if (delayed != null) return delayed!.future;
    if (fail) throw const SocialException('Unavailable', 500);
    return {'heatmap': bookings};
  }

  @override
  Future<Json> refresh(String path, [Map<String, String>? query]) =>
      get(path, query);
}

Widget host(
  OccupancyApi api, {
  List<Json> selected = rooms,
  bool enabled = true,
  Object refreshKey = 'initial',
}) => fixture.host(
  Scaffold(
    body: SingleChildScrollView(
      child: PanelClassroomHeatmap(
        api: api,
        rooms: selected,
        enabled: enabled,
        refreshKey: refreshKey,
      ),
    ),
  ),
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'occupancy counts unique available classrooms and exclusive hour boundaries',
    () {
      final value = panelClassroomHeatmap(rooms, bookings);
      expect(value.cells[0][9], 2);
      expect(value.cells[0][10], 1);
      expect(value.cells[0][11], 0);
      expect(panelClassroomHeatmap([rooms[0]], bookings).cells[0][9], 1);
      expect(panelClassroomHeatmap([rooms[2]], bookings).cells[0][9], 0);
      expect(
        panelClassroomHeatmap(
          [],
          bookings,
        ).cells.expand((v) => v).every((v) => v == 0),
        isTrue,
      );
    },
  );
  testWidgets(
    'week navigation requests full data while local room filters do not refetch',
    (tester) async {
      final api = OccupancyApi();
      await tester.pumpWidget(host(api));
      await tester.pumpAndSettle();
      expect(api.reads, hasLength(1));
      expect(api.reads.single.keys, ['week']);
      final first = DateTime.parse(api.reads.single['week']!);
      expect(first.weekday, DateTime.saturday);
      await tester.tap(find.byTooltip('هفته بعد'));
      await tester.pumpAndSettle();
      expect(
        DateTime.parse(api.reads.last['week']!).difference(first).inDays,
        7,
      );
      final count = api.reads.length;
      await tester.pumpWidget(host(api, selected: [rooms[0]]));
      await tester.pumpAndSettle();
      expect(api.reads.length, count);
      expect(find.text('Room 2'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('failed and late requests never replace the selected week', (
    tester,
  ) async {
    final api = OccupancyApi()..delayed = Completer<Json>();
    final old = api.delayed!;
    await tester.pumpWidget(host(api));
    await tester.pump();
    api.delayed = null;
    api.fail = true;
    await tester.tap(find.byTooltip('هفته بعد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ناموفق'), findsOneWidget);
    old.complete({'heatmap': bookings});
    await tester.pumpAndSettle();
    expect(find.textContaining('ناموفق'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets('old servers show an update message without extra requests', (
    tester,
  ) async {
    final api = OccupancyApi();
    await tester.pumpWidget(host(api, enabled: false));
    await tester.pumpAndSettle();
    expect(api.reads, isEmpty);
    expect(find.textContaining('API'), findsOneWidget);
  });
  testWidgets('classroom heatmap exports real PNG on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FilePicker? previous;
    try {
      previous = FilePicker.platform;
    } catch (_) {}
    final picker = ExportPicker();
    FilePicker.platform = picker;
    addTearDown(() {
      if (previous != null) FilePicker.platform = previous;
    });
    final api = OccupancyApi();
    await tester.pumpWidget(host(api));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('ذخیره نمودار PNG'));
    await tester.tap(find.byTooltip('ذخیره نمودار PNG'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && picker.bytes == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(picker.bytes?.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(tester.takeException(), isNull);
  });
}
