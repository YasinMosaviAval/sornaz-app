import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_organization_filter.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class ParityApi extends PanelApi {
  ParityApi(this.data) : super('test');
  final Json data;
  Json? written;
  Map<String, String>? parameters;
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async => data;
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    written = {...values};
    parameters = {...params};
    return {};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'site management destinations are reachable only when catalog grants them',
    () {
      final menu = panelNavigation([
        for (final key in [
          'pages',
          'settings',
          'guides',
          'inline-translations',
        ])
          {'key': key, 'label': key},
      ]);
      expect(
        objects(menu.single['children']).map((item) => item['key']),
        containsAll(['settings', 'guides', 'inline-translations']),
      );
      expect(
        panelNavigation([
          {'key': 'my-settings'},
        ]).any((item) => item['key'] == 'site-management-menu'),
        isFalse,
      );
    },
  );

  test(
    'organization filters distinguish academy-owned and branch-owned records',
    () {
      final academy = <String, dynamic>{
        'organization': {
          'kind': 'academy',
          'branchId': null,
          'name': 'آموزشگاه',
        },
      };
      final branch = <String, dynamic>{
        'organization': {'kind': 'branch', 'branchId': 5, 'name': 'شعبه'},
        'canManage': false,
      };
      final choices = panelOrganizationOptions({}, [academy, branch], fa: true);
      expect(choices.keys, containsAll(['academy', 'branch:5']));
      expect(panelMatchesOrganization(academy, 'academy'), isTrue);
      expect(panelMatchesOrganization(branch, 'academy'), isFalse);
      expect(panelMatchesOrganization(branch, 'branch:5'), isTrue);
      expect(panelMatchesOrganization({'branch_id': 0}, 'academy'), isTrue);
      expect(panelMatchesOrganization(branch, ''), isTrue);
    },
  );

  testWidgets(
    'personal settings prefill overrides defaults and submit only declared settings',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ParityApi({
        'defaults': {'language': 'fa', 'fontWeight': 2, 'fonts': []},
        'personal': {'language': 'en'},
        'canEditSite': false,
      });
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: const {
              'key': 'my-settings',
              'label': 'تنظیمات من',
              'rows': '',
              'actions': {
                'list': {'method': 'GET'},
                'save': {
                  'label': 'ذخیره تنظیمات شخصی',
                  'method': 'POST',
                  'row': false,
                  'initialSources': ['defaults', 'personal'],
                  'strictFields': true,
                  'fields': [
                    {
                      'key': 'language',
                      'label': 'زبان',
                      'type': 'select',
                      'options': {'fa': 'فارسی', 'en': 'English'},
                    },
                    {'key': 'fontWeight', 'label': 'وزن قلم', 'type': 'number'},
                  ],
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ذخیره تنظیمات شخصی'));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
      final submit = find
          .descendant(
            of: find.byType(PanelFormPage),
            matching: find.byType(FilledButton),
          )
          .last;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.written, {'language': 'en', 'fontWeight': 2});
      api.dispose();
    },
  );

  testWidgets('schedule form only validates the applicable scheduling mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      fixture.host(
        const PanelFormPage(
          title: 'زمان‌بندی',
          fields: [
            {
              'key': 'session_id',
              'label': 'جلسه موجود',
              'required': true,
              'type': 'number',
              'visibleWhen': {'record.needsFirstDate': false},
            },
            {
              'key': 'first_date',
              'label': 'روز شروع',
              'required': true,
              'type': 'date',
              'visibleWhen': {'record.needsFirstDate': true},
            },
          ],
          data: {
            'record': {'needsFirstDate': true},
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('جلسه موجود'), findsNothing);
    expect(find.textContaining('روز شروع'), findsWidgets);
  });

  testWidgets(
    'academy holiday setting maps the selected academy into route params',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ParityApi({
        'holidays': [],
        'academies': [
          {'id': 7, 'name': 'آموزشگاه نمونه'},
        ],
      });
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: const {
              'key': 'national-holidays',
              'label': 'تعطیلات',
              'rows': 'holidays',
              'actions': {
                'list': {'method': 'GET'},
                'academy-setting': {
                  'label': 'تنظیم تعطیلات',
                  'method': 'POST',
                  'row': false,
                  'params': {'academyId': 'academyId'},
                  'fields': [
                    {
                      'key': 'academyId',
                      'label': 'آموزشگاه',
                      'type': 'select',
                      'required': true,
                      'options': {'source': 'academies'},
                    },
                    {
                      'key': 'allowClasses',
                      'label': 'برگزاری کلاس',
                      'type': 'bool',
                    },
                  ],
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تنظیم تعطیلات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('آموزشگاه نمونه').last);
      await tester.pumpAndSettle();
      final submit = find
          .descendant(
            of: find.byType(PanelFormPage),
            matching: find.byType(FilledButton),
          )
          .last;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.parameters?['academyId'], '7');
      api.dispose();
    },
  );

  testWidgets(
    'waiting approval uses request identity and prefills student data',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ParityApi({
        'actionItems': [
          {
            'requestId': 52,
            'type': 'student_waiting',
            'studentName': 'هنرجوی نمونه',
          },
        ],
      });
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: const {
              'key': 'waiting-approvals',
              'label': 'ثبت‌نام‌ها',
              'rows': 'actionItems',
              'rowId': 'requestId',
              'rowTitle': 'studentName',
              'where': {'type': 'student_waiting'},
              'actions': {
                'list': {'method': 'GET'},
                'approve': {
                  'label': 'تأیید هنرجو',
                  'method': 'POST',
                  'row': true,
                  'fields': [
                    {
                      'key': 'name',
                      'label': 'نام',
                      'type': 'text',
                      'required': true,
                      'initial': 'studentName',
                    },
                  ],
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید هنرجو'));
      await tester.pumpAndSettle();
      expect(find.text('هنرجوی نمونه'), findsWidgets);
      final submit = find
          .descendant(
            of: find.byType(PanelFormPage),
            matching: find.byType(FilledButton),
          )
          .last;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.parameters?['id'], '52');
      expect(api.written?['name'], 'هنرجوی نمونه');
      api.dispose();
    },
  );

  testWidgets(
    'direct permission edits preserve covered grants and do not send roleIds',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ParityApi({
        'users': [
          {
            'id': 9,
            'name': 'کاربر نمونه',
            'canEdit': true,
            'permissions': [
              {'id': 1},
              {'id': 2},
            ],
            'rolePermissionIds': [1],
          },
        ],
        'permissions': [
          {'id': 1, 'title': 'مجوز نقش'},
          {'id': 2, 'title': 'مجوز مستقیم'},
          {'id': 3, 'title': 'مجوز تازه'},
        ],
      });
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: const {
              'key': 'users',
              'label': 'کاربران',
              'rows': 'users',
              'actions': {
                'list': {'method': 'GET'},
                'permissions': {
                  'label': 'ویرایش مجوزها',
                  'method': 'POST',
                  'row': true,
                  'fields': [
                    {
                      'key': 'permissionIds',
                      'label': 'مجوزها',
                      'type': 'multi',
                      'initial': 'permissions',
                      'options': {
                        'source': 'permissions',
                        'excludeSource': 'record.rolePermissionIds',
                      },
                    },
                  ],
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'تعیین دسترسی‌ها'),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'تعیین دسترسی‌ها'));
      await tester.pumpAndSettle();
      expect(find.text('مجوز نقش'), findsNothing);
      await tester.tap(find.text('مجوز مستقیم'));
      await tester.tap(find.text('مجوز تازه'));
      final submit = find
          .descendant(
            of: find.byType(PanelFormPage),
            matching: find.byType(FilledButton),
          )
          .last;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.written?['permissionIds'], unorderedEquals([1, 3]));
      expect(api.written?.containsKey('roleIds'), isFalse);
      api.dispose();
    },
  );
}
