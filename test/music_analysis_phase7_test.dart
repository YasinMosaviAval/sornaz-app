import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/note_alignment.dart';
import 'package:sornaz/screens/Notation/performance_assessment.dart';
import 'package:sornaz/screens/Notation/performed_notes.dart';
import 'package:sornaz/screens/Notation/reference_timeline.dart';

ReferenceNote reference(int i, double pitch) => ReferenceNote(
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
  midiPitch: pitch,
);
PerformedNote performed(double start, double end, double pitch, double rms) =>
    PerformedNote(
      startSeconds: start,
      endSeconds: end,
      midiPitch: pitch,
      pitchConfidence: 0.9,
      rms: rms,
    );
ReferenceScore score(List<ReferenceNote> notes) => ReferenceScore(
  title: '',
  partId: 'P1',
  notes: notes,
  tempos: const [ReferenceTempo(0, 120, 0)],
  durationQuarters: notes.length.toDouble(),
  durationSeconds: notes.length * 0.5,
);

void main() {
  test('slightly flat, late and short note has signed raw metrics', () {
    final ref = reference(0, 69);
    final take = performed(0.05, 0.45, 68.9, 0.2);
    final report = const PerformanceAssessor().assess(
      score([ref]),
      NoteAlignment([AlignedNote(AlignmentMark.matched, ref, take)], 120, 1, 0),
    );
    final note = report.notes.single;
    expect(note.pitchCents, closeTo(-10, 1e-9));
    expect(note.onsetBeatOffset, closeTo(0.1, 1e-9));
    expect(note.durationRatio, closeTo(0.8, 1e-9));
    expect(note.soundingDurationRatio, closeTo(0.8, 1e-9));
    expect(note.soundStrengthRms, 0.2);
    expect(note.relativeSoundStrength, 1);
    expect(report.medianAbsolutePitchCents, closeTo(10, 1e-9));
    expect(report.medianAbsoluteOnsetBeats, closeTo(0.1, 1e-9));
    expect(report.markCounts[AlignmentMark.matched], 1);
  });

  test('scaled tempo, offset and local beat duration remain distinct', () {
    final ref = reference(1, 71);
    final take = performed(1.05, 1.65, 71.2, 0.1);
    final report = const PerformanceAssessor().assess(
      score([reference(0, 69), ref]),
      NoteAlignment(
        [AlignedNote(AlignmentMark.matched, ref, take)],
        80,
        1.5,
        0.2,
      ),
    );
    expect(report.notes.single.pitchCents, closeTo(20, 1e-9));
    expect(report.notes.single.onsetBeatOffset, closeTo(0.1 / 0.75, 1e-9));
    expect(report.notes.single.durationRatio, closeTo(0.8, 1e-9));
    expect(report.estimatedQuarterBpm, 80);
  });

  test('missed, extra and wrong markers preserve nullable metrics', () {
    final first = reference(0, 60), second = reference(1, 62);
    final extra = performed(0.2, 0.4, 65, 0.1);
    final wrong = performed(0.5, 1, 63, 0.3);
    final report = const PerformanceAssessor().assess(
      score([first, second]),
      NoteAlignment(
        [
          AlignedNote(AlignmentMark.missed, first, null),
          AlignedNote(AlignmentMark.extra, null, extra),
          AlignedNote(AlignmentMark.wrongNote, second, wrong),
        ],
        120,
        1,
        0,
      ),
    );
    expect(report.notes.map((n) => n.mark), [
      AlignmentMark.missed,
      AlignmentMark.extra,
      AlignmentMark.wrongNote,
    ]);
    expect(report.notes[0].pitchCents, isNull);
    expect(report.notes[1].onsetBeatOffset, isNull);
    expect(report.notes[1].relativeSoundStrength, closeTo(0.5, 1e-9));
    expect(report.notes[2].pitchCents, 100);
    expect(report.medianSoundStrengthRms, 0.2);
  });

  test('no paired notes yields null aggregate metrics instead of a grade', () {
    final report = const PerformanceAssessor().assess(
      score([reference(0, 60)]),
      NoteAlignment(
        [AlignedNote(AlignmentMark.missed, reference(0, 60), null)],
        null,
        1,
        0,
      ),
    );
    expect(report.medianAbsolutePitchCents, isNull);
    expect(report.medianAbsoluteOnsetBeats, isNull);
    expect(report.medianDurationRatio, isNull);
  });

  test('inconsistent alignment is rejected instead of inventing values', () {
    expect(
      () => const PerformanceAssessor().assess(
        score([]),
        const NoteAlignment(
          [AlignedNote(AlignmentMark.extra, null, null)],
          null,
          1,
          0,
        ),
      ),
      throwsFormatException,
    );
  });
}
