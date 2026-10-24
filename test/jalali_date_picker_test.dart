import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/jalali_date_picker.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const delegate = JalaliCalendarDelegate();
  test('Jalali dates retain day 31, leap days and chronology', () {
    final end = delegate.getDay(1405, 2, 31);
    expect([end.year, end.month, end.day], [1405, 2, 31]);
    final next = delegate.addDaysToDate(end, 1);
    expect([next.year, next.month, next.day], [1405, 3, 1]);
    expect(next.isAfter(end), isTrue);
    expect(delegate.getDaysInMonth(1403, 12), 30);
    expect(delegate.getDaysInMonth(1404, 12), 29);
    final actual = JalaliCalendarDelegate.decode(end);
    expect(JalaliCalendarDelegate.encode(actual).day, 31);
  });
  testWidgets('Material picker displays Jalali and returns Gregorian date', (
    tester,
  ) async {
    final date = JalaliCalendarDelegate.decode(delegate.getDay(1405, 2, 31));
    DateTime? selected;
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showSornazDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2200),
                );
              },
              child: const Text('انتخاب'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('انتخاب'));
    await tester.pumpAndSettle();
    expect(find.textContaining('اردیبهشت'), findsWidgets);
    final context = tester.element(find.byType(DatePickerDialog));
    await tester.tap(
      find.text(MaterialLocalizations.of(context).okButtonLabel),
    );
    await tester.pumpAndSettle();
    expect(selected, date);
    expect(tester.takeException(), isNull);
  });
}
