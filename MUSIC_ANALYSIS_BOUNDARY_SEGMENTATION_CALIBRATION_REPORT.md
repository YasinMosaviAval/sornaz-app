# Sornaz — Boundary / Note Segmentation Calibration

## 1. Executive Summary

All **35/35** existing real recordings were found and processed with the frozen Phase 3 → production Open DSP/FFI → Phase 6 segmenter. Musical note sequences are supplied for **33** monophonic cases; R07/R08 are polyphonic stress recordings and excluded from scoring. The baseline produced **135** PerformedNotes from **13,066** raw features. It reproduced the recurring F4→E4 under-segmentation in all five controlled piano takes; R01/R02 remain one note and R03/R04 remain two. R05/R06 each produce three same-pitch notes where one musical note is supplied. Numerous other count excesses are confounded by demonstrated raw octave/subharmonic errors and unlabeled release timing.

There is defensible evidence of a segmentation boundary failure at F4→E4, but no tested general policy passes the full safety gate. The best diagnostic policy, onset-assisted three-frame pitch confirmation, restores the complete seven-note sequence in C01–C03 but creates a new 64→62→62→64 sequence in R06 and leaves repeated-note and tail failures. **Decision A — No production segmentation change justified.** Raw DSP, ABI, FFI, tempo, alignment, assessment and Aubio production status remain unchanged. **NO NEW APK REQUIRED.** Next, independently label a small set of attack/key-up boundaries and discriminate release from a new attack before revisiting a production rule.

## 2. Scope / Non-Goals

This is score-independent observation and test-only experimentation. Expected pitches and note counts are used solely after segmentation. No candidate was fed MusicXML or ground truth. Polyphony, pitch-DSP correction, confidence changes, scoring changes and app binaries are outside scope.

## 3. Repository State

The current Dart segmenter and native feature contract were the authority. Unrelated pre-existing worktree edits and untracked files were left untouched. The production detector, first-qualifying CMND selection and confidence semantics are frozen as requested. This investigation used the existing Aubio-free host production DLL, not a new native build.

## 4. Reports Reviewed

Phase 2–7C reports and implementation/tests, both real-calibration reports, controlled piano and controlled boundary reports, octave/subharmonic report, blinded candidate-ranking report, release/voicing/ambiguity report, and `MUSIC_ANALYSIS_TARGETED_REAL_AUDIO_DSP_VALIDATION_REPORT.md`. Prior conclusions were cross-checked against current code and the newly extracted feature stream. Prior artifacts supplied region context, not independent physical onset truth.

## 5. Input Availability

N01–N12 **12/12**, P01–P10 **10/10**, C01–C05 **5/5**, R01–R08 **8/8**: **35/35** available and processed. `segmentation_input_manifest.csv` contains safe filenames, canonical frame counts and scoring status. The earlier 92-case and 16-case held-out synthetic corpora and their pitch artifacts were present; they were not mislabeled as independently timed boundary truth. R07/R08 remain diagnostic only.

## 6. Ground Truth Quality

Thirty-three cases have a user-supplied musical sequence. None has independently measured key-down/key-up times at millisecond accuracy. C cases have a seven-note score sequence; N, P and R cases have the supplied note sequence. Previously derived regions cannot establish exact timing error. `segmentation_ground_truth.csv` marks attack times `none` and excludes both polyphonic cases. Consequently **early/late start or end, precise false-boundary timing and release-created extras cannot be asserted as independently measured facts**.

## 7. Existing Segmentation Architecture

`lib/screens/Notation/performed_notes.dart` accepts a raw feature only if `!isSilent`, pitch > 0, confidence ≥ .55 and RMS > .001. An accepted frame starts a candidate. An onset flag with a sample inside the frame splits only after the active candidate exceeds .055 s. Otherwise one frame ≥ .8 semitone from the confidence-weighted active mean splits immediately. Two rejected frames close at the last voiced end. At EOF, the active note closes. Candidate emission needs ≥ .055 s and ≥ 2 accepted frames. There is no pitch confirmation, hysteresis, adjacent merge, explicit release state or exposed start/end reason. `PerformedNote` pitch/confidence/RMS are weighted-mean/mean values, not medians.

This differs from any earlier prose implying a sustained pitch-change confirmation or envelope-based repeated-note rule: neither exists in current production code. Native onset is evidence supplied upstream, not a Phase 6 guarantee of a true key attack.

## 8. Current Parameters

`segmentation_current_parameters.csv` enumerates all effective Phase 6 gates and the upstream native onset/silence gates, with units and source files. The native YIN threshold belongs to frozen raw DSP and was not treated as a segmentation tuning parameter.

## 9. Production Baseline

The host baseline decoded the original AAC/M4A files using the installed FFmpeg to stereo signed-16 PCM, ran the **actual Phase 3** `convertS16ToAnalysisPcm` to 44,100-Hz mono float32 little-endian, then extracted actual Phase 5 FFI `RawAudioFeature`s with the existing production Open DSP DLL and passed those frames to the unmodified Phase 6 segmenter. This verifies the converter/FFI/segmenter path on the host; it is **not** an Android decoder/device measurement. `segmentation_raw_features.csv` preserves every pre-segmentation feature and `segmentation_production_baseline.csv` preserves all 135 output segments. CSV blanks in `start_reason`/`end_reason` mean **null: production exposes no reason**. Median confidence/RMS and onset evidence were recomputed diagnostically from overlapping raw frames; emitted notes themselves hold means.

| Family | Counts by case |
|---|---|
| N01–N12 | 1, 2, 5, 1, 3, 2, 4, 4, 4, 3, 6, 3 |
| P01–P10 | 7, 9, 7, 5, 3, 8, 3, 6, 2, 2 |
| C01–C05 | 6, 6, 6, 5, 5 |
| R01–R08 | 1, 1, 2, 2, 3, 3, 3, 2 |

Against musical note counts in 33 scored cases: **6 exact sequences**, **22 cases with count excess** totaling **59**, and **5 under-count cases** totaling **7 missing count units**. These are count discrepancies, **not 59 independently proven false attacks**. Edit distance of MIDI sequences is 72. Sequence comparison prevents a matching count from concealing the wrong notes.

## 10. Single Sustained Notes

R01 F3 = one MIDI 53 segment; R02 F4 = one MIDI 65 segment: preserved. R05 E3 = three MIDI 52 segments and R06 E4 = three MIDI 64 segments: over-count relative to one musical event. Their late segments overlap derived release/tail regions and can reflect re-voicing or short unvoiced gaps; without independent key-up and pitched-tail truth, assigning all four extra segments specifically to release is unsupported. N01/N04 and other nominal single-note controls also vary, with some raw octave errors.

## 11. Octave-Up Transition

R03 F3→F4 outputs **53→65**, two segments. Stable raw plateaus were already correct in the prior DSP validation. Physical boundary accuracy is not independently timed. Earlier N07/N09 octave controls have extra segments, some from raw pitch instability; this cannot be attributed wholesale to Phase 6.

## 12. Octave-Down Transition

R04 F4→F3 outputs **65→53**, two segments. The true downward leap is preserved. Earlier N08/N10 controls have extra segments and mixed raw pitch behavior; they remain safety cases rather than a justification for unconditional pitch continuity.

## 13. Semitone / Small Interval

All five C takes supply 60→62→64→65→64→62→60. Baseline C01–C03 emit 60→62→64→65→62→60; C04–C05 emit 60→64→65→62→60. The F4→E4 boundary is lost **5/5**. Prior controlled-piano raw stable windows identify the underlying F4 and E4, so the repeated merge supports a Phase 6 attribution for this boundary. C04/C05 also miss an early D4; raw/attack evidence is less decisive there. P01–P06 are labeled F4→E4 under different articulation/dynamics, but raw octave/subharmonic errors dominate many segments and prevent clean boundary scoring from count alone.

## 14. Repeated Notes

N11 F4→F4 emits 65→53→65→53→65→53; P07 F4→F4 emits 50→53→53; P08 E4→E4 emits 50→50→64→52→64→50. These are **0/3 exact sequences**. Raw octave flips are a first-layer confound. Current Phase 6 has no envelope-reset evidence beyond native onset and two-frame invalid gaps; pitch cannot itself locate a same-pitch attack. A generic repeated-note fix is not established by these outputs.

## 15. Attack Behavior

Attack pitch and confidence can fluctuate and immediate .8-semitone splitting can emit transient candidates if they last two accepted frames and .055 s. The onset flag may also split a voiced attack after .055 s. `segmentation_boundary_evidence.csv` reports nearby raw onset strength, pitch delta, RMS and confidence; it does **not** infer a production boundary reason absent from the API. Independent attack timestamps are missing, so attack-created extras remain possible rather than proven case-by-case.

## 16. Release Behavior

The prior targeted-DSP report found 13/30, 30/39, 42/56 and 53/82 voiced frames in derived release windows of R01/R02/R05/R06. Present segmentation leaves R01/R02 as one note but divides R05/R06 into three. A pitched natural tail may still be musically connected, and key-up truth is unavailable. An absolute tail cutoff would be unjustified. The failure family is a mixture of re-voicing, native pitch changes and segmentation's short gap/immediate split rules.

## 17. Silence / Noise / Impulse

The prior synthetic DSP controls and the existing native tests cover silent/noisy/impulsive input; the Phase 6 rule rejects `isSilent`, zero pitch, low confidence and low RMS. No independently labeled full-pipeline silence/noise/impulse boundary corpus was included in the present real recordings. Diagnostic-policy safety on such streams is **NOT TESTED**, so it cannot support a production merge.

## 18. Failure Taxonomy

`segmentation_failure_taxonomy.csv` gives per-case sequence status, count excess/deficit and the earliest **supported** layer. The baseline categories are 6 exact, 22 over-count with mixed cause, 5 under-count, 2 polyphonic excluded. Fine categories such as early/late start/end and release-specific extra are recorded as ground-truth insufficient where no independent event times exist. The count of **confirmed** false-extra notes is unavailable; count excess is 59. Confirmed missed F4→E4 boundaries: **5**; all other missed-boundary claims are limited by raw-DSP and timing ambiguity.

## 19. Raw DSP vs Segmentation Attribution

The F4→E4 C-family merge has stable F4/E4 raw evidence from prior investigation and is **SEGMENTATION LIKELY**. P07/P08/N11 and many N/P extras exhibit raw octave/subharmonic excursions; **RAW DSP is a substantial first-layer confound**, and this task did not alter it. R05/R06 split tails are **AMBIGUOUS RELEASE/VOICING** without independent key-up. R03/R04 are correctly segmented by count and sequence. No score-derived pitch was used to correct raw observations.

## 20. Boundary Evidence

`segmentation_boundary_evidence.csv` traces every observed inter-segment boundary to nearby raw pitch, onset, voicing and RMS/confidence. Native onset uses flux > .38 with RMS ratio > 1.35 and refractory 1323 samples; fallback has its own RMS/peak gates. These are candidate cues, not labels. The C-family missed boundary needs persistent pitch comparison to an anchored prior plateau; the current moving active mean and immediate single-frame threshold can absorb a gradual change. That is a mechanism hypothesis supported by the diagnostic result, not a proven universal rule.

## 21. Diagnostic Strategies

Four test-only policies were compared with production A: B = anchored pitch with three-frame confirmation but no onset split; C = anchored three-frame pitch confirmation plus native onset; D = current pitch rule with three invalid frames required to close; E = anchored confirmation plus onset, .75 semitone and three-frame gap. They operate only on stored raw features. Their implementation is `tools/segmentation_diagnostics.dart`; production receives none of these settings.

## 22. Parameter Sweep

The small diagnostic grid varied confirmation 2/3/4 frames, pitch threshold .65/.75/.85 semitone, and gap 2/3 frames. It is stored in `segmentation_parameter_sensitivity.csv`. No grid point preserved all four R single-note controls, both R leap controls, all five C F4→E4 boundaries and repeated-note controls together. The grid was not promoted into production thresholds.

## 23. Parameter Sensitivity

Several nearby settings improve F4→E4 but differ in their collateral splits and count errors. The best validation sequence count is only 6/24 across the grid; repeated-note exactness is 0/3. This is not a robust safe region for a general release/repeated-note policy.

## 24. Development / Validation Discipline

Before the sweep, C01–C03 and P01–P06 were frozen as a **9-case development set**; the other 24 scored cases were validation, including C04/C05, all R mono controls and repeated notes. This is a small, correlated corpus, not a statistically independent population sample. Policy C was not retuned after its validation regression; the sweep is diagnostic sensitivity, not a newly clean held-out test.

## 25. Metrics

Expected/detected counts, absolute count error, exact MIDI sequence, sequence edit distance, single-note preservation, octave/semitone/repeated separation and segment durations are provided per case. **Independent boundary timing error: NOT TESTED**. Minimum emitted duration is .055 s; P09 short D4 survives as a ~.22 s segment, so simple lowering of minimum duration is not justified. No educational score or pass/fail for performers was calculated.

## 26. Strategy Comparison

| Policy | Exact sequence /33 | Development /9 | Validation /24 | Count excess | Count deficit | Key observation |
|---|---:|---:|---:|---:|---:|---|
| A production | 6 | 0 | 6 | 59 | 7 | Five C F4→E4 merges |
| B pitch confirm | 7 | 1 | 6 | 63 | 2 | Some boundary recovery, more extras |
| C onset assisted | **9** | **3** | 6 | 63 | 2 | C01–C03 exact; R06 becomes 64→62→62→64 |
| D gap 3 | 6 | 0 | 6 | 59 | 7 | No overall gain |
| E combined | 8 | 2 | 6 | 63 | 3 | No validation gain |

The exact sequence metric is deliberately strict; raw octave errors affect it. C separates F4→E4 in all C takes, but C04/C05 still miss early D4. Its validation exact count does not improve at all.

## 27. Safety Matrix

`segmentation_safety_matrix.csv` details each policy/control. Production and C preserve R01/R02 and both R octave leaps; neither preserves R05/R06 as one note. C regresses R06 pitch sequence and fails all three repeated controls. Silence/noise/impulse and independently timed release safety for diagnostic policies are **NOT TESTED**. R07/R08 are outside monophonic scoring and excluded from the gate.

## 28. Production Gate

| Criterion | Result | Evidence |
|---|---|---|
| Reproducible baseline boundary defect | PASS | C F4→E4 merge 5/5 |
| Segmentation attribution for that defect | PASS, limited | Stable raw F4/E4 evidence in prior C analysis |
| Candidate improves defect | PASS | C separates F4→E4 5/5 |
| Single-note preservation | **FAIL** | R06 regression; R05/R06 still over-count |
| True octave transitions | PASS | R03/R04 two correct notes |
| Small interval preservation | FAIL | C04/C05 still miss D4; P raw confounds |
| Repeated-note safety | **FAIL** | 0/3 exact and raw ambiguity |
| No increased false split/extra rate | **FAIL** | Count excess 59→63; R06 worsens |
| Validation improvement without regression | **FAIL** | Exact 6/24 unchanged; R06 regresses |
| Silence/noise/impulse and independent release safety | NOT TESTED | No full boundary truth for candidate |
| General, score-independent rule | PASS | Diagnostic uses only raw features |
| Runtime cost | NOT TESTED | No production candidate accepted |

Any critical FAIL prohibits a production segmentation change.

## 29. Production Decision

**A. No production segmentation change justified.** A specific merge is reproducible, but available candidate policies do not meet single-note, repeated-note and no-extra safety requirements. More threshold tuning on these recordings would overfit.

## 30. Production Changes

None. No runtime Dart, native, FFI, MusicXML, tempo, alignment or assessment source changed.

## 31. Files Changed

Added this report; `segmentation_input_manifest.csv`, `segmentation_baseline_summary.csv`, `segmentation_raw_features.csv`, `segmentation_production_baseline.csv`, `segmentation_current_parameters.csv`, `segmentation_ground_truth.csv`, `segmentation_failure_taxonomy.csv`, `segmentation_boundary_evidence.csv`, `segmentation_strategy_comparison.csv`, `segmentation_parameter_sensitivity.csv`, `segmentation_safety_matrix.csv`; and test-only tools `tools/segmentation_diagnostics.dart`, `tools/segmentation_artifacts.ps1`. No private absolute source path appears in the CSVs.

## 32. Tests Added

No production regression test was added because production code did not change. A temporary host-only baseline harness extracted the 35 recordings before being removed; its frozen machine-readable outputs and test-only diagnostic source are retained. The existing regression suite remains authoritative for runtime behavior.

## 33. Regression Results

`flutter test --no-pub test/analysis_audio_test.dart test/music_analysis_ffi_integration_test.dart test/music_analysis_phase6_test.dart test/music_analysis_phase6_integration_test.dart test/music_analysis_phase7_test.dart test/music_analysis_phase7_integration_test.dart test/music_analysis_calibration_test.dart`: **31 passed, 0 failed, 0 skipped**. The temporary 35-file baseline harness: **1 passed, 0 failed, 0 skipped**. `ctest --test-dir .native-host-prod -C Release --output-on-failure`: **3 passed, 0 failed, 0 skipped**. Total executed: **35 passed, 0 failed, 0 skipped**. An initial CTest invocation without `-C Release` reported three **Not Run** because the generator is multi-config; it was corrected and all three ran. An initial Flutter invocation named a nonexistent Phase 3 test path and was replaced by the actual `analysis_audio_test.dart`; no result from that invocation was counted.

## 34. Runtime

Production runtime impact: **zero**, because production code is unchanged. Candidate host runtime and device benchmark: **NOT TESTED** as no policy passed the preceding safety gate. Diagnostic tooling is offline and does not run on devices.

## 35. Raw DSP Status

**Unchanged.** No YIN/CMND, candidate ranking, confidence, voicing, native onset, FFT or DSP thresholds changed. Candidate C and F2 from earlier work remain diagnostic only.

## 36. ABI Status

**Unchanged.** Public C `ma_feature` and Dart FFI contract were not modified.

## 37. Tempo / Alignment / Assessment Status

**Unchanged.** No reference leakage was introduced into segmentation.

## 38. Aubio Status

**Excluded from production.** The existing Open DSP engine remains the production path.

## 39. Build Status

No APK, AAB, IPA, desktop or web output was built. Existing host native binaries were executed for validation without rebuilding. Android device compilation/benchmark: **NOT TESTED**. iOS build: **NOT TESTED** (no macOS environment).

## 40. Remaining Risks

Current raw octave errors can be transformed into extra performed notes. Natural release can remain pitched and high-confidence, while physical key-up is not independently known. Same-pitch re-articulation needs attack evidence beyond pitch; present native onset flags are not calibrated as ground-truth attacks. These limits prevent claims of millisecond timing or a universal boundary threshold.

## 41. Need For More Recordings

**NEW RECORDINGS REQUIRED for a production release/repeated-note boundary rule**, minimum **four short monophonic uncompressed takes with synchronized key-down/key-up timestamps**: (1) one stable F4 hold with natural release, (2) one E4 hold with natural release under the alternate timbre, (3) two F4 attacks at the same pitch with a short real re-articulation, and (4) F4→E4 legato with independently marked second key-down. Record a quiet background lead/tail and retain the source waveform. The four cases distinguish pitched decay from a new attack, verify a same-pitch boundary and resolve the F4→E4 timing without using the detector to label itself. Existing files remain useful and need no re-upload.

## 42. APK Decision

**NO NEW APK REQUIRED.** Only reports, CSVs and offline diagnostics were added; production runtime behavior is unchanged.

## 43. Recommended Next Step

Annotate the four minimal controls independently, then evaluate an attack-plus-persistent-pitch rule against the frozen 35-file corpus and fresh timed controls. Keep raw DSP and segmentation responsibilities separate; require R single-note, true leap, repeated-note, short-note and no-extra safety before any Dart production change.
