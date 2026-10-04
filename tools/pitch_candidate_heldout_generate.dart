// Generated only after diagnostic strategy parameters were frozen.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const rate = 44100;
const pi2 = 2 * math.pi;
final root = Directory('.pitch_candidate_tmp/synthetic_heldout');

void write(
  String id,
  String kind,
  double expected,
  List<double> frequencies,
  List<double> gains, {
  bool decay = true,
}) {
  final bytes = ByteData(rate * 4);
  for (var i = 0; i < rate; i++) {
    final t = i / rate;
    final envelope = decay ? math.exp(-1.5 * t) : 1.0;
    var value = 0.0;
    for (var j = 0; j < frequencies.length; j++) {
      value += gains[j] * math.sin(pi2 * frequencies[j] * t);
    }
    bytes.setFloat32(i * 4, value * envelope, Endian.little);
  }
  File('${root.path}/$id.f32le').writeAsBytesSync(bytes.buffer.asUint8List());
  rows.add('$id,$kind,$expected,0.25,0.85');
}

final rows = <String>['caseId,kind,expectedHz,startSeconds,endSeconds'];
void main() {
  root.createSync(recursive: true);
  var index = 0;
  String next() => 'H${(++index).toString().padLeft(3, '0')}';
  for (final frequency in [
    164.814,
    174.614,
    220.0,
    329.628,
    349.228,
    440.0,
    659.255,
    698.456,
    880.0,
  ]) {
    write(
      next(),
      'heldout_harmonic',
      frequency,
      [frequency, frequency * 2.002, frequency * 3.006],
      [.26, .20, .10],
    );
  }
  for (final pair in [
    [261.626, 137.0, .12],
    [392.0, 173.0, .15],
    [523.251, 181.0, .13],
    [783.991, 211.0, .12],
  ]) {
    write(
      next(),
      'heldout_mixture',
      pair[0],
      [pair[0], pair[0] * 2.003, pair[1]],
      [.26, .11, pair[2]],
    );
  }
  // Separate lower notes with strong H2 make "always choose upper octave"
  // unsafe even though their spectrum can peak above the fundamental.
  for (final frequency in [146.832, 196.0, 246.942]) {
    write(
      next(),
      'heldout_lower_h2',
      frequency,
      [frequency, frequency * 2, frequency * 3],
      [.12, .30, .16],
    );
  }
  File(
    'pitch_candidate_heldout_synthetic_manifest.csv',
  ).writeAsStringSync('${rows.join('\n')}\n');
}
