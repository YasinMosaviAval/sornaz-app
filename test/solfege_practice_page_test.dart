import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sornaz/screens/Home/ui/pages/solfege_practice_page.dart';

void main() {
  testWidgets('solfege practice shows all six requested sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fa'),
        supportedLocales: [Locale('fa'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SolfegePracticePage(),
      ),
    );
    for (final title in [
      'گام شناسی',
      'آکورد شناسی',
      'تشخیص فرکانس',
      'تشخیص فاصله',
      'تشخیص آکورد',
      'تشخیص هارمونی',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });
}
