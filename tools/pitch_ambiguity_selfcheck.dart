import 'pitch_ambiguity_investigate.dart' as audit;
import 'pitch_candidate_evaluate.dart' as prior;

void expectCondition(bool condition, String reason) {
  if (!condition) throw StateError(reason);
}

void main() {
  final shorter = prior.Candidate({
    'hz': '350',
    'cmnd': '.24',
    'spectralFundamental': '55',
    'spectralH2': '20',
    'spectralH3': '10',
    'spectralHalf': '2',
  });
  final longer = prior.Candidate({
    'hz': '175',
    'cmnd': '.08',
    'spectralFundamental': '2',
    'spectralH2': '55',
    'spectralH3': '2',
    'spectralHalf': '1',
  });
  Map<String, String> source(String hz) => {
    'caseId': 'T01',
    'sample': '0',
    'timestamp': '1',
    'pitchHz': hz,
    'confidence': '.9',
    'rms': '.02',
    'onsetStrength': '.1',
    'energy': '.0004',
    'peak': '.04',
  };
  final voiced = audit.Frame(
    source('175'),
    [shorter, longer],
    null,
    'interference_350_150_10',
    175,
    .1,
  );
  expectCondition(!voiced.labelled, 'Missing truth became a pitch label');
  expectCondition(
    voiced.abstain('F2_DISAGREEMENT'),
    'Contradictory candidates were not flagged',
  );
  expectCondition(
    audit.taxonomy(voiced) == 'independent_low_interferer',
    'Known synthetic recipe lost provenance',
  );
  final unvoiced = audit.Frame(
    source('0'),
    [shorter, longer],
    null,
    'unknown',
    175,
    .1,
  );
  expectCondition(
    [
      'F1_CMND',
      'F2_DISAGREEMENT',
      'F3_MARGIN',
      'F4_DECAY_INSTABILITY',
      'F5_CONSERVATIVE',
    ].every((policy) => !unvoiced.abstain(policy)),
    'Unvoiced frame counted as abstained voiced frame',
  );
  print('4 pitch-ambiguity self-checks passed');
}
