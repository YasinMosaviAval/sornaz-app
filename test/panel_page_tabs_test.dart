import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';

import 'social_widget_test.dart' as fixture;

Json section(String key) => {
  'key': key,
  'label': key,
  'en': key,
  'rows': 'items',
  'actions': {
    'list': {'method': 'GET'},
  },
};

class TabsApi extends PanelApi {
  TabsApi() : super('test');
  final calls = <String>[];
  bool failUsers = false;
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    calls.add(path);
    if (failUsers && path == '/users/list') throw StateError('offline');
    return {
      'items': [
        {'id': 1, 'title': path, 'status': 'active'},
      ],
      'levels': [
        {'id': 2, 'title': 'Learning level'},
      ],
      'rules': [
        {'id': 3, 'title': 'Point rule'},
      ],
    };
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'internal tabs use authorized sections without adding sidebar entries',
    () {
      final menu = websitePanelNavigation({
        'navigationVersion': 1,
        'sections': [
          section('lessons'),
          section('course-levels'),
          section('courses'),
        ],
        'navigation': [
          {'key': 'lessons', 'section': 'lessons'},
        ],
      });
      expect(menu.length, 1);
      expect(objects(menu.single['pageTabs']).map((tab) => tab['key']), [
        'course-levels',
        'lessons',
        'courses',
      ]);
      final restricted = panelSectionWithTabs(section('classrooms'), [
        section('classrooms'),
        {...section('classroom-types'), 'hidden': true},
      ]);
      expect(objects(restricted['pageTabs']).map((tab) => tab['key']), [
        'classrooms',
      ]);
    },
  );

  test('personal learning and points retain only available destinations', () {
    final learning = panelSectionWithTabs(section('my-terms'), [
      section('dashboard'),
      section('my-terms'),
      section('my-classrooms'),
    ]);
    expect(objects(learning['pageTabs']).map((tab) => tab['key']), [
      'dashboard',
      'my-terms',
      'my-classrooms',
    ]);
    expect(
      objects(
        objects(learning['pageTabs']).first['relatedSections'],
      ).map((item) => item['key']),
      ['my-classrooms', 'my-terms'],
    );
    final points = panelSectionWithTabs(section('my-points'), [
      section('my-points'),
    ]);
    final pointTabs = objects(points['pageTabs']);
    expect(pointTabs.map((tab) => tab['key']), ['my-points', 'my-point-rules']);
    expect(pointTabs.last['resourceKey'], 'my-points');
    expect(optionalObject(pointTabs.last['actions']).keys, ['list']);
  });

  testWidgets(
    'personal lesson levels use the authorized read-only data endpoint',
    (tester) async {
      final api = TabsApi();
      final lessons = section('my-lessons');
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: panelSectionWithTabs(lessons, [lessons]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Tab).first);
      await tester.pumpAndSettle();
      expect(api.calls, ['/my-lessons/list', '/my-lessons/list']);
      expect(find.text('Learning level'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(tester.takeException(), isNull);
      api.dispose();
    },
  );

  testWidgets(
    'personal point rules remain read-only and use the personal endpoint',
    (tester) async {
      final api = TabsApi();
      final points = section('my-points');
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: panelSectionWithTabs(points, [points]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();
      expect(api.calls, ['/my-points/list', '/my-points/list']);
      expect(find.text('Point rule'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      api.dispose();
    },
  );

  for (final group in [
    ['course-levels', 'lessons', 'courses'],
    ['members', 'users'],
    ['classroom-types', 'classrooms'],
  ]) {
    testWidgets('${group.first} tabs load on selection and show only tables', (
      tester,
    ) async {
      final api = TabsApi();
      final catalog = group.map(section).toList();
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: panelSectionWithTabs(catalog.first, catalog),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.calls, ['/${group.first}/list']);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byIcon(Icons.view_list_outlined), findsNothing);
      expect(find.byIcon(Icons.table_rows_outlined), findsNothing);
      for (var i = 1; i < group.length; i++) {
        await tester.tap(find.byType(Tab).at(i));
        await tester.pumpAndSettle();
        expect(api.calls.last, '/${group[i]}/list');
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.text(group.first), findsOneWidget);
        expect(find.text('/${group[i]}/list'), findsOneWidget);
        expect(find.byType(DataTable), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      api.dispose();
    });
  }

  testWidgets('tabs remain available after a section fails to load', (
    tester,
  ) async {
    final api = TabsApi()..failUsers = true;
    final catalog = ['members', 'users'].map(section).toList();
    await tester.pumpWidget(
      fixture.host(
        PanelResourcePage(
          api: api,
          section: panelSectionWithTabs(catalog.first, catalog),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsNothing);
    await tester.tap(find.byType(Tab).first);
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(api.calls, ['/members/list', '/users/list', '/members/list']);
    api.dispose();
  });
}
