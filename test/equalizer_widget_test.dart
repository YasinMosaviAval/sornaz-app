import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/equalizer_settings.dart';
import 'package:sornaz/screens/Players/ui/pages/equalizer.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets('five bands fit and ten bands preserve spacing at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final eq = EqualizerSettings(applyOverride: (_) async {});
      await eq.load();
      await tester.pumpWidget(
        fixture.host(Scaffold(body: EqualizerTab(settings: eq))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNWidgets(24));
      expect(find.byType(Slider), findsNWidgets(5));
      final band0 = find.byKey(const ValueKey('eq-band-0'));
      final band1 = find.byKey(const ValueKey('eq-band-1'));
      final fiveSpacing =
          tester.getCenter(band1).dx - tester.getCenter(band0).dx;
      final horizontal = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      final scrollable = find.descendant(
        of: horizontal,
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        0,
      );
      expect(find.text('5 فیلتر'), findsOneWidget);
      await tester.ensureVisible(find.text('10 فیلتر'));
      await tester.tap(find.text('10 فیلتر'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(10));
      expect(
        tester.getCenter(band1).dx - tester.getCenter(band0).dx,
        closeTo(fiveSpacing, .01),
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        greaterThan(0),
      );
      for (final slider in tester.widgetList<Slider>(find.byType(Slider))) {
        expect(slider.min, -15);
        expect(slider.max, 15);
      }
      for (final chip in find.byType(ChoiceChip).evaluate()) {
        final rect = tester.getRect(find.byWidget(chip.widget));
        expect(rect.left, greaterThanOrEqualTo(16));
        expect(rect.right, lessThanOrEqualTo(width - 16));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      eq.dispose();
    });
  }
}
