import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_national_holiday_settings.dart';
import 'package:sornaz/screens/Site/panel_organization_filter.dart';
import 'package:sornaz/screens/Site/panel_filter_contract.dart';
import 'package:sornaz/screens/Site/panel_form_contract.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;
import 'panel_dialog_contract_test.dart' as contracts;

class LiveOrganizations extends PanelApi {
  LiveOrganizations() : super('test');
  Json data = {'organizations': <Json>[]};
  @override
  Future<Json> live(String path, [Map<String, String>? query]) async => data;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('actual student schema only offers open terms when creating', () {
    final field = contracts.field('students', 'termId');
    final data = <String, dynamic>{
      'operation': 'create',
      'terms': [
        {'id': 1, 'name': 'Open', 'status': 'open', 'organizationUserId': 10},
        {
          'id': 2,
          'name': 'Ongoing',
          'status': 'ongoing',
          'organizationUserId': 10,
        },
        {
          'id': 3,
          'name': 'Pending',
          'status': 'pending',
          'organizationUserId': 10,
        },
      ],
    };
    expect(
      panelSelectOptions(
        field,
        panelFormContext([field], {'organizationUserId': 10}, data),
      ).keys,
      ['1'],
    );
    data['operation'] = 'update';
    expect(
      panelSelectOptions(
        field,
        panelFormContext(
          [field],
          {'organizationUserId': 10, 'termId': 2},
          data,
        ),
      ).containsKey('2'),
      isTrue,
    );
  });
  test(
    'open term teacher completion submits no session or invoice rebuild',
    () {
      final payload = panelDialogPayload(
        'terms',
        'update',
        {
          'name': 'Group',
          'teachers': [1, 2],
          'status': 'open',
          'classroomId': 1001,
          'cost': 99,
          'sessions': [],
        },
        {
          'record': {'status_code': 'open'},
        },
      );
      expect(payload, {
        'metadataOnly': true,
        'name': 'Group',
        'summary': '',
        'description': '',
        'teachers': [
          {'id': 1},
          {'id': 2},
        ],
      });
      expect(
        panelDialogPayload(
          'terms',
          'update',
          {
            'name': 'Group',
            'teachers': [1, 2],
          },
          {
            'record': {'status_code': 'ongoing'},
          },
        ).containsKey('teachers'),
        isFalse,
      );
    },
  );
  test(
    'open term edit completes teachers without requiring new session dates',
    () {
      final fields = panelTermEditFields(
        panelTermDialogFields(contracts.fields('terms')),
        {'status_code': 'open'},
      );
      final values = <String, dynamic>{
        'name': 'Group',
        'courseId': 500,
        'classroomId': 1001,
        'teachers': [1],
      };
      final data = <String, dynamic>{
        'operation': 'update',
        'courses': [
          {
            'id': 500,
            'organizationKind': 'academy',
            'organizationId': 100,
            'lessonId': 5,
            'teacher_capacity': 2,
          },
        ],
        'classrooms': [
          {'id': 1001, 'academyId': 100, 'branchId': 0},
        ],
        'members': [
          {
            'id': 1,
            'name': 'Teacher',
            'type': 'teacher',
            'academyId': 100,
            'branchId': 0,
            'lessonId': 5,
          },
        ],
      };
      final context = panelFormContext(fields, values, data);
      expect(
        fields
            .where((field) => panelFieldVisible(field, context))
            .map((field) => field['key'])
            .toSet(),
        {'name', 'summary', 'description', 'teachers'},
      );
      expect(panelInvalidField(fields, values, data), isNull);
      expect(
        panelTermEditFields(contracts.fields('terms'), {
          'status_code': 'ongoing',
        }).any((field) => field['key'] == 'teachers'),
        isFalse,
      );
    },
  );
  test('cached and saved panel roots restore branch filter scope', () async {
    var reads = 0;
    final api = PanelApi(
      'branch-scope-fixture',
      client: MockClient((request) async {
        reads++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'branchContext': true},
          }),
          200,
        );
      }),
    );
    await api.get('');
    expect(api.branchContext, isTrue);
    api.branchContext = false;
    await api.get('');
    expect(api.branchContext, isTrue);
    expect(reads, 1);
    api.branchContext = false;
    await api.saved('');
    expect(api.branchContext, isTrue);
    api.dispose();
  });
  test('student classroom is submitted without requiring session dates', () {
    final payload = panelDialogPayload('students', 'create', {
      'studentSchedule': {'classroomId': 1001, 'firstDate': ''},
    }, {});
    expect(payload['studentSchedule']['classroomId'], 1001);
    expect(payload['studentSchedule']['firstDate'], '');
    expect(
      panelDialogPayload('students', 'create', {
        'studentSchedule': {'firstDate': ''},
      }, {}).containsKey('studentSchedule'),
      isFalse,
    );
  });
  test('branch accounts and branch employees have no organization filters', () {
    for (final scope in [
      {'branchContext': true},
      {
        'permissions': {'isBranchContext': true},
      },
      {
        'staff_catalog': {'organization_selection': 'fixed'},
      },
    ]) {
      final data = <String, dynamic>{
        ...scope,
        'branches': [
          {'id': 1, 'name': 'Branch'},
        ],
      };
      expect(panelOrganizationOptions(data, [], fa: true), isEmpty);
      expect(
        panelWebFilters(
          {
            'key': 'example',
            'filters': [
              {'key': 'branch', 'type': 'select'},
              {'key': 'status', 'type': 'select'},
            ],
          },
          data,
          [],
        ).map((field) => field['key']),
        ['status'],
      );
    }
  });

  testWidgets('open form updates organizations and preserves entered data', (
    tester,
  ) async {
    var organizations = <Json>[
      {'user_id': 10, 'name': 'Original'},
    ];
    Json? submitted;
    await tester.pumpWidget(
      fixture.host(
        PanelFormPage(
          dialog: true,
          title: 'Edit',
          fields: const [
            {'key': 'name', 'label': 'Name'},
            {
              'key': 'organizationUserId',
              'label': 'Organization',
              'type': 'select',
              'options': {'source': 'organizations', 'id': 'user_id'},
            },
          ],
          initial: const {'organizationUserId': 10},
          data: {'organizations': organizations},
          loadOptions: () async => {'organizations': organizations},
          onSubmit: (result) async => submitted = result.values,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Keep this input',
    );
    organizations = [
      {'user_id': 10, 'name': 'Renamed'},
      {'user_id': 11, 'name': 'New branch'},
    ];
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Keep this input'), findsOneWidget);
    expect(find.text('Renamed'), findsWidgets);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('New branch'), findsWidgets);
    await tester.tap(find.text('New branch').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(submitted?['name'], 'Keep this input');
    expect('${submitted?['organizationUserId']}', '11');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'holiday settings update branch rows without losing unsaved choices',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final api = LiveOrganizations();
      api.data = {
        'organizations': [
          {
            'academyId': 100,
            'branchId': 0,
            'name': 'Academy',
            'allowClasses': false,
          },
        ],
      };
      await tester.pumpWidget(
        fixture.host(Scaffold(body: PanelNationalHolidaySettings(api: api))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Academy'));
      api.data = {
        'organizations': [
          {
            'academyId': 100,
            'branchId': 0,
            'name': 'Academy renamed',
            'allowClasses': false,
          },
          {
            'academyId': 100,
            'branchId': 101,
            'name': 'New branch',
            'allowClasses': false,
          },
        ],
      };
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('New branch'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Academy renamed'),
            )
            .value,
        isTrue,
      );
      api.data = {
        'organizations': [api.data['organizations'].first],
      };
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('New branch'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
