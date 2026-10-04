// Offline, score-independent audit of the frozen candidate corpus.
// This script does not alter production DSP, the previous split or its CSVs.
import 'dart:io';
import 'dart:math' as math;
import 'pitch_candidate_evaluate.dart' as prior;

double n(Map<String, String> row, String name) => prior.number(row, name);
String k(String id, String sample) => '$id:$sample';
double median(Iterable<double> input) {
  final values = input.where((v) => v.isFinite).toList()..sort();
  if (values.isEmpty) return double.nan;
  return values[values.length ~/ 2];
}

double quantile(Iterable<double> input, double q) {
  final values = input.where((v) => v.isFinite).toList()..sort();
  if (values.isEmpty) return double.nan;
  return values[((values.length - 1) * q).round()];
}

String cell(num value) => value.isNaN ? '' : value.toString();
double cents(double a, double b) =>
    a > 0 && b > 0 ? 1200 * math.log(a / b) / math.ln2 : double.nan;
double spectralScore(prior.Candidate c) => c.spectralScore - 2 * c.cmnd;

class Frame {
  Frame(
    this.source,
    this.candidates,
    this.annotation,
    this.recipe,
    this.previousHz,
    this.rollingRmsMax,
  ) {
    final base = n(source, 'pitchHz');
    final decisions = prior.decisions(
      base,
      n(source, 'onsetStrength'),
      candidates,
      0,
    );
    aHz = base;
    cHz = decisions['C_SPECTRAL']!.hz;
    selected = closest(base);
    alternative = closest(cHz);
    final scored =
        candidates
            .where((c) => c.cmnd < .45 && c.hz >= 80 && c.hz <= 2000)
            .toList()
          ..sort((a, b) => spectralScore(b).compareTo(spectralScore(a)));
    margin = scored.length < 2
        ? double.nan
        : spectralScore(scored[0]) - spectralScore(scored[1]);
    expectedHz =
        annotation == null || (annotation!['expectedMidi'] ?? '').isEmpty
        ? 0
        : prior.midiHz(n(annotation!, 'expectedMidi'));
    aKind = expectedHz > 0 ? prior.kind(aHz, expectedHz) : prior.Kind.unvoiced;
    cKind = expectedHz > 0 ? prior.kind(cHz, expectedHz) : prior.Kind.unvoiced;
    final double m = margin.isFinite ? margin : 0;
    // Candidate-specific research metric: explicitly NOT a calibrated
    // probability or a replacement for the public confidence value.
    diagnosticConfidence = alternative == null
        ? 0
        : math.min(
            (1 - alternative!.cmnd).clamp(0, 1).toDouble(),
            (m / (m + .5)).clamp(0, 1).toDouble(),
          );
  }
  final Map<String, String> source;
  final List<prior.Candidate> candidates;
  final Map<String, String>? annotation;
  final String recipe;
  final double previousHz, rollingRmsMax;
  late final double aHz, cHz, expectedHz, margin, diagnosticConfidence;
  late final prior.Kind aKind, cKind;
  late final prior.Candidate? selected, alternative;
  String get id => source['caseId']!;
  double get time => n(source, 'timestamp');
  double get confidence => n(source, 'confidence');
  double get rms => n(source, 'rms');
  double get onset => n(source, 'onsetStrength');
  String get region => annotation?['region'] ?? 'unlabelled';
  bool get labelled => expectedHz > 0;
  bool get correct => aKind == prior.Kind.correct;
  bool get wrong =>
      aKind == prior.Kind.down ||
      aKind == prior.Kind.up ||
      aKind == prior.Kind.other;
  bool get confidentWrong => wrong && confidence >= .85;
  prior.Candidate? closest(double hz) {
    if (hz <= 0 || candidates.isEmpty) return null;
    final options = candidates.toList()
      ..sort(
        (a, b) => (cents(a.hz, hz).abs()).compareTo(cents(b.hz, hz).abs()),
      );
    return options.first;
  }

  prior.Candidate? get expectedCandidate => closest(expectedHz);
  bool get disagreement => aHz > 0 && cHz > 0 && cents(aHz, cHz).abs() > 500;
  bool get cmndAmbiguity {
    if (selected == null || selected!.cmnd < .10) return false;
    return candidates.any(
      (c) =>
          c.hz > 0 &&
          (cents(c.hz, aHz).abs() - 1200).abs() < 220 &&
          (c.cmnd - selected!.cmnd).abs() < .12,
    );
  }

  bool get lowEnergyInstability =>
      rollingRmsMax > 0 &&
      rms < .35 * rollingRmsMax &&
      previousHz > 0 &&
      cents(aHz, previousHz).abs() > 700;
  bool abstain(String policy) => aHz <= 0
      ? false
      : switch (policy) {
          'F0_CURRENT' => false,
          'F1_CMND' => cmndAmbiguity,
          'F2_DISAGREEMENT' => disagreement,
          'F3_MARGIN' => margin.isFinite && margin < .25,
          'F4_DECAY_INSTABILITY' => lowEnergyInstability,
          'F5_CONSERVATIVE' =>
            disagreement || (cmndAmbiguity && lowEnergyInstability),
          _ => throw ArgumentError(policy),
        };
}

String taxonomy(Frame f) {
  if (f.id == 'N12' && f.region == 'release') return 'release_decay';
  if (f.recipe.startsWith('interference_') || f.recipe == 'heldout_mixture')
    return 'independent_low_interferer';
  if (f.recipe.startsWith('harmonic_weak')) return 'weak_fundamental';
  if (f.recipe.startsWith('harmonic_h2') || f.recipe == 'heldout_lower_h2')
    return 'strong_H2';
  if (f.recipe.contains('inharmonic') || f.recipe.contains('detuned')) {
    return 'inharmonic_or_detuned';
  }
  final candidate = f.alternative ?? f.selected;
  if (candidate == null) return 'candidate_shortlist_or_unvoiced';
  if (candidate.h2 > 2 * candidate.fund) return 'strong_H2_evidence';
  if (candidate.h3 > 2 * candidate.fund) return 'strong_H3_evidence';
  if (candidate.half > candidate.fund) return 'subharmonic_evidence';
  if (f.margin.isFinite && f.margin < .25) return 'small_spectral_margin';
  if (f.selected != null &&
      f.alternative != null &&
      (f.selected!.cmnd - f.alternative!.cmnd).abs() < .05) {
    return 'CMND_ambiguity';
  }
  return f.id.startsWith('S') || f.id.startsWith('H')
      ? 'spectral_ambiguity'
      : 'UNKNOWN_real_acoustic_source';
}

String evidence(prior.Candidate? c) {
  if (c == null) return ',,,,,,,';
  final midi = 69 + 12 * math.log(c.hz / 440) / math.ln2;
  return '${c.hz},$midi,${c.cmnd},${c.fund},${c.h2},${c.h3},'
      '${c.half},${spectralScore(c)}';
}

void writeCsv(String name, List<String> lines) =>
    File(name).writeAsStringSync('${lines.join('\n')}\n');

void main() {
  final annotations = <String, List<Map<String, String>>>{};
  for (final row in prior.table('pitch_candidate_annotations.csv')) {
    (annotations[row['caseId']!] ??= []).add(row);
  }
  final recipes = <String, String>{};
  final synthetic = prior.table('pitch_candidate_synthetic_baseline.csv');
  for (var i = 0; i < synthetic.length; i++) {
    recipes['S${(i + 1).toString().padLeft(3, '0')}'] = synthetic[i]['case']!;
  }
  for (final row in prior.table(
    'pitch_candidate_heldout_synthetic_manifest.csv',
  )) {
    recipes[row['caseId']!] = row['kind']!;
  }
  final candidateMap = <String, List<prior.Candidate>>{};
  for (final path in [
    'pitch_candidate_evidence.csv',
    'pitch_candidate_synthetic_evidence.csv',
    'pitch_candidate_heldout_synthetic_evidence.csv',
  ]) {
    for (final row in prior.table(path)) {
      (candidateMap[k(row['caseId']!, row['sample']!)] ??= []).add(
        prior.Candidate(row),
      );
    }
  }
  final frames = <Frame>[];
  for (final path in [
    'pitch_candidate_baseline.csv',
    'pitch_candidate_synthetic_features.csv',
    'pitch_candidate_heldout_synthetic_features.csv',
  ]) {
    var previousId = '';
    var previousHz = 0.0;
    var rollingRmsMax = 0.0;
    for (final row in prior.table(path)) {
      final id = row['caseId']!;
      if (id != previousId) {
        previousHz = 0;
        rollingRmsMax = 0;
        previousId = id;
      }
      final t = n(row, 'timestamp');
      Map<String, String>? region;
      for (final a in annotations[id] ?? const <Map<String, String>>[]) {
        if (t >= n(a, 'startSeconds') && t < n(a, 'endSeconds')) {
          region = a;
          break;
        }
      }
      final f = Frame(
        row,
        candidateMap[k(id, row['sample']!)] ?? [],
        region,
        recipes[id] ?? 'real_unidentified',
        previousHz,
        rollingRmsMax,
      );
      frames.add(f);
      // A causal envelope maximum: signal evidence only, no truth or case rule.
      rollingRmsMax = math.max(rollingRmsMax, f.rms);
      if (f.aHz > 0) previousHz = f.aHz;
    }
  }
  const policies = [
    'F0_CURRENT',
    'F1_CMND',
    'F2_DISAGREEMENT',
    'F3_MARGIN',
    'F4_DECAY_INSTABILITY',
    'F5_CONSERVATIVE',
  ];
  final labelled = frames.where((f) => f.labelled).toList();
  final pairRows = <String>[
    'caseId,sample,timestamp,region,recipe,set,'
        'change,aKind,cKind,expectedHz,productionHz,productionMidi,'
        'productionCmnd,productionF,productionH2,productionH3,'
        'productionHalf,productionScore,strategyCHz,strategyCMidi,'
        'strategyCCmnd,strategyCF,strategyCH2,strategyCH3,strategyCHalf,'
        'strategyCScore,expectedCandidateHz,expectedCandidateMidi,'
        'expectedCandidateCmnd,expectedCandidateF,expectedCandidateH2,'
        'expectedCandidateH3,expectedCandidateHalf,expectedCandidateScore,'
        'candidateMargin,rms,energy,peak,clipping,onsetStrength,confidence,'
        'previousPitchHz,taxonomy',
  ];
  final taxonomyRows = <String>['set,domain,change,taxonomy,frames'];
  final taxonomyCounts = <String, int>{};
  final groups = <String, List<Frame>>{};
  final syntheticRows = <String>[
    'caseId,recipe,expectedHz,frames,'
        'Acorrect_Cwrong,Awrong_Ccorrect,AoctaveDown,CoctaveDown,'
        'medianProductionFoverH2,medianCcandidateFoverH2,'
        'medianMargin,medianRms',
  ];
  final regressionCases = <String, List<Frame>>{};
  final confidenceRows = <String>[
    'set,domain,Aclass,count,min,q1,median,q3,max,'
        'confidenceGe085,medianCandidateSpecificConfidence',
  ];
  final releaseRows = <String>[
    'caseId,sample,timestamp,region,rms,energy,'
        'peak,pitchHz,confidence,cmndMinimum,candidateMargin,'
        'productionF,productionH2,productionH3,productionHalf,'
        'strategyCHz,strategyCCmnd,strategyCF,strategyCH2,strategyCH3,'
        'strategyCHalf,previousPitchHz,onsetStrength,isSilent,'
        'F1,F2,F3,F4,F5',
  ];
  final domainRows = <String>[
    'set,domain,Aclass,frames,medianCmnd,'
        'medianFoverH2,medianFoverH3,medianFoverHalf,medianRms,'
        'medianConfidence,medianCandidateMargin',
  ];
  final audit = <String, List<Frame>>{};
  final domains = <String, List<Frame>>{};
  for (final f in frames) {
    final id = f.id;
    final domain =
        id.startsWith('N') || id.startsWith('P') || id.startsWith('C')
        ? 'real'
        : 'synthetic';
    final set =
        id.startsWith('H') ||
            [
              'N04',
              'N05',
              'N06',
              'N08',
              'N10',
              'N12',
              'P06',
              'P08',
              'P10',
              'C04',
              'C05',
            ].contains(id)
        ? 'heldout'
        : 'development';
    if (f.labelled) {
      final auditKey = '$set,$domain,${f.aKind.name}';
      (audit[auditKey] ??= []).add(f);
      (domains[auditKey] ??= []).add(f);
      final change = f.correct && f.cKind != prior.Kind.correct
          ? 'regression'
          : f.wrong && f.cKind == prior.Kind.correct
          ? 'improvement'
          : '';
      if (change.isNotEmpty) {
        final family = taxonomy(f);
        final key = '$set,$domain,$change,$family';
        taxonomyCounts[key] = (taxonomyCounts[key] ?? 0) + 1;
        pairRows.add(
          '$id,${f.source['sample']},${f.time},${f.region},'
          '${f.recipe},$set,$change,${f.aKind.name},${f.cKind.name},'
          '${f.expectedHz},${evidence(f.selected)},'
          '${evidence(f.alternative)},${evidence(f.expectedCandidate)},'
          '${cell(f.margin)},${f.rms},${n(f.source, 'energy')},'
          '${n(f.source, 'peak')},${n(f.source, 'clipping')},'
          '${f.onset},${f.confidence},${f.previousHz},$family',
        );
        if (id.startsWith('S')) (regressionCases[id] ??= []).add(f);
      }
      (groups['$set,$domain'] ??= []).add(f);
    }
    if (id == 'N12' &&
        (f.region == 'stable' ||
            f.region == 'release' ||
            f.region == 'background')) {
      releaseRows.add(
        '$id,${f.source['sample']},${f.time},${f.region},'
        '${f.rms},${n(f.source, 'energy')},${n(f.source, 'peak')},'
        '${f.aHz},${f.confidence},${f.selected?.cmnd ?? ''},'
        '${cell(f.margin)},${f.selected?.fund ?? ''},'
        '${f.selected?.h2 ?? ''},${f.selected?.h3 ?? ''},'
        '${f.selected?.half ?? ''},${f.cHz},'
        '${f.alternative?.cmnd ?? ''},${f.alternative?.fund ?? ''},'
        '${f.alternative?.h2 ?? ''},${f.alternative?.h3 ?? ''},'
        '${f.alternative?.half ?? ''},${f.previousHz},${f.onset},'
        '${f.source['isSilent']},'
        '${f.abstain('F1_CMND') ? 1 : 0},'
        '${f.abstain('F2_DISAGREEMENT') ? 1 : 0},'
        '${f.abstain('F3_MARGIN') ? 1 : 0},'
        '${f.abstain('F4_DECAY_INSTABILITY') ? 1 : 0},'
        '${f.abstain('F5_CONSERVATIVE') ? 1 : 0}',
      );
    }
  }
  for (final entry in taxonomyCounts.entries) {
    taxonomyRows.add('${entry.key},${entry.value}');
  }
  for (final entry in regressionCases.entries) {
    final id = entry.key;
    final recipe = recipes[id]!;
    final inCase = labelled.where((f) => f.id == id).toList();
    final pair = entry.value;
    final selected = inCase.map((f) => f.selected).whereType<prior.Candidate>();
    final alternatives = inCase
        .map((f) => f.alternative)
        .whereType<prior.Candidate>();
    syntheticRows.add(
      '$id,$recipe,${inCase.first.expectedHz},'
      '${inCase.length},'
      '${pair.where((f) => f.correct && f.cKind != prior.Kind.correct).length},'
      '${pair.where((f) => f.wrong && f.cKind == prior.Kind.correct).length},'
      '${inCase.where((f) => f.aKind == prior.Kind.down).length},'
      '${inCase.where((f) => f.cKind == prior.Kind.down).length},'
      '${cell(median(selected.map((c) => (c.fund + 1) / (c.h2 + 1))))},'
      '${cell(median(alternatives.map((c) => (c.fund + 1) / (c.h2 + 1))))},'
      '${cell(median(inCase.map((f) => f.margin)))},'
      '${cell(median(inCase.map((f) => f.rms)))}',
    );
  }
  for (final entry in audit.entries) {
    final g = entry.value;
    final confidence = g.map((f) => f.confidence);
    confidenceRows.add(
      '${entry.key},${g.length},'
      '${cell(quantile(confidence, 0))},${cell(quantile(confidence, .25))},'
      '${cell(median(confidence))},${cell(quantile(confidence, .75))},'
      '${cell(quantile(confidence, 1))},'
      '${g.where((f) => f.confidence >= .85).length},'
      '${cell(median(g.map((f) => f.diagnosticConfidence)))}',
    );
    final selected = g.map((f) => f.selected).whereType<prior.Candidate>();
    domainRows.add(
      '${entry.key},${g.length},'
      '${cell(median(selected.map((c) => c.cmnd)))},'
      '${cell(median(selected.map((c) => (c.fund + 1) / (c.h2 + 1))))},'
      '${cell(median(selected.map((c) => (c.fund + 1) / (c.h3 + 1))))},'
      '${cell(median(selected.map((c) => (c.fund + 1) / (c.half + 1))))},'
      '${cell(median(g.map((f) => f.rms)))},'
      '${cell(median(g.map((f) => f.confidence)))},'
      '${cell(median(g.map((f) => f.margin)))}',
    );
  }
  final comparisonRows = <String>[
    'set,domain,policy,labelledFrames,'
        'covered,coveragePercent,voicedFrames,voicedCovered,'
        'voicedCoveragePercent,correctRetained,wrongRetained,'
        'confidentWrongRetained,abstainedCorrect,abstainedWrong,'
        'octaveDownRetained,octaveDownAbstained,octaveUpRetained,'
        'otherErrorRetained,unvoicedRetained',
  ];
  for (final entry in groups.entries) {
    final g = entry.value;
    for (final policy in policies) {
      final covered = g.where((f) => !f.abstain(policy)).toList();
      final abstained = g.where((f) => f.abstain(policy)).toList();
      final voiced = g.where((f) => f.aHz > 0).length;
      final voicedCovered = covered.where((f) => f.aHz > 0).length;
      comparisonRows.add(
        '${entry.key},$policy,${g.length},${covered.length},'
        '${100 * covered.length / g.length},'
        '$voiced,$voicedCovered,${100 * voicedCovered / voiced},'
        '${covered.where((f) => f.correct).length},'
        '${covered.where((f) => f.wrong).length},'
        '${covered.where((f) => f.confidentWrong).length},'
        '${abstained.where((f) => f.correct).length},'
        '${abstained.where((f) => f.wrong).length},'
        '${covered.where((f) => f.aKind == prior.Kind.down).length},'
        '${abstained.where((f) => f.aKind == prior.Kind.down).length},'
        '${covered.where((f) => f.aKind == prior.Kind.up).length},'
        '${covered.where((f) => f.aKind == prior.Kind.other).length},'
        '${covered.where((f) => f.aKind == prior.Kind.unvoiced).length}',
      );
    }
  }
  final riskRows = <String>[
    'set,domain,ranking,targetCoveragePercent,'
        'covered,actualCoveragePercent,wrongRetained,wrongRateCoveredPercent,'
        'confidentWrongRetained,correctAbstained',
  ];
  for (final entry in groups.entries) {
    final g = entry.value;
    for (final ranking in [
      'currentConfidence',
      'spectralMargin',
      'candidateSpecificDiagnostic',
    ]) {
      final sorted = g.toList()
        ..sort((a, b) {
          double score(Frame f) => switch (ranking) {
            'currentConfidence' => f.confidence,
            'spectralMargin' => f.margin.isFinite ? f.margin : -1,
            _ => f.diagnosticConfidence,
          };
          return score(b).compareTo(score(a));
        });
      for (final target in [100, 95, 90, 80]) {
        final keep = (sorted.length * target / 100).round();
        final covered = sorted.take(keep).toList();
        riskRows.add(
          '${entry.key},$ranking,$target,$keep,'
          '${100 * keep / sorted.length},'
          '${covered.where((f) => f.wrong).length},'
          '${100 * covered.where((f) => f.wrong).length / keep},'
          '${covered.where((f) => f.confidentWrong).length},'
          '${sorted.skip(keep).where((f) => f.correct).length}',
        );
      }
    }
  }
  writeCsv('pitch_ambiguity_candidate_pairs.csv', pairRows);
  writeCsv('pitch_ambiguity_failure_taxonomy.csv', taxonomyRows);
  writeCsv('pitch_ambiguity_synthetic_regressions.csv', syntheticRows);
  writeCsv('pitch_ambiguity_confidence_audit.csv', confidenceRows);
  writeCsv('pitch_ambiguity_release_n12.csv', releaseRows);
  writeCsv('pitch_ambiguity_real_vs_synthetic.csv', domainRows);
  writeCsv('pitch_ambiguity_abstention_comparison.csv', comparisonRows);
  writeCsv('pitch_ambiguity_risk_coverage.csv', riskRows);
  stdout.writeln(
    'frames=${frames.length} labelled=${labelled.length} '
    'changedPairs=${pairRows.length - 1} releaseRows=${releaseRows.length - 1}',
  );
}
