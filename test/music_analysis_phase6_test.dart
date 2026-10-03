import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/music_analysis_features.dart';
import 'package:sornaz/screens/Notation/note_alignment.dart';
import 'package:sornaz/screens/Notation/performed_notes.dart';
import 'package:sornaz/screens/Notation/reference_timeline.dart';

RawAudioFeature frame(
  int index, {
  double hz = 440,
  bool silent = false,
  bool onset = false,
  double confidence = 0.95,
}) => RawAudioFeature(
  frameStartSample: index * 512,
  frameValidSamples: 512,
  onsetSample: index * 512,
  timestampSeconds: index * 512 / 44100,
  pitchHz: silent ? 0 : hz,
  pitchConfidence: silent ? 0 : confidence,
  onsetStrength: onset ? 1 : 0,
  energy: silent ? 0 : 0.1,
  rms: silent ? 0 : 0.2,
  peakAbs: silent ? 0 : 0.3,
  clippingFraction: 0,
  signalQuality: 1,
  onsetCandidate: onset,
  isSilent: silent,
  isPartial: false,
);

ReferenceScore score(List<double> pitches) => ReferenceScore(
  title: 'test',
  partId: 'P1',
  durationQuarters: pitches.length.toDouble(),
  durationSeconds: pitches.length * 0.5,
  tempos: const [ReferenceTempo(0, 120, 0)],
  notes: [
    for (var i = 0; i < pitches.length; i++)
      ReferenceNote(
        id: 'n$i',
        measureIndex: 0,
        voice: '1',
        quarterPosition: i.toDouble(),
        quarterDuration: 1,
        startSeconds: i * 0.5,
        durationSeconds: 0.5,
        isRest: false,
        isAttack: true,
        tieStart: false,
        tieStop: false,
        midiPitch: pitches[i],
      ),
  ],
);

PerformedNote note(double time, double pitch) => PerformedNote(
  startSeconds: time,
  endSeconds: time + 0.3,
  midiPitch: pitch,
  pitchConfidence: 0.95,
  rms: 0.2,
);

void main() {
  test(
    'onsets, silence and pitch changes segment a bounded feature stream',
    () async {
      final features = [
        for (var i = 0; i < 70; i++)
          frame(
            i,
            hz: i < 25 ? 440 : 493.88,
            silent: i >= 50 && i < 55,
            onset: i == 25 || i == 55,
          ),
      ];
      final notes = await const PerformedNoteSegmenter()
          .segment(Stream.fromIterable(features))
          .toList();
      expect(notes, hasLength(3));
      expect(notes[0].midiPitch, closeTo(69, 0.1));
      expect(notes[1].midiPitch, closeTo(71, 0.1));
      expect(notes[2].startSeconds, closeTo(55 * 512 / 44100, 0.001));
    },
  );

  test('low-confidence jitter cannot create a note', () async {
    final notes = await const PerformedNoteSegmenter()
        .segment(
          Stream.fromIterable([
            for (var i = 0; i < 30; i++) frame(i, confidence: 0.2),
          ]),
        )
        .toList();
    expect(notes, isEmpty);
  });

  test('tempo change retains ordered matching notes', () {
    final result = const ReferenceNoteAligner().align(score([60, 62, 64, 65]), [
      note(0.1, 60),
      note(0.85, 62),
      note(1.6, 64),
      note(2.35, 65),
    ]);
    expect(
      result.events.map((e) => e.mark),
      everyElement(AlignmentMark.matched),
    );
    expect(result.estimatedQuarterBpm, closeTo(80, 1));
  });

  test('missing, extra and wrong pitches are markers only', () {
    final result = const ReferenceNoteAligner().align(score([60, 62, 64, 65]), [
      note(0, 60),
      note(0.25, 67),
      note(0.5, 62),
      note(1.5, 66),
    ]);
    expect(
      result.events.map((e) => e.mark),
      containsAll([
        AlignmentMark.extra,
        AlignmentMark.missed,
        AlignmentMark.wrongNote,
      ]),
    );
  });

  test('polyphonic reference fails explicitly', () {
    final original = score([60, 64]);
    final polyphonic = ReferenceScore(
      title: '',
      partId: 'P1',
      notes: [
        original.notes[0],
        ReferenceNote(
          id: 'chord',
          measureIndex: 0,
          voice: '1',
          quarterPosition: 0,
          quarterDuration: 1,
          startSeconds: 0,
          durationSeconds: 0.5,
          isRest: false,
          isAttack: true,
          tieStart: false,
          tieStop: false,
          midiPitch: 64,
        ),
      ],
      tempos: original.tempos,
      durationQuarters: 1,
      durationSeconds: 0.5,
    );
    expect(
      () => const ReferenceNoteAligner().align(polyphonic, []),
      throwsUnsupportedError,
    );
  });
}
