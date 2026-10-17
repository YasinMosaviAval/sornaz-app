import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_filter_contract.dart';
import 'package:sornaz/screens/Site/panel_form_contract.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_table_contract.dart';
import 'package:sornaz/screens/Site/panel_ui.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class FiltersApi extends PanelApi {
  FiltersApi(this.data) : super('test');
  final Json data;
  final calls = <(String, Map<String, String>)>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    calls.add((path, {...?query}));
    if (path.endsWith('/usage'))
      return {
        'courses': [
          {'title': 'دوره پیانو', 'organization': 'آموزشگاه'},
        ],
        'contracts': [
          {
            'title': 'قرارداد مدرس',
            'teacher': 'مدرس نمونه',
            'organization': 'شعبه یک',
            'internal_id': 5,
          },
        ],
      };
    return data;
  }

  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async => {};
}

Json section(String key) => {
  'key': key,
  'label': 'عنوان منو',
  'rows': key == 'my-points' ? 'recent' : 'items',
  'actions': {
    'list': {'method': 'GET'},
  },
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'bundled contract replaces a stale server table and retains website filters',
    () {
      final stale = {
        ...section('points'),
        'presentation': {
          'version': 1,
          'columns': [
            {'key': 'title', 'label': 'عنوان'},
          ],
        },
      };
      final contract = panelTableContract(stale);
      expect(
        panelTableColumns(contract, {'canManage': false}).map((c) => c['key']),
        ['title', 'type', 'category', 'points', 'repeatMode'],
      );
      expect(contract['actionsPermission'], 'canManage');
      expect(objects(contract['summaries']).single['label'], 'قوانین فعال');
      expect(panelWebFilters(stale, {}, []).map((f) => f['webId']), [
        'filterPointType',
        'filterPointCategory',
        'filterPointStatus',
      ]);
      expect(panelWebFilters(section('users'), {}, []).map((f) => f['webId']), [
        'accessUserStatus',
      ]);
      expect(panelWebFilters(section('terms'), {}, []).length, 7);
      expect(panelWebFilters(section('classrooms'), {}, []).length, 4);
      expect(panelWebFilters(section('members'), {}, []).length, 4);
    },
  );
  test(
    'combined local filters handle status codes, age, equipment and date bounds',
    () {
      final members = panelWebFilters(section('members'), {}, []);
      expect(
        panelMatchesFilters(
          {'type': 'teacher', 'status_code': 'active', 'currency': 'تومان'},
          members,
          {
            'filterStaffType': 'teacher',
            'filterStaffStatus': 'فعال',
            'filterStaffCurrency': 'تومان',
          },
        ),
        isTrue,
      );
      expect(
        panelMatchesFilters(
          {'type': 'manager', 'status_code': 'active'},
          members,
          {'filterStaffType': 'teacher'},
        ),
        isFalse,
      );
      final rooms = panelWebFilters(section('classrooms'), {}, []);
      expect(
        panelMatchesFilters(
          {
            'statusValue': 'available',
            'equipment': [
              {'name': 'پیانو', 'qty': 2},
            ],
          },
          rooms,
          {
            'filterClassroomStatus': 'در دسترس',
            'filterClassroomEquipment': 'پیانو',
          },
        ),
        isTrue,
      );
      final finance = panelWebFilters(section('finance'), {}, []);
      expect(
        panelMatchesFilters(
          {'dateIso': '2026-10-10'},
          finance,
          {'filterFinanceRange': 'custom', 'filterFinanceFrom': '2026-10-11'},
        ),
        isFalse,
      );
      expect(
        panelMatchesFilters(
          {'dateIso': '2026-10-10'},
          finance,
          {'filterFinanceRange': 'weekly', 'filterFinanceFrom': '2026-10-11'},
          now: DateTime(2026, 10, 16),
        ),
        isTrue,
      );
      final students = panelWebFilters(section('students'), {}, []);
      expect(
        panelMatchesFilters(
          {'birthDate': '2020-01-01'},
          students,
          {'filterStudentAgeGroup': 'child'},
        ),
        isTrue,
      );
    },
  );
  test(
    'server filters use website query names without extra academy/branch filters',
    () {
      final users = panelWebFilters(section('users'), {}, []);
      expect(
        panelFilterQuery(
          users,
          {'accessUserStatus': 'approved'},
          'academy',
          'users',
        ),
        {'status': 'approved', 'organization': 'academy'},
      );
      expect(panelFilterQuery(users, {}, 'branch:7', 'users'), {
        'branchId': '7',
      });
      final schedules = panelWebFilters(section('schedules'), {}, [
        {'startTime': '09:00', 'endTime': '09:15'},
      ]);
      expect(
        panelFilterQuery(
          schedules,
          {'filterScheduleInstrument': 5, 'filterScheduleTimeFrom': '09:05'},
          '',
          'schedules',
        ),
        {'lesson': '5', 'timeFrom': '09:05'},
      );
      expect(
        optionalObject(
          schedules.firstWhere((f) => f['rowPath'] == 'timeFrom')['options'],
        ).keys,
        contains('09:05'),
      );
    },
  );
  test(
    'term organizations include academy accounts and scope rooms and teachers without mixing academies',
    () {
      final data = panelTermOptionData(
        {
          'members': [
            {
              'id': 1,
              'branchId': 0,
              'academyId': 10,
              'type': 'teacher',
              'lessonId': 7,
            },
            {
              'id': 2,
              'branchId': 0,
              'academyId': 20,
              'type': 'teacher',
              'lessonId': 7,
            },
          ],
          'classrooms': [
            {'id': 1, 'branchId': 0, 'academyId': 10},
            {'id': 2, 'branchId': 0, 'academyId': 20},
            {'id': 3, 'branchId': 3, 'academyId': 10},
          ],
        },
        {
          'organizations': [
            {
              'id': 10,
              'user_id': 100,
              'kind': 'academy',
              'name': 'آموزشگاه یک',
            },
            {
              'id': 20,
              'user_id': 200,
              'kind': 'academy',
              'name': 'آموزشگاه دو',
            },
            {'id': 3, 'user_id': 300, 'kind': 'branch', 'name': 'شعبه'},
          ],
          'courses': [
            {'id': 7, 'organizationUserId': 100, 'lesson_id': 7},
          ],
        },
      );
      final fields = panelTermDialogFields([
        {
          'key': 'branchId',
          'options': {'source': 'branches'},
          'type': 'select',
        },
        {
          'key': 'classroomId',
          'options': {
            'source': 'classrooms',
            'match': {'branchId': 'branchId'},
            'requireMatch': true,
          },
        },
      ]);
      expect(panelSelectOptions(fields.first, data).keys, [
        '100',
        '200',
        '300',
      ]);
      expect(
        panelSelectOptions(fields.last, {
          ...data,
          '_form': {'organizationUserId': 100},
        }).keys,
        ['1', '3'],
      );
      final payload = panelDialogPayload('terms', 'create', {
        'organizationUserId': 100,
        'status': 'open',
      }, data);
      expect(payload['branchId'], 0);
      expect(payload['academyId'], 10);
      final branchRoom = panelDialogPayload('terms', 'create', {
        'organizationUserId': 100,
        'classroomId': 3,
        'status': 'open',
      }, data);
      expect(branchRoom['branchId'], 3);
      expect(branchRoom['academyId'], 10);
      final people = {
        'options': {'source': 'members', 'termPeople': true},
      };
      expect(
        panelSelectOptions(people, {
          ...data,
          '_selected': {
            'courseId': {'organizationId': 10},
            'classroomId': {'branchId': 0},
          },
        }).keys,
        ['1'],
      );
    },
  );
  testWidgets(
    'lesson usage opens a labeled dialog and row actions retain colored icons',
    (tester) async {
      tester.view.physicalSize = const Size(2000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FiltersApi({
        'items': [
          {'id': 4, 'title': 'درس نمونه', 'canEdit': true},
        ],
      });
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: {
              ...section('lessons'),
              'actions': {
                'list': {},
                'usage': {'method': 'GET', 'row': true, 'label': 'محل'},
                'update': {'row': true, 'label': 'ویرایش'},
                'delete': {'row': true, 'label': 'حذف'},
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.delete_outline)).color,
        Colors.red,
      );
      await tester.ensureVisible(find.byIcon(Icons.fact_check_outlined));
      await tester.tap(find.byIcon(Icons.fact_check_outlined));
      await tester.pumpAndSettle();
      expect(api.calls.last.$1, '/lessons/usage');
      expect(api.calls.last.$2['id'], '4');
      expect(find.byType(PanelModal), findsOneWidget);
      expect(find.text('دوره پیانو'), findsOneWidget);
      expect(find.text('قرارداد مدرس'), findsOneWidget);
      expect(find.text('internal_id'), findsNothing);
      expect(find.byType(PanelResourcePage), findsOneWidget);
      api.dispose();
    },
  );
  testWidgets(
    'nonadmin point rules and personal history show website cards and no action column',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FiltersApi({
        'canManage': false,
        'balance': {'general': 12, 'professional': 8},
        'rules': [
          {
            'id': 1,
            'title': 'قانون نمونه',
            'status': 'active',
            'type': 'general',
            'category': 'academic',
            'points': 10,
            'repeatMode': 'daily',
          },
        ],
        'recent': [
          {
            'type': 'general',
            'points': 12,
            'action': 'ثبت درس',
            'rule_id': 1,
            'updated_at': '2026-10-01',
          },
        ],
      });
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
      expect(find.text('امتیاز عمومی من'), findsOneWidget);
      expect(find.text('امتیاز حرفه‌ای من'), findsOneWidget);
      expect(api.calls.first.$2['history'], '1');
      expect(
        tester.widget<DataTable>(find.byType(DataTable)).columns.length,
        6,
      );
      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();
      expect(find.text('قوانین فعال'), findsOneWidget);
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.columns.length, 5);
      expect(table.rows.single.cells.length, 5);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      api.dispose();
    },
  );
}
