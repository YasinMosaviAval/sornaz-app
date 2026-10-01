# Music Analysis — Phase 3 Report

## 1. Scope and result

Phase 3 adds only an offline audio-input and preparation layer for later performance analysis. It does not alter the recorder codec, recording container, original audio file, notation timeline, application UI, persistence, or network behavior. The layer is independent of `RecordingService` and converts a completed recording into an owned, temporary, headerless mono PCM file. No microphone test, application package, or platform build output was produced.

The existing untracked `MUSIC_PERFORMANCE_ANALYSIS_PLAN.md` predates this phase and is excluded from this commit.

## 2. Exact file list and purpose

| File | Status | Reason |
|---|---|---|
| `lib/screens/Notation/analysis_audio.dart` | Added | Defines `AnalysisAudioSource`, `AudioMetadata`, `PcmFormat`, `PcmAudioData`, decoder abstraction, cancellation/error contract, temporary-file ownership, streaming downmix and resampling. |
| `android/app/src/main/kotlin/com/example/sornaz/AnalysisAudio.kt` | Added | Decodes Android AAC recordings with `MediaExtractor` and `MediaCodec` into bounded-buffer temporary signed 16-bit PCM. |
| `android/app/src/main/kotlin/com/example/sornaz/MainActivity.kt` | Modified | Registers the isolated `sornaz/analysis_audio` platform channel. |
| `ios/Runner/AnalysisAudio.swift` | Added | Decodes iOS AAC recordings with `AVAssetReader` into bounded-buffer temporary signed 16-bit PCM. |
| `ios/Runner/AppDelegate.swift` | Modified | Registers the isolated analysis-audio channel. |
| `ios/Runner.xcodeproj/project.pbxproj` | Modified | Includes the new Swift decoder in the Runner target. |
| `test/analysis_audio_test.dart` | Added | Tests PCM conversion, source contract, cleanup, errors and cancellation without a microphone. |
| `MUSIC ANALYSIS PHASE 3 REPORT.md` | Added | Records implementation boundaries, validation and remaining risks. |

## 3. Existing recording path, precisely

[`RecordingService`](lib/screens/Voice%20Recorder/services/recording_service.dart) calls the `record` package with `AudioEncoder.aacLc` on native platforms, a **requested** sample rate of **44,100 Hz**, and **128,000 bit/s**. It does not explicitly set a channel count. The actual decoded rate and channel count are therefore taken from the source track, not assumed from the request. Its 100 ms amplitude callback is only a UI waveform signal and is not the analysis input. Web recording uses Opus and is outside this mobile phase.

[`FileService`](lib/screens/Voice%20Recorder/services/file_service_native.dart) gives a new recording a `.m4a` path in the application Documents `Recordings` directory. A stopped recording may remain there as a private draft. On Android, `publish` copies it into the `Music/Sornaz/` MediaStore collection, or to the user-selected document tree, using MIME `audio/mp4`; only after successful publication does it delete the private staging file. The resulting recording is addressed by a `content://` URI. Android also has `materialize` for a temporary editable copy, but this analysis layer reads the URI directly through `MediaExtractor` and does not depend on `FileService`. On iOS, `publish` returns without moving the file, so the `.m4a` remains in application Documents. The original file is opened read-only by the new decoders.

## 4. Final PCM contract

`AnalysisAudioSource` holds either a local file path or Android `content://` URI; `fromLocation` classifies existing saved-recording locations without importing recorder code. `AudioMetadata` records the decoder-reported source sample rate, channel count, duration and MIME. `PcmFormat.analysis` is **44,100 Hz, one channel, IEEE 754 float32, little-endian, headerless**. `PcmAudioData` owns its temporary file, frame count, format and source metadata. Consumers read it in chunks and call `dispose()` to remove it.

Native decoders first write a temporary **interleaved signed 16-bit little-endian** PCM file at the decoded source rate and channel count. Dart reads this file in chunks, averages channels into mono, converts signed 16-bit samples to `[-1, 1)` float values, and uses streaming linear interpolation only if the source rate differs from 44,100 Hz. Averaging prevents amplitude summation from clipping. **There is no peak normalization, automatic gain, loudness matching, or amplitude scaling to a target.** The intermediate decoded file is removed when preparation finishes or fails; the original compressed file is never rewritten.

## 5. Android and iOS strategy

Android uses `MediaExtractor` to locate the AAC audio track and `MediaCodec` to decode. A worker thread drains input and output buffers, copies at most 64 KiB at a time, verifies 16-bit PCM output, and writes into application cache. Local paths and authorized content URIs are supported. An atomic cancellation flag is checked throughout decoding.

iOS uses `AVURLAsset` and `AVAssetReaderTrackOutput` configured for interleaved 16-bit little-endian linear PCM. It writes data in at most 64 KiB pieces to the app's temporary directory on a utility queue. A locked cancellation flag is checked between sample buffers. iOS accepts local paths; Android content URIs are intentionally rejected there. Both adapters accept the current AAC recording codec and return explicit errors for other tracks or unavailable decoding.

## 6. Memory, temporary files and cancellation

No whole recording is loaded into a Dart `List`. Dart consumes `File.openRead()` chunks, carries only an incomplete interleaved frame across chunks, and writes output in 4,096-frame blocks. Each output block is copied before it is queued for asynchronous file writing, avoiding corruption from buffer reuse. Native code uses bounded buffers and writes decoded samples to disk. Peak storage during conversion can temporarily include the original compressed file, native s16 PCM and final f32 PCM; sufficient free space is therefore required.

`AnalysisCancellation` supports cancellation before work, while native decoding, and between Dart stream chunks. The native adapter receives a `cancel` method call; late-decoder results and partial output are cleaned up. `PcmAudioData.dispose()` is required after a successful conversion. Cancellation cannot interrupt a single currently running platform codec call or synchronous filesystem operation instantaneously, but is checked at the next decoding/streaming boundary.

## 7. Error model

`AnalysisAudioException` carries an `AnalysisAudioErrorCode`:

| Code | Meaning |
|---|---|
| `missingFile` | Missing local source or native-reported absent file. |
| `unsupportedFormat` | Non-AAC track, unavailable platform decoder, or invalid decoded sample rate/channel count. |
| `cancelled` | User or caller cancelled preparation. |
| `decodeFailed` | Native decoder failed or platform returned an unknown decode error. |
| `invalidData` | Empty or incomplete decoded PCM stream. |
| `ioFailure` | Dart filesystem operation failed. |

Unexpected native exceptions are mapped to `decodeFailed`; the original platform message is retained where available. A malformed audio file may be reported as `decodeFailed` rather than `unsupportedFormat`, depending on where the platform decoder rejects it.

## 8. Added tests and scenarios

All tests are in `test/analysis_audio_test.dart` and require no microphone:

1. Stereo downmix preserves half-scale amplitude and negative polarity.
2. Resampling survives arbitrary chunk boundaries and produces the expected interpolated samples.
3. An incomplete interleaved frame raises `invalidData` and removes partial output.
4. A missing local source raises `missingFile` before decoding.
5. Source classification distinguishes `content://` from local paths.
6. Preparation removes intermediate decoded PCM, retains the original file and returns disposable output.
7. Invalid decoded format raises `unsupportedFormat` and cleans the decoder file.
8. Pre-cancelled preparation leaves the source untouched.
9. Cancellation during streaming removes partial output.

The existing phase-2 timeline tests and recorder-draft test were also run as focused regressions.

## 9. Validation commands and exact results

Run from the repository root with the installed Flutter SDK:

```powershell
$env:DART_SUPPRESS_ANALYTICS='true'
dart format lib/screens/Notation/analysis_audio.dart test/analysis_audio_test.dart
dart analyze lib/screens/Notation/analysis_audio.dart test/analysis_audio_test.dart
flutter test --no-pub test/analysis_audio_test.dart test/reference_timeline_test.dart test/recording_draft_test.dart
git diff --check
```

Final validation: formatting completed; focused Dart analysis reported **No issues found**; the focused Flutter run reported **17 tests passed** (9 new audio tests, 7 phase-2 tests, 1 recorder-draft test). `git diff --check` reported no whitespace errors. No application output was generated.

## 10. Not tested in this environment

- No real microphone capture was requested or performed.
- Native Android decode was not compiled or exercised on a device; doing so would create application build output, which is outside the requested work.
- iOS code was not compiled or run because this Windows workspace lacks an Apple toolchain and device/simulator.
- No long-duration real AAC recording, corrupted container, unusual hardware decoder, or low-storage device was tested end-to-end.

## 11. Remaining risks

- Android or iOS platform decoders may expose device-specific PCM layouts or codec behavior; device validation is required before relying on these paths in production.
- Streaming linear interpolation is sufficient to standardize rate for the current 44.1 kHz recorder, where no resampling is needed. For other source rates, it does not provide a high-quality anti-alias filter; fidelity should be measured before accepting arbitrary-rate sources for pitch analysis.
- Downmixing opposite-phase stereo channels can cancel content. The current recorder does not request a specific channel layout, so the actual layout must be inspected on target devices.
- Successful output must be disposed by its future consumer, and temporary storage needs a retention/cleanup policy if the process is killed mid-conversion.
- Playback, recording and native decoding competing for audio resources have not been device-tested.

## 12. Proposed input to phase 4

The next phase can consume a `PcmAudioData` only after successful preparation: a readable **headerless float32 little-endian mono file**, fixed at **44,100 frames per second**, plus an exact frame count and source metadata. Read it in bounded chunks; do not load the full recording. The consumer owns disposal after processing. No later-phase implementation is included here.
