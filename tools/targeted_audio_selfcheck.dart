// Checks frozen diagnostic claims without using ground truth in the DSP path.
import 'dart:io';
import 'pitch_candidate_evaluate.dart' as csv;

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final manifest = csv.table('targeted_audio_input_manifest.csv');
  require(manifest.length == 8, 'eight inputs required');
  for (var i = 1; i <= 8; i++) {
    require(
      manifest[i - 1]['caseId'] == 'R${i.toString().padLeft(2, '0')}',
      'mapping order changed',
    );
  }
  final baseline = csv.table('targeted_audio_production_baseline.csv');
  final evidence = csv.table('targeted_audio_candidate_evidence.csv');
  require(
    baseline.length == 2692 && evidence.length == 6856,
    'frozen feature counts changed',
  );
  final rows = csv.table('targeted_audio_pretuning_validation.csv');
  final base = rows.where((r) => r['policy'] == 'A_CURRENT').toList();
  require(
    base.length == 8,
    'expected eight labelled monophonic stable regions',
  );
  require(
    base.every(
      (r) => csv.number(r, 'octaveDown') == 0 && csv.number(r, 'octaveUp') == 0,
    ),
    'new monophonic octave baseline changed',
  );
  final f2R06 = rows.singleWhere(
    (r) => r['caseId'] == 'R06' && r['policy'] == 'F2_DISAGREEMENT',
  );
  require(
    csv.number(f2R06, 'abstain') == 2,
    'F2 correct-coverage regression hidden',
  );
  final stress = csv.table('targeted_audio_octave_stress.csv');
  require(
    stress.length == 2 &&
        stress.every(
          (r) =>
              csv.number(r, 'nearUpper') == 0 &&
              csv.number(r, 'F2Abstained') == 0,
        ),
    'polyphonic ambiguity observation changed',
  );
  final regions = csv.table('targeted_audio_regions.csv');
  require(
    regions
        .where(
          (r) =>
              const ['release', 'background', 'combined'].contains(r['region']),
        )
        .every((r) => (r['expectedMidi'] ?? '').isEmpty),
    'release, background and polyphonic pitch truth must remain null',
  );
  stdout.writeln('6 targeted-audio diagnostic checks passed');
}
