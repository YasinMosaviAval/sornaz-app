import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

const achievementKeys = [
  'educations',
  'certificates',
  'awards',
  'experiences',
  'events',
  'publications',
  'badges',
];
Json entry(String key) => {
  'key': key,
  'label': key,
  'en': key,
  'rows': 'items',
  'actions': {
    'list': {'method': 'GET'},
  },
};

class AchievementApi extends PanelApi {
  AchievementApi() : super('fixture');
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async => {
    'canCreate': false,
    'items': [
      {
        'id': 7,
        'title': 'Received badge',
        'badge_title': 'Received badge',
        'canManage': false,
        'canChangeStatus': false,
      },
    ],
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'seven ordered achievement tabs and independent polls retain sidebar order',
    () {
      final sections = [
        ...achievementKeys.map(entry),
        entry('polls'),
        entry('branches'),
        entry('finance'),
      ];
      final menu = websitePanelNavigation({
        'navigationVersion': 1,
        'sections': sections,
        'navigation': [
          for (final key in ['branches', 'educations', 'finance', 'polls'])
            {'key': key, 'section': key, 'label': key},
        ],
      });
      expect(menu.map((item) => item['key']), [
        'branches',
        'educations',
        'finance',
        'polls',
      ]);
      expect(
        objects(menu[1]['pageTabs']).map((item) => item['key']),
        achievementKeys,
      );
      expect(menu.last['pageTabs'], isNull);
      expect(
        objects(
          panelSectionWithTabs(entry('badges'), sections)['pageTabs'],
        ).map((item) => item['key']),
        achievementKeys,
      );
      final restricted = panelSectionWithTabs(entry('educations'), [
        entry('educations'),
      ]);
      expect(objects(restricted['pageTabs']).map((item) => item['key']), [
        'educations',
      ]);
    },
  );
  testWidgets('received badges never offer create edit or delete', (
    tester,
  ) async {
    final api = AchievementApi();
    final section = {
      ...entry('badges'),
      'actions': {
        'list': {'method': 'GET'},
        'create': {'label': 'افزودن نشان', 'row': false},
        'update': {'label': 'ویرایش', 'row': true},
        'delete': {'label': 'حذف', 'row': true},
      },
    };
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: PanelResourcePage(api: api, section: section),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Received badge'), findsWidgets);
    expect(find.byTooltip('افزودن نشان'), findsNothing);
    expect(find.byTooltip('ویرایش'), findsNothing);
    expect(find.byTooltip('حذف'), findsNothing);
    expect(tester.takeException(), isNull);
    api.dispose();
  });
}
