# Music analysis — Phase 6 report

## Scope and outcome

Phase 6 adds Dart-only, monophonic performed-note segmentation, global tempo estimation, and sequence alignment with Phase 2 MusicXML reference notes. Alignment labels `matched`, `wrongNote`, `missed`, and `extra` are correspondence markers, not scores. There is no product UI, persistence, network sync, or grading. Phase 5 FFI, native ABI 1, DSP source, and the Phase 2/3 contracts were not modified.

The repository, project rules, Phase 2/3/4B/5 reports, reference parser, PCM preparation, FFI bridge, raw feature model, native interface, and existing integration tests were inspected before implementation. Existing unrelated worktree changes were left untouched.

## Files

| File | Change | Reason |
| --- | --- | --- |
| `lib/screens/Notation/performed_notes.dart` | Added | Independent observation model and streaming feature-to-note segmentation. |
| `lib/screens/Notation/note_alignment.dart` | Added | Tempo search, correspondence alignment, and non-scoring markers. |
| `test/music_analysis_phase6_test.dart` | Added | Synthetic raw-feature and reference-note unit tests. |
| `test/music_analysis_phase6_integration_test.dart` | Added | Short synthetic PCM file through the real production open-engine FFI, segmentation, MusicXML parser, and alignment. |
| `MUSIC ANALYSIS PHASE 6 REPORT.md` | Added | Phase contract and validation record. |

## Data model and timing

`PerformedNote` contains `startSeconds`, `endSeconds`, fractional `midiPitch`, mean `pitchConfidence`, and mean `rms`. Its duration is derived from the endpoints. These are observations of a monophonic audio stream; RMS is retained as an unscaled raw dynamic descriptor. `NoteAlignment` contains ordered `AlignedNote` events, nullable estimated quarter BPM, estimated global time scale, and start offset. Each event references a `ReferenceNote`, a `PerformedNote`, or both, with one of the four markers. There is no numeric grade or correctness percentage.

Raw frame and onset sample indices are divided by 44,100 to derive seconds; `timestampSeconds` is not reinterpreted as a centered analysis window. The score's `ReferenceNote.startSeconds` is the piecewise-tempo conversion of its quarter position from Phase 2. An estimated time scale multiplies those seconds and a start offset accounts for leading time before the performance. Estimated quarter BPM is the first reference quarter BPM divided by the scale. This is a **global tempo estimate** relative to the score, not a local beat curve; for changing reference tempi, the same global factor scales every existing tempo segment.

## Algorithms

Segmentation consumes an ordered `Stream<RawAudioFeature>` without loading the PCM or all raw frames into Dart memory. A frame is voiced when native `isSilent` is false, pitch is positive, confidence is at least 0.55, and RMS exceeds 0.001. The active note accumulates confidence-weighted fractional MIDI pitch (`69 + 12 log2(hz/440)`), mean confidence, mean RMS, and last voiced sample endpoint. A valid onset candidate after 55 ms or a pitch deviation of at least 0.8 semitone closes the current note. Two non-voiced frames close it at the last voiced endpoint. Notes shorter than 55 ms or supported by fewer than two frames are discarded. Invalid or unordered frames fail explicitly. State is constant per stream except for emitted notes retained by a caller. There is no destructive audio normalization.

Alignment excludes rests and tie continuations because they are not attacks. Simultaneous pitched reference attacks are rejected explicitly: the mono pitch stream cannot disambiguate chords. Performed notes must be time ordered. For global scales 0.50–2.00 in steps of 0.05, a dynamic-programming sequence alignment considers pairing, omission, and insertion. Omission and insertion each have a correspondence cost of 1.25. Pairing uses a pitch tolerance of 0.65 semitone, a fixed mismatch cost of 1.3, and a bounded onset-time cost relative to scaled reference time plus offset. These costs only choose a path; they are never returned as performance scores. Matched pairs provide a robust median pairwise time slope and median offset, followed by a final alignment pass. Pairings outside the pitch tolerance are marked `wrongNote`; unpaired reference and performed attacks are `missed` and `extra`. The first-pass start offset assumes the first performed note approximately corresponds to the first reference attack; leading insertions remain a limitation.

The dynamic-programming matrix uses O(R×P) memory per candidate scale for R reference attacks and P performed notes; the segmenter itself uses O(1) working state. This is suitable for short and medium monophonic excerpts, but long-score alignment needs banding or checkpointed backtracking before deployment. Empty reference/performance sequences produce explicit extra/missed events; no tempo is reported when there are no corresponding notes.

## Tests and actual results

| Test | Input and expected behavior | Result |
| --- | --- | --- |
| Segmentation | Synthetic 440/493.88 Hz feature frames, onset and silence boundaries; three observed notes with expected pitches and times. | Passed. |
| Low confidence | Thirty pitched but low-confidence frames; no note. | Passed. |
| Different tempo | Four known pitches at 0.75 s quarter intervals against 120 BPM reference; all matched and estimate near 80 BPM. | Passed. |
| Missing/extra/wrong | Synthetic reference and performance sequences carrying each edit type; all markers present. | Passed. |
| Polyphonic guard | Two simultaneous pitched reference attacks; explicit unsupported error. | Passed. |
| End-to-end synthetic file | One-second, two-tone headerless f32le PCM file → production open-engine FFI → raw features → performed notes → parsed MusicXML → alignment; both pitches and at least two matches. | Passed on Windows host DLL. |

Validation from repository root:

```powershell
C:\dev\sdk\flutter-sdk\flutter\bin\dart.bat format lib/screens/Notation/performed_notes.dart lib/screens/Notation/note_alignment.dart test/music_analysis_phase6_test.dart test/music_analysis_phase6_integration_test.dart
C:\dev\sdk\flutter-sdk\flutter\bin\dart.bat analyze lib/screens/Notation/performed_notes.dart lib/screens/Notation/note_alignment.dart test/music_analysis_phase6_test.dart test/music_analysis_phase6_integration_test.dart
C:\dev\sdk\flutter-sdk\flutter\bin\flutter.bat test --no-pub test/music_analysis_phase6_test.dart test/music_analysis_phase6_integration_test.dart
```

Observed: formatter completed; targeted Dart analyzer reported **No issues found**; **6 tests passed, 0 failed**. The integration test used the previously built `.native-host-prod/Release/music_analysis_dsp.dll`. It is skipped with an explicit reason if that DLL is absent. No microphone, network, or product UI is needed.

## Platform build status

Android: **no new Android build or device test in Phase 6**. Phase 5 previously built the arm64 native library with Aubio disabled; that is prior evidence, not a Phase 6 Android build. iOS: **not built or tested** because the current host is Windows and Xcode is unavailable. No APK, AAB, IPA, desktop or other application output was generated, as required by project rules. Native code and ABI were not changed, so no native rebuild was required for this Dart-only phase. A full Android/iOS runtime test remains open.

## Limits and Phase 7 contract

This baseline uses one global tempo factor and monophonic note segmentation. Real instrument attacks, vibrato, repeated same-pitch notes without reliable onset candidates, octave errors, low signal-to-noise recordings, grace notes, sustained tied notes, chords, multiple voices, repeats, and expressive local rubato need labeled device recordings and further validation. Note boundaries may lag the physical attack because native pitch needs an analysis window. The simple dynamic-programming correspondence can misclassify heavily inserted or reordered passages. The integration test covers synthetic PCM and host FFI, not actual device decoding or microphone recordings.

Phase 7 should accept `ReferenceScore`, ordered `PerformedNote` observations, and `NoteAlignment` markers without modifying the ABI. It may introduce an explicit scoring policy only after a labeled real-audio corpus establishes pitch/onset tolerances, correspondence accuracy, confidence calibration, tempo-variation behavior, and mobile performance. Scoring must treat `missed`, `extra`, and `wrongNote` as separate evidence and must not mistake Phase 6 edit costs for grades. Before release, run Android device and macOS iOS Release builds/tests, verify open-engine-only production linkage, and evaluate memory for long scores. This report does not implement those Phase 7 tasks.
