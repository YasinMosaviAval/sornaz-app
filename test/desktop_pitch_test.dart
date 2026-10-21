import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Tuner/audio/desktop_pitch_input.dart';

void main() {
  test('Windows microphone detector preserves low, concert and high notes', () {
    for (final frequency in [
      27.5,
      32.7,
      55.0,
      110.0,
      440.0,
      880.0,
      1760.0,
      4186.0,
    ]) {
      final samples = List.generate(
        4096,
        (i) => .3 * sin(2 * pi * frequency * i / 22050),
      );
      final detected = detectDesktopPitch(samples, 22050);
      expect((1200 * log(detected / frequency) / ln2).abs(), lessThan(12));
    }
  });
  test('Windows detector rejects silence and unpitched noise', () {
    expect(detectDesktopPitch(List.filled(2048, 0), 11025), -1);
    final random = Random(42);
    expect(
      detectDesktopPitch(
        List.generate(2048, (_) => random.nextDouble() - .5),
        11025,
      ),
      -1,
    );
  });
}
