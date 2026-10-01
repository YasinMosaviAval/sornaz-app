# Music analysis — Phase 4B report

## Scope and result

Phase 4B adds a second, independently implemented signal engine and compares it with the Phase 4 Aubio engine on identical 44,100 Hz mono float32 PCM. Both emit the existing raw, timestamped `ma_feature` records; neither makes musical judgments. The default engine and production build are now the in-house MIT-licensed engine. Aubio is retained only behind an explicit comparative-build switch. No Dart FFI, alignment, scoring, UI, or later-phase work was added. No APK or other application package was built.

The comparison is against known synthetic truth, not merely against agreement between engines. Both engines passed the original Phase 4 scenarios, and the production Android arm64 native library was linked with Aubio disabled. iOS source configuration was updated, but an iOS build was unavailable on this Windows host.

## Files added or changed

| File | Reason |
| --- | --- |
| `native/dsp_engine.h` | Internal C++ engine contract; no public feature-layout change. |
| `native/dsp_engine_open.cpp` | Original open engine: FFT-assisted normalized difference pitch and spectral-flux onset descriptor. |
| `native/dsp_engine_aubio.cpp` | Isolates Phase 4 Aubio code behind a compile-time option. |
| `native/open_dsp/LICENSE` | MIT license for the new original engine. |
| `native/music_analysis_dsp.cpp` | Keeps stream, queue, timing, energy, RMS, clipping, quality, and sparse-impulse logic common to both engines; dispatches engines. |
| `native/music_analysis_dsp.h` | Additive engine-selection API; retains ABI version 1 and existing types/functions. |
| `native/CMakeLists.txt` | `MA_ENABLE_AUBIO=OFF` by default; builds vendor code only for explicit A/B builds; registers tests. |
| `android/app/build.gradle` | Explicitly configures the Android native build with Aubio OFF. |
| `ios/Runner.xcodeproj/project.pbxproj` | Adds both C++ sources; Debug enables comparative Aubio, while Profile/Release exclude Aubio C sources and omit its macro. |
| `native/tests/music_analysis_dsp_test.cpp` | Runs the preserved Phase 4 suite independently against either engine; asserts ABI struct sizes. |
| `native/tests/c_abi_smoke.c` | Checks additive engine availability and unsupported-engine error through the C ABI. |
| `native/tests/ab_benchmark.cpp` | Identical-PCM A/B runner, absolute-truth metrics, raw feature CSV, and onset timing error. |
| `native/tests/results/phase4b_raw_features.csv` | Captured raw per-frame outputs for both engines and synthetic cases. |
| `native/tests/results/phase4b_pitch_summary.csv` | Captured pitch error, voiced coverage, and runtime. |
| `native/tests/results/phase4b_onset_summary.csv` | Captured absolute impulse onset error. |
| This report | Reproducible evidence, limitations, and Phase 5 contract. |

Pre-existing untracked `MUSIC_PERFORMANCE_ANALYSIS_PLAN.md` and `android/app/.cxx/` were not edited or included.

## Architecture and algorithm

`ma_context` owns one `DspEngine` and a bounded 256-feature ring. Its borrowed input hop is 512 samples; it never retains an input file. The common wrapper computes mean-square energy, RMS, peak, clipping fraction, silence gate (`RMS < 0.003`), and simple signal quality without rescaling amplitudes. It retains the original sparse-impulse fallback. Engine output is then queued in the unchanged feature record. Each context owns its own FFT state, so contexts can process independent streams without shared mutable state.

The open engine is original C++17 code using only the standard library. It maintains a sliding 4096-sample window. A radix-2, 8192-point zero-padded FFT computes linear autocorrelation. Prefix sums of squared samples form the YIN-style difference function `d(tau) = sum(x[i]^2) + sum(x[i+tau]^2) - 2*autocorrelation(tau)`. Cumulative mean normalization is evaluated for lags corresponding approximately to 80–2000 Hz. The first local minimum below 0.15 is refined with parabolic interpolation; confidence is `clamp(1 - normalized_difference, 0, 1)`. Pitch is gated on a voiced frame. Positive spectral flux over the first 511 non-DC bins gives raw onset strength; a flux threshold of 0.38, RMS increase of 1.35, and 30 ms spacing yield candidates. The common sparse-impulse fallback remains active. These are raw estimates, not final notes or rhythm decisions.

The Aubio path retains Phase 4 `yinfast` pitch (4096/512, tolerance 0.15, confidence 0.55, 80–2000 Hz) and `hfc` onset (1024/512, threshold 0.3, 30 ms minimum interval). Its input, common energy/quality features, queue, and timing are identical to the open path. The two algorithms have different onset descriptors, so descriptor magnitudes must not be compared as if calibrated identically.

## License and publication separation

The new engine adds **no third-party source or binary dependency**. Its implementation is original and licensed MIT in `native/open_dsp/LICENSE`; [OSI lists MIT as an approved license](https://opensource.org/license/mit). The existing vendored Aubio identifies itself as **0.4.9** in `native/third_party/aubio/VERSION`; its `COPYING` is GPL-3.0, and [upstream identifies Aubio as GPLv3 or later](https://github.com/aubio/aubio/blob/master/setup.py). The GPL comparison path is opt-in (`-DMA_ENABLE_AUBIO=ON`) and is not a production dependency. No license claim is made for the entire application from this engine-specific license; distribution review still must consider all application dependencies.

The production CMake target has no `aubio_vendor` target, no Aubio source file, and no Aubio include path when `MA_ENABLE_AUBIO=OFF`. Android Gradle passes that value explicitly. For iOS, Runner Debug retains comparative sources, while Profile/Release exclude `*.c` (the Aubio vendor C files in Runner) and compile the Aubio C++ translation unit as empty because `MA_ENABLE_AUBIO` is undefined. The iOS exclusion rule needs an Xcode build audit before release because it is broader than the vendor directory.

## ABI and feature contract

`MA_ABI_VERSION` remains **1**. Existing `ma_create`, `ma_push_samples`, `ma_finalize`, `ma_read_features`, `ma_destroy`, and status functions retain names and signatures. `ma_config` remains 16 bytes and `ma_feature` remains 80 bytes on the tested x64 ABI; all existing fields and their order are unchanged. Frame start, valid count, and onset position are sample indices; timestamp is frame start divided by 44,100. Final incomplete hop is zero-padded only inside the engine and reports its original valid count. Input remains finite `[-1, 1]` mono float PCM at 44.1 kHz. No destructive normalization was added.

The additive `ma_create_with_engine(config, MA_ENGINE_OPEN|MA_ENGINE_AUBIO, out)` selects a path for native A/B tests; `ma_available_engines()` reports its availability bitmask. Ordinary `ma_create` chooses the open engine. Requesting Aubio from a production binary returns `MA_UNSUPPORTED_CONFIG`. No engine choice or new feature struct is required of an ABI-1 consumer. Context lifetime and caller-owned output buffer rules remain unchanged. Engine allocation failure maps to `MA_OUT_OF_MEMORY` instead of crossing the C boundary as a C++ allocation exception.

## Quantitative comparison

Windows x64 Release build, identical 1.0-second, gain-0.5 pure sine input, 737-sample push chunks; median absolute error is computed **separately against the known frequency** over voiced frames from 0.25 seconds onward. Runtime is elapsed wall time for processing and draining, not a device-wide CPU benchmark. Values below are from the committed CSV; small timing changes are expected on rerun.

| Truth Hz | Open error Hz | Aubio error Hz | Open voiced/total | Aubio voiced/total | Open ms | Aubio ms |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 110 | 0.000298 | 0.000298 | 84/87 | 83/87 | 174.608 | 63.655 |
| 220 | 0.001007 | 0.001053 | 84/87 | 83/87 | 127.951 | 40.736 |
| 440 | 0.018433 | 0.018860 | 84/87 | 83/87 | 156.135 | 51.209 |
| 660 | 0.063599 | 0.064880 | 84/87 | 83/87 | 159.209 | 75.293 |
| 880 | 0.169495 | 0.171753 | 84/87 | 83/87 | 135.945 | 47.309 |
| 1760 | 1.391602 | 1.399170 | 84/87 | 83/87 | 148.473 | 43.278 |

For an impulse at known sample **14700**, the nearest candidate from each engine was sample **14700**: absolute error **0 samples** (0 ms). The common fallback can produce this exact candidate, so this result is not evidence that either spectral onset detector alone is sample accurate. The open FFT implementation is approximately 2.1–3.4× slower than Aubio on these short Windows host runs. The test does not measure mobile power, memory peak, polyphonic pitch quality, or real-instrument accuracy.

## Test coverage and results

The unchanged Phase 4 scenarios run against **both** engines: 440 Hz sine and amplitude metrics; consecutive 440/660 Hz tones; silence; impulse onset; quiet-to-loud dynamics without normalization; clipping/quality; chunks of 1, 257, 512, 4096 and 16384 samples with invariant frames/pitch/onsets; partial final hop; NaN/out-of-range samples, invalid ABI, finalize/push lifecycle; and a 120-second incremental stream with bounded output queue. The new benchmark adds 110, 220, 880 and 1760 Hz absolute-truth cases, plus raw captures of silence, impulse, dynamics, clipping and partial frames. The C smoke test remains.

Validation commands and observed results:

```text
cmake -S native -B .native-ab-build -G "Visual Studio 17 2022" -A x64 -DMA_ENABLE_AUBIO=ON -DBUILD_TESTING=ON
cmake --build .native-ab-build --config Release --parallel 2
ctest --test-dir .native-ab-build -C Release --output-on-failure
```

**4/4 passed, 0 failed**: open Phase 4 suite 18.18 s; Aubio Phase 4 suite 6.28 s; C ABI smoke 0.05 s; A/B benchmark 1.60 s; total 26.13 s. The benchmark asserts under 10 Hz absolute median error on every listed tone and records exact synthetic onset truth/error.

```text
cmake -S native -B .native-host-prod -G "Visual Studio 17 2022" -A x64 -DMA_ENABLE_AUBIO=OFF -DBUILD_TESTING=ON
cmake --build .native-host-prod --config Release --parallel 2
ctest --test-dir .native-host-prod -C Release --output-on-failure
```

**3/3 passed, 0 failed** in the independent production configuration after the allocation-error handling change: open Phase 4 suite 21.44 s, C ABI smoke 0.06 s, open-only benchmark 1.11 s; total 22.65 s. The Aubio test target was not registered. After extending the C smoke test with engine-availability and unsupported-engine checks, that test passed again in both A/B and production modes (1/1 each).

The raw data files under `native/tests/results/` are versioned evidence. Running the A/B executable in a chosen working directory regenerates `ab_raw_features.csv`, `ab_summary.csv`, and `ab_onset_summary.csv` there.

## Android production build and proof of no Aubio linkage

Only the **native arm64-v8a library** was built, not an APK/AAB:

```text
cmake -S native -B .native-android-prod -G Ninja \
  -DCMAKE_MAKE_PROGRAM=C:/dev/sdk/android-sdk/cmake/3.22.1/bin/ninja.exe \
  -DCMAKE_TOOLCHAIN_FILE=C:/dev/sdk/android-sdk/ndk/28.2.13676358/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-23 \
  -DCMAKE_BUILD_TYPE=Release -DMA_ENABLE_AUBIO=OFF -DBUILD_TESTING=OFF
cmake --build .native-android-prod --parallel 2
```

**Passed:** `libmusic_analysis_dsp.so` linked. CMake compiled only `music_analysis_dsp.cpp` and `dsp_engine_open.cpp`; `build.ninja` contained no Aubio entry. `llvm-nm` on the entire `.so` returned **0** Aubio/new_fvec/del_fvec symbol matches. `llvm-readelf -d` listed only `libm.so`, `libdl.so`, and `libc.so` as direct shared-library dependencies; **no Aubio dependency**. Exported ABI-1 symbols included the original functions plus the additive engine-selection functions. This is evidence for this arm64 native build, not an assertion about an unbuilt full application package or other ABIs.

## iOS status and remaining risks

iOS build: **not run**; Xcode and an iOS toolchain are unavailable on this Windows machine. Shared C++ source and Xcode project entries are ready, but compiling both Debug and Release on macOS, inspecting Release symbols, and ensuring `*.c` exclusion does not hide another needed Runner C source are still required. Android was validated for arm64 only; other Android ABIs and complete app integration were not built in this phase.

Other limitations: synthetic single tones are easier than singing/instruments; octave errors, breath/noise, vibrato, polyphony, and transitions need a curated audio corpus. Open-engine CPU time is materially higher than Aubio and mobile power/latency has not been measured. Onset strength scales differ between engines. The quality metric is intentionally simple and does not estimate SNR. The test CSV is a Windows host snapshot, not a cross-device reproducibility guarantee. A static MIT license should be reviewed by the project's rights holder before distribution if project ownership requires a different copyright notice.

## Exact input recommendation for Phase 5

Only after Phase 4B acceptance, Phase 5 should consume the existing Phase 3 PCM chunks (mono float32, 44,100 Hz, finite `[-1,1]`, no header or destructive amplitude normalization) through the existing ABI-1 stream lifecycle, use production `ma_create` (open engine), drain at most 256 queued records per call, and keep sample-index timing intact. Its first gate should be an iOS Release symbol/build audit and mobile performance checks on a small labeled real-audio corpus. Engine selection is for native comparison and should not become scoring policy. Phase 5 may add Dart FFI only then; it should not infer correctness from agreement between engines and should use separately labeled pitch/onset truth.
