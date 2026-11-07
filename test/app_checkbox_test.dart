import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/app_checkbox.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'shared checkbox and row stay compact and toggle once, dark=$dark',
      (tester) async {
        var value = false, calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, update) => Column(
                  children: [
                    AppCheckbox(
                      value: value,
                      onChanged: (next) => update(() {
                        value = next!;
                        calls++;
                      }),
                    ),
                    AppCheckboxTile(
                      title: const Text('Option'),
                      value: value,
                      onChanged: (next) => update(() {
                        value = next!;
                        calls++;
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(AppCheckbox)).height, 24);
        expect(tester.getSize(find.byType(AppCheckboxTile)).height, 28);
        await tester.tap(find.text('Option'));
        await tester.pumpAndSettle();
        expect(value, isTrue);
        expect(calls, 1);
        await tester.tap(find.byType(AppCheckbox));
        await tester.pumpAndSettle();
        expect(value, isFalse);
        expect(calls, 2);
      },
    );
  }
  testWidgets('disabled and multiline checkbox rows preserve content in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 180,
              child: AppCheckboxTile(
                value: true,
                onChanged: null,
                title: const Text(
                  'عنوان طولانی که در چند خط نمایش داده می‌شود',
                ),
                subtitle: const Text('توضیح انتخاب'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(AppCheckboxTile)).height,
      greaterThan(28),
    );
    await tester.tap(find.text('توضیح انتخاب'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    expect(tester.takeException(), isNull);
  });
}
