import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_logo.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Social/user_panel.dart';

void main() {
  for (final locale in ['fa', 'en']) {
    testWidgets('guest stage menu has a 24dp edge inset in $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppData(),
          child: MaterialApp(
            locale: Locale(locale),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(drawer: Drawer(), appBar: GuestStageBar()),
          ),
        ),
      );
      final menu = tester.getRect(find.byIcon(Icons.menu));
      final guestLogo = tester.getRect(find.byType(AppLogo));
      expect(locale == 'fa' ? 800 - menu.right : menu.left, closeTo(24, 0.1));
      expect(guestLogo.size, const Size(40, 40));
      expect(find.text('صحنه'), findsNothing);
      expect(find.text('Stage'), findsNothing);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppData(),
          child: MaterialApp(
            locale: Locale(locale),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(drawer: Drawer(), appBar: HomeTopBar()),
          ),
        ),
      );
      expect(tester.getRect(find.byType(AppLogo)), guestLogo);
    });
  }
}
