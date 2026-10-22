import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('assignment retains fields and submits only at step four', (
    tester,
  ) async {
    PanelFormResult? saved;
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PanelFormPage(
                  title: 'Assignment',
                  dialog: true,
                  termAssignment: true,
                  declaredOnly: true,
                  data: const {},
                  fields: const [
                    {
                      'key': 'name',
                      'label': 'نام',
                      'type': 'text',
                      'required': true,
                    },
                    {'key': 'addresses', 'label': 'نشانی', 'type': 'text'},
                    {
                      'key': 'studentSchedule',
                      'label': 'زمان‌بندی',
                      'type': 'object',
                      'options': <Map<String, dynamic>>[],
                    },
                    {
                      'key': 'classroomId',
                      'label': 'کلاس',
                      'type': 'select',
                      'options': {'4': 'کلاس اول'},
                    },
                  ],
                  onSubmit: (result) async {
                    saved = result;
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
    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب هنرجو'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Test student');
    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(find.text('آدرس هنرجو'), findsOneWidget);
    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(find.text('تاریخ جلسات ترم'), findsOneWidget);
    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(find.text('کلاس برگزاری'), findsOneWidget);
    expect(saved, isNull);
    await tester.tap(find.text('قبلی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();
    expect(saved?.values['name'], 'Test student');
    expect(tester.takeException(), isNull);
  });
}
