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

class LiveOrganizations extends PanelApi {
  LiveOrganizations() : super('test');
  Json data = {'organizations': <Json>[]};
  @override
  Future<Json> live(String path, [Map<String, String>? query]) async => data;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
