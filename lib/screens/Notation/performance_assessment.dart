import 'dart:math' as math;

import 'note_alignment.dart';
import 'reference_timeline.dart';

/// Observations for one alignment event. Null means the event has no pair.
class NoteAssessment {
  const NoteAssessment({
    required this.alignment,
    required this.pitchCents,
    required this.onsetBeatOffset,
    required this.durationRatio,
    required this.soundStrengthRms,
    required this.relativeSoundStrength,
    required this.soundingDurationRatio,
  });

  final AlignedNote alignment;
  AlignmentMark get mark => alignment.mark;

  /// Signed: positive is sharp, negative is flat.
  final double? pitchCents;

  /// Signed: positive is late, negative is early; one beat is one quarter note.
  final double? onsetBeatOffset;

  /// Performed duration / tempo-scaled reference duration.
  final double? durationRatio;

  /// Unnormalized RMS from Phase 6. This is not an envelope/sustain measure.
  final double? soundStrengthRms;

  /// RMS divided by median RMS of all performed notes in this report.
  final double? relativeSoundStrength;

  /// Capped duration coverage; only a proxy for sound persistence.
  final double? soundingDurationRatio;
}

class PerformanceReport {
  const PerformanceReport({
    required this.notes,
    required this.markCounts,
    required this.estimatedQuarterBpm,
    required this.medianAbsolutePitchCents,
    required this.medianAbsoluteOnsetBeats,
    required this.medianDurationRatio,
    required this.medianSoundStrengthRms,
  });

  final List<NoteAssessment> notes;
  final Map<AlignmentMark, int> markCounts;
  final double? estimatedQuarterBpm;
  final double? medianAbsolutePitchCents;
  final double? medianAbsoluteOnsetBeats;
  final double? medianDurationRatio;
  final double? medianSoundStrengthRms;
  // Intentionally no 0–100 grade: tolerances are not calibrated on real audio.
}

class PerformanceAssessor {
  const PerformanceAssessor();

  PerformanceReport assess(ReferenceScore score, NoteAlignment alignment) {
    if (!alignment.timeScale.isFinite ||
        alignment.timeScale <= 0 ||
        !alignment.startOffsetSeconds.isFinite) {
      throw const FormatException('Invalid alignment timing.');
    }
    final rmsValues = alignment.events
        .map((e) => e.performed?.rms)
        .whereType<double>()
        .where((v) => v.isFinite && v >= 0)
        .toList();
    final medianRms = _median(rmsValues);
    final counts = {for (final mark in AlignmentMark.values) mark: 0};
    final assessments = <NoteAssessment>[];
    for (final event in alignment.events) {
      counts[event.mark] = counts[event.mark]! + 1;
      final reference = event.reference;
      final performed = event.performed;
      if ((event.mark == AlignmentMark.missed &&
              (reference == null || performed != null)) ||
          (event.mark == AlignmentMark.extra &&
              (reference != null || performed == null)) ||
          ((event.mark == AlignmentMark.matched ||
                  event.mark == AlignmentMark.wrongNote) &&
              (reference == null || performed == null))) {
        throw const FormatException('Inconsistent alignment event.');
      }
      if (performed != null &&
          (!performed.midiPitch.isFinite ||
              !performed.startSeconds.isFinite ||
              !performed.endSeconds.isFinite ||
              performed.durationSeconds < 0 ||
              !performed.rms.isFinite ||
              performed.rms < 0)) {
        throw const FormatException('Invalid performed note.');
      }
      double? pitch, onset, length, persistence;
      if (reference != null && performed != null) {
        if (reference.midiPitch == null || reference.durationSeconds <= 0) {
          throw const FormatException('Invalid paired reference note.');
        }
        pitch = (performed.midiPitch - reference.midiPitch!) * 100;
        final bpm = _bpmAt(score, reference.quarterPosition);
        final beatSeconds = 60 / bpm * alignment.timeScale;
        final expectedStart =
            alignment.startOffsetSeconds +
            alignment.timeScale * reference.startSeconds;
        onset = (performed.startSeconds - expectedStart) / beatSeconds;
        length =
            performed.durationSeconds /
            (alignment.timeScale * reference.durationSeconds);
        persistence = math.min(1, length);
      }
      assessments.add(
        NoteAssessment(
          alignment: event,
          pitchCents: pitch,
          onsetBeatOffset: onset,
          durationRatio: length,
          soundStrengthRms: performed?.rms,
          relativeSoundStrength:
              performed == null || medianRms == null || medianRms == 0
              ? null
              : performed.rms / medianRms,
          soundingDurationRatio: persistence,
        ),
      );
    }
    return PerformanceReport(
      notes: List.unmodifiable(assessments),
      markCounts: Map.unmodifiable(counts),
      estimatedQuarterBpm: alignment.estimatedQuarterBpm,
      medianAbsolutePitchCents: _median(
        assessments
            .map((n) => n.pitchCents?.abs())
            .whereType<double>()
            .toList(),
      ),
      medianAbsoluteOnsetBeats: _median(
        assessments
            .map((n) => n.onsetBeatOffset?.abs())
            .whereType<double>()
            .toList(),
      ),
      medianDurationRatio: _median(
        assessments.map((n) => n.durationRatio).whereType<double>().toList(),
      ),
      medianSoundStrengthRms: medianRms,
    );
  }

  static double _bpmAt(ReferenceScore score, double quarterPosition) {
    if (score.tempos.isEmpty) {
      throw const FormatException('Reference score has no tempo.');
    }
    var bpm = score.tempos.first.quarterBpm;
    for (final tempo in score.tempos) {
      if (tempo.quarterPosition > quarterPosition) break;
      bpm = tempo.quarterBpm;
    }
    if (!bpm.isFinite || bpm <= 0) {
      throw const FormatException('Invalid reference tempo.');
    }
    return bpm;
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    values.sort();
    final middle = values.length ~/ 2;
    return values.length.isOdd
        ? values[middle]
        : (values[middle - 1] + values[middle]) / 2;
  }
}
