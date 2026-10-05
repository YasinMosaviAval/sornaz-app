// Test-only f/f2 and decay stress signals. Never treats polyphony as V1 truth.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'pitch_candidate_evaluate.dart' as prior;
import 'pitch_ambiguity_investigate.dart' as ambiguity;

const rate = 44100;
double med(Iterable<double> values) {
  final sorted = values.where((x) => x.isFinite).toList()..sort();
  return sorted.isEmpty ? double.nan : sorted[sorted.length ~/ 2];
}

String value(double x) => x.isFinite ? x.toStringAsFixed(5) : '';

void main() {
  final root = Directory('.targeted_audio_tmp/synthetic')
    ..createSync(recursive: true);
  final probe = File(
    '.targeted_audio_build/Release/music_analysis_pitch_candidate_probe.exe',
  );
  if (!probe.existsSync()) throw StateError('native probe missing');
  final raw = File('${root.path}/baseline.csv')
    ..writeAsStringSync(
      'caseId,sample,timestamp,pitchHz,confidence,rms,energy,peak,clipping,onsetStrength,onsetCandidate,isSilent,isPartial\n',
    );
  final ev = File('${root.path}/evidence.csv')
    ..writeAsStringSync(
      'caseId,sample,timestamp,lag,hz,cmnd,selected,spectralFundamental,spectralH2,spectralH3,spectralHalf,interpolatedLag\n',
    );
  final recipes = <String, (double, double, String, String)>{};
  var index = 0;
  for (final f in [329.628, 349.228]) {
    for (final profile in ['fundamental', 'H2rich']) {
      for (final low in [0.0, .03, .10, .30, .60, 1.0]) {
        final id = 'G${(++index).toString().padLeft(2, '0')}';
        recipes[id] = (f, low, profile, 'steady');
      }
    }
  }
  for (final mode in ['clean', 'harmonic', 'noise', 'weakLow']) {
    final id = 'G${(++index).toString().padLeft(2, '0')}';
    recipes[id] = (349.228, mode == 'weakLow' ? .10 : 0.0, 'fundamental', mode);
  }
  for (final entry in recipes.entries) {
    final id = entry.key;
    final (f, low, profile, mode) = entry.value;
    final bytes = ByteData(rate * 2 * 4);
    for (var i = 0; i < rate * 2; i++) {
      final t = i / rate;
      var y = 0.0;
      if (t >= .2) {
        final local = t - .2;
        final envelope = mode == 'steady'
            ? .28
            : .28 * math.exp(-3 * math.max(0, local - .65));
        final h2 = profile == 'H2rich' || mode == 'harmonic' ? .7 : .3;
        y =
            envelope *
            (math.sin(2 * math.pi * f * t) +
                h2 * math.sin(4 * math.pi * f * t) +
                .15 * math.sin(6 * math.pi * f * t) +
                low * math.sin(math.pi * f * t));
        if (mode == 'noise') {
          y +=
              .003 *
              math.sin(2 * math.pi * 7313 * t) *
              math.exp(-2 * math.max(0, local - .65));
        }
      }
      bytes.setFloat32(i * 4, y, Endian.little);
    }
    final file = File('${root.path}/$id.f32le')
      ..writeAsBytesSync(bytes.buffer.asUint8List());
    final result = Process.runSync(probe.absolute.path, [
      id,
      file.absolute.path,
      raw.absolute.path,
      ev.absolute.path,
    ]);
    if (result.exitCode != 0) {
      throw StateError('probe $id failed: ${result.stderr}');
    }
  }
  final cand = <String, List<prior.Candidate>>{};
  for (final row in prior.table(ev.path)) {
    (cand['${row['caseId']}:${row['sample']}'] ??= []).add(
      prior.Candidate(row),
    );
  }
  final groups = <String, List<Map<String, String>>>{};
  for (final row in prior.table(raw.path)) {
    (groups[row['caseId']!] ??= []).add(row);
  }
  final lines = <String>[
    'caseId,targetHz,lowComponentGainRelativeToTarget,profile,envelope,stableFrames,productionVoiced,productionNearTarget,productionNearLower,productionOther,strategyCNearTarget,strategyCNearLower,F2Abstained,releaseFrames,releaseVoiced,releaseMedianConfidence,releaseF2Abstained',
  ];
  for (final entry in recipes.entries) {
    final id = entry.key;
    final (f, low, profile, mode) = entry.value;
    final rows = groups[id]!;
    var voiced = 0,
        high = 0,
        lower = 0,
        other = 0,
        cHigh = 0,
        cLower = 0,
        f2 = 0,
        releaseFrames = 0,
        releaseVoiced = 0,
        releaseF2 = 0;
    final releaseConfidence = <double>[];
    for (final row in rows) {
      final t = prior.number(row, 'timestamp');
      final stable = t >= .4 && t < .85;
      final decay = mode != 'steady' && t >= 1.15 && t < 1.75;
      if (!stable && !decay) {
        continue;
      }
      final cs = cand['$id:${row['sample']}'] ?? <prior.Candidate>[];
      final frame = ambiguity.Frame(row, cs, null, '', 0, 0);
      if (stable) {
        if (frame.aHz > 0) {
          voiced++;
          final ratio = frame.aHz / f;
          if ((ratio - 1).abs() < .06) {
            high++;
          } else if ((ratio - .5).abs() < .03) {
            lower++;
          } else {
            other++;
          }
        }
        if (frame.cHz > 0 && (frame.cHz / f - 1).abs() < .06) cHigh++;
        if (frame.cHz > 0 && (frame.cHz / f - .5).abs() < .03) cLower++;
        if (frame.abstain('F2_DISAGREEMENT')) f2++;
      }
      if (decay) {
        releaseFrames++;
        if (frame.aHz > 0) {
          releaseVoiced++;
          releaseConfidence.add(frame.confidence);
        }
        if (frame.abstain('F2_DISAGREEMENT')) releaseF2++;
      }
    }
    lines.add(
      '$id,$f,$low,$profile,$mode,${rows.where((r) => prior.number(r, 'timestamp') >= .4 && prior.number(r, 'timestamp') < .85).length},$voiced,$high,$lower,$other,$cHigh,$cLower,$f2,$releaseFrames,$releaseVoiced,${value(med(releaseConfidence))},$releaseF2',
    );
  }
  File(
    'targeted_audio_synthetic_ff2_grid.csv',
  ).writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('synthetic diagnostic cases=${recipes.length}');
}
