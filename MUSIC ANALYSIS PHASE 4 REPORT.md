# Music Analysis — Phase 4 Report

## 1. Scope and outcome

Phase 4 adds a shared native DSP core using Aubio. It accepts **mono, 44,100 Hz, headerless float32 PCM** from phase 3 through a versioned C ABI and incrementally returns timestamped raw signal features. It does not parse scores, align events, identify final notes, judge performance, score a student, change the UI, connect Dart to native code, or sync data. Phase-2 and phase-3 source files were not changed.

The core, upstream Aubio source, independent native tests, Android NDK integration and iOS Xcode source integration are present. Host native tests pass. A standalone Android ARM64 native library compiles. **iOS was not built** in this Windows environment. No APK, IPA or other application package was built.

## 2. Files added or changed

| Path | Status | Purpose |
|---|---|---|
| `native/music_analysis_dsp.h` | Added | Public, versioned C ABI and fixed-layout feature/configuration types. |
| `native/music_analysis_dsp.cpp` | Added | Bounded incremental processing, Aubio pitch and onset extraction, RMS, peak, clipping and quality features. |
| `native/CMakeLists.txt` | Added | Shared source build for host tests and Android NDK; builds vendored Aubio as a static dependency and the DSP API as a shared library. |
| `native/tests/music_analysis_dsp_test.cpp` | Added | Independent signal, streaming, lifecycle and chunk-invariance scenarios. |
| `native/tests/c_abi_smoke.c` | Added | Compiles and exercises the API from a C translation unit. |
| `native/third_party/aubio/` | Added vendor bundle | Pinned Aubio 0.4.9 source, license and upstream metadata. Exact paths of the 133 upstream files are enumerated in `native/third_party/aubio/SORNAZ_VENDOR_MANIFEST.txt`; the manifest itself is the 134th file. |
| `android/app/build.gradle` | Changed | Registers `native/CMakeLists.txt` for Android external native build. |
| `ios/Runner.xcodeproj/project.pbxproj` | Changed | Registers the shared C++ file and all 60 Aubio C translation units, sets C++17/includes/macros, and preserves C ABI symbols at link time. |
| `.gitignore` | Changed | Excludes temporary standalone native validation directories (`.native-*/`). |
| `.gitattributes` | Changed | Preserves upstream Aubio whitespace as-is while keeping `git diff --check` meaningful for project-owned files. |
| `MUSIC ANALYSIS PHASE 4 REPORT.md` | Added | This report, including contracts and observed validation. |

The pre-existing untracked `MUSIC_PERFORMANCE_ANALYSIS_PLAN.md` is excluded from this phase and its commit.

## 3. Native architecture and Aubio provenance

`music_analysis_dsp.cpp` is the **single shared implementation**. Each context owns one Aubio `yinfast` pitch detector, one Aubio `hfc` onset detector, three Aubio vectors, one partial-hop buffer and a fixed 256-feature ring buffer. Android CMake compiles the pinned Aubio C source to `aubio_vendor` and links it into `libmusic_analysis_dsp.so`. iOS Runner compiles the same C sources and C++ source into the app target. Neither platform uses an online/runtime dependency for feature extraction. No Aubio file decoder is used; input has already been prepared by phase 3.

Aubio is pinned to **0.4.9**, upstream commit `90bd27a23123fcc524c31787c9c8fc0ae4c79378`, from the [official Aubio repository](https://github.com/aubio/aubio/tree/0.4.9). Its source is licensed **GPL-3.0-or-later**, as stated in the vendored `COPYING` and the [upstream license information](https://github.com/aubio/aubio). The project must assess GPL obligations before distributing an application linked with Aubio. Vendoring and static linking do not remove those obligations. The source is retained locally so native builds do not download Aubio.

## 4. DSP parameters and meaning

| Parameter | Value / method | Meaning |
|---|---|---|
| Input | 44,100 samples/s, mono float32, amplitude in `[-1, 1]` | Caller supplies host-memory float samples decoded from phase-3 little-endian PCM; native code never changes the original file. |
| Processing hop | 512 samples (about 11.61 ms) | One feature is emitted per complete hop. |
| Pitch | Aubio `yinfast`, window 4096, hop 512 | Fast YIN-equivalent pitch estimator; [`aubio` documents `yinfast` and its relationship to YIN](https://aubio.org/manual/latest/cli.html). |
| Pitch tolerance | 0.15 | Aubio YIN tolerance. |
| Pitch silence gate | −50 dBFS | Aubio detector setting. |
| Exposed pitch | 80–2000 Hz and confidence ≥0.55 | Outside this range/gate, `pitch_hz` and `pitch_confidence` are zero. This is a signal-validity gate, not a note judgment. |
| Onset | Aubio `hfc`, window 1024, hop 512 | HFC peak-picking emits **candidates**, not accepted musical note starts. |
| Onset threshold/silence/minimum interval | 0.3 / −55 dBFS / 30 ms | Aubio onset settings. |
| Sparse impulse fallback | RMS ≥0.02, >4× previous hop RMS, peak ≥0.1 | Preserves a short isolated transient as another raw candidate when HFC does not trigger. |
| Energy | Mean squared sample amplitude, exposed as `energy` | No peak normalization or automatic gain. |
| RMS | Square root of mean squared amplitude over valid samples | For partial final hops, padded zeroes are excluded. |
| Silence | RMS <0.003 | Simple technical silence flag. |
| Clipping | Fraction of valid samples with absolute value ≥0.999 | Remains available separately from peak amplitude. |
| Signal quality | Zero for silence; otherwise `max(0, 1−4×clipping_fraction)` | Simple signal-health indicator, not SNR or performance quality. |

The `onset_strength` field is Aubio's nonnegative HFC descriptor. The sparse-impulse fallback can set `onset_candidate` without changing that descriptor. Pitch estimates remain monophonic; simultaneous notes are outside this phase's validated scope.

## 5. Complete C ABI contract

The public header is `native/music_analysis_dsp.h`. `MA_ABI_VERSION` is **1**. `ma_abi_version()` returns it. `ma_config` includes `struct_size`, `abi_version`, `sample_rate` and `channels`; `ma_create` currently accepts exactly ABI 1, 44,100 Hz and one channel. All exported functions use `extern "C"`, fixed-width public integers and explicit buffer capacities.

| Function | Contract |
|---|---|
| `ma_create(config, &context)` | Allocates a context on success. Sets output pointer to null on failure. Caller owns successful context. |
| `ma_push_samples(context, samples, count, &consumed)` | Borrows input only during the call, validates each accepted sample, advances by `consumed`, and may return `MA_QUEUE_FULL` after partial consumption. Caller must drain features and retry remaining samples. |
| `ma_finalize(context)` | Processes one zero-padded final hop only if samples remain; returns `MA_QUEUE_FULL` without finalizing if a feature cannot be enqueued. After draining, retry. A second successful finalize returns `MA_FINALIZED`. |
| `ma_read_features(context, output, capacity, &count)` | Copies at most `capacity` structures into caller-owned memory and drains them from the ring. Zero capacity is valid with a null output. |
| `ma_destroy(context)` | Releases all Aubio objects and context memory; null is accepted. No call is valid on the pointer afterward. |
| `ma_status_message(status)` | Returns a static message; caller must not free it. |

Status values: `MA_OK`, `MA_INVALID_ARGUMENT`, `MA_UNSUPPORTED_CONFIG`, `MA_OUT_OF_MEMORY`, `MA_QUEUE_FULL`, `MA_FINALIZED`, `MA_INVALID_SAMPLE` and `MA_INTERNAL_ERROR`. The API is single-context/single-thread at a time; callers must serialize calls on one context. Multiple independent contexts may exist. A non-finite or out-of-range input sample is rejected; `consumed` still reports samples accepted before the bad one, so callers must not assume a call is atomic. The ring holds at most **256** features, independent of recording length. A caller that never drains it receives backpressure.

## 6. Feature model and timing

Each `ma_feature` contains `frame_start_sample` (`uint64`), `frame_valid_samples` (`uint64`), `onset_sample` (`uint64`), `timestamp_seconds` (`double`), `pitch_hz`, `pitch_confidence`, `onset_strength`, `energy`, `rms`, `peak_abs`, `clipping_fraction`, `signal_quality` (`float`), and flags `onset_candidate`, `is_silent`, `is_partial` (`uint32`). All copied feature memory belongs to the caller.

`frame_start_sample` is the absolute sample index of the current **512-sample hop**. `timestamp_seconds = frame_start_sample / 44100`. A pitch estimate uses Aubio's causal history (up to its 4096-sample window), so the timestamp marks the hop being reported, not the centre of the entire pitch window. For a candidate onset, `onset_sample` is Aubio's corrected onset sample or the sparse-impulse peak sample. It is meaningful only when `onset_candidate = 1`. An exact multiple of 512 input samples produces no extra final frame. A final incomplete hop produces one feature with `is_partial = 1`; Aubio receives zero padding, while energy and clipping use only `frame_valid_samples` original values. No final symbolic note or musical timing judgment is produced.

## 7. Native test scenarios: input, expected result and observed result

| Scenario | Input | Expected | Observed |
|---|---|---|---|
| Steady sine | 440 Hz, 1 s, amplitude 0.5 | Median voiced pitch within 5 Hz, RMS about 0.3535, energy about 0.125, peak about 0.5 | PASS |
| Consecutive pitches | 440 Hz then 660 Hz, 0.5 s each | Each stable region within 8 Hz of its frequency | PASS |
| Silence | 1 s of zeroes | All frames silent, pitch and RMS zero | PASS |
| Sparse onset | Single amplitude-0.8 impulse at one third of a second | At least one raw onset candidate | PASS |
| Amplitude change | 0.1-gain then 0.8-gain 440 Hz | Later RMS >5× earlier RMS | PASS |
| Clipping | 4096 samples at +1.0 | Clipping fraction >0.99 and signal quality <0.01 | PASS |
| Chunk invariance | Same 440 Hz signal in chunks of 1, 257, 512, 4096 and 16384 samples | Same count, sample positions, RMS, pitch and onset flags | PASS |
| Partial final hop | 513 samples at 0.25 | Two frames; second has one valid sample and RMS 0.25 | PASS |
| Invalid data/lifecycle | NaN, 1.1, wrong ABI, repeated finalize, push after finalize | Explicit status and consumed count | PASS |
| Longer incremental stream | 120 s of repeated 220 Hz data, drained periodically | Expected feature count with bounded queue | PASS |
| Pure C caller smoke | 512 zero samples through public C header | Create/push/finalize/read/destroy and silent feature | PASS |

These are synthetic native tests, not instrument recordings or device tests. `ctest` reported **2/2 test executables passed**; the C++ executable prints ten scenario PASS lines and the C executable returned zero.

## 8. Validation commands and actual outcomes

Host validation was run with the local Visual Studio CMake toolchain:

```powershell
cmake -S native -B .native-test-build -G 'Visual Studio 17 2022' -A x64 -DBUILD_TESTING=ON
cmake --build .native-test-build --config Debug --target music_analysis_dsp_test music_analysis_c_abi_smoke --parallel 4
ctest --test-dir .native-test-build -C Debug --output-on-failure
```

Result: configuration and build succeeded. The final CTest run reported **100% tests passed, 0 failed out of 2**, total **24.74 s**. The C++ executable also ran directly and printed all ten scenario PASS lines. The first host build required adding Aubio's `HAVE_C99_VARARGS_MACROS` definition for MSVC; this is included in the final CMake and iOS settings.

Standalone Android ARM64 validation used the local NDK 28.2.13676358 and Ninja:

```powershell
cmake -S native -B .native-android-arm64-check -G Ninja -DCMAKE_MAKE_PROGRAM='<local ninja.exe>' -DCMAKE_TOOLCHAIN_FILE='<local NDK>/build/cmake/android.toolchain.cmake' -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -DBUILD_TESTING=OFF
cmake --build .native-android-arm64-check --target music_analysis_dsp --parallel 4
llvm-nm -D .native-android-arm64-check/libmusic_analysis_dsp.so
git diff --check
```

Result: standalone Android configuration and native compilation succeeded, producing `libmusic_analysis_dsp.so` (1,984,984 bytes in this local build). `llvm-nm` showed exported `ma_abi_version`, `ma_status_message`, `ma_create`, `ma_push_samples`, `ma_finalize`, `ma_read_features` and `ma_destroy`. The final `git diff --check` reported no whitespace errors. The Android **Gradle application build and APK packaging were not run**, so integration inside a complete app package is not verified here. The first sandboxed NDK configure stalled during compiler checks; the approved unsandboxed configure and build succeeded.

## 9. iOS build status

The Xcode project references all **60 Aubio C files** and the shared C++ file, with C++17, header paths and build definitions. A static project check found 61 native source references and no duplicate generated project IDs. **No iOS compile or link was run:** this workspace is Windows and has no Xcode/iOS SDK. iOS build readiness is source-level only; symbol retention and linking need verification on macOS. No IPA was produced.

## 10. Limits and remaining risks

- YIN returns a dominant monophonic pitch; it does not separate polyphonic notes.
- HFC and the impulse fallback produce candidates, including possible false positives. Thresholds require real instrument recordings before product use.
- Signal quality is a simple silence/clipping proxy, not a measured SNR or diagnosis of microphone conditions.
- The phase-3 linear resampler may alias when source audio is not already 44.1 kHz; native extraction assumes its declared input contract is met.
- Aubio's onset sample accessor uses an upstream 32-bit sample counter, so extremely long continuous streams can wrap the onset sample position even though the wrapper's frame positions are 64-bit.
- iOS target compilation and complete Android Gradle packaging remain unverified.
- GPL-3.0-or-later compatibility and redistribution obligations need project-level review before shipping the app with Aubio.

## 11. Exact contract for phase 5

Phase 5 may read `PcmAudioData` from phase 3 as bounded **float32 little-endian mono blocks at 44,100 Hz**, convert each block to a temporary `float*` buffer, and call the C ABI on a worker isolate. It must pass `ma_config{sizeof(ma_config), 1, 44100, 1}`, honor `consumed` and `MA_QUEUE_FULL` by draining the fixed queue, call `ma_finalize` until it succeeds, drain remaining features, and call `ma_destroy` in every success/error/cancel path. It should preserve sample indices and confidence in Dart models and release the phase-3 temporary PCM file after processing. That bridge is **not implemented in phase 4**.
