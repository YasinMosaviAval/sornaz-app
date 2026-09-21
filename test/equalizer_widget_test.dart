import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/equalizer_settings.dart';
import 'package:sornaz/screens/Players/ui/pages/equalizer.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 430.0]) {
    testWidgets('presets wrap and all ten vertical bands fit at $width', (
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
      await tester.ensureVisible(find.text('10 Bands'));
      await tester.tap(find.text('10 Bands'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(10));
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
