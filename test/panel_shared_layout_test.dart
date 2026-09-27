import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_ui.dart';
import 'package:sornaz/screens/Site/branch_color_picker.dart';
import 'package:sornaz/screens/Site/panel_presentation.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as localized;

class LayoutApi extends PanelApi {
  LayoutApi() : super('layout');
  final queries = <Map<String, String>>[];
  final writes = <(String, Json)>[];
  final rows = <Json>[
    {'id': 1, 'title': 'دوره گیتار', 'status': 'فعال'},
    {'id': 2, 'title': 'دوره فقط خواندنی', 'status': 'فعال', 'read_only': true},
  ];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    queries.add({...?query});
    return {'items': rows, 'total': rows.length};
  }

  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    writes.add((action, {...values}));
    if (action == 'create') rows.add({'id': 3, ...values});
    if (action == 'delete')
      rows.removeWhere((row) => '${row['id']}' == params['id']);
    if (action == 'update')
      rows.firstWhere((row) => '${row['id']}' == params['id']).addAll(values);
    return {};
  }
}

const section = <String, dynamic>{
  'key': 'courses',
  'label': 'مدیریت دوره‌ها',
  'en': 'Courses',
  'rows': 'items',
  'filters': [
    {
      'key': 'status',
      'label': 'وضعیت',
      'type': 'select',
      'options': {'active': 'فعال', 'inactive': 'غیرفعال'},
    },
  ],
  'actions': {
    'list': {'method': 'GET', 'row': false},
    'create': {
      'method': 'POST',
      'row': false,
      'label': 'افزودن دوره',
      'fields': [
        {'key': 'title', 'label': 'عنوان', 'required': true},
      ],
    },
    'update': {
      'method': 'POST',
      'row': true,
      'label': 'ویرایش',
      'fields': [
        {'key': 'title', 'label': 'عنوان', 'required': true},
      ],
    },
    'delete': {'method': 'POST', 'row': true, 'label': 'حذف'},
  },
};

void main() {
  for (final width in [320.0, 430.0]) {
    testWidgets(
      'panel filters, forms and table respect permissions at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = LayoutApi();
        addTearDown(api.dispose);
        await tester.pumpWidget(
          localized.host(PanelResourcePage(api: api, section: section)),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.refresh), findsNothing);
        expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
        await tester.tap(find.byType(PanelValueRow));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(PanelModal),
            matching: find.text('غیرفعال'),
          ),
        );
        await tester.pumpAndSettle();
        expect(api.queries.last['status'], 'inactive');
        await tester.tap(find.byTooltip('افزودن دوره'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<PanelFormPage>(find.byType(PanelFormPage)).dialog,
          true,
        );
        await tester.enterText(find.byType(TextFormField), 'دوره جدید');
        await tester.tap(find.byIcon(Icons.save_outlined));
        await tester.pumpAndSettle();
        expect(api.writes.last.$1, 'create');
        expect(api.writes.last.$2, {'title': 'دوره جدید'});
        expect(find.text('دوره جدید'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.table_rows_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(DataTable), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
        expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(600, 0),
        );
        await tester.pumpAndSettle();
        final deletion = find.byTooltip('حذف').first;
        await tester.ensureVisible(deletion);
        await tester.tap(deletion);
        await tester.pumpAndSettle();
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect((dialog.title! as Text).style!.fontSize, 14);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(api.writes.last.$1, 'delete');
        expect(api.rows.any((row) => row['id'] == 2), true);
        expect(tester.takeException(), null);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('shared PDF options use report title and three palettes', (
    tester,
  ) async {
    final api = LayoutApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      localized.host(PanelResourcePage(api: api, section: section)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(BranchColorPicker), findsNWidgets(3));
    expect(
      find.widgetWithText(TextFormField, 'مدیریت دوره‌ها'),
      findsOneWidget,
    );
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('statistics fit a compact row on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      localized.host(
        const PanelScaffold(
          body: PanelStatistics(
            stats: {'monthlyIncome': 123456789, 'activeStudents': 1500},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Card).first).height, 40);
    expect(
      tester.getTopLeft(find.byType(Card).first).dy,
      tester.getTopLeft(find.byType(Card).last).dy,
    );
    expect(tester.takeException(), null);
  });
}
