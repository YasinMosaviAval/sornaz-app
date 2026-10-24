import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/site_panel_page.dart';
import 'package:sornaz/screens/Site/panel_gallery.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';

Map<String, dynamic> section(String key) => {
  'key': key,
  'label': key,
  'en': key,
  'actions': {'list': {}},
};
http.Response reply(Object value) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'status': 200,
      'data': {'success': true, 'data': value},
    }),
  ),
  200,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('personal points remain available in the panel top bar', (
    tester,
  ) async {
    final calls = <String>[];
    final api = PanelApi(
      'test',
      client: MockClient((request) async {
        calls.add(request.url.path);
        if (request.url.path.endsWith('/my-points/list'))
          return reply({'balance': 15, 'recent': []});
        return reply({
          'navigationVersion': 1,
          'navigation': [],
          'sections': [section('my-points')],
        });
      }),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppData(),
        child: MaterialApp(
          home: NativePanel(token: 'test', api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Points'), findsOneWidget);
    await tester.tap(find.byTooltip('Points'));
    await tester.pumpAndSettle();
    expect(calls.any((path) => path.endsWith('/my-points/list')), isTrue);
    api.dispose();
  });

  testWidgets('personal gallery saves through its own endpoint', (
    tester,
  ) async {
    final calls = <String>[];
    var changes = 0;
    final api = PanelApi(
      'test',
      client: MockClient((request) async {
        calls.add(request.url.path);
        return reply({
          'id': 1,
          'title': 'New title',
          'url': '',
          'type': 'image',
        });
      }),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppData(),
        child: MaterialApp(
          home: Scaffold(
            body: GalleryRecord(
              api: api,
              sectionKey: 'my-gallery',
              row: const {
                'id': 1,
                'title': 'Old title',
                'url': '',
                'type': 'image',
              },
              fields: const [
                {'key': 'title', 'label': 'Title'},
              ],
              data: const {},
              canEdit: true,
              onChanged: () => changes++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Edit'));
    // Gallery stays busy until its edit route closes; settle only the transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextFormField), 'New title');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(
      calls.where((path) => path.endsWith('/my-gallery/update')),
      hasLength(1),
    );
    expect(calls.any((path) => path.endsWith('/gallery/update')), isFalse);
    expect(changes, 1);
    api.dispose();
  });

  testWidgets(
    'personal finance retains invoices, installments and payment details',
    (tester) async {
      final api = PanelApi(
        'test',
        client: MockClient(
          (_) async => reply({
            'invoices': [
              {'id': 1, 'title': 'Invoice', 'readOnly': true},
            ],
            'installments': [
              {'id': 2, 'amount': 10},
            ],
            'payments': [
              {'id': 3, 'amount': 5},
            ],
          }),
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppData(),
          child: MaterialApp(
            home: PanelResourcePage(
              api: api,
              section: {...section('my-finance'), 'rows': 'invoices'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final views = tester.widgetList<PanelDataView>(
        find.byType(PanelDataView),
      );
      expect(
        views.any(
          (view) =>
              view.value is Map &&
              (view.value as Map).containsKey('installments') &&
              (view.value as Map).containsKey('payments'),
        ),
        isTrue,
      );
      api.dispose();
    },
  );
  test('operation-only sections never become extra menu entries', () {
    final menu = websitePanelNavigation({
      'navigationVersion': 1,
      'sections': [
        for (final key in [
          'dashboard',
          'my-gallery',
          'my-lessons',
          'my-settings',
          'my-waiting',
          'roles',
        ])
          section(key),
      ],
      'navigation': [
        {'key': 'dashboard', 'section': 'dashboard', 'label': 'داشبورد'},
        {'key': 'gallery', 'section': 'my-gallery', 'label': 'گالری'},
        {'key': 'settings', 'section': 'my-settings', 'label': 'تنظیمات'},
      ],
    });
    expect(menu.map((item) => item['key']), ['dashboard', 'my-gallery']);
    expect(menu.map((item) => item['label']), ['داشبورد', 'گالری']);
    expect(menu.any((item) => item['key'] == 'roles'), isFalse);
  });

  test(
    'dashboard workflows remain reachable without becoming sidebar extras',
    () {
      final menu = websitePanelNavigation({
        'navigationVersion': 1,
        'sections': [
          section('dashboard'),
          section('waiting-approvals'),
          section('roles'),
        ],
        'navigation': [
          {
            'key': 'dashboard',
            'section': 'dashboard',
            'links': ['waiting-approvals'],
          },
        ],
      });
      expect(menu, hasLength(1));
      expect(menu.single['relatedSections'].single['key'], 'waiting-approvals');
      expect(menu.single['relatedSections'].single['actions'], {'list': {}});
    },
  );

  test('website groups, order and category parameters survive hydration', () {
    final menu = websitePanelNavigation({
      'navigationVersion': 1,
      'sections': [section('awards'), section('gallery')],
      'navigation': [
        {
          'key': 'profileAchievementsSubmenu',
          'label': 'سوابق و دستاوردها',
          'children': [
            {'key': 'awards', 'section': 'awards', 'label': 'پاداش‌ها و جوایز'},
          ],
        },
        {
          'key': 'gallery-intro-video',
          'section': 'gallery',
          'initialParams': {'collection': 'intro_video'},
          'where': {'category': 'intro_video'},
        },
      ],
    });
    expect(menu.first['children'].single['key'], 'awards');
    expect(menu.last['initialParams'], {'collection': 'intro_video'});
    expect(menu.last['actions'], {'list': {}});
  });

  test(
    'old and mismatched server contracts do not fall back to catalog menus',
    () {
      expect(
        () => websitePanelNavigation({
          'sections': [section('roles')],
        }),
        throwsA(isA<PanelNavigationUnavailable>()),
      );
      expect(
        () => websitePanelNavigation({
          'navigationVersion': 1,
          'sections': [],
          'navigation': [
            {'key': 'roles', 'section': 'roles'},
          ],
        }),
        throwsA(isA<PanelNavigationUnavailable>()),
      );
    },
  );

  testWidgets(
    'native panel shows exact server menu with no search or catalog extras',
    (tester) async {
      final calls = <String>[];
      final api = PanelApi(
        'test',
        client: MockClient((request) async {
          calls.add(request.url.path);
          if (request.url.path.endsWith('/my-settings/list'))
            return reply({
              'personal': {'language': 'fa'},
            });
          return reply({
            'navigationVersion': 1,
            'sections': [
              for (final key in [
                'my-lessons',
                'my-gallery',
                'my-settings',
                'dashboard',
              ])
                section(key),
            ],
            'navigation': [
              {
                'key': 'settings',
                'section': 'my-settings',
                'label': 'تنظیمات',
                'en': 'Settings',
              },
            ],
          });
        }),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppData(),
          child: MaterialApp(
            home: NativePanel(token: 'test', api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.text('my-lessons'), findsNothing);
      expect(find.text('my-gallery'), findsNothing);
      expect(find.text('Settings'), findsNothing);
      expect(calls.any((path) => path.endsWith('/my-settings/list')), isFalse);
      expect(calls.any((path) => path.endsWith('/settings/list')), isFalse);
      api.dispose();
    },
  );

  testWidgets(
    'old API displays deployment requirement instead of an incorrect menu',
    (tester) async {
      final api = PanelApi(
        'test',
        client: MockClient(
          (_) async => reply({
            'sections': [section('my-lessons')],
          }),
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppData(),
          child: MaterialApp(
            home: NativePanel(token: 'test', api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Update the website panel API to load its authorized menu.'),
        findsOneWidget,
      );
      expect(find.text('my-lessons'), findsNothing);
      api.dispose();
    },
  );
}
