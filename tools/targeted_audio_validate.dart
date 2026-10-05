// Reproducible host-only validation. Truth is read only after DSP features exist.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'pitch_candidate_evaluate.dart' as prior;
import 'pitch_ambiguity_investigate.dart' as ambiguity;

const descriptions = <String, String>{
  'R01': 'F3 sustain and release',
  'R02': 'F4 sustain and release',
  'R03': 'F3 to F4',
  'R04': 'F4 to F3',
  'R05': 'E3 new timbre sustain and release',
  'R06': 'E4 new timbre sustain and release',
  'R07': 'E4 plus softer E3; polyphonic stress',
  'R08': 'F4 plus approximately equal F3; polyphonic stress',
};

class Region {
  const Region(this.id, this.name, this.start, this.end, this.midi);
  final String id, name;
  final double start, end;
  final int? midi;
  bool contains(double t) => t >= start && t < end;
}

// Derived from 250-ms RMS/pitch/onset inspection, not measured key timing.
const regions = <Region>[
  Region('R01', 'leading', 0, .95, null),
  Region('R01', 'attack', .95, 1.25, null),
  Region('R01', 'stable', 1.25, 2.2, 53),
  Region('R01', 'release', 2.2, 2.55, null),
  Region('R01', 'background', 2.55, 4.06, null),
  Region('R02', 'leading', 0, 1.15, null),
  Region('R02', 'attack', 1.15, 1.45, null),
  Region('R02', 'stable', 1.45, 2.4, 65),
  Region('R02', 'release', 2.4, 2.85, null),
  Region('R02', 'background', 2.85, 3.97, null),
  Region('R03', 'leading', 0, .85, null),
  Region('R03', 'attack', .85, 1.1, null),
  Region('R03', 'firstStable', 1.1, 1.55, 53),
  Region('R03', 'transition', 1.55, 1.95, null),
  Region('R03', 'secondStable', 1.95, 2.75, 65),
  Region('R03', 'release', 2.75, 3.2, null),
  Region('R03', 'background', 3.2, 3.58, null),
  Region('R04', 'leading', 0, .9, null),
  Region('R04', 'attack', .9, 1.15, null),
  Region('R04', 'firstStable', 1.15, 1.7, 65),
  Region('R04', 'transition', 1.7, 2.2, null),
  Region('R04', 'secondStable', 2.2, 2.85, 53),
  Region('R04', 'release', 2.85, 3.3, null),
  Region('R04', 'background', 3.3, 3.58, null),
  Region('R05', 'leading', 0, .8, null),
  Region('R05', 'attack', .8, 1.1, null),
  Region('R05', 'stable', 1.1, 2.6, 52),
  Region('R05', 'release', 2.6, 3.25, null),
  Region('R05', 'background', 3.25, 4.3, null),
  Region('R06', 'leading', 0, .95, null),
  Region('R06', 'attack', .95, 1.2, null),
  Region('R06', 'stable', 1.2, 2.25, 64),
  Region('R06', 'release', 2.25, 3.2, null),
  Region('R06', 'background', 3.2, 3.58, null),
  Region('R07', 'leading', 0, 1.3, null),
  Region('R07', 'attack', 1.3, 1.65, null),
  Region('R07', 'combined', 1.65, 2.75, null),
  Region('R07', 'release', 2.75, 3.55, null),
  Region('R07', 'background', 3.55, 3.97, null),
  Region('R08', 'leading', 0, 1.05, null),
  Region('R08', 'attack', 1.05, 1.4, null),
  Region('R08', 'combined', 1.4, 2.65, null),
  Region('R08', 'release', 2.65, 3.3, null),
  Region('R08', 'background', 3.3, 4.23, null),
];

double med(Iterable<double> values) {
  final sorted = values.where((x) => x.isFinite).toList()..sort();
  return sorted.isEmpty ? double.nan : sorted[sorted.length ~/ 2];
}

String num(double v) => v.isFinite ? v.toStringAsFixed(6) : '';
void csv(String name, List<String> lines) =>
    File(name).writeAsStringSync('${lines.join('\n')}\n');
String kind(double hz, int midi) =>
    prior.kind(hz, prior.midiHz(midi.toDouble())).name;
double cents(double hz, int midi) => hz > 0
    ? 1200 * math.log(hz / prior.midiHz(midi.toDouble())) / math.ln2
    : double.nan;

void main() {
  final baseline = prior.table('targeted_audio_production_baseline.csv');
  final evidence = prior.table('targeted_audio_candidate_evidence.csv');
  final candidates = <String, List<prior.Candidate>>{};
  for (final e in evidence) {
    (candidates['${e['caseId']}:${e['sample']}'] ??= []).add(
      prior.Candidate(e),
    );
  }
  final regionCsv = <String>[
    'caseId,region,startSeconds,endSeconds,startSample,endSample,expectedMidi,provenance',
  ];
  for (final r in regions) {
    regionCsv.add(
      '${r.id},${r.name},${r.start},${r.end},${(r.start * 44100).round()},${(r.end * 44100).round()},${r.midi ?? ''},derived_250ms_RMS_onset_pitch_inspection',
    );
  }
  csv('targeted_audio_regions.csv', regionCsv);

  final validation = <String>[
    'caseId,region,expectedMidi,policy,frames,voiced,correct,octaveDown,octaveUp,other,unvoiced,abstain,coveragePercent,medianCorrectCents,medianRms,medianConfidence',
  ];
  final comparison = <String>[
    'caseId,region,policy,frames,expectedMidi,correct,octaveDown,octaveUp,other,unvoiced,abstain,nearLower,nearUpper,interpretation',
  ];
  final release = <String>[
    'caseId,region,frames,voiced,medianRms,medianEnergy,medianConfidence,medianCmnd,medianMargin,medianFoverH2,largePitchJumps,F2Abstained,voicedF2Retained',
  ];
  final timbre = <String>[
    'caseId,timbreGroup,region,frames,voiced,medianCmnd,medianConfidence,medianMargin,medianFund,medianH2,medianH3,medianHalf,medianRms',
  ];
  final stress = <String>[
    'caseId,region,frames,voiced,nearLower,nearUpper,other,medianConfidence,medianMargin,medianLowerCmnd,medianUpperCmnd,medianLowerFund,medianLowerH2,medianUpperFund,medianUpperH2,F2Abstained,note',
  ];
  final stats = <String>[
    'caseId,format,sampleRate,channels,pcmFrames,pcmSeconds,rms,peak,clippingFraction,leadingBelow003Seconds,trailingBelow003Seconds',
  ];
  const policies = [
    'A_CURRENT',
    'B_CMND',
    'C_SPECTRAL',
    'D_TEMPORAL',
    'E_COMBINED',
    'F2_DISAGREEMENT',
  ];

  for (final id in descriptions.keys) {
    final rows = baseline.where((r) => r['caseId'] == id).toList();
    final stream = File('.targeted_audio_tmp/$id.f32le').openSync();
    var frames = 0, clipped = 0, lead = 0, tail = 0;
    var total = 0.0, peak = 0.0, started = false;
    try {
      while (true) {
        final bytes = stream.readSync(512 * 4);
        if (bytes.isEmpty) break;
        final data = ByteData.sublistView(Uint8List.fromList(bytes));
        var power = 0.0;
        for (var i = 0; i < bytes.length; i += 4) {
          final s = data.getFloat32(i, Endian.little);
          if (!s.isFinite) throw FormatException('nonfinite PCM $id');
          frames++;
          power += s * s;
          total += s * s;
          peak = math.max(peak, s.abs());
          if (s.abs() >= 1) clipped++;
        }
        if (math.sqrt(power / (bytes.length ~/ 4)) < .003) {
          if (!started) lead++;
          tail++;
        } else {
          started = true;
          tail = 0;
        }
      }
    } finally {
      stream.closeSync();
    }
    stats.add(
      '$id,mono_f32le,44100,1,$frames,${num(frames / 44100)},${num(math.sqrt(total / frames))},${num(peak)},${num(clipped / frames)},${num(lead * 512 / 44100)},${num(tail * 512 / 44100)}',
    );

    var temporal = 0.0, previous = 0.0, rmsMax = 0.0;
    final perRegion =
        <
          String,
          List<
            (Map<String, String>, ambiguity.Frame, Map<String, prior.Decision>)
          >
        >{};
    for (final row in rows) {
      final t = prior.number(row, 'timestamp');
      final r = regions.where((r) => r.id == id && r.contains(t)).firstOrNull;
      if (r == null) continue;
      final cs = candidates['$id:${row['sample']}'] ?? <prior.Candidate>[];
      final d = prior.decisions(
        prior.number(row, 'pitchHz'),
        prior.number(row, 'onsetStrength'),
        cs,
        temporal,
      );
      final f = ambiguity.Frame(
        row,
        cs,
        r.midi == null ? null : {'expectedMidi': '${r.midi}', 'region': r.name},
        '',
        previous,
        rmsMax,
      );
      (perRegion[r.name] ??= []).add((row, f, d));
      if (d['D_TEMPORAL']!.hz > 0) temporal = d['D_TEMPORAL']!.hz;
      if (f.aHz > 0) previous = f.aHz;
      rmsMax = math.max(rmsMax, f.rms);
    }
    for (final r in regions.where((r) => r.id == id)) {
      final g = perRegion[r.name] ?? [];
      if (g.isEmpty) continue;
      final fs = g.map((x) => x.$2).toList();
      final voiced = fs.where((f) => f.aHz > 0).toList();
      final selected = voiced
          .map((f) => f.selected)
          .whereType<prior.Candidate>()
          .toList();
      if (r.midi != null) {
        for (final policy in policies) {
          var correct = 0,
              down = 0,
              up = 0,
              other = 0,
              unvoiced = 0,
              abstain = 0;
          final centValues = <double>[];
          for (final x in g) {
            final reject = policy == 'F2_DISAGREEMENT' && x.$2.abstain(policy);
            final hz = policy == 'F2_DISAGREEMENT'
                ? x.$2.aHz
                : x.$3[policy]!.hz;
            if (reject) {
              abstain++;
              continue;
            }
            final k = kind(hz, r.midi!);
            switch (k) {
              case 'correct':
                correct++;
                centValues.add(cents(hz, r.midi!));
              case 'down':
                down++;
              case 'up':
                up++;
              case 'other':
                other++;
              default:
                unvoiced++;
            }
          }
          validation.add(
            '$id,${r.name},${r.midi},$policy,${g.length},${g.length - unvoiced - abstain},$correct,$down,$up,$other,$unvoiced,$abstain,${num(100 * (g.length - abstain) / g.length)},${num(med(centValues))},${num(med(fs.map((f) => f.rms)))},${num(med(voiced.map((f) => f.confidence)))}',
          );
          comparison.add(
            '$id,${r.name},$policy,${g.length},${r.midi},$correct,$down,$up,$other,$unvoiced,$abstain,,,monophonic_stable',
          );
        }
      }
      if (r.name == 'stable' || r.name == 'release' || r.name == 'background') {
        var jumps = 0, last = 0.0;
        for (final f in fs) {
          if (last > 0 &&
              f.aHz > 0 &&
              (1200 * math.log(f.aHz / last) / math.ln2).abs() > 700) {
            jumps++;
          }
          if (f.aHz > 0) {
            last = f.aHz;
          }
        }
        release.add(
          '$id,${r.name},${g.length},${voiced.length},${num(med(fs.map((f) => f.rms)))},${num(med(g.map((x) => prior.number(x.$1, 'energy'))))},${num(med(voiced.map((f) => f.confidence)))},${num(med(selected.map((c) => c.cmnd)))},${num(med(voiced.map((f) => f.margin)))},${num(med(selected.map((c) => (c.fund + 1) / (c.h2 + 1))))},$jumps,${fs.where((f) => f.abstain('F2_DISAGREEMENT')).length},${voiced.where((f) => !f.abstain('F2_DISAGREEMENT')).length}',
        );
      }
      if (r.midi != null) {
        timbre.add(
          '$id,${int.parse(id.substring(1)) <= 4 ? 'group_A' : 'group_B'},${r.name},${g.length},${voiced.length},${num(med(selected.map((c) => c.cmnd)))},${num(med(voiced.map((f) => f.confidence)))},${num(med(voiced.map((f) => f.margin)))},${num(med(selected.map((c) => c.fund)))},${num(med(selected.map((c) => c.h2)))},${num(med(selected.map((c) => c.h3)))},${num(med(selected.map((c) => c.half)))},${num(med(voiced.map((f) => f.rms)))}',
        );
      }
      if (r.name == 'combined') {
        final lower = id == 'R07' ? 52 : 53, upper = id == 'R07' ? 64 : 65;
        for (final policy in policies) {
          var nearLower = 0,
              nearUpper = 0,
              other = 0,
              unvoiced = 0,
              abstained = 0;
          for (final x in g) {
            if (policy == 'F2_DISAGREEMENT' && x.$2.abstain(policy)) {
              abstained++;
              continue;
            }
            final hz = policy == 'F2_DISAGREEMENT'
                ? x.$2.aHz
                : x.$3[policy]!.hz;
            if (hz <= 0) {
              unvoiced++;
            } else if (kind(hz, lower) == 'correct') {
              nearLower++;
            } else if (kind(hz, upper) == 'correct') {
              nearUpper++;
            } else {
              other++;
            }
          }
          comparison.add(
            '$id,combined,$policy,${g.length},,,,,$other,$unvoiced,$abstained,$nearLower,$nearUpper,polyphonic_stress_no_unique_truth',
          );
        }
        prior.Candidate? near(ambiguity.Frame f, int midi) {
          final options = f.candidates.toList()
            ..sort(
              (a, b) => (a.hz - prior.midiHz(midi.toDouble())).abs().compareTo(
                (b.hz - prior.midiHz(midi.toDouble())).abs(),
              ),
            );
          return options.isEmpty ? null : options.first;
        }

        final low = fs
            .map((f) => near(f, lower))
            .whereType<prior.Candidate>()
            .toList();
        final high = fs
            .map((f) => near(f, upper))
            .whereType<prior.Candidate>()
            .toList();
        stress.add(
          '$id,combined,${g.length},${voiced.length},${voiced.where((f) => kind(f.aHz, lower) == 'correct').length},${voiced.where((f) => kind(f.aHz, upper) == 'correct').length},${voiced.where((f) => kind(f.aHz, lower) != 'correct' && kind(f.aHz, upper) != 'correct').length},${num(med(voiced.map((f) => f.confidence)))},${num(med(voiced.map((f) => f.margin)))},${num(med(low.map((c) => c.cmnd)))},${num(med(high.map((c) => c.cmnd)))},${num(med(low.map((c) => c.fund)))},${num(med(low.map((c) => c.h2)))},${num(med(high.map((c) => c.fund)))},${num(med(high.map((c) => c.h2)))},${fs.where((f) => f.abstain('F2_DISAGREEMENT')).length},polyphonic_outside_monophonic_V1',
        );
      }
    }
  }
  csv('targeted_audio_phase3_verification.csv', stats);
  csv('targeted_audio_pretuning_validation.csv', validation);
  csv('targeted_audio_strategy_comparison.csv', comparison);
  csv('targeted_audio_release_analysis.csv', release);
  csv('targeted_audio_timbre_analysis.csv', timbre);
  csv('targeted_audio_octave_stress.csv', stress);
  stdout.writeln(
    'validated ${descriptions.length} files; ${validation.length - 1} scored region-policy rows',
  );
}
