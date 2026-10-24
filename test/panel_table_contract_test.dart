import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_table_contract.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

final contracts = optionalObject(
  jsonDecode(
    File('test/fixtures/panel_table_contracts.json').readAsStringSync(),
  ),
);

class TableApi extends PanelApi {
  TableApi(this.row) : super('test');
  Json row;
  int writes = 0;
  bool fail = false;
  Map<String, String>? parameters;
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async => {
    'items': [row],
  };
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    writes++;
    parameters = params;
    if (fail) throw StateError('offline');
    row = {...row, 'status': 'inactive'};
    return {};
  }
}

Json section(String key, {Json? presentation}) => {
  'key': key,
  'label': 'عنوان منو',
  'rows': 'items',
  'presentation': presentation ?? contracts[key],
  'actions': {
    'list': {'method': 'GET'},
    for (final key in ['status', 'update', 'delete'])
      key: {'label': key, 'row': true, 'method': 'POST'},
  },
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'actual server contracts restrict columns and account-specific controls',
    () {
      final levels = panelTableContract(section('course-levels'));
      expect(objects(levels['columns']).map((c) => c['key']), [
        'name',
        'summary',
      ]);
      expect(levels['rowActions'], ['details']);
      final types = optionalObject(contracts['classroom-types']);
      expect(
        panelTableColumns(types, {
          'permissions': {'showStatus': false, 'showCategory': false},
        }).map((c) => c['key']),
        ['createdByName', 'title', 'summary'],
      );
      final points = optionalObject(contracts['points']);
      expect(
        panelTableColumns(points, {'canManage': false}).map((c) => c['key']),
        isNot(contains('status')),
      );
      expect(
        panelTableColumns(points, {'canManage': true}).map((c) => c['key']),
        contains('status'),
      );
      expect(
        objects(contracts['students']['columns']).map((c) => c['key']),
        isNot(contains('status')),
      );
    },
  );
  testWidgets(
    'levels show summary and website details without mutation controls or raw metadata',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = TableApi({
        'id': 1,
        'name': 'مبتدی',
        'summary': 'خلاصه سطح',
        'description': 'شرح سطح',
        'secret_metadata': 'internal-value',
      });
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(api: api, section: section('course-levels')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('خلاصه سطح'), findsOneWidget);
      expect(find.text('وضعیت'), findsNothing);
      expect(find.text('delete'), findsNothing);
      expect(find.text('update'), findsNothing);
      await tester.tap(find.byTooltip('جزئیات'));
      await tester.pumpAndSettle();
      expect(find.text('جزئیات سطح درس'), findsOneWidget);
      expect(find.text('شرح سطح'), findsOneWidget);
      expect(find.text('internal-value'), findsNothing);
      expect(api.writes, 0);
      api.dispose();
    },
  );
  for (final fail in [false, true]) {
    testWidgets(
      'inline status writes once and ${fail ? 'retains state after failure' : 'refreshes after success'}',
      (tester) async {
        final api = TableApi({
          'id': 4,
          'title': 'قانون',
          'status': 'active',
          'canChangeStatus': true,
        })..fail = fail;
        await tester.pumpWidget(
          fixture.host(
            PanelResourcePage(
              api: api,
              section: section(
                'test',
                presentation: {
                  'columns': [
                    {'key': 'status', 'label': 'وضعیت', 'action': 'status'},
                  ],
                  'rowActions': <String>[],
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PopupMenuButton<String>), findsNothing);
        await tester.tap(find.text('فعال'));
        await tester.pumpAndSettle();
        expect(api.writes, 1);
        expect(api.parameters?['id'], '4');
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(fail ? 'فعال' : 'غیرفعال'), findsOneWidget);
        api.dispose();
      },
    );
  }
  testWidgets('read-only status remains colored and cannot write', (
    tester,
  ) async {
    final api = TableApi({
      'id': 4,
      'status': 'pending',
      'canChangeStatus': false,
    });
    await tester.pumpWidget(
      fixture.host(
        PanelResourcePage(
          api: api,
          section: section(
            'test',
            presentation: {
              'columns': [
                {'key': 'status', 'label': 'وضعیت', 'action': 'status'},
              ],
              'rowActions': <String>[],
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cell = tester.widget<PanelStatusCell>(find.byType(PanelStatusCell));
    expect(cell.onPressed, isNull);
    expect(api.writes, 0);
    api.dispose();
  });
}
