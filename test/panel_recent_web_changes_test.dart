import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form_contract.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  testWidgets('batch range uses server hours and its time zone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PanelFormResult? saved;
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Open'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PanelFormPage(
                  title: 'Batch',
                  dialog: true,
                  fields: const [
                    {'key': 'rangeStart', 'type': 'time'},
                    {'key': 'rangeEnd', 'type': 'time'},
                    {'key': 'durationMinutes', 'type': 'number'},
                  ],
                  data: const {},
                  initial: const {
                    'rangeStart': '10:00',
                    'rangeEnd': '18:00',
                    'durationMinutes': 30,
                  },
                  loadBatchTimes: (_) async => {
                    'timezoneId': 7,
                    'times': List.generate(96, (i) {
                      final minute = 600 + i * 5;
                      return '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
                    }),
                  },
                  onSubmit: (result) async {
                    saved = result;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final start = tester.widget<PanelField>(
      find.byWidgetPredicate(
        (widget) => widget is PanelField && widget.field['key'] == 'rangeStart',
      ),
    );
    expect(start.field['type'], 'select');
    expect(start.field['options'].containsKey('09:00'), isFalse);
    expect(find.text('16 ترم مستقل ایجاد می‌شود.'), findsOneWidget);
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();
    expect(saved!.values['timezoneId'], 7);
    expect(tester.takeException(), isNull);
  });
  testWidgets('changing the venue retains an eligible academy teacher', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PanelFormResult? saved;
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Open'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PanelFormPage(
                  title: 'Term',
                  dialog: true,
                  fields: const [
                    {
                      'key': 'courseId',
                      'type': 'select',
                      'options': {'source': 'courses'},
                    },
                    {
                      'key': 'classroomId',
                      'type': 'select',
                      'options': {'source': 'classrooms'},
                    },
                    {
                      'key': 'teachers',
                      'type': 'multi',
                      'options': {
                        'source': 'members',
                        'termPeople': true,
                        'where': {'type': 'teacher'},
                      },
                      'dependsOn': ['classroomId'],
                    },
                  ],
                  data: const {
                    'courses': [
                      {
                        'id': 1,
                        'name': 'Course',
                        'organizationKind': 'academy',
                        'organizationId': 100,
                      },
                    ],
                    'classrooms': [
                      {'id': 1, 'name': 'Shared', 'branchId': 0},
                      {'id': 2, 'name': 'Branch', 'branchId': 7},
                    ],
                    'members': [
                      {
                        'id': 1,
                        'name': 'Teacher',
                        'type': 'teacher',
                        'academyId': 100,
                        'branchId': 0,
                      },
                    ],
                  },
                  initial: const {
                    'courseId': 1,
                    'classroomId': 1,
                    'teachers': [1],
                  },
                  onSubmit: (result) async {
                    saved = result;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    tester
        .widget<PanelField>(
          find.byWidgetPredicate(
            (widget) =>
                widget is PanelField && widget.field['key'] == 'classroomId',
          ),
        )
        .changed(2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();
    expect(saved!.values['teachers'], [1]);
    expect(tester.takeException(), isNull);
  });
  test(
    'batch preview counts independent slots and rejects fractional sessions',
    () {
      expect(
        panelBatchTermCount({
          'rangeStart': '10:00',
          'rangeEnd': '18:00',
          'durationMinutes': 30,
        }),
        16,
      );
      expect(
        panelBatchTermCount({
          'rangeStart': '10:00',
          'rangeEnd': '10:45',
          'durationMinutes': 30,
        }),
        isNull,
      );
      expect(
        panelBatchTermCount({
          'rangeStart': '18:00',
          'rangeEnd': '10:00',
          'durationMinutes': 30,
        }),
        isNull,
      );
      expect(
        panelBatchTermCount({
          'rangeStart': '10:00',
          'rangeEnd': '18:00',
          'durationMinutes': 0,
        }),
        isNull,
      );
    },
  );
  test('student assignment uses the existing parent and address payload', () {
    final payload = panelDialogPayload('terms', 'assign-student', {
      'name': 'Student',
      'parentName': 'Parent',
      'addresses': [
        {'address': 'Street'},
      ],
    }, {});
    expect(payload['type'], 'student');
    expect(payload['parent']['name'], 'Parent');
    expect(payload['addresses'], [
      {'address': 'Street'},
    ]);
  });
  testWidgets(
    'requesting a staff code retains the form until final submission',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var codes = 0, saves = 0;
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PanelFormPage(
                    title: 'Staff',
                    dialog: true,
                    fields: const [],
                    data: const {},
                    initial: const {'type': 'manager'},
                    onRequestCode: (result) async {
                      codes++;
                    },
                    onSubmit: (result) async {
                      saves++;
                    },
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ارسال کد تأیید'));
      await tester.pumpAndSettle();
      expect(codes, 1);
      expect(saves, 0);
      expect(find.byType(PanelFormPage), findsOneWidget);
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(find.byType(PanelFormPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test('academy teachers remain available before a room is selected', () {
    final options = panelSelectOptions(
      {
        'options': {
          'source': 'members',
          'termPeople': true,
          'where': {'type': 'teacher'},
        },
      },
      {
        '_selected': {
          'courseId': {'organizationId': 100, 'organizationKind': 'academy'},
        },
        'members': [
          {
            'id': 1,
            'name': 'Academy',
            'academyId': 100,
            'branchId': 0,
            'type': 'teacher',
          },
          {
            'id': 2,
            'name': 'Foreign',
            'academyId': 200,
            'branchId': 0,
            'type': 'teacher',
          },
        ],
      },
    );
    expect(options.keys, ['1']);
  });

  test(
    'branch course teachers follow course ownership rather than the venue',
    () {
      final options = panelSelectOptions(
        {
          'options': {
            'source': 'members',
            'termPeople': true,
            'where': {'type': 'teacher'},
          },
        },
        {
          '_selected': {
            'courseId': {'organizationKind': 'branch', 'branchId': 7},
            'classroomId': {'branchId': 8},
          },
          'members': [
            {
              'id': 1,
              'name': 'Course teacher',
              'branchId': 7,
              'type': 'teacher',
            },
            {
              'id': 2,
              'name': 'Venue teacher',
              'branchId': 8,
              'type': 'teacher',
            },
          ],
        },
      );
      expect(options.keys, ['1']);
    },
  );

  test('batch payload preserves its retry key and optional classroom', () {
    final values = {
      'requestKey': 'abc',
      'teachers': [1],
      'durationMinutes': 30,
      'rangeStart': '10:00',
      'rangeEnd': '18:00',
    };
    expect(panelDialogPayload('terms', 'batch', values, {}), values);
  });

  test(
    'staff verification retains only the session cookie between requests',
    () async {
      var count = 0;
      final api = PanelApi(
        'test',
        client: MockClient((request) async {
          if (count++ == 0) {
            expect(request.headers['cookie'], isNull);
            return http.Response(
              '{"success":true,"data":{}}',
              200,
              headers: {
                'set-cookie': 'PHPSESSID=fixture; Path=/; HttpOnly; Secure',
              },
            );
          }
          expect(request.headers['cookie'], 'PHPSESSID=fixture');
          expect(request.headers['authorization'], 'Bearer test');
          return http.Response('{"success":true,"data":{}}', 200);
        }),
      );
      addTearDown(api.dispose);
      await api.act('members', 'registration-otp');
      await api.act('members', 'create');
    },
  );
}
