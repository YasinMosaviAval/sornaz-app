import 'dart:convert';
import 'dart:io';

import 'analysis_audio.dart';
import 'music_analysis_ffi.dart';
import 'note_alignment.dart';
import 'performance_assessment.dart';
import 'performed_notes.dart';
import 'reference_timeline.dart';

/// An expert annotation, not a score or a DSP output.
class CalibrationTruthNote {
  const CalibrationTruthNote({
    required this.midiPitch,
    required this.startSeconds,
    required this.endSeconds,
  });
  final double midiPitch, startSeconds, endSeconds;
}

class CalibrationCase {
  const CalibrationCase({
    required this.id,
    required this.instrument,
    required this.source,
    required this.musicXml,
    this.truthByReferenceId = const {},
  });
  final String id, instrument, musicXml;
  final AnalysisAudioSource source;
  final Map<String, CalibrationTruthNote> truthByReferenceId;
}

class CalibrationResult {
  const CalibrationResult(
    this.caseId,
    this.instrument,
    this.report,
    this.truthByReferenceId, {
    this.sourceMetadata,
    this.pcmFrames,
    this.rawFeatureFrames,
  });
  final String caseId, instrument;
  final PerformanceReport report;
  final Map<String, CalibrationTruthNote> truthByReferenceId;
  final AudioMetadata? sourceMetadata;
  final int? pcmFrames, rawFeatureFrames;

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'caseId': caseId,
    'instrument': instrument,
    'sourceSampleRate': sourceMetadata?.sourceSampleRate,
    'sourceChannels': sourceMetadata?.sourceChannels,
    'sourceDurationMicroseconds': sourceMetadata?.duration.inMicroseconds,
    'sourceMimeType': sourceMetadata?.mimeType,
    'pcmFormat': 'mono-44100-f32le',
    'pcmFrames': pcmFrames,
    'rawFeatureFrames': rawFeatureFrames,
    'dspEngine': 'open',
    'estimatedQuarterBpm': report.estimatedQuarterBpm,
    'markCounts': {
      for (final mark in AlignmentMark.values)
        mark.name: report.markCounts[mark],
    },
    'medianAbsolutePitchCents': report.medianAbsolutePitchCents,
    'medianAbsoluteOnsetBeats': report.medianAbsoluteOnsetBeats,
    'medianDurationRatio': report.medianDurationRatio,
    'medianSoundStrengthRms': report.medianSoundStrengthRms,
    'notes': [for (final note in report.notes) _noteJson(note)],
  };

  Map<String, Object?> _noteJson(NoteAssessment note) {
    final reference = note.alignment.reference;
    final performance = note.alignment.performed;
    final truth = reference == null ? null : truthByReferenceId[reference.id];
    return {
      'mark': note.mark.name,
      'referenceId': reference?.id,
      'referenceMidiPitch': reference?.midiPitch,
      'referenceQuarterPosition': reference?.quarterPosition,
      'performedStartSeconds': performance?.startSeconds,
      'performedEndSeconds': performance?.endSeconds,
      'performedMidiPitch': performance?.midiPitch,
      'pitchConfidence': performance?.pitchConfidence,
      'pitchCents': note.pitchCents,
      'onsetBeatOffset': note.onsetBeatOffset,
      'durationRatio': note.durationRatio,
      'soundStrengthRms': note.soundStrengthRms,
      'relativeSoundStrength': note.relativeSoundStrength,
      'soundingDurationRatio': note.soundingDurationRatio,
      'truthMidiPitch': truth?.midiPitch,
      'truthStartSeconds': truth?.startSeconds,
      'truthEndSeconds': truth?.endSeconds,
      'pitchErrorVsTruthCents': truth == null || performance == null
          ? null
          : (performance.midiPitch - truth.midiPitch) * 100,
      'onsetErrorVsTruthSeconds': truth == null || performance == null
          ? null
          : performance.startSeconds - truth.startSeconds,
      'endErrorVsTruthSeconds': truth == null || performance == null
          ? null
          : performance.endSeconds - truth.endSeconds,
    };
  }

  static const csvFields = [
    'caseId',
    'instrument',
    'estimatedQuarterBpm',
    'mark',
    'referenceId',
    'referenceMidiPitch',
    'referenceQuarterPosition',
    'performedStartSeconds',
    'performedEndSeconds',
    'performedMidiPitch',
    'pitchConfidence',
    'pitchCents',
    'onsetBeatOffset',
    'durationRatio',
    'soundStrengthRms',
    'relativeSoundStrength',
    'soundingDurationRatio',
    'truthMidiPitch',
    'truthStartSeconds',
    'truthEndSeconds',
    'pitchErrorVsTruthCents',
    'onsetErrorVsTruthSeconds',
    'endErrorVsTruthSeconds',
  ];

  String toCsv() {
    String cell(Object? value) {
      if (value == null) return '';
      final text = value.toString();
      return '"${text.replaceAll('"', '""')}"';
    }

    final rows = [csvFields.join(',')];
    for (final note in report.notes) {
      final values = {
        'caseId': caseId,
        'instrument': instrument,
        'estimatedQuarterBpm': report.estimatedQuarterBpm,
        ..._noteJson(note),
      };
      rows.add(csvFields.map((field) => cell(values[field])).join(','));
    }
    return '${rows.join('\n')}\n';
  }

  Future<void> writeTo(Directory directory) async {
    await directory.create(recursive: true);
    if (caseId.isEmpty || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(caseId)) {
      throw const FormatException('Case ID must be a safe filename.');
    }
    await File(
      '${directory.path}/$caseId.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(toJson()));
    await File('${directory.path}/$caseId.csv').writeAsString(toCsv());
  }
}

/// Uses the existing Phase 3 decoder/preparer and Phase 5 open-engine bridge.
/// The source recording is never modified; only the temporary PCM is disposed.
class MusicAnalysisCalibrationRunner {
  const MusicAnalysisCalibrationRunner(this.preparer, this.ffi);
  final AnalysisAudioPreparer preparer;
  final MusicAnalysisFfi ffi;

  Future<CalibrationResult> run(
    CalibrationCase input, {
    AnalysisCancellation? cancellation,
  }) async {
    final token = cancellation ?? AnalysisCancellation();
    final score = const ReferenceTimelineParser().parse(input.musicXml);
    final pcm = await preparer.prepare(input.source, cancellation: token);
    try {
      var rawFeatureFrames = 0;
      final notes = await const PerformedNoteSegmenter()
          .segment(
            ffi.extract(pcm, cancellation: token).map((feature) {
              rawFeatureFrames++;
              return feature;
            }),
          )
          .toList();
      token.throwIfCancelled();
      final alignment = const ReferenceNoteAligner().align(score, notes);
      final report = const PerformanceAssessor().assess(score, alignment);
      return CalibrationResult(
        input.id,
        input.instrument,
        report,
        input.truthByReferenceId,
        sourceMetadata: pcm.sourceMetadata,
        pcmFrames: pcm.frames,
        rawFeatureFrames: rawFeatureFrames,
      );
    } finally {
      await pcm.dispose();
    }
  }
}
