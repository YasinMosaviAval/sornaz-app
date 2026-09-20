import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/components/expanding_search_bar.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'toolbar chrome reverses $direction without reversing page content',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(direction == TextDirection.rtl ? 'fa' : 'en'),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                drawer: const Drawer(),
                appBar: HomeTopBar(
                  leadingWidget: const Icon(
                    Icons.person,
                    key: ValueKey('avatar'),
                  ),
                  onSearch: (_) {},
                  hint: 'Search',
                ),
                body: const Text('Page body', key: ValueKey('body')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final avatar = tester
            .getCenter(find.byKey(const ValueKey('avatar')))
            .dx;
        final menu = tester.getCenter(find.byIcon(Icons.menu)).dx;
        expect(avatar < menu, direction == TextDirection.rtl);
        expect(
          Directionality.of(tester.element(find.byKey(const ValueKey('body')))),
          direction,
        );
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(direction == TextDirection.rtl ? 'fa' : 'en'),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                appBar: ExpandingSearchBar(
                  title: const Text('Files'),
                  onChanged: (_) {},
                  onSettings: () {},
                ),
                body: const Text('Page body'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.text('Files')).dx <
              tester.getCenter(find.byIcon(Icons.settings)).dx,
          direction == TextDirection.ltr,
        );
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
