import 'dart:math' as math;

/// Mirrors the server's observation policy; shared fixtures verify parity.
class PracticeNotationGrade {
  static Map<String, dynamic> evaluate(
    Map reference,
    Map recording,
    String assessment,
  ) {
    final frames = (recording['frames'] as List).cast<List>();
    final notes = (reference['notes'] as List).cast<List>();
    final peak = frames.fold<num>(0, (v, f) => math.max(v, f[2] as num));
    final threshold = math.max(8, peak * .12);
    final onsets = <num>[];
    num previousEnergy = 0, previousPitch = 0;
    for (final frame in frames) {
      final at = frame[0] as num,
          hz = frame[1] as num,
          energy = frame[2] as num;
      final pitch = hz > 0
          ? 69 + 12 * math.log((hz / 100) / 440) / math.ln2
          : 0;
      if (energy >= threshold &&
          (previousEnergy < threshold ||
              energy > previousEnergy * 1.6 &&
                  energy - previousEnergy > peak * .12 ||
              pitch > 0 &&
                  previousPitch > 0 &&
                  (pitch - previousPitch).abs() > .45) &&
          (onsets.isEmpty || at - onsets.last >= 100)) {
        onsets.add(at);
      }
      previousEnergy = energy;
      previousPitch = pitch;
    }
    if (onsets.isEmpty || peak < 8) {
      return {'passed': false, 'pitch': 0, 'rhythm': 0};
    }
    final offset = onsets.first - (notes.first[0] as num);
    final tolerance = math.max(100, (reference['beatMs'] as num) * .25);
    var matched = 0, next = 0, pitchGood = 0, durationGood = 0;
    for (final note in notes) {
      final start = note[0] as num,
          end = note[1] as num,
          expected = note[2] as num;
      while (next < onsets.length &&
          onsets[next] - offset < start - tolerance) {
        next++;
      }
      if (next < onsets.length &&
          (onsets[next] - offset - start).abs() <= tolerance) {
        matched++;
        next++;
      }
      final trim = math.min(80, (end - start) * .2);
      var samples = 0, voiced = 0, correct = 0;
      for (final frame in frames) {
        final at = frame[0] as num,
            hz = frame[1] as num,
            energy = frame[2] as num;
        if (at - offset < start + trim || at - offset > end - trim) continue;
        samples++;
        if (energy >= threshold) {
          voiced++;
          if (hz > 0 &&
              ((69 + 12 * math.log((hz / 100) / 440) / math.ln2) - expected)
                          .abs() *
                      100 <=
                  (reference['pitchTolerance'] as num)) {
            correct++;
          }
        }
      }
      final covered =
          samples >= math.max(1, ((end - start - 2 * trim) / 50 * .7).floor());
      if (covered && voiced / samples >= .65) durationGood++;
      if (covered && correct / samples >= .7) pitchGood++;
    }
    var restSamples = 0, restQuiet = 0;
    for (final frame in frames) {
      final time = (frame[0] as num) - offset;
      if (time < 0 || time > (reference['durationMs'] as num)) continue;
      if (notes.any(
        (n) =>
            time >= (n[0] as num) - tolerance &&
            time <= (n[1] as num) + tolerance,
      )) {
        continue;
      }
      restSamples++;
      if ((frame[2] as num) < threshold) restQuiet++;
    }
    final count = notes.length;
    final rhythm = (100 * math.min(matched, durationGood) / count).round();
    final pitch = (100 * pitchGood / count).round();
    return {
      'passed':
          rhythm >= 80 &&
          onsets.length <= count + math.max(1, (count * .15).floor()) &&
          (restSamples == 0 || restQuiet / restSamples >= .7) &&
          (assessment == 'rhythm' || pitch >= 80),
      'pitch': pitch,
      'rhythm': rhythm,
    };
  }
}
