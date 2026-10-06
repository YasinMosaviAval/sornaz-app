// Reproducibility checks for the diagnostic safety blockers.
import 'pitch_candidate_evaluate.dart' as csv;

void require(bool condition, String detail) {
  if (!condition) throw StateError(detail);
}

void main() {
  final manifest = csv.table('raw_voicing_input_manifest.csv');
  final baseline = csv.table('raw_voicing_baseline_features.csv');
  require(
    manifest.length == 39 && baseline.length == 15214,
    'real input or feature corpus changed',
  );
  final silence = csv.table('raw_voicing_silence_analysis.csv');
  final pre = silence.where((r) => r['region'] == 'PRE_NOTE_SILENCE');
  require(
    pre.length == 4 &&
        pre.fold<int>(
              0,
              (n, r) => n + csv.number(r, 'accepted_voiced').round(),
            ) ==
            136,
    'independent pre-note false-voicing reproduction changed',
  );
  final v02 = csv.table('raw_voicing_v02_octave_analysis.csv');
  require(
    v02.length == 121 &&
        v02.every(
          (r) =>
              csv.number(r, 'production_hz') > 150 &&
              csv.number(r, 'production_hz') < 180 &&
              csv.number(r, 'upper_candidate_hz') > 300,
        ),
    'V02 lower selected / upper alternative evidence changed',
  );
  final synthetic = csv.table('raw_voicing_synthetic_silence_noise.csv');
  final background = synthetic.firstWhere((r) => r['case_id'] == 'Q005');
  final quiet = synthetic.firstWhere((r) => r['case_id'] == 'Q007');
  require(
    csv.number(background, 'C_CONF_950_retained') == 52 &&
        csv.number(quiet, 'B_RMS_010_retained') == 0,
    'voicing strategy safety counterexamples changed',
  );
  final regressions = csv.table('raw_voicing_prior_c_regression_recheck.csv');
  require(
    regressions.fold<int>(
              0,
              (n, r) => n + csv.number(r, 'A_octave_down').round(),
            ) ==
            448 &&
        regressions.fold<int>(
              0,
              (n, r) => n + csv.number(r, 'C_octave_down').round(),
            ) ==
            468,
    'frozen spectral C regression changed',
  );
  print('5 raw-voicing diagnostic checks passed');
}
