# Open DSP octave/subharmonic investigation

## 1. Executive Summary

All ten previously supplied recordings were found and passed through the existing Phase 3 PCM conversion and production Open DSP path. A test-only instrumented build captured exact rolling YIN/CMND windows at eleven selected real frames. F4/E4 regions repeatedly yielded F3/E3 **in raw DSP**, before segmentation. In those same windows the expected fundamental is spectrally stronger than its half-frequency, but its shorter-period CMND minimum fails the existing 0.15 threshold and the double-period minimum passes. Independent synthetic mixtures reproduce the failure across several target frequencies. **No production pitch fix was made:** a replacement candidate-selection rule has not yet demonstrated safety on true octave notes, mixed sources and release artifacts. No threshold, ABI, downstream stage, or app output changed.

## 2. Scope / Non-Goals

Scope: exact native pitch-decision investigation, independent synthetic truth, regression tests and conditional fix decision. Previous Phase 2/3/4B/5/6/7/7B/7C reports, real calibrations, controlled calibrations and current source were checked; code is authoritative where old prose differs. Out of scope: changing segmentation, alignment, tempo, assessment, scoring, UI, FFI ABI or adding Aubio to production. Validation truth never enters audio observation.

## 3. Input Availability

All `Sornaz_1.m4a` through `Sornaz_10.m4a` and the preceding five controlled-piano recordings were available locally without re-upload. Private absolute paths are omitted from artifacts. Earlier audio hashes, decoder details and complete Phase 3 statistics remain in `MUSIC_ANALYSIS_CONTROLLED_NOTE_BOUNDARY_CALIBRATION_REPORT.md`; this investigation re-prepared all ten and matched its PCM frame counts.

## 4. Exact 10-Case Mapping

| Case | Declared ground truth | Condition |
|---|---|---|
| 01 | F4→E4 (65→64) | detached |
| 02 | F4→E4 (65→64) | legato |
| 03 | F4→E4 (65→64) | slow |
| 04 | F4→E4 (65→64) | fast |
| 05 | F4→E4 (65→64) | soft |
| 06 | F4→E4 (65→64) | loud |
| 07 | F4→F4 (65→65) | repeated |
| 08 | E4→E4 (64→64) | repeated |
| 09 | D4 (62) | very short |
| 10 | D4 (62) | normal duration |

This mapping labels diagnostic regions only; the detector sees PCM alone. Exact attack-time annotations are unavailable.

## 5. Current Open DSP Pitch Algorithm

`native/dsp_engine_open.cpp` uses 44,100 Hz mono float32, a 4096-sample rolling window and 512-sample hop. FFT autocorrelation produces a cumulative mean normalized difference (CMND). Lags 22–551 (approximately 2000–80 Hz) are searched in ascending order. The **first** lag with CMND < 0.15 is followed down to a local minimum. Three-point interpolation yields `44100 / interpolatedLag`; confidence equals `1 - CMND[chosenLag]`. There is no spectral fundamental verification, octave comparison, pitch-continuity check or mixed-source disambiguation. All constants are unchanged.

## 6. Baseline Raw DSP Results

The frozen pre-task baseline is `controlled_note_boundary_raw_features.csv`, `controlled_note_boundary_segments.csv`, `controlled_note_boundary_cross_case.csv`, `controlled_note_boundary_diagnostic_windows.csv` and `controlled_note_boundary_spectrum.csv`; none was rewritten. Near-target/octave-down accepted-frame counts in selected approximate regions: 01 F4 7/34; 02 F4 9/23; 05 E4 0/21; 06 F4 8/31; 07 first/second F4 0/12 and 0/26. Correct-pitch counterexamples: 08 E4 regions 32/6 and 41/4; 09 D4 19/9; 10 D4 41/7. Cases 03/04 lack securely assigned F4 windows and must not be counted as proven octave failures. Baseline performed-note counts 01–10: 7, 9, 7, 5, 3, 8, 3, 6, 2, 2.

## 7. Exact Native Window Instrumentation

`MA_TRACE_YIN` compiles a hook into a separate host diagnostic executable that builds the *same* OpenEngine translation unit. It observes actual `samples_`, `cmnd_`, selected lag and `ma_feature` without modifying selection. The hook is absent from normal production builds. The diagnostic executable pushes Phase 3 headerless float32 PCM through the C ABI in 512-frame chunks; each reported window is `[frameStart+512−4096, frameStart+512)`. `open_dsp_octave_native_trace.csv` contains eleven frames; `open_dsp_octave_candidates.csv` lists local minima; `open_dsp_octave_spectrum.csv` uses the exact same windows. All eleven traced `pitchHz` values match the earlier raw-feature CSV within 5×10⁻¹⁰ Hz of CSV rounding. Expected Hz is diagnostic metadata, not an engine input. The hook occurs before possible C-ABI fallback onset marking, so its pitch and CMND are exact while onset marking may be finalized later.

## 8. Exact Native Failure Frames

| Case | Sample | Time s | Validation Hz | Raw Hz | Chosen lag | Confidence | Observation |
|---:|---:|---:|---:|---:|---:|---:|---|
| 01 | 86016 | 1.9505 | 349.228 | 175.597 | 251 | .916 | F3 in F4 region |
| 01 | 95232 | 2.1595 | 349.228 | 175.225 | 252 | .901 | F3 in F4 region |
| 02 | 82432 | 1.8692 | 349.228 | 175.413 | 251 | .876 | F3 in F4 region |
| 05 | 123392 | 2.7980 | 329.628 | 164.587 | 268 | .902 | E3 in E4 region |
| 06 | 71680 | 1.6254 | 349.228 | 175.544 | 251 | .883 | F3 in F4 region |
| 07 | 70144 | 1.5906 | 349.228 | 175.344 | 252 | .901 | F3 in F4 region |
| 07 | 101376 | 2.2988 | 349.228 | 174.669 | 252 | .901 | F3 in F4 region |
| 02 | 135680 | 3.0766 | 329.628 | 332.034 | 133 | .945 | correct E4 |
| 08 | 79360 | 1.7995 | 329.628 | 331.299 | 133 | .969 | correct E4 |
| 09 | 64000 | 1.4512 | 293.665 | 294.380 | 150 | .947 | correct D4 |
| 10 | 41984 | .9520 | 293.665 | 293.563 | 150 | .979 | correct D4 |

The raw error is measured before Phase 6. The provided ground truth labels regions, but precise boundaries were not manually annotated.

## 9. Exact CMND Candidate Analysis

| Case/sample | Shorter expected lag CMND | Double lag CMND | Selected minimum | Decision |
|---|---:|---:|---:|---|
| 01/86016 | lag 126: .2333 | lag 252: .0878 | lag 251: .0843 | shorter lag fails .15; double passes |
| 01/95232 | lag 126: .1545 | lag 252: .0990 | lag 252: .0990 | shorter narrowly fails |
| 02/82432 | lag 126: .4191 | lag 252: .1248 | lag 251: .1240 | shorter fails |
| 05/123392 | lag 134: .2498 | lag 268: .0983 | lag 268: .0983 | E3 selected |
| 06/71680 | lag 126: .2723 | lag 252: .1200 | lag 251: .1170 | F3 selected |
| 07/70144 | lag 126: .2466 | lag 252: .0994 | lag 252: .0994 | F3 selected |
| 07/101376 | lag 126: .2909 | lag 252: .0989 | lag 252: .0989 | F3 selected |
| 08/79360 | lag 134: .0322 | lag 268: .0219 | lag 133: .0306 | earlier qualifying E4 lag wins |

All local minima appear in the candidate CSV. High confidence measures a good fit at the *selected* period, not the probability that its octave is correct.

## 10. Exact-Window Spectrum Analysis

Hann projections of the exact native window give: case 01/sample 86016 F4 51.01 vs F3 9.88 (half/target .194); case 06/sample 71680 F4 47.40 vs F3 1.35 (.029); case 07/sample 70144 F4 46.37 vs F3 .13 (.003); case 05/sample 123392 E4 60.59 vs E3 3.00 (.050). Several windows also have a substantial distinct component around 140–151 Hz, but its physical source is unknown. Values are relative magnitudes, not SPL. A largest-spectral-peak pitch rule is not proven safe for harmonic-rich or mixed-source audio.

## 11. Period-Doubling / Subharmonic Root Cause

A mixed/complex waveform can have a poor short-period CMND fit even when the expected fundamental dominates its spectral bin. Its near-double-period fit crosses the fixed gate, so the first-qualifying-minimum rule outputs half the target frequency. This is an algorithmic period-selection limitation in Raw DSP, **not** evidence of a decoder sample-rate error or an alignment-created pitch value. The cause of each interfering source and the best general remedy remain unproven.

## 12. Failure Classification

**Proven:** exact raw octave-down results in multiple recordings; gate/lag choice; high-confidence octave error; correct E4/D4 control frames; synthetic independent-frequency reproduction. **Likely:** a distinct lower-frequency component contributes to some real windows' poor shorter-period fit. **Possible:** transient, decay or inharmonic effects contribute to other frames. **Not supported:** global decoding pitch/time rescaling, a universal clean-sine pitch fault, or the claim that every extra segment comes solely from DSP.

## 13. Synthetic Corpus Design

`native/tests/open_dsp_octave_synthetic.cpp` passes float32 samples through the unchanged production C ABI in 512-frame chunks. Its **92 rows** include pure sines 110–1760 Hz; six pitches with strong/weak fundamental, second-harmonic emphasis, decay, inharmonicity and detuning; F3→F4/F4→F5 true octave leaps; E4↔F4 semitone transitions; silence, seeded low noise and impulse; and 36 mixtures of targets 293.66/329.63/349.23/440 Hz with independent 120/150/180 Hz components at gains .04/.10/.20. Truth is used only after analysis. The test asserts clean controls; interference failures are deliberately recorded, not hidden.

## 14. Synthetic Baseline Results

All **56 non-interference control rows passed** median-frequency/unvoiced assertions. Eleven of 36 interference rows contained at least one octave-down frame. Exact counts, medians, confidence and host elapsed milliseconds per row are in `open_dsp_octave_synthetic_results.csv`. Pure sines, ordinary harmonic tones, both true octave leaps and both semitone transition directions are correct in steady regions. Silence, low-level noise and impulse have no voiced steady-region result.

## 15. Synthetic Failure Reproduction

| Target/interferer/gain | Voiced frames | Octave-down | Median Hz | Median confidence |
|---|---:|---:|---:|---:|
| 293.66/150/.10 | 52 | 38 | 146.87 | .999 |
| 329.63/150/.20 | 52 | 52 | 164.24 | .964 |
| 349.23/150/.20 | 52 | 52 | 173.81 | .916 |
| 349.23/180/.10 | 52 | 37 | 174.68 | .998 |
| 440.00/180/.20 | 52 | 52 | 218.88 | .865 |

The mechanism is not confined to F4/E4 or these recordings. A two-tone mixture can also be legitimate polyphony; which source is the intended *monophonic* target is not inherently known. This limits what any blanket octave-up rule could safely do.

## 16. Production Fix Gate

Exact-window, multi-file and independent synthetic reproduction pass. A defensible replacement rule must also preserve genuine lower-octave notes, true octave leaps, mixed-source ambiguity, decay/release behavior and the five earlier piano cases on blinded data. No rule has passed that safety matrix. Raising 0.15 may admit noisy shorter lags; blindly preferring a spectral peak may select a harmonic or another source. Both remain experiments, not approved fixes.

## 17. Production Fix Decision

**No production algorithm change.** The diagnosis is strong, but a safe, general candidate policy is not yet established. `dsp_engine_open.cpp` changes are restricted to `#if defined(MA_TRACE_YIN)` test instrumentation and compile out of normal builds. ABI and feature semantics are unchanged.

## 18. Fix Design

No production fix was designed or shipped. Next, compare score-agnostic shorter-lag evidence, spectral harmonic support and continuity in an isolated diagnostic runner, with an abstain outcome for ambiguous mixtures. Do not modify the default detector until held-out safety tests pass.

## 19. Why The Fix Is General

Not applicable: no fix. The proposed evaluation spans multiple pitches, octaves, amplitudes, interference frequencies, decays and held-out recordings, rather than a note-specific exception.

## 20. Why It Is Not Dataset-Specific

No production constant, MIDI lookup, filename condition, piano rule or expected-frequency hint changed. Synthetic labels are used only to evaluate the output.

## 21. Files Changed

| File | Purpose |
|---|---|
| `native/dsp_engine_open.cpp` | compile-time-only state hook; normal behavior unchanged |
| `native/CMakeLists.txt` | host-only diagnostic and synthetic targets/CTest |
| `native/tests/open_dsp_trace_hook.h` | test-only hook contract |
| `native/tests/open_dsp_yin_trace.cpp` | exact rolling-window, CMND candidates, spectrum probe |
| `native/tests/open_dsp_octave_synthetic.cpp` | independent controls and synthetic reproduction |
| `open_dsp_octave_native_trace.csv` | exact selected real frames |
| `open_dsp_octave_candidates.csv` | all local candidate minima in selected frames |
| `open_dsp_octave_spectrum.csv` | exact-window spectral measurements |
| `open_dsp_octave_synthetic_results.csv` | 92 synthetic baseline rows |
| this report | evidence and production decision |

The temporary PCM and host build files, plus a one-off Dart PCM test, are not deliverables. Existing unrelated worktree changes are excluded.

## 22. New Regression Tests

CTest `music_analysis_octave_synthetic_control` fails if a clean pitched control's steady-region median differs by >5% or silence/seeded low noise/impulse produces voiced steady-region frames. It covers pure, harmonic-rich, decaying, detuned and inharmonic spectra, real octave leaps and semitone changes. The interference rows remain known *diagnostic failures* and are not asserted to pass. Existing native DSP, C ABI and A/B tests remain intact.

## 23. Synthetic Before/After

Baseline only: 92 cases, 11/36 interference rows with octave-down frames, 56/56 other controls passing. No after run exists because production pitch behavior was not changed.

## 24. Ten-Recording Before/After

Before is the frozen full ten-case CSV baseline and the eleven exact frames above. After is **not applicable**: code behavior did not change. All ten files were re-prepared, with frame counts matching the previous Phase 3 results; no false improvement is claimed.

## 25. Previous Five-Take Corpus Before/After

The previous five controlled-piano inputs are present. Their earlier stable-raw-pitch/segmentation pattern differs from the current octave-heavy raw observations. No after comparison is meaningful without an algorithm change.

## 26. Downstream Segmentation Impact

Segmentation was not edited or rerun with altered raw features. Period-doubled frames can create false pitch jumps, but some extra segments also reflect release/background and onset behavior. Attribution of every segment requires annotated attack/release times. The previously frozen performed-note counts remain 7/9/7/5/3/8/3/6/2/2.

## 27. True Octave Leap Safety

Synthetic F3→F4 and F4→F5 controls passed as correct steady regions with current production. Any candidate octave-up or continuity policy must keep these passing. No proposed replacement has done so yet.

## 28. Semitone Transition Safety

Synthetic E4→F4 and F4→E4 steady regions passed. This does not prove fast boundary segmentation, which is outside this task.

## 29. Release / Silence / Noise Safety

Steady silence, seeded low noise and isolated impulse remained unvoiced in controls. Real release artifacts were not manually labelled and remain an explicit safety gate for any new selection policy.

## 30. Performance Before/After

No after measurement exists because production is unchanged. The synthetic CSV records baseline host milliseconds per row, not mobile performance; the trace build adds diagnostic overhead and is excluded from production. A future fix needs like-for-like host and device CPU/memory benchmarks.

## 31. Native ABI Status

Unchanged: no public header, C ABI feature layout, exported function or Dart FFI binding was modified. The C++ hook is private to the host diagnostic build.

## 32. Aubio Production Exclusion

The host test build used `MA_ENABLE_AUBIO=OFF`; the production shared target still consists of `music_analysis_dsp.cpp` and `dsp_engine_open.cpp`. New targets use the Open engine. No Aubio source or library was added to production.

## 33. Full Regression Results

- `cmake --build .native-trace-build --config Release` and `ctest --test-dir .native-trace-build -C Release --output-on-failure`: **4 passed, 0 failed, 0 skipped** (DSP, C ABI, A/B, new synthetic controls).
- `flutter test --no-pub test/analysis_audio_test.dart test/music_analysis_ffi_integration_test.dart test/music_analysis_phase6_test.dart test/music_analysis_phase6_integration_test.dart test/music_analysis_phase7_test.dart test/music_analysis_phase7_integration_test.dart test/music_analysis_calibration_test.dart`: **31 passed, 0 failed, 0 skipped**. Covers Phase 3, host FFI production-open path, Phase 6, Phase 7 and calibration harness.
- Initial `flutter test` without `--no-pub` failed dependency resolution because pub.dev returned an authorization error for `html`; no test ran in that attempt. Cached-dependency offline run above completed.
- Temporary one-off Phase 3 conversion test on all ten real files: **1 passed, 0 failed, 0 skipped**; frame counts matched baseline. It was removed after investigation and is not a committed test.
- Android device test and iOS build/test: **not performed**.

## 34. Build Verification

Windows host CMake Release native test targets built with Aubio disabled. No Android APK/AAB, iOS IPA, desktop application build or installer was produced. Host diagnostic executables are verification-only artifacts and are not packaged.

## 35. Remaining Limitations

Only eleven representative frames were exact-traced, though all baseline raw features are retained. Exact hand-annotated attacks/releases and source isolation are unavailable. The approximately 140–151 Hz component's physical origin is unknown. Synthetic additive mixtures demonstrate the mechanism but cannot by themselves establish a universal intended-source pitch policy. Host FFmpeg-to-Phase3 parity is verified for frame counts; mobile decoder parity and target-device performance were not tested. This corpus cannot close general instrument calibration.

## 36. Recommended Next Step

Run a **diagnostic-only blinded candidate-ranking experiment** on isolated lower/higher octave notes across registers, true octave leaps, repeated notes, controlled two-tone mixtures with known intended source, decay/release and background signals, the prior five piano takes and all ten current takes. Manually annotate stable pitch spans and attack/release times. Compare first-below-0.15 with candidate ranking (CMND short-lag evidence, harmonic structure, continuity, abstention) on per-frame octave-down/up, false-voiced, abstain and runtime metrics. Only a rule that improves held-out failures without regressing clean lower notes, mixed-source/release safety or performance merits a minimal production patch. Then return to controlled segmentation calibration.

## 37. Acceptance Criteria For Returning To Segmentation Work

Require a frozen labelled held-out corpus; exact native traces; reduced real and synthetic octave errors without material regression on true lower notes, octave leaps, semitone transitions, silence, release or ambiguity; bounded target-device CPU/memory; stable confidence semantics; unchanged ABI and Aubio-free production; passing native/Flutter regressions; and manually annotated event boundaries to separate residual raw-DSP from segmentation errors. **These criteria are not yet met; pitch calibration is not closed.**
