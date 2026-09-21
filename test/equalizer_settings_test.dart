import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/equalizer_presets.dart';
import 'package:sornaz/screens/Players/services/equalizer_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('23 immutable workbook presets contain both band modes', () {
    expect(equalizerPresets.length, 23);
    for (final values in equalizerPresets.values) {
      expect(values[0].length, 5);
      expect(values[1].length, 10);
      expect(values.expand((v) => v).every((v) => v >= -15 && v <= 15), isTrue);
    }
    expect(equalizerPresets['Rock']![0], [5, 3, -1, 3, 5]);
    expect(equalizerPresets['R&B']![1], [2, 6, 4, 0, -2, -1, 2, 2, 1, 3]);
  });
  test(
    'editing presets selects Custom, preserves originals and restores both modes',
    () async {
      final applied = <Map<String, Object>>[];
      final eq = EqualizerSettings(
        applyOverride: (state) async => applied.add(state),
      );
      await eq.load();
      await eq.select('Rock');
      await eq.setGain(1, -7.5);
      expect(eq.selected, 'Custom');
      expect(eq.gains, [5, -7.5, -1, 3, 5]);
      expect(equalizerPresets['Rock']![0], [5, 3, -1, 3, 5]);
      await eq.select('Pop');
      await eq.select('Custom');
      expect(eq.gains[1], -7.5);
      await eq.setBands(10);
      await eq.select('Dance');
      await eq.setGain(9, 15);
      await eq.setEnabled(false);
      final restored = EqualizerSettings(applyOverride: (_) async {});
      await restored.load();
      expect(restored.enabled, isFalse);
      expect(restored.bands, 10);
      expect(restored.selected, 'Custom');
      expect(restored.gains.last, 15);
      await restored.setBands(5);
      expect(restored.gains, [5, -7.5, -1, 3, 5]);
      expect(applied.last['frequencies'], EqualizerSettings.frequencies10);
      expect(applied.last['enabled'], false);
      await restored.reset();
      expect(restored.gains, List.filled(5, 0));
      expect(restored.custom[10]!.last, 15);
      eq.dispose();
      restored.dispose();
    },
  );
  test(
    'rapid changes persist in order and failed native apply can recover',
    () async {
      var fail = true;
      final eq = EqualizerSettings(
        applyOverride: (_) async {
          if (fail) throw StateError('unavailable');
        },
      );
      await eq.load();
      await eq.select('Rock');
      expect(eq.error, isNotNull);
      fail = false;
      final changes = [
        for (var i = 0; i < 10; i++) eq.setGain(0, i.toDouble()),
      ];
      await Future.wait(changes);
      expect(eq.error, isNull);
      final restored = EqualizerSettings(applyOverride: (_) async {});
      await restored.load();
      expect(restored.gains.first, 9);
      eq.dispose();
      restored.dispose();
    },
  );
}
