// Targeted, diagnostic-only analysis of frozen raw features. No production import.
import 'dart:io';
import 'dart:math' as math;
import 'pitch_candidate_evaluate.dart' as csv;

double v(Map<String, String> r, String k) => csv.number(r, k);
String q(Object? x) => '"${(x ?? '').toString().replaceAll('"', '""')}"';
void write(String path, List<String> head, Iterable<List<Object?>> rows) {
  File(path).writeAsStringSync(
    '${head.map(q).join(',')}\n${rows.map((r) => r.map(q).join(',')).join('\n')}\n',
  );
}

double med(Iterable<double> xs) {
  final a = xs.where((x) => x.isFinite).toList()..sort();
  return a.isEmpty ? double.nan : a[a.length ~/ 2];
}

double spread(Iterable<double> xs) {
  final a = xs.where((x) => x.isFinite).toList();
  final m = med(a);
  return med(a.map((x) => (x - m).abs()));
}

bool accepted(Map<String, String> r) => r['segmenter_accepts'] == 'true';
double cents(double a, double b) =>
    a > 0 && b > 0 ? 1200 * math.log(a / b) / math.ln2 : double.infinity;

void main() {
  final frames = csv.table('raw_voicing_baseline_features.csv');
  final evidence = csv.table('raw_voicing_candidate_evidence.csv');
  final selected = <String, Map<String, String>>{};
  for (final e in evidence) {
    if (e['selected'] == '1') {
      selected['${e['case_id']}:${e['sample']}'] = e;
    }
  }
  final summary = <List<Object?>>[];
  final trackRows = <List<Object?>>[];
  final compare = <List<Object?>>[];
  for (final id in ['V01', 'V02', 'V03', 'V04']) {
    final all = frames.where((r) => r['case_id'] == id).toList();
    final pre = all.where((r) => r['region'] == 'PRE_NOTE_SILENCE').toList();
    final post = all
        .where((r) => r['region'] == 'POST_NOTE_BACKGROUND')
        .toList();
    final voiced = pre.where(accepted).toList();
    final ev = [
      for (final r in voiced)
        if (selected['$id:${r['frame_start_sample']}'] case final e?) e,
    ];
    final tracks = <List<Map<String, String>>>[];
    for (final r in all) {
      if (!accepted(r)) continue;
      if (tracks.isEmpty ||
          v(r, 'frame_index') - v(tracks.last.last, 'frame_index') > 1 ||
          cents(v(r, 'pitch_hz'), v(tracks.last.last, 'pitch_hz')).abs() >
              100) {
        tracks.add([r]);
      } else {
        tracks.last.add(r);
      }
    }
    final preTracks = tracks
        .where((t) => t.first['region'] == 'PRE_NOTE_SILENCE')
        .toList();
    summary.add([
      id,
      pre.length,
      voiced.length,
      med(voiced.map((r) => v(r, 'pitch_hz'))),
      spread(voiced.map((r) => v(r, 'pitch_hz'))),
      med(voiced.map((r) => v(r, 'rms'))),
      med(voiced.map((r) => v(r, 'pitch_confidence'))),
      pre.isEmpty ? 0 : voiced.length / pre.length,
      preTracks.isEmpty ? 0 : preTracks.map((t) => t.length).reduce(math.max),
      preTracks.length,
      med(ev.map((e) => v(e, 'spectral_F'))),
      med(ev.map((e) => v(e, 'spectral_H2'))),
      med(ev.map((e) => v(e, 'spectral_H3'))),
      post.length,
      post.where(accepted).length,
      'PHYSICAL SOURCE UNKNOWN',
    ]);
    var bReject = 0, cReject = 0;
    for (var i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      final start = t.first;
      final startIndex = all.indexOf(start);
      final before = all.skip(math.max(0, startIndex - 8)).take(8).toList();
      final base = med(before.map((r) => v(r, 'rms')));
      final peak = t.take(5).map((r) => v(r, 'rms')).fold(0.0, math.max);
      final ratio = base > 0 ? peak / base : double.infinity;
      final onset = t
          .take(5)
          .map((r) => v(r, 'onset_strength'))
          .fold(0.0, math.max);
      final event = ratio >= 2 || onset >= .20;
      final preOnly = t.every((r) => r['region'] == 'PRE_NOTE_SILENCE');
      // C remembers a track only after >= 0.25 s of uninterrupted presence;
      // this cannot reject its initial frames without retrospective delay.
      final memory = preOnly && t.length >= 22 && !event;
      if (preOnly) {
        if (!event) bReject += t.length;
        if (memory) cReject += math.max(0, t.length - 21);
      }
      trackRows.add([
        id,
        i + 1,
        start['region'],
        t.last['region'],
        start['timestamp_seconds'],
        t.last['timestamp_seconds'],
        t.length,
        med(t.map((r) => v(r, 'pitch_hz'))),
        spread(t.map((r) => v(r, 'pitch_hz'))),
        med(t.map((r) => v(r, 'rms'))),
        onset,
        ratio,
        event,
        memory,
        preOnly ? 'independent_negative' : 'derived_or_unlabelled',
      ]);
    }
    compare.add([id, 'A_CURRENT', voiced.length, 0, 'baseline']);
    compare.add([
      id,
      'B_NEW_EVENT',
      voiced.length - bReject,
      bReject,
      'track-start RMS ratio >=2 or onset >=0.20',
    ]);
    compare.add([
      id,
      'C_BACKGROUND_MEMORY',
      voiced.length - cReject,
      cReject,
      'same pitch >=22 frames without new event; retrospective delay unavailable',
    ]);
  }
  write('background_147_summary.csv', [
    'case_id',
    'pre_frames',
    'pre_accepted',
    'median_hz',
    'hz_mad',
    'median_rms',
    'median_confidence',
    'occupancy',
    'longest_pre_track_frames',
    'pre_tracks',
    'selected_F_median',
    'selected_H2_median',
    'selected_H3_median',
    'post_frames_derived',
    'post_accepted_derived',
    'physical_source',
  ], summary);
  write('background_147_temporal_tracks.csv', [
    'case_id',
    'track_index',
    'start_region',
    'end_region',
    'start_seconds',
    'end_seconds',
    'frames',
    'median_hz',
    'hz_mad',
    'median_rms',
    'early_peak_onset',
    'early_rms_ratio',
    'new_event_evidence',
    'background_memory_after_22_frames',
    'truth_quality',
  ], trackRows);
  write('background_context_strategy_comparison.csv', [
    'case_id',
    'strategy',
    'pre_accepted_retained',
    'pre_rejected',
    'rule',
  ], compare);

  // Six deterministic feature-level counterexamples. These test only the
  // contextual decision, not native YIN or acoustic realism.
  final controls = <(String, String, double, double, double, bool, String)>[
    (
      'T01',
      'persistent periodic background only',
      147,
      0,
      double.infinity,
      false,
      'Same signal can be labelled differently from T02',
    ),
    (
      'T02',
      'quiet intentional note from recording start',
      0,
      147,
      double.infinity,
      true,
      'Same .008*sin(2*pi*147*t) waveform as T01; intent is unobservable',
    ),
    (
      'T03',
      'background then different-frequency note',
      147,
      329.628,
      3,
      true,
      'Clear relative energy change',
    ),
    (
      'T04',
      'background then same-frequency clear attack',
      147,
      147,
      3,
      true,
      'Clear relative energy change',
    ),
    (
      'T05',
      'background then same-frequency soft attack',
      147,
      147,
      1.1,
      true,
      'Weak energy change; onset below .20',
    ),
    (
      'T06',
      'legato transition with weak onset',
      329.628,
      349.228,
      1.1,
      true,
      'Pitch changes but onset/energy event is weak',
    ),
  ];
  write(
    'background_context_counterexamples.csv',
    [
      'case_id',
      'diagnostic_recipe',
      'background_hz',
      'new_hz',
      'early_rms_ratio',
      'intentional_event',
      'B_new_event_retained',
      'C_background_memory_retained',
      'B_safety',
      'C_safety',
      'scope_note',
    ],
    [
      for (final (id, recipe, background, note, ratio, intent, noteText)
          in controls)
        [
          id,
          recipe,
          background,
          note,
          ratio,
          intent,
          ratio >= 2,
          id == 'T01' || id == 'T02' ? false : ratio >= 2,
          (intent == (ratio >= 2)) ? 'PASS' : 'FAIL',
          id == 'T01'
              ? 'PASS_AFTER_DELAY_ONLY'
              : id != 'T02' && ratio >= 2
              ? 'PASS'
              : 'FAIL',
          '$noteText; deterministic feature-level control, not native-DSP output',
        ],
    ],
  );
}
