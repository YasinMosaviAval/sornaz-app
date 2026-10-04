// Host-only, score-independent calibration. No package imports or app changes.
import 'dart:io';
import 'dart:math' as math;

List<String> cells(String line) {
  final out = <String>[];
  final current = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      if (quoted && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (c == ',' && !quoted) {
      out.add(current.toString());
      current.clear();
    } else {
      current.write(c);
    }
  }
  out.add(current.toString());
  return out;
}

List<Map<String, String>> table(String path) {
  final lines = File(path).readAsLinesSync();
  final headers = cells(lines.first.replaceFirst('\uFEFF', ''));
  return [
    for (final line in lines.skip(1))
      if (line.trim().isNotEmpty)
        {
          for (var i = 0, values = cells(line); i < headers.length; i++)
            headers[i]: values[i],
        },
  ];
}

double number(Map<String, String> row, String key) =>
    double.tryParse(row[key] ?? '') ?? 0;
String key(String id, String sample) => '$id:$sample';
double midiHz(double midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

class Candidate {
  Candidate(Map<String, String> row)
    : hz = number(row, 'hz'),
      cmnd = number(row, 'cmnd'),
      fund = number(row, 'spectralFundamental'),
      h2 = number(row, 'spectralH2'),
      h3 = number(row, 'spectralH3'),
      half = number(row, 'spectralHalf');
  final double hz, cmnd, fund, h2, h3, half;
  double get spectralScore =>
      math.log(1 + fund) +
      .5 * math.log(1 + h2) +
      .25 * math.log(1 + h3) -
      .5 * math.log(1 + half);
}

enum Kind { correct, down, up, other, unvoiced, abstain }

Kind kind(double hz, double expected, {bool abstain = false}) {
  if (abstain) return Kind.abstain;
  if (hz <= 0) return Kind.unvoiced;
  final cents = 1200 * math.log(hz / expected) / math.ln2;
  if (cents.abs() < 100) return Kind.correct;
  if ((cents + 1200).abs() < 200) return Kind.down;
  if ((cents - 1200).abs() < 200) return Kind.up;
  return Kind.other;
}

class Decision {
  const Decision(this.hz, [this.abstain = false]);
  final double hz;
  final bool abstain;
}

// Parameters below are frozen before held-out scoring. They are exploratory,
// not production constants. All rules use observed candidates only.
Map<String, Decision> decisions(
  double baseline,
  double onset,
  List<Candidate> candidates,
  double previousTemporal,
) {
  final out = <String, Decision>{'A_CURRENT': Decision(baseline)};
  // Candidate ranking only revises an already voiced production observation.
  // Otherwise the trace can contain local minima that production correctly
  // rejected; promoting them would manufacture notes from release/background.
  if (baseline <= 0) {
    for (final name in [
      'B_CMND',
      'C_SPECTRAL',
      'D_TEMPORAL',
      'E_COMBINED',
      'F_ABSTAIN',
    ])
      out[name] = const Decision(0);
    return out;
  }
  final viable = candidates
      .where((c) => c.cmnd < .45 && c.hz >= 80 && c.hz <= 2000)
      .toList();
  if (viable.isEmpty) {
    for (final name in [
      'B_CMND',
      'C_SPECTRAL',
      'D_TEMPORAL',
      'E_COMBINED',
      'F_ABSTAIN',
    ])
      out[name] = Decision(baseline);
    return out;
  }
  final shortest = viable.map((c) => c.hz).reduce(math.max);
  final b = viable.reduce(
    (a, b) =>
        a.cmnd + .20 * math.log(shortest / a.hz) / math.ln2 <=
            b.cmnd + .20 * math.log(shortest / b.hz) / math.ln2
        ? a
        : b,
  );
  final c = viable.reduce(
    (a, b) =>
        a.spectralScore - 2 * a.cmnd >= b.spectralScore - 2 * b.cmnd ? a : b,
  );
  Candidate? temporal;
  if (previousTemporal > 0 && onset < .38) {
    for (final candidate in viable) {
      if ((1200 * math.log(candidate.hz / previousTemporal) / math.ln2).abs() <
              80 &&
          (temporal == null || candidate.cmnd < temporal.cmnd)) {
        temporal = candidate;
      }
    }
  }
  final d =
      temporal ??
      viable.firstWhere(
        (candidate) =>
            baseline > 0 && (candidate.hz / baseline - 1).abs() < .03,
        orElse: () => viable.reduce((a, b) => a.cmnd < b.cmnd ? a : b),
      );
  final e = viable.reduce(
    (a, b) =>
        a.spectralScore -
                2 * a.cmnd +
                .12 * math.log(shortest / a.hz) / math.ln2 >=
            b.spectralScore -
                2 * b.cmnd +
                .12 * math.log(shortest / b.hz) / math.ln2
        ? a
        : b,
  );
  out['B_CMND'] = Decision(b.hz);
  out['C_SPECTRAL'] = Decision(c.hz);
  out['D_TEMPORAL'] = Decision(d.hz);
  out['E_COMBINED'] = Decision(e.hz);
  // Honest ambiguity: disagreeing CMND and spectral candidates, each with
  // support, are not forced to a high-confidence octave correction.
  out['F_ABSTAIN'] = Decision(
    e.hz,
    b.hz > 0 &&
        c.hz > 0 &&
        (1200 * math.log(b.hz / c.hz) / math.ln2).abs() > 500,
  );
  return out;
}

class Counts {
  final counts = {for (final k in Kind.values) k: 0};
  final cents = <double>[];
  void add(Kind k, double hz, double expected) {
    counts[k] = counts[k]! + 1;
    if (k == Kind.correct) cents.add(1200 * math.log(hz / expected) / math.ln2);
  }

  int get total => counts.values.fold(0, (a, b) => a + b);
  double get medianCents {
    if (cents.isEmpty) return double.nan;
    cents.sort();
    return cents[cents.length ~/ 2];
  }
}

void main() {
  final split = table('pitch_candidate_annotations.csv');
  final evidence = <String, List<Candidate>>{};
  for (final row in [
    ...table('pitch_candidate_evidence.csv'),
    ...table('pitch_candidate_synthetic_evidence.csv'),
    ...table('pitch_candidate_heldout_synthetic_evidence.csv'),
  ]) {
    (evidence[key(row['caseId']!, row['sample']!)] ??= []).add(Candidate(row));
  }
  final features = [
    ...table('pitch_candidate_baseline.csv'),
    ...table('pitch_candidate_synthetic_features.csv'),
    ...table('pitch_candidate_heldout_synthetic_features.csv'),
  ];
  final devNew = {'N01', 'N02', 'N03', 'N07', 'N09', 'N11'};
  final devPrior = {
    'P01',
    'P02',
    'P03',
    'P04',
    'P05',
    'P07',
    'P09',
    'C01',
    'C02',
    'C03',
  };
  final summaries = <String, Counts>{};
  final rows = <String>[
    'caseId,set,region,startSeconds,endSeconds,expectedMidi,'
        'strategy,frames,correct,octaveDown,octaveUp,other,unvoiced,abstain,'
        'medianCorrectCents',
  ];
  final releaseRows = <String>[
    'caseId,region,strategy,frames,voiced,unvoiced,'
        'abstain,halfF4ObservationsNotErrors,medianBaselineVoicedConfidence',
  ];
  final leapRows = <String>[
    'caseId,region,strategy,frames,correct,down,up,'
        'other,unvoiced,abstain',
  ];
  final featureByCase = <String, List<Map<String, String>>>{};
  for (final f in features) {
    (featureByCase[f['caseId']!] ??= []).add(f);
  }
  final runtimes = <String, int>{};
  for (final region in split) {
    final id = region['caseId']!;
    final start = number(region, 'startSeconds');
    final end = number(region, 'endSeconds');
    final expectedMidi = number(region, 'expectedMidi');
    final expected = expectedMidi == 0 ? 0.0 : midiHz(expectedMidi);
    final isStable = region['region']!.startsWith('stable');
    final isSynthetic = id.startsWith('S') || id.startsWith('H');
    final set = id.startsWith('H')
        ? 'heldout'
        : isSynthetic
        ? 'development'
        : id.startsWith('N')
        ? (devNew.contains(id) ? 'development' : 'heldout')
        : (devPrior.contains(id) ? 'development' : 'heldout');
    final corpus = isSynthetic
        ? 'synthetic'
        : id.startsWith('N')
        ? 'new'
        : 'prior';
    final counters = <String, Counts>{};
    final halfF4 = <String, int>{};
    final confidence = <double>[];
    var previousD = 0.0;
    for (final f in featureByCase[id] ?? <Map<String, String>>[]) {
      final t = number(f, 'timestamp');
      if (t < start || t >= end) continue;
      final a = number(f, 'pitchHz');
      final onset = number(f, 'onsetStrength');
      final candidates = evidence[key(id, f['sample']!)] ?? [];
      final watch = Stopwatch()..start();
      final results = decisions(a, onset, candidates, previousD);
      watch.stop();
      runtimes[id] = (runtimes[id] ?? 0) + watch.elapsedMicroseconds;
      previousD = results['D_TEMPORAL']!.hz;
      for (final entry in results.entries) {
        final name = entry.key;
        final d = entry.value;
        final counter = counters[name] ??= Counts();
        if (isStable) {
          final k = kind(d.hz, expected, abstain: d.abstain);
          counter.add(k, d.hz, expected);
          (summaries['$set:$corpus:$name'] ??= Counts()).add(k, d.hz, expected);
        } else {
          counter.add(
            d.abstain
                ? Kind.abstain
                : d.hz <= 0
                ? Kind.unvoiced
                : Kind.other,
            d.hz,
            349.228,
          );
          if (id == 'N12' &&
              d.hz > 0 &&
              !d.abstain &&
              (1200 * math.log(d.hz / 174.614) / math.ln2).abs() < 200) {
            halfF4[name] = (halfF4[name] ?? 0) + 1;
          }
          if (d.hz > 0 && !d.abstain && name == 'A_CURRENT') {
            confidence.add(number(f, 'confidence'));
          }
        }
      }
    }
    for (final entry in counters.entries) {
      final c = entry.value;
      if (isStable) {
        rows.add(
          [
            id,
            set,
            region['region'],
            start,
            end,
            expectedMidi,
            entry.key,
            c.total,
            c.counts[Kind.correct],
            c.counts[Kind.down],
            c.counts[Kind.up],
            c.counts[Kind.other],
            c.counts[Kind.unvoiced],
            c.counts[Kind.abstain],
            c.cents.isEmpty ? '' : c.medianCents,
          ].join(','),
        );
        if (['N07', 'N08', 'N09', 'N10'].contains(id)) {
          leapRows.add(
            [
              id,
              region['region'],
              entry.key,
              c.total,
              c.counts[Kind.correct],
              c.counts[Kind.down],
              c.counts[Kind.up],
              c.counts[Kind.other],
              c.counts[Kind.unvoiced],
              c.counts[Kind.abstain],
            ].join(','),
          );
        }
      } else if (id == 'N12') {
        confidence.sort();
        releaseRows.add(
          [
            id,
            region['region'],
            entry.key,
            c.total,
            c.counts[Kind.other],
            c.counts[Kind.unvoiced],
            c.counts[Kind.abstain],
            halfF4[entry.key] ?? 0,
            confidence.isEmpty ? '' : confidence[confidence.length ~/ 2],
          ].join(','),
        );
      }
    }
  }
  File(
    'pitch_candidate_region_results.csv',
  ).writeAsStringSync('${rows.join('\n')}\n');
  File(
    'pitch_candidate_octave_leaps.csv',
  ).writeAsStringSync('${leapRows.join('\n')}\n');
  File(
    'pitch_candidate_release_results.csv',
  ).writeAsStringSync('${releaseRows.join('\n')}\n');
  final comparison = <String>[
    'set,corpus,strategy,frames,correct,octaveDown,'
        'octaveUp,other,unvoiced,abstain,medianCorrectCents',
  ];
  for (final entry in summaries.entries) {
    final parts = entry.key.split(':');
    final c = entry.value;
    comparison.add(
      [
        parts[0],
        parts[1],
        parts[2],
        c.total,
        c.counts[Kind.correct],
        c.counts[Kind.down],
        c.counts[Kind.up],
        c.counts[Kind.other],
        c.counts[Kind.unvoiced],
        c.counts[Kind.abstain],
        c.cents.isEmpty ? '' : c.medianCents,
      ].join(','),
    );
  }
  File(
    'pitch_candidate_strategy_comparison.csv',
  ).writeAsStringSync('${comparison.join('\n')}\n');
  File('pitch_candidate_heldout_results.csv').writeAsStringSync(
    '${comparison.where((r) => r.startsWith('heldout,') || r.startsWith('set,')).join('\n')}\n',
  );
  File('pitch_candidate_synthetic_results.csv').writeAsStringSync(
    '${comparison.where((r) => r.contains(',synthetic,') || r.startsWith('set,')).join('\n')}\n',
  );
  File('pitch_candidate_runtime.csv').writeAsStringSync(
    'caseId,evaluationMicroseconds\n${runtimes.entries.map((e) => '${e.key},${e.value}').join('\n')}\n',
  );
  stdout.writeln(
    'features=${features.length} evidenceFrames=${evidence.length} '
    'annotations=${split.length} resultRows=${rows.length - 1}',
  );
}
