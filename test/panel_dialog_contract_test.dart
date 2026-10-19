import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_form_contract.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

// Generated from the real PHP catalog by scripts/mobile_panel_dialog_test.php --export.
final contracts = optionalObject(
  jsonDecode(
    File('test/fixtures/panel_dialog_contracts.json').readAsStringSync(),
  ),
);
List<Json> fields(String section) => objects(contracts[section]['fields']);
Json field(String section, String key) =>
    fields(section).firstWhere((f) => f['key'] == key);

final staffData = <String, dynamic>{
  'staff_catalog': {
    'organizations': [
      {'user_id': 10, 'name': 'Academy'},
      {'user_id': 20, 'branch_id': 2, 'name': 'Branch'},
    ],
    'roles': [
      {'id': 1, 'name': 'academy_teacher', 'title': 'Academy teacher'},
      {'id': 2, 'name': 'branch_teacher', 'title': 'Branch teacher'},
      {'id': 3, 'name': 'academy_manager', 'title': 'Academy manager'},
    ],
    'lessons': [
      {
        'lesson_id': 4,
        'organization_user_id': 10,
        'name': 'Piano',
        'level_ids': [1],
      },
      {
        'lesson_id': 5,
        'organization_user_id': 20,
        'name': 'Violin',
        'level_ids': [2],
      },
    ],
    'levels': [
      {'id': 1, 'name': 'Level 1'},
      {'id': 2, 'name': 'Level 2'},
    ],
    'currencies': [
      {'id': 1, 'name': 'Rial'},
    ],
  },
};

class DialogApi extends PanelApi {
  DialogApi() : super('test');
  int writes = 0;
  Json? payload;
  final Json data = {
    'classrooms': <Json>[],
    'classroomTypes': [
      {'id': 1, 'name': 'Room'},
    ],
    'organizations': [
      {'user_id': 10, 'name': 'Academy'},
    ],
    'permissions': {'isReceptionist': false},
  };
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async => data;
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, dynamic> files = const {},
  }) async {
    writes++;
    payload = values;
    if (writes == 1) throw const SocialException('Retry this save');
    return {};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'real staff schema scopes organization, contract role, lesson and offered levels',
    () {
      final values = panelInitialValues(fields('members'), {}, staffData);
      expect(values['organizationUserId'], 10);
      final context = panelFormContext(fields('members'), {
        ...values,
        'lessonId': 4,
      }, staffData);
      expect(panelSelectOptions(field('members', 'roleId'), context).keys, [
        '1',
      ]);
      expect(panelSelectOptions(field('members', 'lessonId'), context).keys, [
        '4',
      ]);
      expect(panelSelectOptions(field('members', 'levelId'), context).keys, [
        '1',
      ]);
      final manager = panelFormContext(fields('members'), {
        ...values,
        'type': 'manager',
        'lessonId': 4,
        'levelId': 1,
      }, staffData);
      expect(panelFieldVisible(field('members', 'lessonId'), manager), isFalse);
      expect(panelSelectOptions(field('members', 'roleId'), manager).keys, [
        '3',
      ]);
      final submitted = panelSubmittedValues(fields('members'), {
        ...values,
        'type': 'manager',
        'lessonId': 4,
        'levelId': 1,
        'unrelated': 'keep private',
      }, staffData);
      expect(submitted.containsKey('lessonId'), isFalse);
      expect(submitted.containsKey('levelId'), isFalse);
      expect(submitted.containsKey('unrelated'), isFalse);
      final branch = panelFormContext(fields('members'), {
        ...values,
        'organizationUserId': 20,
        'lessonId': 5,
      }, staffData);
      expect(panelSelectOptions(field('members', 'roleId'), branch).keys, [
        '2',
      ]);
      expect(panelSelectOptions(field('members', 'levelId'), branch).keys, [
        '2',
      ]);
    },
  );

  test(
    'real student form shows parents by age and availability by selected term',
    () {
      final today = DateTime.now();
      final minor = DateTime(
        today.year - 17,
        today.month,
        today.day,
      ).toIso8601String().substring(0, 10);
      final adult = DateTime(
        today.year - 20,
        today.month,
        today.day,
      ).toIso8601String().substring(0, 10);
      final data = {
        'terms': [
          {'id': 1, 'organizationUserId': 10, 'name': 'Open', 'status': 'open'},
          {
            'id': 2,
            'organizationUserId': 10,
            'name': 'Ongoing',
            'status': 'ongoing',
          },
        ],
      };
      Json context(String birth, int term) => panelFormContext(
        fields('students'),
        {'birthDate': birth, 'termId': term},
        data,
      );
      expect(
        panelFieldVisible(
          field('students', 'parentFatherName'),
          context(minor, 1),
        ),
        isTrue,
      );
      expect(
        panelFieldVisible(
          field('students', 'parentFatherName'),
          context(adult, 1),
        ),
        isFalse,
      );
      expect(
        panelFieldVisible(
          field('students', 'availabilities'),
          context(minor, 1),
        ),
        isFalse,
      );
      expect(
        panelFieldVisible(
          field('students', 'availabilities'),
          context(minor, 2),
        ),
        isTrue,
      );
    },
  );

  test(
    'edit prefills preserve aliases, zero amounts and explicit selections',
    () {
      final values = panelInitialValues(fields('classrooms'), {
        'status': 'در دسترس',
        'statusValue': 'unavailable',
        'capacity': 0,
        'name': 'Existing',
      }, {});
      expect(values['status'], 'unavailable');
      expect(values['capacity'], 0);
      final changed = panelInitialValues(
        fields('members'),
        {
          'roles': [1],
          'roleId': 3,
          'type': 'manager',
        },
        staffData,
        applyAliases: false,
      );
      expect(changed['roleId'], 3);
      expect(
        panelValue({
          'items': [
            {'id': 42},
          ],
        }, 'items.0.id'),
        42,
      );
    },
  );

  test(
    'address cities follow the selected province rather than its display text',
    () {
      final addressFields = objects(field('students', 'addresses')['options']);
      final city = addressFields.firstWhere((f) => f['key'] == 'city');
      final data = {
        'provinces': [
          {'province_id': 1, 'province_name': 'Tehran'},
          {'province_id': 2, 'province_name': 'Fars'},
        ],
        'counties': [
          {'province_id': 1, 'county_name': 'Tehran city'},
          {'province_id': 2, 'county_name': 'Shiraz'},
        ],
      };
      expect(
        panelSelectOptions(
          city,
          panelFormContext(addressFields, {'province': 'Tehran'}, data),
        ).keys,
        ['Tehran city'],
      );
      expect(
        panelSelectOptions(
          city,
          panelFormContext(addressFields, {'province': 'Fars'}, data),
        ).keys,
        ['Shiraz'],
      );
    },
  );

  test('primitive options and missing optional lists never crash a form', () {
    final field = <String, dynamic>{
      'key': 'timezone',
      'type': 'select',
      'options': {'source': 'timezones'},
    };
    final context = panelFormContext(
      [field],
      {},
      {
        'timezones': ['Asia/Tehran', 'UTC'],
      },
    );
    expect(panelSelectOptions(field, context).keys, ['Asia/Tehran', 'UTC']);
    expect(
      panelSelectOptions(field, panelFormContext([field], {}, {})),
      isEmpty,
    );
    final api = PanelApi('test');
    expect(api.headers['X-Sornaz-Panel-Forms'], '2');
    api.dispose();
  });

  test(
    'term draft and receptionist use different session and status contracts',
    () {
      final data = {
        'operation': 'create',
        'timezones': [
          {'id': 1, 'name': 'Asia/Tehran'},
        ],
      };
      final draft = panelInitialValues(fields('terms'), {}, data);
      expect(draft['sessionCount'], 8);
      expect((draft['sessions'] as List).length, 1);
      final receptionist = panelInitialValues(fields('terms'), {}, {
        ...data,
        'permissions': {'isReceptionist': true},
      });
      expect(receptionist['status'], 'pending');
      expect((receptionist['sessions'] as List).length, 8);
      final submitted = panelSubmittedValues(fields('terms'), receptionist, {
        ...data,
        'permissions': {'isReceptionist': true},
      });
      expect(submitted['status'], 'pending');
      final wire = panelDialogPayload('terms', 'create', {
        'status': 'open',
        'sessionCount': 8,
        'installmentCount': 2,
        'sessions': [
          {'startTime': '10:00', 'durationMinutes': 60, 'timezoneId': 1},
        ],
      }, {});
      expect(wire['undatedTemplate'], isTrue);
      expect(wire['sessions'].first['endTime'], '11:00');
      expect(wire['sessions'].first['date'], '');
      expect((wire['installments'] as List).length, 2);
    },
  );

  test(
    'validation catches required collections, numeric limits and unrelated selections',
    () {
      expect(
        panelInvalidField([field('points', 'points')], {'points': 100001}, {}),
        'points',
      );
      expect(
        panelInvalidField([field('terms', 'teachers')], {'teachers': []}, {}),
        'teachers',
      );
      expect(
        panelInvalidField(
          [field('classrooms', 'onlineUrl')],
          {'deliveryMode': 'online', 'onlineUrl': 'bad-url'},
          {},
        ),
        'onlineUrl',
      );
      expect(
        panelInvalidField(
          [field('classrooms', 'onlineUrl')],
          {'deliveryMode': 'in_person'},
          {},
        ),
        isNull,
      );
    },
  );

  test(
    'term teachers are restricted to the selected course lesson and branch',
    () {
      final data = {
        'classrooms': [
          {'id': 9, 'branchId': 3},
        ],
        'courses': [
          {'id': 1, 'organizationUserId': 3, 'lessonId': 7},
        ],
        'members': [
          {'id': 10, 'type': 'teacher', 'branchId': 3, 'lessonId': 7},
          {'id': 11, 'type': 'teacher', 'branchId': 3, 'lessonId': 8},
          {'id': 12, 'type': 'teacher', 'branchId': 4, 'lessonId': 7},
        ],
      };
      expect(
        panelSelectOptions(
          field('terms', 'teachers'),
          panelFormContext(fields('terms'), {
            'courseId': 1,
            'organizationUserId': 3,
            'classroomId': 9,
          }, data),
        ).keys,
        ['10'],
      );
    },
  );

  testWidgets(
    'modern create retains inputs after failed save and sends only web fields',
    (tester) async {
      final api = DialogApi();
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: {
              'key': 'classrooms',
              'label': 'کلاس‌ها',
              'rows': 'classrooms',
              'actions': {
                'list': {},
                'create': {
                  ...optionalObject(contracts['classrooms']),
                  'method': 'POST',
                  'row': false,
                  'label': 'افزودن',
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(PanelFormPage), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'لینک کلاس آنلاین'),
        findsNothing,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'نام کلاس'),
        'Test room',
      );
      final save = find.widgetWithText(FilledButton, 'ذخیره تغییرات');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(api.writes, 1);
      expect(find.byType(PanelFormPage), findsOneWidget);
      expect(find.text('Test room'), findsOneWidget);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(api.writes, 2);
      expect(find.byType(PanelFormPage), findsNothing);
      expect(api.payload?['organizationUserId'], 10);
      expect(api.payload?['name'], 'Test room');
      expect(api.payload?.containsKey('onlineUrl'), isFalse);
      expect(api.payload?.containsKey('id'), isFalse);
      expect(tester.takeException(), isNull);
      api.dispose();
    },
  );
}
