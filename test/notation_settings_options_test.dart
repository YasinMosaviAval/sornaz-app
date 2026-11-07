import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Notation/notation_settings.dart';
import 'package:sornaz/helpers/app_appearance.dart';

void main() {
  testWidgets('shared checkbox height is 24 and still accepts taps', (
    tester,
  ) async {
    var checked = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(checkboxTheme: appCheckboxTheme),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Checkbox(
              value: checked,
              onChanged: (value) => setState(() => checked = value!),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(Checkbox)).height, 24);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(checked, isTrue);
  });
  testWidgets('notation choices use full rows and persist selected values', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fa'),
        supportedLocales: [Locale('fa'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: NotationSettingsPage(),
      ),
    );
    await tester.pump();
    expect(find.text('آزمایش تحلیل اجرا'), findsNothing);
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.text('نمایش ربع‌پرده‌ها'), findsNothing);
    final helpTitle = find.text('نمایش راهنمای عملکرد');
    expect(tester.widget<Text>(helpTitle).style!.fontSize, 12);
    final subtitle = tester.widget<Text>(find.text('نگه داشتن انگشت روی دکمه'));
    expect(subtitle.style!.color, Colors.grey.shade600);
    await tester.tap(helpTitle);
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool('notation.showHelp'),
      false,
    );

    await tester.tap(find.text('حالت انتخاب کشش نت'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حالت دوم'));
    await tester.pumpAndSettle();
    expect(find.text('حالت دوم'), findsOneWidget);

    await tester.tap(find.text('نمایش نت‌ها روی کلیدهای پیانو'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نت‌های گام'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('notation.durationMode'), 2);
    expect(prefs.getInt('notation.pianoLabelMode'), 2);
  });
}
