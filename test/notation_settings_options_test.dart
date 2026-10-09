import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Notation/notation_settings.dart';

void main() {
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
