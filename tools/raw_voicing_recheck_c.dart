// Re-evaluate frozen A/C policies on newly rerun original 92-case traces.
import 'dart:io';
import 'pitch_candidate_evaluate.dart' as p;

void main() {
  final annotations = <String, List<Map<String, String>>>{};
  for (final a in p.table('pitch_candidate_annotations.csv')) {
    if (a['caseId']!.startsWith('S')) (annotations[a['caseId']!] ??= []).add(a);
  }
  final candidates = <String, List<p.Candidate>>{};
  for (final row in p.table('.raw_voicing_tmp/original_probe_evidence.csv')) {
    (candidates[p.key(row['caseId']!, row['sample']!)] ??= []).add(
      p.Candidate(row),
    );
  }
  final tally = <String, List<int>>{};
  for (final row in p.table('.raw_voicing_tmp/original_probe_features.csv')) {
    final id = row['caseId']!, time = p.number(row, 'timestamp');
    final region = (annotations[id] ?? [])
        .where(
          (a) =>
              p.number(a, 'expectedMidi') > 0 &&
              time >= p.number(a, 'startSeconds') &&
              time < p.number(a, 'endSeconds'),
        )
        .toList();
    if (region.isEmpty) continue;
    final expected = p.midiHz(p.number(region.first, 'expectedMidi'));
    final aHz = p.number(row, 'pitchHz');
    final cHz = p
        .decisions(
          aHz,
          p.number(row, 'onsetStrength'),
          candidates[p.key(id, row['sample']!)] ?? [],
          0,
        )['C_SPECTRAL']!
        .hz;
    final t = tally.putIfAbsent(id, () => List<int>.filled(6, 0));
    final a = p.kind(aHz, expected), c = p.kind(cHz, expected);
    t[0]++;
    if (a == p.Kind.down) t[1]++;
    if (c == p.Kind.down) t[2]++;
    if (a == p.Kind.correct && c == p.Kind.down) t[3]++;
    if (a == p.Kind.down && c == p.Kind.correct) t[4]++;
    if (a == p.Kind.correct && c == p.Kind.correct) t[5]++;
  }
  final rows = <String>[
    'case_id,labelled_frames,A_octave_down,C_octave_down,A_correct_to_C_down,A_down_to_C_correct,both_correct',
  ];
  for (final id in tally.keys.toList()..sort()) {
    rows.add('$id,${tally[id]!.join(',')}');
  }
  File(
    'raw_voicing_prior_c_regression_recheck.csv',
  ).writeAsStringSync('${rows.join('\n')}\n');
  final all = tally.values;
  int sum(int index) => all.fold(0, (v, a) => v + a[index]);
  stdout.writeln(
    'cases=${tally.length} A_down=${sum(1)} C_down=${sum(2)} A_correct_to_C_down=${sum(3)} A_down_to_C_correct=${sum(4)}',
  );
}
