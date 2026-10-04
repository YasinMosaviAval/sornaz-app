import 'pitch_candidate_evaluate.dart' as evaluation;

void main() {
  final shorter = evaluation.Candidate({
    'hz': '350',
    'cmnd': '.23',
    'spectralFundamental': '50',
    'spectralH2': '20',
    'spectralH3': '10',
    'spectralHalf': '2',
  });
  final doubled = evaluation.Candidate({
    'hz': '175',
    'cmnd': '.08',
    'spectralFundamental': '2',
    'spectralH2': '50',
    'spectralH3': '3',
    'spectralHalf': '0',
  });
  final voiced = evaluation.decisions(175, .1, [shorter, doubled], 0);
  if (voiced['A_CURRENT']!.hz != 175 || voiced['C_SPECTRAL']!.hz != 350) {
    throw StateError('Candidate evaluation failed');
  }
  final unvoiced = evaluation.decisions(0, .1, [shorter, doubled], 0);
  if (unvoiced.values.any((result) => result.hz != 0)) {
    throw StateError('Candidate ranking manufactured a voiced frame');
  }
  if (evaluation.kind(174.614, 174.614) != evaluation.Kind.correct ||
      evaluation.kind(349.228, 174.614) != evaluation.Kind.up ||
      evaluation.kind(87.307, 174.614) != evaluation.Kind.down ||
      evaluation.kind(0, 174.614) != evaluation.Kind.unvoiced) {
    throw StateError('Octave confusion classification failed');
  }
  print('4 candidate-ranking self-checks passed');
}
