# Sornaz — blinded pitch candidate ranking and octave safety

## 1. Executive Summary

All **12 new** recordings were processed with their declared N01–N12 mapping. All **10 preceding** boundary recordings and **five preceding** piano takes were still available and reprocessed. In conservatively selected *stable* regions of the new 12, the current engine already reported the correct octave in nearly every frame: 1,442 correct of 1,450 labelled frames, zero octave-down, zero octave-up, two unvoiced and six other errors. The raw octave failure from the previous report remains present in the older 10-file corpus and in independent synthetic mixtures; the new octave recordings predominantly act as safety controls rather than new failure reproductions. N12 release contains high-confidence low-frequency observations but has **no valid pitch truth** there.

Six diagnostic outcomes were compared: current production A, CMND rank B, spectral/harmonic C, temporal D, combined E and ambiguity/abstention F. C gives the largest reduction on *selected older real windows* (held-out prior octave-down 84→21 frames) and on newly generated synthetic held-out data (104→52), but **increases** octave-down frames on the original 92-case synthetic corpus (448→468), slightly degrades some previously correct piano windows and has unverified mobile cost. D substantially harms true-pitch regions. No candidate passes the whole safety gate. **PRODUCTION PITCH FIX NOT YET JUSTIFIED.** Production Open DSP, ABI, Segmentation, Tempo and Assessment remain unchanged. The next step is independent labelled attack/release and polyphonic-source evidence, plus a rule that does not trade one failure class for another.

## 2. Scope / Non-Goals

This phase evaluates candidate selection on exact OpenEngine CMND windows, without MusicXML, score, MIDI truth, case name or filename entering the detector or selector. No app UI, scoring, phase-eight persistence/sync, Aubio production integration, DSP production patch, segmentation or app binary is part of this task. Diagnostic strategies are **not** calibrated confidence values and are not product behavior.

## 3. Repository State

The previous `MUSIC_ANALYSIS_OPEN_DSP_OCTAVE_SUBHARMONIC_FIX_REPORT.md`, Phase 2/3/4B/5/6/7/7B/7C reports, real-calibration and controlled-piano/boundary reports, current Phase 3 converter, C ABI/OpenEngine and native tests were checked. Current code takes the first CMND local minimum after crossing 0.15; no historical report is used to override code. Existing unrelated worktree edits in top bars/social/notation and untracked prior reports/UI files were preserved, excluded from this task. `pitch_candidate_split.json` was written **before** any ranking implementation or held-out scoring.

## 4. Input Availability

N01–N12, P01–P10 and C01–C05 were all found locally and actually processed; no re-upload was required. Source files remain untouched. `pitch_candidate_source_hashes.csv` freezes SHA-256 identity for N01–N12. Committed machine-readable artifacts contain safe IDs, not absolute private paths. The file mapping for P and C is the one documented in the prior reports; no new mapping was inferred from audio.

## 5. Exact New 12-Case Mapping

| ID | Declared validation truth | Role |
|---|---|---|
| N01 | F3 (53) | sustained lower note |
| N02 | F4 (65) | sustained middle note |
| N03 | F5 (77) | sustained upper note |
| N04 | E3 (52) | sustained lower note |
| N05 | E4 (64) | sustained middle note |
| N06 | E5 (76) | sustained upper note |
| N07 | F3→F4 (53→65) | true upward leap |
| N08 | F4→F3 (65→53) | true downward leap |
| N09 | F4→F5 (65→77) | true upward leap |
| N10 | F5→F4 (77→65) | true downward leap |
| N11 | F4→F4 (65→65) | independent repeated attacks |
| N12 | sustained F4 (65), then release | no reference pitch after sustain |

The mapping is evaluation-only. `pitch_candidate_annotations.csv` records diagnostic windows and uncertainty.

## 6. Previous Corpus Availability

P01–P10 are the former F4/E4, repeated-note and D4 boundary cases. C01–C05 are the former seven-note controlled piano takes. Their earlier notes and labels were reused only in evaluation. All 27 real files produced 10,374 raw frames in `pitch_candidate_baseline.csv`; 9,957 voiced/non-silent windows produced candidate evidence. Their baseline CSV was frozen before candidate strategies were evaluated. Prior exact-window and original 92-row synthetic baseline remain intact.

## 7. Phase 3 Verification

The host investigation decoded each original AAC-LC/M4A to bounded s16le with FFmpeg, then used the **existing Dart `convertS16ToAnalysisPcm`** (the Phase 3 downmix/resampling implementation) to create headerless mono 44,100-Hz little-endian float32. Source is 44,100-Hz stereo in all 12 new files, so no rate interpolation was needed. Phase 3 averages channels and does not normalize amplitude, apply AGC or alter pitch/time. One temporary Flutter test converted all 27 files and checked exact `4 × frames` byte length. `pitch_candidate_source_metadata.csv` contains source codec/rate/channels/duration; `pitch_candidate_pcm_stats.csv` contains all 27 PCM frame counts, duration, peak, RMS, clipped-sample count and leading/trailing hop RMS <.003. The leading/trailing measure is an **energy threshold**, not a claim of digital silence.

| New case | PCM seconds | Frames | RMS | Peak | Clipped |
|---|---:|---:|---:|---:|---:|
| N01 | 4.853 | 214,016 | .0943 | .843 | 0 |
| N02 | 5.016 | 221,184 | .0689 | .918 | 0 |
| N03 | 4.621 | 203,776 | .0365 | .742 | 0 |
| N04 | 4.226 | 186,368 | .0905 | .830 | 0 |
| N05 | 4.853 | 214,016 | .0500 | .799 | 0 |
| N06 | 3.971 | 175,104 | .0435 | .878 | 0 |
| N07 | 5.573 | 245,760 | .1015 | .805 | 0 |
| N08 | 4.783 | 210,944 | .1118 | .799 | 0 |
| N09 | 4.946 | 218,112 | .0701 | .738 | 0 |
| N10 | 5.178 | 228,352 | .0672 | .645 | 0 |
| N11 | 5.341 | 235,520 | .0973 | .872 | 0 |
| N12 | 8.220 | 362,496 | .0537 | .897 | 0 |

The AAC container durations rounded to hundredths of a second agree with PCM duration within that display precision. Host decoding is not a mobile-device decoder parity test.

## 8. Annotation Method

The user supplied note identities/order, **not measured onset/release times**. New-case windows were selected conservatively from 250-ms RMS and raw-pitch summaries: central stable plateaus were kept; attacks and transitions were excluded where uncertain. N12 sustain was bounded before the obvious approximately 2.7–3.3 s release region; 3.4–8.1 s is labelled background. Previous P/C diagnostic windows come from their frozen reports and are marked `previous_diagnostic`; they are retrospective and weaker than independent hand-labelled truth. A small number of cases (notably N03/N05/N06) have short usable stable windows. These labels are **provisional**. No precise attack-time claim or millisecond transition-latency claim follows from them.

## 9. Stable / Attack / Transition / Release Regions

`pitch_candidate_annotations.csv` contains safe ID, type, seconds and sample indices, expected MIDI where valid, confidence and provenance for **185 regions** (new, previous, original synthetic and new synthetic held-out). Examples: N07 stable F3 1.35–2.55 s, transition 2.70–3.02 s, stable F4 3.05–4.35 s; N08 stable F4 1.20–2.30 s and F3 3.05–4.45 s; N11 first F4 1.05–2.30 s, second-attack window 2.90–3.25 s and second F4 3.30–4.70 s; N12 stable F4 1.25–2.50 s, release 2.70–3.30 s and background 3.40–8.10 s. Attack windows and transitions are descriptive, not expected-pitch scoring windows. Release has **null truth**, never zero or forced F4.

## 10. Development / Held-Out Split

The split was frozen in `pitch_candidate_split.json` before the strategy code or held-out scoring: new development N01/N02/N03/N07/N09/N11; new held-out N04/N05/N06/N08/N10/N12; previous development P01–P05/P07/P09 and C01–C03; previous held-out P06/P08/P10 and C04–C05. The existing 92 synthetic rows were development because their outcomes were already known from the prior phase. **Sixteen newly generated synthetic H001–H016** were created after strategy constants were fixed and were held out. Candidate parameters were not adjusted after seeing held-out results. This is a disciplined fixed split, **not fully blinded clinical-style validation**: the new real recordings' baseline contour was inspected to annotate windows before scoring, and the small corpus shares instrument/environment properties.

## 11. Current Production Baseline

`pitch_candidate_baseline.csv` preserves all 10,374 real C-ABI features: sample index, timestamp, Hz, confidence, RMS, energy, peak, clipping, onset strength/flag, silence and partial flag. The test-only probe compiles the same OpenEngine source with `MA_TRACE_YIN`; the normal library does not have the hook. It records only observations and never modifies `pitch_hz`. The 92-case synthetic baseline was **rerun**, not copied: 56/56 non-interference controls passed, and 11/36 interference rows had octave-down frames, matching the preceding report.

## 12. Candidate Extraction

`native/tests/pitch_candidate_probe.cpp` observes the exact rolling 4096-sample window and CMND curve at each processed frame. It records up to six shortest local minima, the production-selected candidate and up to three strongest minima. For each retained candidate it calculates Hann-window Goertzel magnitudes at `f`, `2f`, `3f`, and `f/2`. Candidate evidence is score-agnostic and filename-independent; truth is applied only by the Dart evaluator afterward. This shortlist can omit a distant minimum and therefore bounds experimental conclusions. Diagnostic spectrum calculation/CSV I/O is **not** a proposed production algorithm.

## 13. Strategy A – Current Production

A uses raw `pitchHz` exactly as production reports it: first CMND local minimum following the existing 0.15 gate. It is the untouched baseline. Unvoiced remains unvoiced.

## 14. Strategy B – CMND Ranking

B examines candidates with CMND <.45 and ranks by `CMND + .20 × log2(shortestCandidateHz/candidateHz)`, a diagnostic preference against very long periods. This is a fixed exploratory rule, not a calibrated threshold. Crucially it only revises **already voiced** production frames; early evaluation exposed a tooling defect where an unvoiced release frame could be promoted from a local minimum. That diagnostic bug was fixed before final results and regression-checked; no production code was involved.

## 15. Strategy C – Harmonic/Spectral Evidence

C selects the candidate maximizing `ln(1+F) + .5 ln(1+H2) + .25 ln(1+H3) − .5 ln(1+half) − 2×CMND`, with exact-window Hann/Goertzel magnitudes. This does not simply take the largest FFT bin, but its weights are still exploratory. It improves some older real windows yet worsens the original synthetic interference corpus and slightly regresses two previously correct piano takes. It does **not** pass production safety.

## 16. Strategy D – Temporal Evidence

D prefers a candidate within 80 cents of the prior selected candidate when onset strength is below .38; otherwise it uses the current supported candidate. It is reset at each diagnostic region and is deliberately simple. It fails badly on some true-pitch regions (for example new development correct 812→786 and new held-out 630→604), illustrating that continuity alone is unsafe. This experiment does not establish physical transition latency because boundaries are provisional.

## 17. Strategy E – Combined Ranking

E adds a small shorter-period term to C. It makes no meaningful real held-out gain over C, retains the C synthetic octave-down regression and is not a production candidate. Its exploratory constants were frozen before held-out evaluation.

## 18. Abstention Experiment

F uses E's candidate but abstains where CMND and spectral strategies disagree by >500 cents. On the original synthetic corpus it produces 312 abstentions and reduces non-abstained octave-down frames from A's 448 to 364, but this is partly a **coverage trade-off**, not proof of improved pitch accuracy. On prior real development it abstains 47 frames and held-out prior 13; N12 release abstains 6 of 52 frames yet still reports 40 voiced. The public ABI could express non-decision with existing zero-pitch/low-confidence fields if ever justified, but no such production behavior is approved here.

## 19. New 12-Recording Results

Selected stable windows: development A 812/817 correct, 5 other; held-out A 630/633 correct, 1 other and 2 unvoiced; **zero octave-down in both**. B reaches 817/817 development and 631/633 held-out (2 unvoiced); C reaches 816/817 and 631/633. Thus the new sustained/leap controls validate that several candidate policies do not generally octave-shift them, but they do not provide many new octave-down failures to fix. A high percentage here is **not** a general accuracy estimate: windows deliberately exclude uncertain attacks/releases and the sample count is small.

## 20. Lower-Octave Safety

N01 F3: A/B/C/E all 104/104 correct stable frames, zero octave-up. N04 E3 (held-out): all 129/129 correct, zero octave-up. Lower portions of N07/N08 also remain 103/103 and 121/121 under C. These are positive local safety observations, not proof across all instruments, dynamics or ambiguous mixtures.

## 21. Upper-Octave Safety

N03 F5 central plateau: A and C 30/31 correct, B 31/31. N06 E5 held-out: A/B/C/E 41/41 correct. Upper portions of N09/N10 mostly remain correct (N09 post-leap 28/32 A vs 32/32 C; N10 pre-leap 26/29 A vs 27/29 C, with two unvoiced retained). Short windows and attack exclusion limit inference.

## 22. True Octave Leap Results

`pitch_candidate_octave_leaps.csv` gives every strategy and each pre/post stable region. For A and C respectively: N07 F3 103/103 and F4 112/112 correct; N08 F4 95/95 and F3 121/121; N09 F4 103/103 and F5 28/32→32/32; N10 F5 26/29→27/29 and F4 74/74. There is no false octave-up correction in these chosen stable windows. Transition windows are excluded from pitch truth; **transition latency and continuity lock are not proved** without measured attack times. D's aggregate errors caution against making continuity decisive.

## 23. Repeated Note Results

N11 first/second stable F4 windows are 108/108 and 120/120 correct under A and C (full per-region counts in CSV). The attack window is annotated separately and not converted into a reference pitch. This task does not test whether Phase 6 emits two note events; only raw pitch safety is claimed.

## 24. Release / Decay Results

N12 stable F4 is 108/108 correct under A/B/C/E. In its **provisional** 2.70–3.30 s release region, A reports pitch in 46/52 frames (6 unvoiced), with median baseline confidence .877; 32 reported values are near half F4. C also reports 46/52 voiced, though zero of its selected values are near half F4; this is **not automatically an improvement**, because release pitch truth is absent and those 46 could still be misleading. F abstains 6 and reports 40 voiced. In 3.40–8.10 s background, every strategy retains A's 1 voiced and 404 unvoiced frames after the evaluator's no-promotion correction. Release safety is **not established**.

## 25. Previous 10-Recording Results

P01–P10 were rerun; their prior diagnostic windows are used with provenance warnings. In development prior (including C01–C03), A has 570 correct/234 octave-down/358 unvoiced of 1,174, while C has 746 correct/58 octave-down/358 unvoiced, with 4 octave-up and 8 other. In held-out prior (P06/P08/P10 plus C04/C05), A has 403 correct/84 down/70 unvoiced of 557; C has 466 correct/21 down/70 unvoiced, 0 up. These are promising **diagnostic** changes but cannot override synthetic or release failures.

## 26. Previous Five-Take Results

All five C01–C05 were run through the current C ABI. In their 35 prior diagnostic windows, A had C01 123/123, C02 142/142, C03 136/136, C04 121/124 and C05 126/132 correct. C changed C01 to 122/123 and C03 to 133/136 while leaving C02/C04/C05 counts unchanged. The small regressions on previously healthy takes are another reason not to ship C unqualified. Old windows were retrospectively chosen and have limited timing truth.

## 27. Synthetic Corpus

The original 92-case native corpus was rerun. `native/tests/open_dsp_octave_synthetic.cpp` now optionally writes its exact generated float32 signal to temporary files for the candidate probe; default CTest behavior is unchanged. The 92 include pure sine, harmonic-rich/weak-fundamental, decay, inharmonic/detuned, true octave leaps, semitone changes, silence/noise/impulse and 36 low-frequency mixtures. H001–H016 were newly generated **after strategy parameters froze**, using nine harmonic notes across lower/middle/upper registers, four target-plus-independent-low-tone mixtures and three true low notes with strong H2. Their signals are deterministic and described by `pitch_candidate_heldout_synthetic_manifest.csv`. All labels are evaluation-only.

## 28. Synthetic Results

On 4,628 labelled frames from the original 92 cases: A correct 3,920, down 448, other 260; B correct 4,056, down 416, other 156; C correct 4,160, **down 468**, other 0; E correct 4,143, down 468, other 17. On 832 new held-out synthetic frames: A 624 correct/104 down/104 other; B 728 correct/104 down/0 other; C 780 correct/52 down/0 other; E 735 correct/52 down/45 other. C's held-out improvement is real under these generated labels, but its original-corpus octave-down increase blocks the claim that it is globally safer. Silent/noisy/impulse controls remain in the original native CTest, not relabelled as pitched notes in the confusion matrix.

## 29. Octave Confusion Matrix

`pitch_candidate_strategy_comparison.csv` reports correct octave, down, up, other, unvoiced, abstain and median cents **only for correct-octave frames**, separately for development/held-out and new/prior/synthetic. Classification: |cents|<100 correct; within ±200 cents of −1200/+1200 octave down/up; remaining voiced values other. Null/unvoiced/abstain are distinct, never converted to zero error. The exact per-region matrix is `pitch_candidate_region_results.csv`.

## 30. Strategy Comparison Table

| Corpus / split | A correct/down/up/other/unvoiced | B correct/down/up/other/unvoiced | C correct/down/up/other/unvoiced | D correct/down/up/other/unvoiced | E correct/down/up/other/unvoiced |
|---|---|---|---|---|---|
| New dev (817) | 812/0/0/5/0 | 817/0/0/0/0 | 816/0/0/1/0 | 786/0/0/31/0 | 815/0/0/2/0 |
| New held (633) | 630/0/0/1/2 | 631/0/0/0/2 | 631/0/0/0/2 | 604/0/0/27/2 | 631/0/0/0/2 |
| Prior dev (1,174) | 570/234/0/12/358 | 703/103/2/8/358 | 746/58/4/8/358 | 426/325/0/65/358 | 746/58/4/8/358 |
| Prior held (557) | 403/84/0/0/70 | 457/30/0/0/70 | 466/21/0/0/70 | 282/205/0/0/70 | 466/21/0/0/70 |
| Original synthetic (4,628) | 3920/448/0/260/0 | 4056/416/0/156/0 | 4160/468/0/0/0 | 3900/468/0/260/0 | 4143/468/0/17/0 |
| New synthetic held (832) | 624/104/0/104/0 | 728/104/0/0/0 | 780/52/0/0/0 | 624/104/0/104/0 | 735/52/0/45/0 |

F adds abstention and has separate rows in the CSV; it cannot be compared by raw correct count without also reporting coverage. Runtime below includes host-only diagnostic extraction, not mobile cost. Percentages can be computed from these counts but are not population estimates.

## 31. Held-Out Results

Held-out new real controls contain almost no baseline octave-down, so they are a **weak discriminator** between A/B/C. Held-out prior windows favor C (84→21 octave-down) while held-out synthetic also favors C (104→52). Neither validates C against the **original** development synthetic corpus where it worsens octave-down, or against N12 release where true pitch is undefined. No post-held-out parameter retuning occurred; the held-out was not reclassified as development.

## 32. Runtime / Performance

`pitch_candidate_runtime_benchmark.csv` contains three Windows-host wall-time trials for unchanged OpenEngine versus the test-only exact-spectrum/CSV probe on N01/N07/N12. Median production/probe milliseconds: N01 **259/321** (~1.24×), N07 **287/442** (~1.54×), N12 **411/559** (~1.36×). Process startup, filesystem output and host variability are included, so these are **not** isolated candidate-ranking CPU costs or mobile benchmarks. The Dart evaluator's own 185-region multi-strategy computation is recorded in `pitch_candidate_runtime.csv` and is not production execution. Diagnostic per-candidate Goertzel and CSV storage use extra CPU/memory; worst-case memory remains bounded to one 4096-sample window plus candidate rows per file in native probe, while the Dart host evaluator loads CSVs for offline research. Candidate ranking would need a separate allocation/CPU design and Android measurement before shipping.

## 33. Production Fix Gate

| Criterion | Result | Evidence |
|---|---|---|
| Reduces older real octave-down | PASS diagnostically | prior held-out A 84→21 with C |
| Improves new real held-out octave-down | NOT TESTED meaningfully | new held-out A already has 0 down in stable windows |
| Improves original synthetic octave-down | **FAIL** for C/E | 448→468; B 448→416 but less real gain |
| New synthetic held-out improvement | PASS for C | 104→52 |
| True F3/E3 and F5/E5 stable safety | PASS on chosen windows | no false octave-up in N01/N04/N07/N08 |
| True octave leaps, both directions | PASS on selected stable regions; timing NOT TESTED | N07–N10; attacks not timestamped |
| Repeated note raw stable pitch | PASS on selected regions | N11 |
| Release/decay safety | **NOT ESTABLISHED** | N12 46/52 voiced in release, no valid pitch truth |
| Silence/noise/impulse | PASS for existing native controls | CTest 56/56 original non-interference controls |
| Calibrated confidence | NOT TESTED | alternatives reuse baseline confidence in diagnostic CSV |
| Mobile CPU/memory | NOT TESTED | host probe only |
| Score/instrument/filename independence | PASS in experimental code | candidate inputs only feature evidence |
| ABI unchanged, Aubio-free | PASS | C ABI and production target unchanged |

**No strategy passes the complete gate.**

## 34. Production Decision

**B/D outcome:** diagnostic candidate ranking improves some errors, but production safety is unproved; some rules demonstrably fail. **PRODUCTION PITCH FIX NOT YET JUSTIFIED.** No production algorithm change or threshold retune was made. The apparent improvement of C on older real windows does not excuse its new synthetic octave-down regression and unresolved release/latency/performance questions.

## 35. Production Fix Design

Not applicable. A future patch, if justified by new evidence, should modify only OpenEngine candidate selection and preserve the C ABI. No prospective implementation is approved by this report.

## 36. Files Changed

| Files | Purpose |
|---|---|
| `native/CMakeLists.txt`, `native/tests/pitch_candidate_probe.cpp`, `native/tests/pitch_candidate_baseline_benchmark.cpp` | host-only probe/benchmark targets; production library untouched |
| `native/tests/open_dsp_octave_synthetic.cpp` | optional exact synthetic PCM export for diagnostics; default regression behavior unchanged |
| `tools/pitch_candidate_evaluate.dart`, `tools/pitch_candidate_selfcheck.dart`, `tools/pitch_candidate_heldout_generate.dart`, `tools/pitch_candidate_pcm_stats.dart` | reproducible offline evaluation, deterministic controls, bounded-memory PCM audit |
| `pitch_candidate_split.json`, `pitch_candidate_annotations.csv`, `pitch_candidate_source_metadata.csv`, `pitch_candidate_source_hashes.csv`, `pitch_candidate_pcm_stats.csv` | frozen split, transparent provisional windows, input identity and Phase 3 verification |
| `pitch_candidate_baseline.csv`, `pitch_candidate_evidence.csv`, `pitch_candidate_synthetic_features.csv`, `pitch_candidate_synthetic_evidence.csv`, `pitch_candidate_heldout_synthetic_features.csv`, `pitch_candidate_heldout_synthetic_evidence.csv` | raw feature and candidate evidence without private paths |
| `pitch_candidate_synthetic_baseline.csv`, `pitch_candidate_heldout_synthetic_manifest.csv` | rerun 92-case corpus and newly frozen 16-case corpus |
| `pitch_candidate_region_results.csv`, `pitch_candidate_strategy_comparison.csv`, `pitch_candidate_heldout_results.csv`, `pitch_candidate_synthetic_results.csv`, `pitch_candidate_octave_leaps.csv`, `pitch_candidate_release_results.csv`, `pitch_candidate_runtime.csv`, `pitch_candidate_runtime_benchmark.csv` | machine-readable comparison and safety results |
| this report | investigation and conditional production decision |

Temporary s16le/f32le data and the one-off Flutter Phase 3 conversion test were removed after analysis. Existing unrelated worktree edits are not part of this work.

## 37. Regression Tests Added

`tools/pitch_candidate_selfcheck.dart` checks (1) a known ambiguous CMND/spectral candidate pair, (2) baseline candidate preservation, (3) no unvoiced→voiced promotion and (4) octave/unvoiced classification; **4/4 passed**. Existing native synthetic CTest still asserts its 56 non-interference controls. The deterministic H001–H016 manifest and stable annotations make future strategy comparisons reproducible but are diagnostic data, not an assertion that a particular candidate must win.

## 38. Production Before/After

**Not applicable: production pitch code did not change.** The 27 real-file and 92+16 synthetic comparison is among offline strategies, not an A/B of two production builds. No synthetic or real accuracy gain is attributed to an unshipped fix.

## 39. Downstream Segmentation Impact

Segmentation code and production features are unchanged. It was not rerun with hypothetical candidate outputs: those outputs lack recalibrated confidence and are not approved feature streams. Any boundary improvements from an eventual pitch fix require a fresh controlled calibration. Current previous ten-case baseline remains as documented in the preceding boundary report.

## 40. Tempo/Assessment Impact

None in production. Tempo and assessment policy were not edited or recalibrated. Diagnostic candidate differences were not converted to educational grades.

## 41. ABI Status

Public C ABI version 1, `ma_feature` layout and Dart FFI binding are unchanged. The native probe is test-only and uses the existing private trace hook; it is not compiled into the production library.

## 42. Aubio Production Status

Host CMake configuration used `MA_ENABLE_AUBIO=OFF`; production OpenEngine remains independent of Aubio. No Aubio linkage or new third-party production dependency was introduced.

## 43. Build Verification

Windows host CMake Release targets compiled with Aubio off. This is **native test-tool compilation**, not an application output. No APK, AAB, IPA, desktop app, installer or release archive was built. Android native compilation was not needed because production native code did not change and was **not performed**. iOS build/test was **not performed**.

## 44. Full Regression Results

- `cmake --build .pitch_candidate_build --config Release` then `ctest --test-dir .pitch_candidate_build -C Release --output-on-failure`: **4 passed, 0 failed, 0 skipped** (native DSP, C ABI, Open/A-B, synthetic controls).
- `flutter test --no-pub test/analysis_audio_test.dart test/music_analysis_ffi_integration_test.dart test/music_analysis_phase6_test.dart test/music_analysis_phase6_integration_test.dart test/music_analysis_phase7_test.dart test/music_analysis_phase7_integration_test.dart test/music_analysis_calibration_test.dart`: **31 passed, 0 failed, 0 skipped**.
- `dart tools/pitch_candidate_selfcheck.dart`: **4 checks passed, 0 failed, 0 skipped**.
- Temporary `flutter test --no-pub test/_pitch_candidate_prepare_test.dart`: **1 passed, 0 failed, 0 skipped** for exact Phase 3 conversion of 27 inputs; temporary file removed afterward.
- `dart tools/pitch_candidate_evaluate.dart`: completed 20,458 real/original-synthetic/held-out-synthetic feature rows and 185 annotations without error. Its output tables are evidence, not a regression success claim.

## 45. Remaining Risks

New real stable windows had almost no baseline octave errors, leaving little power to compare remedies. Annotations are provisional and partly based on the baseline contour; precise attack, transition and release truth is absent. The 16 synthetic held-out examples are deterministic but small and do not model all instrument timbres. The candidate shortlist may omit distant alternatives. Alternate selections currently inherit baseline confidence, which is not calibrated for the new pitch. C's extra Goertzel work has no mobile benchmark and its real-release selection cannot be declared correct. The native probe's host-only CSV I/O should not be mistaken for a deployable implementation. Android device and iOS parity remain untested.

## 46. Recommended Next Step

Record dry isolated F3/F4/F5 and E3/E4/E5 with **independently measured MIDI/key-down and release timestamps**, plus alternating octave leaps in both directions, repeated attacks, natural decays, pedal/reverb and controlled low-frequency interferers at known levels. Retain uncompressed source alongside M4A, microphone/device metadata and an independent fundamental reference. Add a truly unseen instrument/room to held-out validation. Investigate why spectral ranking corrects older real windows but increases octave-down on some synthetic mixtures; measure exact winning candidates and build an explicit ambiguity/abstain criterion that does not retain high confidence on release. Only then propose a small score-agnostic OpenEngine selection change and device benchmark.

## 47. Acceptance Criteria For Returning To Segmentation Calibration

Require a pre-frozen labelled hold-out corpus with attack/release truth, material reduction of real **and original synthetic** octave-down errors, no false-up corrections of genuine lower notes, preserved both-direction true octave leaps/repeated notes/semitone controls, no new release/noise voiced artifacts, candidate-specific confidence or honest abstention, bounded Android CPU/memory, unchanged ABI/Aubio-free production, complete regression pass and a reproducible production before/after on all 27 available real inputs plus synthetic controls. **These criteria are not met.**
