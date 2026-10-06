// Deterministic, development-only signal controls. No truth enters DSP.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const rate = 44100;
const tau = 2 * math.pi;
void main() {
  final dir = Directory('.raw_voicing_tmp/new_synthetic')
    ..createSync(recursive: true);
  final rows = <String>[
    'case_id,family,expected_hz,amplitude,seed,window_start,window_end',
  ];
  var state = 1917;
  double random() {
    state = (1664525 * state + 1013904223) & 0xffffffff;
    return (state / 0xffffffff) * 2 - 1;
  }

  void make(
    String id,
    String family,
    double expected,
    double amplitude,
    double Function(double, int) signal,
  ) {
    final bytes = ByteData(rate * 4);
    for (var i = 0; i < rate; i++) {
      bytes.setFloat32(i * 4, signal(i / rate, i), Endian.little);
    }
    File('${dir.path}/$id.f32le').writeAsBytesSync(bytes.buffer.asUint8List());
    rows.add('$id,$family,$expected,$amplitude,1917,0.25,0.85');
  }

  make('Q001', 'digital_silence', 0, 0, (_, __) => 0);
  make('Q002', 'low_seeded_white_noise', 0, .002, (_, __) => .002 * random());
  make(
    'Q003',
    'stronger_seeded_white_noise',
    0,
    .012,
    (_, __) => .012 * random(),
  );
  make(
    'Q004',
    'low_frequency_noise',
    0,
    .010,
    (t, _) => .006 * math.sin(tau * 37 * t) + .004 * random(),
  );
  make(
    'Q005',
    'room_like_periodic_background',
    0,
    .008,
    (t, _) => .008 * math.sin(tau * 147 * t) + .001 * random(),
  );
  make('Q006', 'impulse', 0, .8, (_, i) => i == rate ~/ 2 ? .8 : 0);
  make(
    'Q007',
    'weak_legitimate_tone',
    329.628,
    .006,
    (t, _) => .006 * math.sin(tau * 329.628 * t),
  );
  make(
    'Q008',
    'quiet_legitimate_tone',
    329.628,
    .014,
    (t, _) => .014 * math.sin(tau * 329.628 * t),
  );
  make(
    'Q009',
    'normal_legitimate_tone',
    329.628,
    .12,
    (t, _) => .12 * math.sin(tau * 329.628 * t),
  );
  make(
    'Q010',
    'decaying_tone',
    329.628,
    .12,
    (t, _) => .12 * math.exp(-5 * t) * math.sin(tau * 329.628 * t),
  );
  make(
    'Q011',
    'harmonic_rich_decay',
    329.628,
    .12,
    (t, _) =>
        .12 *
        math.exp(-5 * t) *
        (math.sin(tau * 329.628 * t) + .7 * math.sin(tau * 659.256 * t)),
  );
  make(
    'Q012',
    'decay_plus_noise',
    329.628,
    .12,
    (t, _) =>
        .12 * math.exp(-6 * t) * math.sin(tau * 329.628 * t) + .002 * random(),
  );
  make(
    'Q013',
    'decay_plus_subharmonic',
    329.628,
    .12,
    (t, _) =>
        .12 * math.exp(-6 * t) * math.sin(tau * 329.628 * t) +
        .008 * math.sin(tau * 164.814 * t),
  );
  make(
    'Q014',
    'true_lower_octave',
    164.814,
    .04,
    (t, _) =>
        .04 * math.sin(tau * 164.814 * t) + .02 * math.sin(tau * 329.628 * t),
  );
  make(
    'Q015',
    'true_upper_octave',
    659.255,
    .04,
    (t, _) =>
        .04 * math.sin(tau * 659.255 * t) + .02 * math.sin(tau * 1318.51 * t),
  );
  for (final (id, gain) in [('Q016', .02), ('Q017', .08), ('Q018', .16)]) {
    make(
      id,
      'f_over_2_interference',
      329.628,
      gain,
      (t, _) =>
          .10 * math.sin(tau * 329.628 * t) +
          gain * math.sin(tau * 164.814 * t),
    );
  }
  File(
    'raw_voicing_synthetic_manifest.csv',
  ).writeAsStringSync('${rows.join('\n')}\n');
}
