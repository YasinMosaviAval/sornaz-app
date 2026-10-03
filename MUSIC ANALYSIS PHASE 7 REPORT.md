# Music analysis — Phase 7 report

## Scope and outcome

Phase 7 assesses the Phase 6 `NoteAlignment` result. The user request calls it `MatchResult`; the repository's actual type is `NoteAlignment`, so the new module consumes that type without changing Phase 6 or native ABI 1. It produces a `NoteAssessment` for every alignment event and one aggregate `PerformanceReport`. The report is descriptive data, not a grade. No final product UI, backend, persistence, DSP, FFI, MusicXML parser, or segmentation code changed. Earlier Phase 2, 3, 4B, 5, and 6 reports and the relevant source/test contracts were reviewed.

## Files and modules

| File | Change | Purpose |
| --- | --- | --- |
| `lib/screens/Notation/performance_assessment.dart` | Added | Per-note observations, aggregate report and pure Dart assessment calculation. |
| `test/music_analysis_phase7_test.dart` | Added | Exact synthetic metric and marker tests. |
| `test/music_analysis_phase7_integration_test.dart` | Added | Synthetic PCM file through production native FFI, Phase 6 segmentation/alignment, MusicXML parser and Phase 7 report. |
| `MUSIC ANALYSIS PHASE 7 REPORT.md` | Added | Scope, metrics, measured results, platform status, limitations and Phase 8 contract. |

## Data model and exact metrics

`NoteAssessment` retains the original `AlignedNote` and its `AlignmentMark` (`matched`, `wrongNote`, `missed`, `extra`). A missing reference/performance partner yields null for metrics that cannot be computed; it never becomes zero error. Paired notes carry:

| Field | Definition | Interpretation |
| --- | --- | --- |
| `pitchCents` | `100 × (performed.midiPitch − reference.midiPitch)` | Signed cents; positive is sharp, negative is flat. The fractional MIDI pitch from Phase 6 is used without rounding. |
| `onsetBeatOffset` | `(performed.startSeconds − (startOffsetSeconds + timeScale × reference.startSeconds)) / (timeScale × 60 / referenceQuarterBpmAtNote)` | Signed quarter-note beats; positive is late. Tempo is selected from the active Phase 2 tempo segment at the note's quarter position. |
| `durationRatio` | `performed.durationSeconds / (timeScale × reference.durationSeconds)` | 1 means equal observed and expected lengths, below 1 is shorter. |
| `soundStrengthRms` | Phase 6 mean RMS | Raw, unnormalized strength proxy; no reference dynamic is available in MusicXML model. |
| `relativeSoundStrength` | note RMS / median RMS of all performed notes in this report | Within-take comparison only; null if median RMS is zero or unavailable. |
| `soundingDurationRatio` | `min(1, durationRatio)` | Capped coverage proxy for sound persistence. It cannot measure continuity or stability within a note because Phase 6 retains mean RMS but not an envelope. |

`PerformanceReport` contains the ordered immutable note assessments, counts for every alignment mark, the Phase 6 estimated quarter BPM, and descriptive medians: absolute pitch cents, absolute onset beats, duration ratio and raw RMS. Medians ignore null measurements. Empty evidence yields null aggregates. Input timing, note values and inconsistent mark/partner combinations are checked rather than silently converted to plausible numbers.

## Scoring policy

There is **no 0–100 score**, weighted overall grade, pass/fail threshold, or inferred dynamic correctness. The Phase 6 alignment costs are correspondence machinery, not grades. Pitch and onset tolerances, instrument-specific attacks, onset latency, dynamics, and sound persistence have not been calibrated on labeled real performances; a numeric grade would imply unjustified certainty. The model leaves room for a later versioned, calibratable policy while preserving the raw evidence.

## Tests, commands and observed numbers

| Scenario | Exact expectation and observed result |
| --- | --- |
| Slightly flat, late, short | A reference A4 at 120 BPM and performed MIDI 68.9, start 0.05 s, end 0.45 s produced **−10 cents**, **+0.1 beat**, **0.8 duration ratio**, **0.8 sounding-duration proxy**, RMS **0.2**, relative RMS **1.0**. Matched marker retained. |
| Tempo scale and start offset | Scale 1.5, offset 0.2 s, performed onset 1.05 s for reference onset 0.5 s produced **+20 cents**, **+0.133333… beat**, **0.8 duration ratio** and estimated **80 quarter BPM**. |
| Missed, extra, wrong | All three markers retained; missed pitch and extra onset metrics are null. Extra RMS **0.1** versus median RMS **0.2** produced relative strength **0.5**; paired wrong pitch produced **+100 cents**. |
| No paired evidence | Pitch/onset/duration medians are null, with no substitute grade. |
| Invalid alignment | Extra marker with no performed note raises `FormatException`. |
| Synthetic end-to-end file | One-second, two-tone f32le PCM at 44.1 kHz through open-engine host DLL yielded **2 performed notes**, **2 matched notes**, pitch differences **+3.537114871254232** and **−5.076459026888358 cents**, median RMS **0.28311679418865954**, median duration ratio **0.9666606104651163**. |

Validation from repository root:

```powershell
C:\dev\sdk\flutter-sdk\flutter\bin\dart.bat format lib/screens/Notation/performance_assessment.dart test/music_analysis_phase7_test.dart test/music_analysis_phase7_integration_test.dart
C:\dev\sdk\flutter-sdk\flutter\bin\dart.bat analyze lib/screens/Notation/performance_assessment.dart test/music_analysis_phase7_test.dart test/music_analysis_phase7_integration_test.dart
C:\dev\sdk\flutter-sdk\flutter\bin\flutter.bat test --no-pub test/music_analysis_phase7_test.dart test/music_analysis_phase7_integration_test.dart
C:\dev\sdk\flutter-sdk\flutter\bin\flutter.bat build apk --release --no-pub
C:\dev\sdk\flutter-sdk\flutter\bin\flutter.bat build apk --release --no-pub --target-platform android-arm64
```

Observed before commit: formatter completed; targeted Dart analyzer returned **No issues found**; **6 tests passed, 0 failed**, including the real production-mode native host library. The host DLL test skips explicitly if that library is absent. Android build status is recorded below. The test file's printed integration values are diagnostic evidence, not application output.

## Android and iOS build status

Android Release APK build, default three architectures: **failed** after `21m 25s` of Gradle work. The Cargokit plugin attempted `rustup target add --toolchain stable armv7-linux-androideabi`; the local target was absent and its `rust-std` download failed with connection timeout (`os error 10060`). Gradle also could not resolve Flutter's `armeabi_v7a_release` and `x86_64_release` Maven artifacts; the endpoint returned HTTP 403. Flutter automatically retried the same unavailable dependencies, so that redundant retry was stopped. This is an environment/dependency failure, not a reported Dart compilation failure. `rustup target list --installed` showed `aarch64-linux-android` but not armv7.

Arm64-only Android Release APK build: **passed**. Gradle `assembleRelease` completed in **789.3 seconds** and Flutter reported `Built build\app\outputs\flutter-apk\app-release.apk (36.6MB)`. The resulting file was present with a fresh modification time and **38,362,295 bytes**. This validates packaging for Android arm64, not on-device runtime behavior or the unavailable armv7/x64 variants. The build includes the existing unrelated uncommitted UI edits in the working tree; they are not part of the Phase 7 commit. No native ABI, Aubio linkage configuration, or DSP source was changed by Phase 7.

iOS: **not built or tested**. Xcode is unavailable on this Windows host. The shared native source may be configured for iOS, but that is not evidence of an iOS build or runtime test.

## Limits and proposed Phase 8 contract

There is no labeled real-instrument corpus. Synthetic sine waves do not represent attacks, vibrato, breath, noise, transients, polyphony, expressive rubato, or instrument-specific pitch behavior. Phase 6 can mis-segment or misalign notes; Phase 7 faithfully measures its correspondences and cannot repair them. A one-note performance may have unstable global tempo/offset, and end-of-note timing depends on Phase 6 voiced-frame detection. RMS is not loudness and does not measure dynamic expression against a written marking. `soundingDurationRatio` is only a duration proxy, not a frame-level sustain metric. Missing and extra events have no paired pitch/onset/duration errors. The end-to-end test is host synthetic audio, not a device recording.

Phase 8 should consume this immutable, versionable raw assessment report, not reinterpret null as zero. It should first acquire labeled, consented real-instrument recordings across devices, tempi, dynamics and noise conditions; measure segmentation/alignment accuracy and systematic onset latency; and define explicit instrument-aware calibration profiles with uncertainty and missing-data handling. If frame-level sustain or dynamics are required, Phase 8 must define a bounded feature-summary extension without silently changing the Phase 5 ABI. Any eventual 0–100 policy should be optional, versioned, explainable, validated against expert labels, and separately tested for bias and sensitivity. UI or sync should use a stable serialized report schema only after those contracts are agreed; they are outside Phase 7.
