import 'dart:math' as math;

import 'music_analysis_features.dart';

/// A single monophonic, detected attack. These values are observations, not scores.
class PerformedNote {
  const PerformedNote({
    required this.startSeconds,
    required this.endSeconds,
    required this.midiPitch,
    required this.pitchConfidence,
    required this.rms,
  });
  final double startSeconds, endSeconds, midiPitch, pitchConfidence, rms;
  double get durationSeconds => endSeconds - startSeconds;
}

/// Bounded-state segmentation of ordered 44.1 kHz DSP frames.
class PerformedNoteSegmenter {
  const PerformedNoteSegmenter();
  static const sampleRate = 44100;
  static const minConfidence = 0.55;
  static const minDuration = 0.055;
  static const pitchSplitSemitones = 0.8;
  static const silenceFrames = 2;

  Stream<PerformedNote> segment(Stream<RawAudioFeature> features) async* {
    _NoteBuilder? active;
    var silent = 0;
    var lastEnd = 0.0;
    var lastStartSample = -1;
    await for (final frame in features) {
      if (frame.frameStartSample <= lastStartSample ||
          frame.frameValidSamples <= 0 ||
          !frame.pitchConfidence.isFinite ||
          !frame.pitchHz.isFinite ||
          !frame.rms.isFinite ||
          frame.rms < 0) {
        throw const FormatException('Invalid or unordered raw audio feature.');
      }
      lastStartSample = frame.frameStartSample;
      final start = frame.frameStartSample / sampleRate;
      final end =
          (frame.frameStartSample + frame.frameValidSamples) / sampleRate;
      lastEnd = end;
      final voiced =
          !frame.isSilent &&
          frame.pitchHz > 0 &&
          frame.pitchConfidence >= minConfidence &&
          frame.rms > 0.001;
      if (!voiced) {
        silent++;
        if (active != null && silent >= silenceFrames) {
          final note = active.finish(active.lastVoicedEnd);
          if (note != null) yield note;
          active = null;
        }
        continue;
      }
      silent = 0;
      final midi = 69 + 12 * math.log(frame.pitchHz / 440) / math.ln2;
      final onset =
          frame.onsetCandidate &&
          frame.onsetSample >= frame.frameStartSample &&
          frame.onsetSample < frame.frameStartSample + frame.frameValidSamples;
      final boundary = onset ? frame.onsetSample / sampleRate : start;
      if (active != null &&
          (onset && start - active.start > minDuration ||
              (midi - active.meanPitch).abs() >= pitchSplitSemitones)) {
        final note = active.finish(boundary);
        if (note != null) yield note;
        active = null;
      }
      active ??= _NoteBuilder(boundary);
      active.add(midi, frame.pitchConfidence, frame.rms, end);
    }
    if (active != null) {
      final note = active.finish(math.min(lastEnd, active.lastVoicedEnd));
      if (note != null) yield note;
    }
  }
}

class _NoteBuilder {
  _NoteBuilder(this.start);
  final double start;
  double lastVoicedEnd = 0, _pitchSum = 0, _weight = 0, _rmsSum = 0;
  int _frames = 0;
  double get meanPitch => _pitchSum / _weight;
  void add(double pitch, double confidence, double rms, double end) {
    _pitchSum += pitch * confidence;
    _weight += confidence;
    _rmsSum += rms;
    _frames++;
    lastVoicedEnd = end;
  }

  PerformedNote? finish(double end) =>
      end - start < PerformedNoteSegmenter.minDuration || _frames < 2
      ? null
      : PerformedNote(
          startSeconds: start,
          endSeconds: end,
          midiPitch: meanPitch,
          pitchConfidence: _weight / _frames,
          rms: _rmsSum / _frames,
        );
}
