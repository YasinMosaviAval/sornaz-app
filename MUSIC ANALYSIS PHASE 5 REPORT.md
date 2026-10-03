# Music analysis — Phase 5 report

## Scope and result

Phase 5 connects the Phase 3 PCM output to the Phase 4B native signal engine through Dart FFI. The public native ABI is unchanged: `MA_ABI_VERSION` remains 1, the native header and C++ source were not edited, and the Dart side consumes the existing 16-byte config and 80-byte feature records. The bridge explicitly requests `MA_ENGINE_OPEN`; a product-mode runtime check rejects any library reporting the Aubio engine. It emits only immutable, timestamped raw features. There is no alignment, note classification, musical scoring, UI, persistence, or upload in this phase.

The bridge was exercised against a real Aubio-free Windows host native DLL, including a full Phase 3 preparation → FFI → raw-feature test. A standalone Android arm64-v8a native library built successfully with Aubio disabled. No APK, AAB, IPA, or other application package was generated. iOS was not built because this Windows environment has no Xcode toolchain.

## Repository inputs reviewed

- `MUSIC ANALYSIS PHASE 3 REPORT.md` and `lib/screens/Notation/analysis_audio.dart`: `PcmAudioData` owns a temporary headerless mono IEEE float32 little-endian file at 44,100 Hz, with exact frame count and explicit disposal. The Phase 3 decoder and original compressed file remain unchanged.
- `MUSIC ANALYSIS PHASE 4B REPORT.md`, `native/music_analysis_dsp.h`, `native/music_analysis_dsp.cpp`, `native/CMakeLists.txt`, and the platform build settings: ABI 1, 512-sample hop, 256-feature native queue, explicit open-engine selector, and production CMake option `MA_ENABLE_AUBIO=OFF`.
- Existing `pubspec.lock`: `ffi` 2.2.0 was already resolved transitively. It is now declared directly; no new version or source archive was introduced. The locally cached package carries a BSD-style license in its `LICENSE` file.

## Files added or changed

| File | Purpose |
| --- | --- |
| `lib/screens/Notation/music_analysis_features.dart` | Independent immutable Dart representation of every raw native feature field. |
| `lib/screens/Notation/music_analysis_ffi.dart` | ABI-1 structs and function bindings, open-engine selection, bounded streaming, cancellation, error mapping and native ownership. |
| `test/music_analysis_ffi_integration_test.dart` | Real native FFI integration and Phase 3-to-native scenarios. |
| `pubspec.yaml` | Makes the already resolved `ffi` package a direct dependency. |
| `pubspec.lock` | Marks the same `ffi` 2.2.0 package as `direct main`; package hash and source are unchanged. |
| `ios/Runner.xcodeproj/project.pbxproj` | Adds the two already-existing Phase 4B C symbols used by FFI to iOS linker retention flags for Debug, Profile and Release. |
| This report | Records architecture, exact validation, build status and limits. |

Pre-existing uncommitted top-bar edits, `MUSIC_PERFORMANCE_ANALYSIS_PLAN.md`, and `android/app/.cxx/` were left outside this phase and commit.

## FFI contract and feature model

`MusicAnalysisFfi.open()` loads `libmusic_analysis_dsp.so` on Android and resolves symbols from the Runner process on iOS. An explicit `libraryPath` is available for standalone host tests. Startup checks `ma_abi_version()==1`, `sizeof(ma_config)==16`, `sizeof(ma_feature)==80`, and availability of the open engine. Missing libraries, missing exported symbols, and ABI mismatch are separate errors. In product mode, an available Aubio engine is treated as a configuration error.

The bridge binds the existing functions `ma_abi_version`, `ma_available_engines`, `ma_create_with_engine`, `ma_push_samples`, `ma_finalize`, `ma_read_features`, and `ma_destroy`. `ma_create_with_engine` always receives engine ID **1**, the open engine. `size_t` is represented by Dart FFI `Size`; sample indices use `Uint64`; status/engine values use 32-bit integers. No native declaration, function signature, field order, size, or feature interpretation was changed. The iOS linker flags now retain `ma_available_engines` and `ma_create_with_engine` alongside the earlier ABI symbols; an actual iOS link has not been run.

The Dart `RawAudioFeature` copies all 15 native fields before the native output buffer can be reused: `frameStartSample`, `frameValidSamples`, `onsetSample`, `timestampSeconds`, `pitchHz`, `pitchConfidence`, `onsetStrength`, `energy`, `rms`, `peakAbs`, `clippingFraction`, `signalQuality`, `onsetCandidate`, `isSilent`, and `isPartial`. It is independent of recorder and notation models and contains no final notes or judgments.

## Streaming, ownership and cancellation

`extract(PcmAudioData, cancellation: ...)` returns a single-use `Stream<RawAudioFeature>`. Before allocation, it validates mono/44,100 Hz/float32 little-endian format, nonnegative frame count and exact `frames × 4` file length. It opens the temporary file as a stream, carries only 0–3 bytes between file chunks, decodes floats without amplitude normalization, and pushes at most **4,096 samples per native call**. It handles partial consumption and `MA_QUEUE_FULL` by draining batches of at most **64** features; finalization is retried after draining when necessary. The whole recording and whole feature sequence are never accumulated by this layer. The caller retains ownership of `PcmAudioData` and must dispose it after the stream completes or is cancelled.

An `Arena` owns the six fixed native buffers, including the config, context pointer slot, input samples, output features and two `size_t` counters. The native context is destroyed before the arena is released in `finally`, including on exceptions, stream cancellation and consumer cancellation. A failed intermediate allocation is also covered by the arena. Native feature fields are copied to Dart values before the next read. Contexts are per stream; no shared mutable native context is used.

The existing Phase 3 `AnalysisCancellation` token is checked before file access, before each input batch, before native calls and before yielding each feature. Cancellation is cooperative: it stops at the next I/O or frame boundary and does not interrupt a currently executing synchronous native call. The input chunk is bounded, so a single call cannot contain the entire file. Cancelling a stream subscription also runs the async generator's cleanup path.

## Error categories

| Dart code | Trigger |
| --- | --- |
| `unsupportedPlatform` | No default native library path for this platform. |
| `libraryUnavailable` | The selected shared library cannot be loaded. |
| `missingSymbol` | One of the required ABI-1 functions is absent. |
| `abiMismatch` | Version/layout/open-engine check fails, or a product library advertises Aubio. |
| `unsupportedFormat` | PCM contract differs from Phase 3 or native rejects the config. |
| `missingFile` | Phase 3 PCM file is absent or cannot be statted. |
| `invalidPcm` | Wrong byte length, truncated stream, NaN/Infinity or out-of-range sample. |
| `cancelled` | Token is cancelled before or during extraction. |
| `outOfMemory` | Native status 3 or Dart native-buffer allocation failure. |
| `nativeFailure` | Invalid native progress, queue/read inconsistency or other native status. |
| `ioFailure` | Filesystem error while streaming an opened PCM file. |

Each failure is a `MusicAnalysisException` containing a category and a human-readable diagnostic. No error from this layer is converted to a musical result.

## Tests and observed results

`test/music_analysis_ffi_integration_test.dart` runs against the **real Aubio-free** host DLL and covers: library-load failure; the available-engine bitmask being exactly 1; 440 Hz sine with raw pitch/RMS/energy/peak and sample-clock timing; final partial frame; Phase 3 signed-16 decoder fixture through `AnalysisAudioPreparer` into FFI while preserving the original source; silence and clipping without amplitude rescaling; cancellation after the first emitted feature followed by successful reuse with a new context; missing PCM and pre-cancelled request; and wrong format, wrong file length and NaN. The existing nine Phase 3 audio tests were run alongside it. No microphone is needed.

Validation from the repository root, using the installed Flutter SDK and the already built production-mode host DLL at `.native-host-prod/Release/music_analysis_dsp.dll`:

```powershell
dart format lib/screens/Notation/music_analysis_ffi.dart lib/screens/Notation/music_analysis_features.dart test/music_analysis_ffi_integration_test.dart
dart analyze lib/screens/Notation/music_analysis_ffi.dart lib/screens/Notation/music_analysis_features.dart test/music_analysis_ffi_integration_test.dart
flutter test --no-pub test/music_analysis_ffi_integration_test.dart test/analysis_audio_test.dart
git diff --check
```

Observed: formatter made no further changes on the final run; **Dart analysis: No issues found**; **17 tests passed, 0 failed** (8 new FFI tests and 9 Phase 3 tests); `git diff --check` found no whitespace errors. The host test checks the DLL's engine bitmask at runtime, so it cannot silently run against a comparison build containing Aubio.

`flutter pub get --offline` was attempted and **failed** because the unrelated `html` package was absent from this environment's offline cache. `ffi` 2.2.0 itself was already in the project lockfile and local cache, and the targeted analyzer/tests resolved it through the existing package configuration. The lockfile's dependency classification was updated to match the new direct declaration without changing its version, hash or source. A normal dependency-resolution run remains necessary when the complete package cache or network is available.

## Android and iOS build status

The Android **arm64-v8a native library only** was configured with NDK 28.2.13676358, CMake 3.22.1, `ANDROID_PLATFORM=android-23`, Release mode and `MA_ENABLE_AUBIO=OFF`, then built successfully. The build compiled `music_analysis_dsp.cpp` and `dsp_engine_open.cpp` and linked `libmusic_analysis_dsp.so`. `build.ninja` contained **0** Aubio entries; `llvm-nm` on the full shared object found **0** Aubio/new_fvec/del_fvec symbols; `llvm-readelf -d` showed only `libm.so`, `libdl.so` and `libc.so` as direct shared dependencies. The exported symbol table contains all seven functions required by this FFI bridge. This verifies the native Android arm64 artifact, not a complete Flutter/Gradle application build or other Android ABIs. No application output was requested or generated.

iOS: **not built or tested**. `xcodebuild` is unavailable on this Windows host. The Runner project now retains the two additional symbols in Debug/Profile/Release, while its existing Profile/Release configuration excludes Aubio C sources and omits the Aubio macro. A macOS Release build and exported-symbol inspection are still required before claiming iOS release validation. The broad iOS `*.c` exclusion from Phase 4B also still requires Xcode audit.

## Remaining limits and next input

Tests use synthetic audio and a fixture decoder; actual microphone/codec behavior and Android/iOS device runtime were not tested here. The Dart stream runs native calls synchronously on its isolate for each bounded batch; device latency and cancellation responsiveness should be measured on representative recordings. A PCM file modified concurrently after its initial length check may produce an I/O or truncation error. The bridge does not persist features or connect them to a score.

The next phase may consume the `Stream<RawAudioFeature>` after successful Phase 3 preparation, retain exact sample-index timing, and make any musical decisions in a separate layer. It should first complete the iOS Release build/symbol audit and Android device integration test. Phase 5 itself makes no such musical decisions.
