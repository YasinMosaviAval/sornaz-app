# Music Analysis — Phase 2 Report

## Scope and result

Phase 2 implements a Dart-only MusicXML reference timeline. It parses a single `score-partwise` part into immutable `ReferenceScore`, `ReferenceNote`, and `ReferenceTempo` objects without depending on the notation WebView, audio capture, native code, FFI, local persistence, or a backend. It intentionally does not implement later phases.

The existing untracked `MUSIC_PERFORMANCE_ANALYSIS_PLAN.md` is not part of this phase or its commit.

## Exact file list and reasons

| File | Status | Reason |
|---|---|---|
| `pubspec.yaml` | Modified | Declare `xml: ^7.0.1` as a direct dependency because the new Dart parser imports it. The same version was already present as a transitive dependency in `pubspec.lock`; the lockfile did not need a content change. |
| `lib/screens/Notation/reference_timeline.dart` | Added | Define immutable reference models and parse MusicXML into score positions and elapsed seconds. |
| `test/reference_timeline_test.dart` | Added | Exercise timing, pitch, rests, tempo, polyphonic positioning, ties, and rejected input. |
| `MUSIC ANALYSIS PHASE 2 REPORT.md` | Added | Document the phase-2 contract, support limits, tests, and validation. |

No existing UI, JavaScript notation editor, audio service, native project, database, or networking file was changed.

## Final model structure

`ReferenceScore` contains `title`, `partId`, immutable `notes`, immutable `tempos`, `durationQuarters`, and `durationSeconds`. Its `secondsAt(quarterPosition)` converts a valid score position to elapsed time using the active tempo segment.

`ReferenceNote` contains a stable-in-document `id` (`partId:zeroBasedMeasureIndex:documentNoteIndex`), `measureIndex`, `voice`, `quarterPosition`, `quarterDuration`, `startSeconds`, `durationSeconds`, `isRest`, `isAttack`, `tieStart`, `tieStop`, and nullable `midiPitch`. A rest has no MIDI pitch or attack. A tie continuation remains a separate notated segment but has `isAttack = false`; it must not be interpreted as a newly struck note. The MIDI value is written pitch and may be fractional when `<alter>` is fractional.

`ReferenceTempo` contains `quarterPosition`, `quarterBpm`, and `startSeconds`. It marks a piecewise-constant tempo segment. `ReferenceFormatException` reports malformed or explicitly unsupported input.

## Position, time, and tempo conversion

Score position and duration are measured in **quarter-note units** from the beginning of the score. For MusicXML `<duration>D</duration>` with current `<divisions>V</divisions>`, the note lasts `D / V` quarter notes. The `<type>` and `<dot>` tags describe notation; MusicXML's duration is authoritative for timing. A dotted quarter with `divisions = 480` and `duration = 720` therefore lasts `1.5` quarters.

Within a measure, normal notes advance the cursor by their duration. `<chord>` notes reuse the preceding onset. `<backup>` and `<forward>` move the cursor to support multiple voices. The next measure begins after the greatest occupied position in the current measure, padded to its time-signature capacity for ordinary measures; an `implicit="yes"` measure uses its actual occupied extent, so a pickup can be short. The score's total quarter duration includes this measure padding, while explicit rests remain `ReferenceNote` events.

Tempo is stored as quarter notes per minute. A MusicXML `<sound tempo="120">` means 120 quarters per minute. A metronome mark is converted using its beat unit and dots: for example, dotted quarter `= 60` becomes `90` quarter BPM, and dotted half `= 60` becomes `180` quarter BPM. When both are present and `sound/@tempo` repeats the displayed metronome number, the parser uses the metronome beat unit. This handles the app's current MusicXML exporter, which writes that combination for dotted units. If the two numbers differ, the explicit sound tempo takes precedence. The default before any tempo direction is 120 quarter BPM.

For each interval with constant BPM, `elapsedSeconds = quarterDistance × 60 / quarterBpm`. `secondsAt` integrates these intervals. A note's `durationSeconds` is calculated as `secondsAt(noteEnd) - secondsAt(noteStart)`, so a future tempo change inside a note is handled correctly. Positions and seconds use Dart `double`; callers should use tolerances when comparing floating-point values. Tempo changes at the same position use the last direction encountered.

## Current MusicXML support

| Feature | Status | Behavior or limit |
|---|---|---|
| `score-partwise`, one part | Supported | Exactly one `<part>` required; zero or multiple parts are rejected. |
| Measures, divisions, time signature | Supported | Divisions must precede durations. Ordinary short measures are padded; `implicit="yes"` measures are not. An overfull measure is rejected when a time signature is known. |
| Pitched notes and rests | Supported | Written step, octave, and numeric `alter` become MIDI pitch; rests have null pitch. |
| Dots and note type | Supported through `<duration>` | Dots and type do not override MusicXML duration. |
| Ties | Partially supported | Start/stop flags are retained and stop segments are not new attacks; continuity between matching pitches is not yet validated. |
| Chords and multiple voices in one part | Supported for positioning | Chord onset is shared; backup/forward positioning and voice labels are retained. Later analysis of simultaneous audio is outside phase 2. |
| `sound tempo`, metronome beat unit and dots | Supported | Converted to quarter BPM; exporter compatibility rule described above. |
| Direction offset | Supported | Offset uses current divisions; positions before measure start are rejected. |
| Fractional accidentals | Supported | Fractional `<alter>` is preserved in written MIDI pitch. |
| Key signature | Timing independent | Pitch comes from each note's `<pitch>/<alter>`; key-signature accidentals are not inferred from the key field. |
| Timewise scores, multiple parts, transposition | Rejected or unsupported | No misleading single-line timeline is emitted for these structures. |
| Repeats and endings | Rejected | Playback unfolding is not implemented. |
| Navigation marks, grace notes, cue notes, tuplets | Not supported as distinct semantics | Tuplet timing can be represented when ordinary `<duration>` exists; grace/cue timing and playback navigation need a separate decision before accepting those scores. |

## Added tests and scenarios

All tests are in `test/reference_timeline_test.dart`:

1. **Quarter positions and seconds:** verifies ordinary measure padding, explicit rest, written accidental, and total duration.
2. **Dotted duration and tempo change:** verifies `duration/divisions`, note onset, elapsed time, and a changed tempo.
3. **Metronome beat conversion:** verifies dotted half-note mark to quarter BPM.
4. **Bundled exporter compatibility:** verifies a dotted metronome mark paired with the app's `sound tempo` value.
5. **Backup and chord:** verifies simultaneous onset, preserved voice labels, and written MIDI values.
6. **Tie continuation:** verifies a continuation is a segment without a new attack.
7. **Invalid and unsupported input:** verifies malformed XML, timewise scores, missing duration, and repeats fail explicitly.

## Validation commands and results

Run from the repository root:

```powershell
$env:DART_SUPPRESS_ANALYTICS='true'
dart format lib/screens/Notation/reference_timeline.dart test/reference_timeline_test.dart
dart analyze lib/screens/Notation/reference_timeline.dart test/reference_timeline_test.dart
flutter test --no-pub test/reference_timeline_test.dart
git diff --check
```

Validation on this change: `dart format` completed; `dart analyze` reported **No issues found**; the focused Flutter test suite reported **7 tests passed**; `git diff --check` reported no whitespace errors. The commands use the existing offline Flutter SDK and `--no-pub`; no application package or platform output was generated.
