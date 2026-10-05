// Frozen diagnostic policies from the previous segmentation calibration.
// Musical labels are consulted only after detection, for evaluation.
import 'segmentation_diagnostics.dart' as d;
import 'pitch_candidate_evaluate.dart' as csv;

void main() {
  final raw = <String, List<d.Frame>>{};
  for (final row in csv.table('video_boundary_raw_features.csv')) {
    (raw[row['case_id']!] ??= []).add(d.Frame(row));
  }
  final base = <String, List<d.Segment>>{};
  for (final row in csv.table('video_segmentation_baseline.csv')) {
    (base[row['case_id']!] ??= []).add(
      d.Segment(
        csv.number(row, 'start_seconds'),
        csv.number(row, 'end_seconds'),
        csv.number(row, 'fractional_midi'),
        csv.number(row, 'mean_confidence'),
        csv.number(row, 'mean_rms'),
      ),
    );
  }
  const truth = <String, List<int>>{
    'V01': [65],
    'V02': [64],
    'V03': [65, 65],
    'V04': [65, 64],
  };
  const policies = <d.Policy>[
    d.Policy('B_PITCH_CONFIRM_3', anchor: true, confirm: 3, onset: false),
    d.Policy('C_ONSET_ASSISTED', anchor: true, confirm: 3, pitch: .8),
    d.Policy('D_GAP_3', gap: 3),
    d.Policy('E_COMBINED', anchor: true, confirm: 3, gap: 3, pitch: .75),
  ];
  final rows = <String>[
    'case_id,policy,detected_count,detected_midi,expected_count,expected_midi,sequence_exact,count_error,edit_distance,parameters_frozen',
  ];
  for (final id in truth.keys) {
    final variants = <String, List<d.Segment>>{'A_PRODUCTION': base[id]!};
    for (final p in policies) {
      variants[p.name] = d.detect(raw[id]!, p);
    }
    for (final entry in variants.entries) {
      final found = entry.value.map((x) => x.rounded).toList();
      final expected = truth[id]!;
      rows.add(
        '$id,${entry.key},${found.length},${found.join('>')},'
        '${expected.length},${expected.join('>')},${found.join('>') == expected.join('>')},'
        '${found.length - expected.length},${d.editDistance(found, expected)},true',
      );
    }
  }
  d.write('video_segmentation_strategy_comparison.csv', rows);
}
