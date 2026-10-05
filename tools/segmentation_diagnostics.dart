// Score-independent offline experiments. Truth is used only after segmentation.
import 'dart:io';
import 'dart:math' as math;
import 'pitch_candidate_evaluate.dart' as csv;

class Frame {
  Frame(Map<String, String> r)
    : sample = csv.number(r, 'start_sample').round(),
      valid = csv.number(r, 'valid_samples').round(),
      onsetSample = csv.number(r, 'onset_sample').round(),
      hz = csv.number(r, 'pitch_hz'),
      confidence = csv.number(r, 'confidence'),
      rms = csv.number(r, 'rms'),
      energy = csv.number(r, 'energy'),
      onsetStrength = csv.number(r, 'onset_strength'),
      onset = csv.number(r, 'onset_candidate') > 0,
      silent = csv.number(r, 'is_silent') > 0;
  final int sample, valid, onsetSample;
  final double hz, confidence, rms, energy, onsetStrength;
  final bool onset, silent;
  double get start => sample / 44100;
  double get end => (sample + valid) / 44100;
  bool get voiced => !silent && hz > 0 && confidence >= .55 && rms > .001;
  double get midi => 69 + 12 * math.log(hz / 440) / math.ln2;
}

class Segment {
  Segment(this.start, this.end, this.midi, this.confidence, this.rms);
  final double start, end, midi, confidence, rms;
  int get rounded => midi.round();
}

class Policy {
  const Policy(
    this.name, {
    this.confirm = 1,
    this.anchor = false,
    this.pitch = .8,
    this.gap = 2,
    this.onset = true,
    this.minDuration = .055,
  });
  final String name;
  final int confirm, gap;
  final bool anchor, onset;
  final double pitch, minDuration;
}

double median(Iterable<double> source) {
  final a = source.where((x) => x.isFinite).toList()..sort();
  return a.isEmpty ? double.nan : a[a.length ~/ 2];
}

void write(String path, List<String> rows) =>
    File(path).writeAsStringSync('${rows.join('\n')}\n');

List<Segment> detect(List<Frame> frames, Policy p) {
  final out = <Segment>[];
  final active = <Frame>[];
  final pending = <Frame>[];
  double start = 0;
  var gap = 0;
  double mean(Iterable<Frame> values) {
    var sum = 0.0, weight = 0.0;
    for (final f in values) {
      sum += f.midi * f.confidence;
      weight += f.confidence;
    }
    return sum / weight;
  }

  void finish(double end) {
    if (active.isNotEmpty &&
        end - start >= p.minDuration &&
        active.length >= 2) {
      out.add(
        Segment(
          start,
          end,
          mean(active),
          median(active.map((f) => f.confidence)),
          median(active.map((f) => f.rms)),
        ),
      );
    }
    active.clear();
    pending.clear();
  }

  for (final f in frames) {
    if (!f.voiced) {
      gap++;
      if (gap >= p.gap && active.isNotEmpty) {
        if (pending.isNotEmpty) {
          active.addAll(pending);
          pending.clear();
        }
        finish(active.last.end);
      }
      continue;
    }
    gap = 0;
    if (active.isEmpty) {
      start = f.start;
      active.add(f);
      continue;
    }
    final onset =
        p.onset &&
        f.onset &&
        f.onsetSample >= f.sample &&
        f.onsetSample < f.sample + f.valid &&
        f.start - start > p.minDuration;
    if (onset) {
      if (pending.isNotEmpty) {
        active.addAll(pending);
        pending.clear();
      }
      final boundary = f.onsetSample / 44100;
      finish(boundary);
      start = boundary;
      active.add(f);
      continue;
    }
    final reference = p.anchor
        ? mean(active.take(math.min(6, active.length)))
        : mean(active);
    final delta = (f.midi - reference).abs();
    if (delta >= p.pitch) {
      pending.add(f);
      final center = median(pending.map((x) => x.midi));
      final consistent = pending
          .where((x) => (x.midi - center).abs() < .35)
          .length;
      if (pending.length >= p.confirm && consistent >= p.confirm) {
        final buffered = pending.toList();
        pending.clear();
        final boundary = buffered.first.start;
        finish(boundary);
        start = boundary;
        active.addAll(buffered);
      } else if (pending.length >= p.confirm + 3) {
        active.addAll(pending);
        pending.clear();
      }
    } else {
      if (pending.isNotEmpty) {
        active.addAll(pending);
        pending.clear();
      }
      active.add(f);
    }
  }
  if (active.isNotEmpty) {
    if (pending.isNotEmpty) active.addAll(pending);
    finish(active.last.end);
  }
  return out;
}

int editDistance(List<int> actual, List<int> expected) {
  var row = List<int>.generate(expected.length + 1, (i) => i);
  for (var i = 0; i < actual.length; i++) {
    final next = List<int>.filled(expected.length + 1, 0);
    next[0] = i + 1;
    for (var j = 0; j < expected.length; j++) {
      next[j + 1] = math.min(
        math.min(next[j] + 1, row[j + 1] + 1),
        row[j] + (actual[i] == expected[j] ? 0 : 1),
      );
    }
    row = next;
  }
  return row.last;
}

void main() {
  final truth = <String, List<int>>{};
  for (var i = 1; i <= 12; i++) {
    final id = 'N${i.toString().padLeft(2, '0')}';
    truth[id] = switch (i) {
      1 => [53],
      2 => [65],
      3 => [77],
      4 => [52],
      5 => [64],
      6 => [76],
      7 => [53, 65],
      8 => [65, 53],
      9 => [65, 77],
      10 => [77, 65],
      11 => [65, 65],
      _ => [65],
    };
  }
  for (var i = 1; i <= 10; i++) {
    final id = 'P${i.toString().padLeft(2, '0')}';
    truth[id] = i <= 6
        ? [65, 64]
        : i == 7
        ? [65, 65]
        : i == 8
        ? [64, 64]
        : [62];
  }
  for (var i = 1; i <= 5; i++) {
    truth['C${i.toString().padLeft(2, '0')}'] = [60, 62, 64, 65, 64, 62, 60];
  }
  truth.addAll({
    'R01': [53],
    'R02': [65],
    'R03': [53, 65],
    'R04': [65, 53],
    'R05': [52],
    'R06': [64],
  });
  final raw = <String, List<Frame>>{};
  for (final r in csv.table('segmentation_raw_features.csv')) {
    (raw[r['case_id']!] ??= []).add(Frame(r));
  }
  final baseline = <String, List<Segment>>{};
  for (final r in csv.table('segmentation_production_baseline.csv')) {
    (baseline[r['case_id']!] ??= []).add(
      Segment(
        csv.number(r, 'start_seconds'),
        csv.number(r, 'end_seconds'),
        csv.number(r, 'fractional_midi'),
        csv.number(r, 'median_pitch_confidence'),
        csv.number(r, 'median_rms'),
      ),
    );
  }
  const policies = [
    Policy('B_PITCH_CONFIRM_3', anchor: true, confirm: 3),
    Policy('C_ONSET_ASSISTED', confirm: 3, anchor: true, pitch: .8),
    Policy('D_GAP_3', gap: 3),
    Policy('E_COMBINED', anchor: true, confirm: 3, gap: 3, pitch: .75),
  ];
  // B additionally avoids an onset-only split; C retains the production onset.
  const b = Policy('B_PITCH_CONFIRM_3', anchor: true, confirm: 3, onset: false);
  final variants = [b, ...policies.skip(1)];
  final comparison = <String>[
    'case_id,set,policy,expected_count,detected_count,count_error,expected_midi,detected_midi,sequence_exact,edit_distance,median_segment_duration',
  ];
  final gt = <String>[
    'case_id,source_label,expected_count,expected_midi,ground_truth_quality,independent_attack_times,production_scoring',
  ];
  final taxonomy = <String>[
    'case_id,expected_count,baseline_count,count_excess,count_deficit,exact_sequence,category,first_supported_layer,independent_timing',
  ];
  final evidence = <String>[
    'case_id,boundary_index,time_seconds,prev_segment_midi,next_segment_midi,pitch_delta_cents,onset_strength_near,voiced_before,voiced_after,median_rms_before,median_rms_after,median_confidence_before,median_confidence_after,unvoiced_gap_frames,reason_in_production',
  ];
  final sensitivity = <String>[
    'policy,confirmation_frames,pitch_threshold_semitones,gap_frames,development_sequence_exact,validation_sequence_exact,development_count_error_abs,validation_count_error_abs,R_single_exact,R_octave_exact,C_F4E4_sequence_exact,P_repeated_exact',
  ];
  final ids = raw.keys.toList()..sort();
  for (final id in ids) {
    final expected = truth[id];
    gt.add(
      '$id,${id.startsWith('R')
          ? 'targeted_real'
          : id.startsWith('C')
          ? 'controlled_piano'
          : id.startsWith('P')
          ? 'controlled_boundary'
          : 'octave_real'},${expected?.length ?? ''},${expected?.join('>') ?? ''},${expected == null ? 'polyphonic_outside_V1' : 'musical_sequence_only'},none,${expected == null ? 'excluded' : 'included'}',
    );
    final current = baseline[id] ?? [];
    final observed = current.map((s) => s.rounded).toList();
    final exact = expected != null && observed.join('>') == expected.join('>');
    final excess = expected == null
        ? 0
        : math.max(0, current.length - expected.length);
    final deficit = expected == null
        ? 0
        : math.max(0, expected.length - current.length);
    final category = expected == null
        ? 'polyphonic_excluded'
        : exact
        ? 'correct_sequence'
        : excess > 0
        ? 'over_count_mixed_cause'
        : deficit > 0
        ? 'under_count'
        : 'same_count_wrong_sequence';
    final firstLayer = id.startsWith('P')
        ? 'RAW_DSP_PREDOMINANT'
        : id.startsWith('C')
        ? 'SEGMENTATION_LIKELY'
        : id == 'R05' || id == 'R06'
        ? 'AMBIGUOUS_RELEASE_VOICING'
        : 'MIXED_OR_UNDETERMINED';
    taxonomy.add(
      '$id,${expected?.length ?? ''},${current.length},$excess,$deficit,$exact,$category,$firstLayer,no',
    );
    void compare(String name, List<Segment> found) {
      if (expected == null) {
        return;
      }
      final got = found.map((s) => s.rounded).toList();
      comparison.add(
        '$id,${id.startsWith('C') && int.parse(id.substring(1)) <= 3 || id.startsWith('P') && int.parse(id.substring(1)) <= 6 ? 'development' : 'validation'},$name,${expected.length},${got.length},${got.length - expected.length},${expected.join('>')},${got.join('>') == expected.join('>')},${editDistance(got, expected)},${median(found.map((s) => s.end - s.start))}',
      );
    }

    compare('A_PRODUCTION', current);
    for (final p in variants) {
      compare(p.name, detect(raw[id]!, p));
    }
    for (var j = 1; j < current.length; j++) {
      final at = current[j].start;
      final before = raw[id]!
          .where((f) => f.start >= at - .055 && f.start < at)
          .toList();
      final after = raw[id]!
          .where((f) => f.start >= at && f.start < at + .055)
          .toList();
      final near = raw[id]!
          .where(
            (f) => f.onset && (f.onsetSample / 44100 - at).abs() < 512 / 44100,
          )
          .toList();
      final prev = current[j - 1], next = current[j];
      final gap = raw[id]!
          .where(
            (f) => f.start >= prev.end && f.start < next.start && !f.voiced,
          )
          .length;
      evidence.add(
        '$id,$j,$at,${prev.midi},${next.midi},${100 * (next.midi - prev.midi)},${near.isEmpty ? '' : near.map((f) => f.onsetStrength).reduce(math.max)},${before.where((f) => f.voiced).length},${after.where((f) => f.voiced).length},${median(before.map((f) => f.rms))},${median(after.map((f) => f.rms))},${median(before.map((f) => f.confidence))},${median(after.map((f) => f.confidence))},$gap,',
      );
    }
  }
  // Freeze C01–C03 and P01–P06 as development; all others are validation.
  for (final confirm in [2, 3, 4]) {
    for (final threshold in [.65, .75, .85]) {
      for (final gap in [2, 3]) {
        final p = Policy(
          'sweep',
          anchor: true,
          confirm: confirm,
          pitch: threshold,
          gap: gap,
        );
        var devExact = 0,
            valExact = 0,
            devErr = 0,
            valErr = 0,
            rSingles = 0,
            rLeaps = 0,
            cBoundary = 0,
            pRepeat = 0;
        for (final id in ids) {
          final expected = truth[id];
          if (expected == null) continue;
          final got = detect(raw[id]!, p).map((s) => s.rounded).toList();
          final exact = got.join('>') == expected.join('>');
          final dev =
              id.startsWith('C') && int.parse(id.substring(1)) <= 3 ||
              id.startsWith('P') && int.parse(id.substring(1)) <= 6;
          if (dev) {
            if (exact) devExact++;
            devErr += (got.length - expected.length).abs();
          } else {
            if (exact) valExact++;
            valErr += (got.length - expected.length).abs();
          }
          if (['R01', 'R02', 'R05', 'R06'].contains(id) && exact) rSingles++;
          if (['R03', 'R04'].contains(id) && exact) rLeaps++;
          if (id.startsWith('C') && got.join('>').contains('65>64')) {
            cBoundary++;
          }
          if (['P07', 'P08', 'N11'].contains(id) && exact) pRepeat++;
        }
        sensitivity.add(
          'anchor_onset,$confirm,$threshold,$gap,$devExact,$valExact,$devErr,$valErr,$rSingles,$rLeaps,$cBoundary,$pRepeat',
        );
      }
    }
  }
  write('segmentation_ground_truth.csv', gt);
  write('segmentation_failure_taxonomy.csv', taxonomy);
  write('segmentation_boundary_evidence.csv', evidence);
  write('segmentation_strategy_comparison.csv', comparison);
  write('segmentation_parameter_sensitivity.csv', sensitivity);
  stdout.writeln(
    'cases=${ids.length} scored=${truth.length} baselineSegments=${baseline.values.fold<int>(0, (n, s) => n + s.length)}',
  );
}
