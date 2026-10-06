// Host-only audit of frozen raw features and exact-window YIN traces.
// Truth is attached only after native processing, never passed to the detector.
import 'dart:io';
import 'dart:math' as math;
import 'pitch_candidate_evaluate.dart' as csv;

double n(Map<String, String> r, String k) => csv.number(r, k);
String key(String id, String sample) => '$id:$sample';
String q(Object? value) =>
    '"${(value ?? '').toString().replaceAll('"', '""')}"';
void write(
  String name,
  List<String> header,
  Iterable<List<Object?>> rows,
) => File(name).writeAsStringSync(
  '${header.map(q).join(',')}\n${rows.map((r) => r.map(q).join(',')).join('\n')}\n',
);
double median(Iterable<double> values) {
  final a = values.where((x) => x.isFinite).toList()..sort();
  return a.isEmpty ? double.nan : a[a.length ~/ 2];
}

double midi(double hz) =>
    hz > 0 ? 69 + 12 * math.log(hz / 440) / math.ln2 : double.nan;
double score(Map<String, String> c) =>
    math.log(1 + n(c, 'spectralFundamental')) +
    .5 * math.log(1 + n(c, 'spectralH2')) +
    .25 * math.log(1 + n(c, 'spectralH3')) -
    .5 * math.log(1 + n(c, 'spectralHalf')) -
    2 * n(c, 'cmnd');

class Region {
  Region(
    this.id,
    this.type,
    this.start,
    this.end,
    this.expected,
    this.source,
    this.quality,
  );
  final String id, type, source, quality;
  final double start, end, expected;
}

class F {
  F(this.r, this.region, this.candidates);
  final Map<String, String> r;
  final Region? region;
  final List<Map<String, String>> candidates;
  String get id => r['caseId']!;
  double get t => n(r, 'timestamp');
  double get hz => n(r, 'pitchHz');
  double get rms => n(r, 'rms');
  double get conf => n(r, 'confidence');
  bool get nativeVoiced => hz > 0 && n(r, 'isSilent') == 0;
  bool get accepted => nativeVoiced && conf >= .55 && rms > .001;
  Map<String, String>? get selected {
    for (final c in candidates) {
      if (n(c, 'selected') == 1) return c;
    }
    return null;
  }

  Map<String, String>? get alternative {
    final a =
        candidates
            .where(
              (c) =>
                  n(c, 'selected') != 1 &&
                  n(c, 'cmnd') < .45 &&
                  n(c, 'hz') >= 80 &&
                  n(c, 'hz') <= 2000,
            )
            .toList()
          ..sort((a, b) => score(b).compareTo(score(a)));
    return a.isEmpty ? null : a.first;
  }

  double get margin {
    final a =
        candidates
            .where(
              (c) =>
                  n(c, 'cmnd') < .45 && n(c, 'hz') >= 80 && n(c, 'hz') <= 2000,
            )
            .toList()
          ..sort((a, b) => score(b).compareTo(score(a)));
    return a.length < 2 ? double.nan : score(a[0]) - score(a[1]);
  }

  String get kind {
    final truth = region?.expected ?? 0;
    if (truth <= 0) return 'UNLABELLED';
    if (!accepted) return 'UNVOICED';
    final cents = 100 * (midi(hz) - truth);
    if (cents.abs() < 100) return 'CORRECT';
    if ((cents + 1200).abs() < 200) return 'OCTAVE_DOWN';
    if ((cents - 1200).abs() < 200) return 'OCTAVE_UP';
    return 'OTHER';
  }

  bool keep(String policy) {
    if (!accepted) return false;
    switch (policy) {
      case 'A_PRODUCTION':
        return true;
      case 'B_RMS_010':
        return rms >= .010;
      case 'C_CONF_950':
        return conf >= .950;
      case 'D_CONSERVATIVE':
        return rms >= .010 && conf >= .950;
      case 'E_SPECTRAL_DISAGREE':
        final a = alternative;
        if (a == null || selected == null) return true;
        final sep = (midi(n(a, 'hz')) - midi(hz)).abs();
        return !(sep > 7 && score(a) > score(selected!));
    }
    throw ArgumentError(policy);
  }
}

void main() {
  final regions = <Region>[];
  for (final a in csv.table('pitch_candidate_annotations.csv')) {
    final id = a['caseId']!;
    if (!(id.startsWith('N') || id.startsWith('P') || id.startsWith('C')))
      continue;
    regions.add(
      Region(
        id,
        (a['region'] ?? '').toUpperCase(),
        n(a, 'startSeconds'),
        n(a, 'endSeconds'),
        n(a, 'expectedMidi'),
        'prior_frozen_annotation',
        a['confidence'] ?? 'derived',
      ),
    );
  }
  for (final a in csv.table('targeted_audio_regions.csv')) {
    regions.add(
      Region(
        a['caseId']!,
        (a['region'] ?? '').toUpperCase(),
        n(a, 'startSeconds'),
        n(a, 'endSeconds'),
        n(a, 'expectedMidi'),
        'prior_targeted_derived',
        'derived',
      ),
    );
  }
  // Conservative diagnostic windows; musical labels and video intervals are
  // evaluation metadata only. Occluded key-ups are not precise pitch truth.
  final video = <String, List<(String, double, double, double, String)>>{
    'V01': [
      ('PRE_NOTE_SILENCE', 0, 1.69993, 0, 'video_key_down'),
      ('ATTACK', 1.69993, 1.95, 0, 'derived'),
      ('STABLE_SUSTAIN', 2.0, 2.9, 65, 'video_plus_signal'),
      ('RELEASE_DECAY', 2.9, 4.26651, 0, 'low_confidence_key_up'),
      ('POST_NOTE_BACKGROUND', 4.26651, 6.86934, 0, 'low_confidence_key_up'),
    ],
    'V02': [
      ('PRE_NOTE_SILENCE', 0, 1.72991, 0, 'video_key_down'),
      ('ATTACK', 1.72991, 2.05, 0, 'derived'),
      ('STABLE_SUSTAIN', 2.1, 3.5, 64, 'video_plus_signal'),
      ('RELEASE_DECAY', 3.5, 4.66317, 0, 'low_confidence_key_up'),
      ('POST_NOTE_BACKGROUND', 4.66317, 5.568, 0, 'low_confidence_key_up'),
    ],
    'V03': [
      ('PRE_NOTE_SILENCE', 0, 1.49667, 0, 'video_key_down'),
      ('ATTACK', 1.49667, 1.93, 0, 'derived'),
      ('STABLE_SUSTAIN', 1.95, 2.6, 65, 'video_plus_signal'),
      ('TRANSITION', 2.6, 3.52, 0, 'video_rearticulation'),
      ('STABLE_SUSTAIN', 3.55, 4.45, 65, 'video_plus_signal'),
      ('RELEASE_DECAY', 4.45, 5.49989, 0, 'low_confidence_key_up'),
      ('POST_NOTE_BACKGROUND', 5.49989, 7.168, 0, 'low_confidence_key_up'),
    ],
    'V04': [
      ('PRE_NOTE_SILENCE', 0, 1.60559, 0, 'video_key_down'),
      ('ATTACK', 1.60559, 1.93, 0, 'derived'),
      ('STABLE_SUSTAIN', 1.95, 2.30, 65, 'video_plus_signal'),
      ('TRANSITION', 2.30, 2.75, 0, 'video_second_key_down'),
      ('STABLE_SUSTAIN', 2.8, 3.3, 64, 'video_plus_signal'),
      ('RELEASE_DECAY', 3.3, 4.3055, 0, 'low_confidence_key_up'),
      ('POST_NOTE_BACKGROUND', 4.3055, 5.312, 0, 'low_confidence_key_up'),
    ],
  };
  for (final e in video.entries) {
    for (final (type, start, end, expected, source) in e.value) {
      regions.add(
        Region(
          e.key,
          type,
          start,
          end,
          expected,
          source,
          source == 'video_key_down'
              ? 'medium'
              : source == 'low_confidence_key_up'
              ? 'low'
              : 'derived',
        ),
      );
    }
  }
  write(
    'raw_voicing_region_annotations.csv',
    [
      'case_id',
      'region',
      'start_seconds',
      'end_seconds',
      'expected_midi_evaluation_only',
      'source',
      'quality',
    ],
    regions.map(
      (r) => [
        r.id,
        r.type,
        r.start,
        r.end,
        r.expected > 0 ? r.expected : null,
        r.source,
        r.quality,
      ],
    ),
  );
  final byId = <String, List<Region>>{};
  for (final r in regions) {
    (byId[r.id] ??= []).add(r);
  }
  final evidence = <String, List<Map<String, String>>>{};
  for (final path in [
    'pitch_candidate_evidence.csv',
    'targeted_audio_candidate_evidence.csv',
    '.raw_voicing_tmp/probe_evidence.csv',
  ]) {
    for (final c in csv.table(path)) {
      (evidence[key(c['caseId']!, c['sample']!)] ??= []).add(c);
    }
  }
  final source = <Map<String, String>>[];
  for (final path in [
    'pitch_candidate_baseline.csv',
    'targeted_audio_production_baseline.csv',
    '.raw_voicing_tmp/probe_baseline.csv',
  ]) {
    source.addAll(csv.table(path));
  }
  final frames = <F>[];
  for (final r in source) {
    final id = r['caseId']!, t = n(r, 'timestamp');
    Region? region;
    for (final a in byId[id] ?? <Region>[]) {
      if (t >= a.start && t < a.end) {
        region = a;
        break;
      }
    }
    frames.add(F(r, region, evidence[key(id, r['sample']!)] ?? []));
  }
  write(
    'raw_voicing_baseline_features.csv',
    [
      'case_id',
      'frame_index',
      'frame_start_sample',
      'timestamp_seconds',
      'pitch_hz',
      'fractional_midi',
      'rounded_midi',
      'pitch_confidence',
      'onset_strength',
      'energy',
      'rms',
      'peak_abs',
      'clipping_fraction',
      'signal_quality',
      'flags',
      'native_voiced',
      'segmenter_accepts',
      'silence_flag',
      'region',
      'expected_midi_evaluation_only',
      'selected_candidate_hz',
      'selected_cmnd',
      'best_alternative_hz',
      'best_alternative_cmnd',
      'candidate_margin',
    ],
    frames.map((f) {
      final s = f.selected, a = f.alternative;
      return [
        f.id,
        (n(f.r, 'sample') / 512).round(),
        f.r['sample'],
        f.t,
        f.hz,
        f.hz > 0 ? midi(f.hz) : null,
        f.hz > 0 ? midi(f.hz).round() : null,
        f.conf,
        n(f.r, 'onsetStrength'),
        n(f.r, 'energy'),
        f.r['rms'],
        f.r['peak'],
        f.r['clipping'],
        n(f.r, 'isSilent') == 1 ? 0 : math.max(0, 1 - 4 * n(f.r, 'clipping')),
        'silent=${f.r['isSilent']};onset=${f.r['onsetCandidate']};partial=${f.r['isPartial']}',
        f.nativeVoiced,
        f.accepted,
        f.r['isSilent'],
        f.region?.type ?? 'UNKNOWN',
        (f.region?.expected ?? 0) > 0 ? f.region!.expected : null,
        s?['hz'],
        s?['cmnd'],
        a?['hz'],
        a?['cmnd'],
        f.margin.isFinite ? f.margin : null,
      ];
    }),
  );
  final ids = frames.map((f) => f.id).toSet().toList()..sort();
  write(
    'raw_voicing_input_manifest.csv',
    [
      'case_id',
      'source_file',
      'source_kind',
      'source_present',
      'baseline_frames',
      'ground_truth_quality',
    ],
    ids.map((id) {
      final sourceName = id.startsWith('N')
          ? 'Sornaz_octave_${id.substring(1)}.m4a'
          : id.startsWith('P')
          ? 'Sornaz_${int.parse(id.substring(1))}.m4a'
          : id.startsWith('C')
          ? [
              'Sornaz_اول.m4a',
              'Sornaz_دوم.m4a',
              'Sornaz_سوم.m4a',
              'Sornaz_چهارم.m4a',
              'Sornaz_پنجم.m4a',
            ][int.parse(id.substring(1)) - 1]
          : id.startsWith('R')
          ? 'Sornaz_$id.m4a'
          : '${id.substring(1)}.mp4';
      return [
        id,
        sourceName,
        id.startsWith('V') ? 'MP4' : 'M4A',
        true,
        frames.where((f) => f.id == id).length,
        id.startsWith('V')
            ? 'video_key_action_intervals'
            : 'musical_labels_derived_regions',
      ];
    }),
  );
  final vEvidence = csv.table('.raw_voicing_tmp/probe_evidence.csv');
  write(
    'raw_voicing_candidate_evidence.csv',
    [
      'case_id',
      'sample',
      'timestamp',
      'candidate_hz',
      'candidate_midi',
      'cmnd',
      'selected',
      'spectral_F',
      'spectral_H2',
      'spectral_H3',
      'spectral_f_over_2',
      'diagnostic_C_score',
    ],
    vEvidence.map(
      (c) => [
        c['caseId'],
        c['sample'],
        c['timestamp'],
        c['hz'],
        midi(n(c, 'hz')),
        c['cmnd'],
        c['selected'],
        c['spectralFundamental'],
        c['spectralH2'],
        c['spectralH3'],
        c['spectralHalf'],
        score(c),
      ],
    ),
  );
  final v02 = frames.where(
    (f) => f.id == 'V02' && f.region?.type == 'STABLE_SUSTAIN',
  );
  write(
    'raw_voicing_v02_octave_analysis.csv',
    [
      'sample',
      'time',
      'production_hz',
      'production_confidence',
      'rms',
      'selected_hz',
      'selected_cmnd',
      'selected_F',
      'selected_H2',
      'selected_H3',
      'selected_f_over_2',
      'upper_candidate_hz',
      'upper_candidate_cmnd',
      'upper_F',
      'upper_H2',
      'upper_H3',
      'upper_f_over_2',
      'score_margin',
    ],
    v02.map((f) {
      final s = f.selected;
      final upper =
          f.candidates
              .where((c) => n(c, 'hz') > 250 && n(c, 'hz') < 450)
              .toList()
            ..sort((a, b) => n(a, 'cmnd').compareTo(n(b, 'cmnd')));
      final u = upper.isEmpty ? null : upper.first;
      return [
        f.r['sample'],
        f.t,
        f.hz,
        f.conf,
        f.rms,
        s?['hz'],
        s?['cmnd'],
        s?['spectralFundamental'],
        s?['spectralH2'],
        s?['spectralH3'],
        s?['spectralHalf'],
        u?['hz'],
        u?['cmnd'],
        u?['spectralFundamental'],
        u?['spectralH2'],
        u?['spectralH3'],
        u?['spectralHalf'],
        f.margin.isFinite ? f.margin : null,
      ];
    }),
  );
  final policies = [
    'A_PRODUCTION',
    'B_RMS_010',
    'C_CONF_950',
    'D_CONSERVATIVE',
    'E_SPECTRAL_DISAGREE',
  ];
  final slices = <String, List<F>>{};
  for (final f in frames) {
    final group = f.id.startsWith('V')
        ? 'video'
        : f.id.startsWith('R')
        ? 'targeted_real'
        : 'previous_real';
    if (f.region?.type == 'PRE_NOTE_SILENCE')
      (slices['video_pre'] ??= []).add(f);
    if (f.region?.type == 'POST_NOTE_BACKGROUND')
      (slices['video_post_weak_truth'] ??= []).add(f);
    if (f.region?.type == 'RELEASE_DECAY')
      (slices['video_decay_uncertain'] ??= []).add(f);
    if ((f.region?.expected ?? 0) > 0)
      (slices['${group}_stable'] ??= []).add(f);
  }
  final strategy = <List<Object?>>[];
  for (final e in slices.entries) {
    for (final p in policies) {
      final a = e.value;
      final retained = a.where((f) => f.keep(p)).toList();
      strategy.add([
        e.key,
        p,
        a.length,
        a.where((f) => f.accepted).length,
        retained.length,
        retained.where((f) => f.kind == 'CORRECT').length,
        retained
            .where((f) => f.kind != 'CORRECT' && f.kind != 'UNLABELLED')
            .length,
        a.where((f) => f.kind == 'CORRECT' && !f.keep(p)).length,
        a
            .where(
              (f) =>
                  f.kind != 'CORRECT' &&
                  f.kind != 'UNLABELLED' &&
                  f.accepted &&
                  !f.keep(p),
            )
            .length,
        retained.where((f) => f.kind == 'OCTAVE_DOWN').length,
        a.where((f) => f.kind == 'OCTAVE_DOWN' && !f.keep(p)).length,
        a.isEmpty ? null : retained.length / a.length,
      ]);
    }
  }
  write('raw_voicing_strategy_comparison.csv', [
    'slice',
    'strategy',
    'total_frames',
    'baseline_accepted',
    'retained',
    'correct_retained',
    'wrong_retained',
    'correct_rejected',
    'wrong_rejected',
    'octave_down_retained',
    'octave_down_rejected',
    'coverage_all_frames',
  ], strategy);
  final candidateRows = <List<Object?>>[];
  for (final id in ['V01', 'V02', 'V03', 'V04']) {
    final stable = frames
        .where((f) => f.id == id && (f.region?.expected ?? 0) > 0)
        .toList();
    final totals = <String, List<int>>{
      for (final p in ['A_CURRENT', 'B_CMND', 'C_SPECTRAL', 'E_COMBINED'])
        p: List<int>.filled(5, 0),
    };
    for (final f in stable) {
      final decisions = csv.decisions(
        f.hz,
        n(f.r, 'onsetStrength'),
        f.candidates.map(csv.Candidate.new).toList(),
        0,
      );
      for (final entry in totals.entries) {
        final hz = decisions[entry.key]!.hz;
        final expected = csv.midiHz(f.region!.expected);
        final kind = csv.kind(hz, expected);
        final counts = entry.value;
        counts[0]++;
        switch (kind) {
          case csv.Kind.correct:
            counts[1]++;
            break;
          case csv.Kind.down:
            counts[2]++;
            break;
          case csv.Kind.up:
            counts[3]++;
            break;
          default:
            counts[4]++;
        }
      }
    }
    for (final entry in totals.entries) {
      candidateRows.add([id, entry.key, ...entry.value]);
    }
  }
  write('raw_voicing_candidate_selection.csv', [
    'case_id',
    'strategy',
    'stable_frames',
    'correct',
    'octave_down',
    'octave_up',
    'other_or_unvoiced',
  ], candidateRows);
  write(
    'raw_voicing_coverage_error.csv',
    [
      'slice',
      'strategy',
      'labelled_frames',
      'correct_retained',
      'wrong_retained',
      'correct_rejected',
      'wrong_rejected',
      'coverage_of_baseline_accepted',
    ],
    [
      for (final e in slices.entries)
        if (e.key.endsWith('_stable'))
          for (final p in policies)
            [
              e.key,
              p,
              e.value.length,
              e.value.where((f) => f.kind == 'CORRECT' && f.keep(p)).length,
              e.value
                  .where((f) => f.accepted && f.kind != 'CORRECT' && f.keep(p))
                  .length,
              e.value.where((f) => f.kind == 'CORRECT' && !f.keep(p)).length,
              e.value
                  .where((f) => f.accepted && f.kind != 'CORRECT' && !f.keep(p))
                  .length,
              e.value.where((f) => f.accepted).isEmpty
                  ? null
                  : e.value.where((f) => f.keep(p)).length /
                        e.value.where((f) => f.accepted).length,
            ],
    ],
  );
  final regionRows = <List<Object?>>[];
  for (final id in ['V01', 'V02', 'V03', 'V04']) {
    for (final type in [
      'PRE_NOTE_SILENCE',
      'RELEASE_DECAY',
      'POST_NOTE_BACKGROUND',
    ]) {
      final a = frames
          .where((f) => f.id == id && f.region?.type == type)
          .toList();
      if (a.isEmpty) continue;
      final voiced = a.where((f) => f.accepted).toList();
      final pitchCounts = <int, int>{};
      for (final f in voiced) {
        pitchCounts.update(midi(f.hz).round(), (v) => v + 1, ifAbsent: () => 1);
      }
      final ranked = pitchCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      regionRows.add([
        id,
        type,
        a.length,
        voiced.length,
        voiced.where((f) => f.conf >= .85).length,
        median(a.map((f) => f.rms)),
        median(voiced.map((f) => f.rms)),
        median(voiced.map((f) => f.conf)),
        median(voiced.map((f) => n(f.selected ?? {}, 'cmnd'))),
        median(voiced.map((f) => f.margin)),
        ranked.take(3).map((e) => '${e.key}:${e.value}').join(';'),
        type == 'PRE_NOTE_SILENCE'
            ? 'visible_pre_key_down'
            : 'key_up_occluded_or_decay_uncertain',
      ]);
    }
  }
  final h = [
    'case_id',
    'region',
    'total_frames',
    'accepted_voiced',
    'high_confidence_accepted',
    'median_all_rms',
    'median_voiced_rms',
    'median_voiced_confidence',
    'median_selected_cmnd',
    'median_candidate_margin',
    'top_rounded_midi_counts',
    'truth_quality',
  ];
  write(
    'raw_voicing_silence_analysis.csv',
    h,
    regionRows.where((r) => r[1] != 'RELEASE_DECAY'),
  );
  write(
    'raw_voicing_decay_analysis.csv',
    h,
    regionRows.where((r) => r[1] == 'RELEASE_DECAY'),
  );
  final noiseRows = <List<Object?>>[];
  for (final id in ids) {
    final a = frames.where((f) => f.id == id).toList();
    final low = a
        .where((f) => ['PRE_NOTE_SILENCE', 'LEADING'].contains(f.region?.type))
        .toList();
    final stable = a.where((f) => (f.region?.expected ?? 0) > 0).toList();
    if (low.isEmpty || stable.isEmpty) continue;
    noiseRows.add([
      id,
      low.length,
      stable.length,
      median(low.map((f) => f.rms)),
      median(stable.map((f) => f.rms)),
      low.where((f) => f.accepted).length,
      stable.where((f) => f.kind == 'CORRECT').length,
      id.startsWith('V') ? 'visual_pre_key_down' : 'derived_leading_region',
    ]);
  }
  write('raw_voicing_noise_floor.csv', [
    'case_id',
    'background_frames',
    'stable_frames',
    'background_median_rms',
    'stable_median_rms',
    'background_accepted',
    'stable_correct',
    'background_truth_quality',
  ], noiseRows);
  final taxonomy = <List<Object?>>[];
  for (final id in ['V01', 'V02', 'V03', 'V04']) {
    final a = frames.where((f) => f.id == id).toList();
    final pre = a
        .where((f) => f.region?.type == 'PRE_NOTE_SILENCE' && f.accepted)
        .toList();
    final post = a
        .where((f) => f.region?.type == 'POST_NOTE_BACKGROUND' && f.accepted)
        .toList();
    final decay = a
        .where((f) => f.region?.type == 'RELEASE_DECAY' && f.accepted)
        .toList();
    final stableDown = a
        .where(
          (f) => f.region?.type == 'STABLE_SUSTAIN' && f.kind == 'OCTAVE_DOWN',
        )
        .toList();
    for (final (name, part, proof) in [
      ('PRE_NOTE_FALSE_PITCH', pre, 'independent_visible_key_down'),
      ('POST_NOTE_PITCH_ESTIMATE', post, 'low_confidence_key_up'),
      ('DECAY_OR_SUSTAIN_UNCERTAIN', decay, 'release_truth_not_independent'),
      (
        'STABLE_SUSTAIN_OCTAVE_DOWN',
        stableDown,
        'musical_truth_and_conservative_window',
      ),
    ]) {
      taxonomy.add([
        name,
        id,
        part.length,
        median(part.map((f) => f.rms)),
        median(part.map((f) => f.conf)),
        median(part.map((f) => n(f.selected ?? {}, 'cmnd'))),
        proof,
      ]);
    }
  }
  write('raw_voicing_failure_taxonomy.csv', [
    'failure_family',
    'case_id',
    'frames',
    'median_rms',
    'median_confidence',
    'median_selected_cmnd',
    'truth_quality',
  ], taxonomy);
  final syn = csv.table('.raw_voicing_tmp/new_synthetic_baseline.csv');
  final synManifest = {
    for (final r in csv.table('raw_voicing_synthetic_manifest.csv'))
      r['case_id']!: r,
  };
  final synRows = <List<Object?>>[];
  for (final e in synManifest.entries) {
    final a = syn
        .where(
          (r) =>
              r['caseId'] == e.key &&
              n(r, 'timestamp') >= .25 &&
              n(r, 'timestamp') < .85,
        )
        .toList();
    int kept(String p) => a.where((r) {
      final hz = n(r, 'pitchHz'), rms = n(r, 'rms'), conf = n(r, 'confidence');
      final accepted =
          hz > 0 && n(r, 'isSilent') == 0 && conf >= .55 && rms > .001;
      return accepted &&
          (p == 'A' ||
              p == 'B' && rms >= .010 ||
              p == 'C' && conf >= .950 ||
              p == 'D' && rms >= .010 && conf >= .950);
    }).length;
    final voiced = a
        .where((r) => n(r, 'pitchHz') > 0 && n(r, 'isSilent') == 0)
        .toList();
    synRows.add([
      e.key,
      e.value['family'],
      e.value['expected_hz'],
      a.length,
      kept('A'),
      kept('B'),
      kept('C'),
      kept('D'),
      median(voiced.map((r) => n(r, 'pitchHz'))),
      median(voiced.map((r) => n(r, 'confidence'))),
      median(a.map((r) => n(r, 'rms'))),
    ]);
  }
  final sh = [
    'case_id',
    'family',
    'expected_hz',
    'window_frames',
    'A_retained',
    'B_RMS_010_retained',
    'C_CONF_950_retained',
    'D_conservative_retained',
    'median_voiced_hz',
    'median_voiced_confidence',
    'median_rms',
  ];
  write(
    'raw_voicing_synthetic_silence_noise.csv',
    sh,
    synRows.where(
      (r) => ![
        'f_over_2_interference',
        'true_lower_octave',
        'true_upper_octave',
      ].contains(r[1]),
    ),
  );
  write(
    'raw_voicing_synthetic_octave_grid.csv',
    sh,
    synRows.where(
      (r) => [
        'f_over_2_interference',
        'true_lower_octave',
        'true_upper_octave',
      ].contains(r[1]),
    ),
  );
  write(
    'raw_voicing_real_case_safety.csv',
    [
      'case_id',
      'strategy',
      'stable_labelled_frames',
      'baseline_correct',
      'correct_retained',
      'correct_rejected',
      'baseline_wrong',
      'wrong_retained',
      'wrong_rejected',
    ],
    [
      for (final id in ids)
        for (final p in policies)
          () {
            final a = frames
                .where((f) => f.id == id && (f.region?.expected ?? 0) > 0)
                .toList();
            return [
              id,
              p,
              a.length,
              a.where((f) => f.kind == 'CORRECT').length,
              a.where((f) => f.kind == 'CORRECT' && f.keep(p)).length,
              a.where((f) => f.kind == 'CORRECT' && !f.keep(p)).length,
              a.where((f) => f.accepted && f.kind != 'CORRECT').length,
              a
                  .where((f) => f.accepted && f.kind != 'CORRECT' && f.keep(p))
                  .length,
              a
                  .where((f) => f.accepted && f.kind != 'CORRECT' && !f.keep(p))
                  .length,
            ];
          }(),
    ],
  );
  final syntheticAnnotations = <String, List<Region>>{};
  for (final a in csv.table('pitch_candidate_annotations.csv')) {
    final id = a['caseId']!;
    if (!(id.startsWith('S') || id.startsWith('H'))) continue;
    (syntheticAnnotations[id] ??= []).add(
      Region(
        id,
        a['region'] ?? 'stable',
        n(a, 'startSeconds'),
        n(a, 'endSeconds'),
        n(a, 'expectedMidi'),
        'frozen_synthetic_truth',
        'exact',
      ),
    );
  }
  for (final (path, out) in [
    (
      'pitch_candidate_synthetic_features.csv',
      'raw_voicing_original_synthetic_safety.csv',
    ),
    (
      'pitch_candidate_heldout_synthetic_features.csv',
      'raw_voicing_heldout_synthetic_safety.csv',
    ),
  ]) {
    final grouped = <String, List<Map<String, String>>>{};
    for (final r in csv.table(path)) {
      (grouped[r['caseId']!] ??= []).add(r);
    }
    final rows = <List<Object?>>[];
    for (final entry in grouped.entries) {
      final a = entry.value
          .where(
            (r) => (syntheticAnnotations[entry.key] ?? []).any(
              (a) =>
                  a.expected > 0 &&
                  n(r, 'timestamp') >= a.start &&
                  n(r, 'timestamp') < a.end,
            ),
          )
          .toList();
      if (a.isEmpty) continue;
      for (final p in [
        'A_PRODUCTION',
        'B_RMS_010',
        'C_CONF_950',
        'D_CONSERVATIVE',
      ]) {
        var correct = 0, wrong = 0, correctLost = 0, wrongRemoved = 0;
        for (final r in a) {
          final expected = (syntheticAnnotations[entry.key] ?? [])
              .firstWhere(
                (x) =>
                    n(r, 'timestamp') >= x.start &&
                    n(r, 'timestamp') < x.end &&
                    x.expected > 0,
              )
              .expected;
          final hz = n(r, 'pitchHz'),
              conf = n(r, 'confidence'),
              rms = n(r, 'rms');
          final accepted =
              hz > 0 && n(r, 'isSilent') == 0 && conf >= .55 && rms > .001;
          if (!accepted) continue;
          final isCorrect = (midi(hz) - expected).abs() < 1;
          final keep =
              p == 'A_PRODUCTION' ||
              p == 'B_RMS_010' && rms >= .010 ||
              p == 'C_CONF_950' && conf >= .950 ||
              p == 'D_CONSERVATIVE' && rms >= .010 && conf >= .950;
          if (isCorrect && keep) correct++;
          if (!isCorrect && keep) wrong++;
          if (isCorrect && !keep) correctLost++;
          if (!isCorrect && !keep) wrongRemoved++;
        }
        rows.add([
          entry.key,
          p,
          a.length,
          correct,
          wrong,
          correctLost,
          wrongRemoved,
        ]);
      }
    }
    write(out, [
      'case_id',
      'strategy',
      'labelled_frames',
      'correct_retained',
      'wrong_retained',
      'correct_rejected',
      'wrong_rejected',
    ], rows);
  }
  stdout.writeln(
    'real cases=${ids.length} real frames=${frames.length} V02 stable=${v02.length}',
  );
}
