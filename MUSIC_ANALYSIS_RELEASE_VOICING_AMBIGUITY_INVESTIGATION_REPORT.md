# Sornaz — release, voicing and pitch ambiguity investigation

## 1. Executive Summary

**All 27 real inputs are present** (N01–N12, P01–P10, C01–C05); the 12 new-file SHA-256 values match the frozen manifest. This investigation re-evaluated every frozen frame/candidate record from those 27 inputs (10,374 real raw features) without re-decoding or modifying the originals. The original **92 synthetic cases were rerun** with 0 case-count/voicing/octave-count mismatches, and the **16 held-out synthetic signals were regenerated and rerun** through the native probe with 1,392/1,392 feature lines identical to the frozen CSV. The previous Development/Held-Out split was not changed.

Strategy C's net original-synthetic octave-down regression (448→468) is **29 newly wrong octave-down frames in exactly two interference recipes, offset by nine previously wrong octave-down frames corrected elsewhere**. In those two recipes the wrong lower-frequency candidate has an exceptionally good CMND and counts the actual fundamental as its H2. The candidate spectral-score margin is **not** small, so a low-margin-only abstention rule misses this failure. On selected older real windows C often finds a spectrally strong shorter-period alternative and corrects raw octave-down values; the physical source of those real waveforms' additional components is still **UNKNOWN**.

Current OpenEngine confidence is optimistic **as a correctness indicator**: every labelled voiced error in this selected corpus also has confidence ≥.85; real octave-down medians are .894 (development) and .909 (held-out), compared with .986/.980 for correct frames. Confidence separates distributions somewhat but is not a calibrated probability of correct pitch or voicing. N12 release has 46 voiced estimates in 52 frames, median confidence .877 and falling RMS; its pitch truth is **undefined**, so these are unsupported/contested estimates rather than proven wrong notes. Competing spectral evidence exists in 32 of the release frames.

Five diagnostic abstention policies plus F0 baseline were evaluated. **F2 (CMND-production versus spectral-C disagreement)** is the best *research* trade-off on selected labelled real data: held-out wrong/high-confidence frames 85→21, all 1,033 correct held-out real frames retained, voiced coverage **94.28%** (total labelled coverage 94.62%). Yet held-out synthetic voiced coverage falls to **81.25%**; it abstains on 156/832 frames, and release correctness cannot be proven. No policy meets the complete safety gate. **No Production change was made.** The next step is independent release/attack and mixed-source truth, not tuning current thresholds.

## 2. Scope / Non-Goals

This is an offline, score-agnostic investigation of the frozen OpenEngine observations and exact-window candidate evidence. It compares A with diagnostic C, audits confidence, examines N12 release and tests F0–F5 abstention policies. It does not change pitch selection, 0.15 CMND gate, segmentation, tempo, assessment, MusicXML, Dart FFI, ABI, UI, Aubio production linkage or an application output. No new user recording was requested during this task.

## 3. Repository State

`MUSIC_ANALYSIS_BLINDED_PITCH_CANDIDATE_RANKING_REPORT.md` and all requested baseline/evidence/annotation/result CSVs were read against current code. `pitch_candidate_split.json` is unchanged. `native/dsp_engine_open.cpp` is unchanged in this task; the test-only `MA_TRACE_YIN` path from the preceding task remains separate from the production shared library. Existing unrelated worktree modifications were left alone. The current source still chooses the first CMND minimum crossing 0.15, and confidence remains `1 − selected CMND`.

## 4. Input Availability

All N01–N12, P01–P10 and C01–C05 M4A source files are available. N01–N12 hashes match `pitch_candidate_source_hashes.csv` (0/12 mismatches). Existing CSVs contain 10,374 real, 8,692 original-synthetic and 1,392 held-out-synthetic feature rows. Those frozen data and `pitch_candidate_annotations.csv` are the input to the new audit; the original real M4As were not unnecessarily re-decoded. No private absolute file path appears in new artifacts.

## 5. Previous Frozen Split

Development new: N01/N02/N03/N07/N09/N11; held-out new: N04/N05/N06/N08/N10/N12. Development previous: P01–P05/P07/P09/C01–C03; held-out previous: P06/P08/P10/C04/C05. Original 92 synthetic cases are development; H001–H016 remain held-out. No group moved after observing a result. This is a fixed diagnostic split, not an independent population sample: annotations were previously selected using recorded contours, and cases share capture conditions.

## 6. Baseline Reproduction

The untouched `pitch_candidate_baseline.csv`, `pitch_candidate_evidence.csv`, synthetic features/evidence, candidate annotations and prior comparison tables were processed by `tools/pitch_ambiguity_investigate.dart`. It evaluated 20,458 feature records and 8,639 labelled stable-region frames; outside stable truth, release/background remains unlabelled. Host CMake Release was configured with `MA_ENABLE_AUBIO=OFF`. Native CTest reran the existing 92-case synthetic generator: 92 cases, 0 mismatches in case, voiced and octave counts against frozen `pitch_candidate_synthetic_baseline.csv`. The H001–H016 generator/probe rerun reproduced all **1,392 feature lines exactly**. No previous split or baseline artifact was overwritten by the new audit.

## 7. Strategy C Improvement Cases

`pitch_ambiguity_candidate_pairs.csv` records every A↔C outcome change with both candidates, expected candidate (evaluation only), exact-window evidence and prior pitch. There are **673 A-wrong→C-correct** labelled frames: development real 184, held-out real 64, original synthetic 269 and held-out synthetic 156. On prior held-out real windows, raw octave-down reduces 84→21. Many real improvements have a production candidate whose median stabilized F/(H2+1) is only ~.076 and selected CMND ~.09–.11, while the alternative puts more support at its own fundamental. This is strong *signal-level* evidence for a shorter candidate but does not identify the recording's physical interfering source or certify every pitch at release.

## 8. Strategy C Regression Cases

There are **33 A-correct→C-wrong** labelled frames: four in real development windows, none in real held-out, 29 in original synthetic, none in new synthetic held-out. The 29 original-synthetic regressions are all octave-down and occur only in S050 and S071. Their A candidate is near the target, with CMND near the 0.15 gate. C selects the lower candidate, which has a much smaller CMND and treats the target's strong fundamental as its own H2. Four real regressions are mixed/weak-evidence windows; no note-specific or acoustic-source cause was independently demonstrated, so their physical family remains **UNKNOWN** (plus some low-margin evidence).

## 9. Failure Taxonomy

`pitch_ambiguity_failure_taxonomy.csv` classifies every changed pair. A synthetic recipe can prove its injected low-frequency component; a real recording cannot be assigned that physical cause merely from matching frequencies. Original synthetic: 269 improvements and 29 regressions fall in `independent_low_interferer`. Held-out synthetic: 156 improvements in the same known family, zero regressions. Real development: 175 improvements and two regressions remain `UNKNOWN_real_acoustic_source`; four improvements are CMND ambiguity, five improvements and two regressions have small spectral margins. Real held-out: 58 improvements remain unknown, four are CMND ambiguity and two small-margin. Attack/release are not pitch-scored as stable truth. Candidate shortlist limitation and inharmonicity remain hypotheses where the stored candidates do not establish them.

## 10. Exact Synthetic Regression Families

Only two original cases cause all **29 newly wrong** octave-down frames; their recipes already belonged to the original 36-mixture sweep:

| Case | Exact recipe | Expected Hz | A-correct→C-down | A-down→C-correct | A-down frames → C-down frames (52 stable frames) |
|---|---|---:|---:|---:|---:|
| S050 | `interference_293_150_10` | 293.66 | 14 | 0 | 38→52 |
| S071 | `interference_349_180_10` | 349.23 | 15 | 0 | 37→52 |

Both recipes combine a target harmonic tone with an independent low-frequency sine at gain .10 in the frozen generator. Cases at other gains/frequencies correct some previous down/other values; nine former down frames elsewhere become correct, yielding the aggregate 448→468 rather than 448→477. The exact list of *all* original synthetic cases with a change is `pitch_ambiguity_synthetic_regressions.csv`. No new synthetic case was added to the previous held-out set or used to retune its parameters.

## 11. Candidate Pair Evidence

For each changed frame, `pitch_ambiguity_candidate_pairs.csv` contains A, C and nearest-to-truth evaluation candidate: Hz, fractional MIDI, CMND, exact-window spectral F/H2/H3/f/2 and combined C score, plus RMS, energy, peak, clipping, onset strength, confidence, previous pitch, region and taxonomy. On S050's 14 regressions, median A candidate is **294 Hz**, CMND **.1494**, fundamental magnitude **327.38**, H2 **114.36**, score **6.62**; C candidate is **147 Hz**, CMND **.0008**, its own F **97.33**, H2 **327.38**, score **7.49**. On S071's 15, A is **350 Hz**, CMND **.1491**, F **326.52**, H2 **113.16**, score **6.66**; C is **175 Hz**, CMND **.0018**, F **88.92**, H2 **326.52**, score **7.37**. The true target's spectral energy is literally reinterpreted as H2 support for the false low candidate. Expected candidate columns are evaluation metadata; no selector receives them.

## 12. CMND Evidence

For S050/S071 the double-period fit is nearly perfect despite the intended target being present. A's first qualifying shorter lag sits just under .15, while C's scoring rewards the double-period candidate's near-zero CMND. The same lower-lag preference corrects many real frames where A's low candidate has CMND ~.09–.11 but the shorter candidate has strong fundamental support. CMND alone cannot determine the intended source in a mixed waveform. Setting a wider/narrower single gate from these frames would overfit and could alter true lower-note behavior.

## 13. Spectral/Harmonic Evidence

C's diagnostic score is `ln(1+F)+.5 ln(1+H2)+.25 ln(1+H3)−.5 ln(1+f/2)−2×CMND`. In a harmonic series this can favor a plausible fundamental. In S050/S071, however, the *actual target* becomes H2 of a lower candidate and the independent low tone supplies that candidate's F; the score therefore favors the wrong octave by median margins **.868** and **.718**. This is a structural failure of that specific evidence combination, not evidence that every spectral ranking must fail. Spectral magnitudes are relative Goertzel values, not calibrated SPL or source-separated amplitudes.

## 14. Real vs Synthetic Comparison

`pitch_ambiguity_real_vs_synthetic.csv` gives medians by fixed split/domain/A class for selected CMND, `(F+1)/(H2+1)`, `(F+1)/(H3+1)`, `(F+1)/(f/2+1)`, RMS, confidence and C score margin. The +1 floor prevents ratios with near-zero denominators from exploding. Real correct vs real octave-down selected candidates: development CMND **.0143 vs .1061**, F/H2 **6.05 vs .076**, RMS **.095 vs .033**, margin **3.03 vs 1.53**; held-out CMND **.0198 vs .0922**, F/H2 **4.33 vs .076**, RMS **.081 vs .031**, margin **3.10 vs 1.55**. Original synthetic correct vs down: CMND **.00071 vs .0360**, F/H2 **2.51 vs .178**, RMS **.248 vs .281**, margin **5.22 vs 3.06**. Synthetic amplitude and mixture structure are plainly different from the real captures; these are descriptive distributions, not statistical significance or instrument-general calibration.

## 15. Candidate Margin Analysis

The diagnostic margin is `best C score − second-best C score` among stored viable candidates (CMND <.45, 80–2000 Hz). Real down frames have lower *median* margins than real correct frames, but S050/S071 wrong winners still have substantial margins ~.72–.87. Therefore “small margin means ambiguous” has limited sensitivity to confident false subharmonics. On real held-out at 95% fixed coverage, margin ranking retains 72 wrong vs baseline 85; at 90% it retains 49 wrong while abstaining 17 correct. The margin is candidate-set-dependent and its units are diagnostic log-score units, not probability.

## 16. Current Confidence Audit

`pitch_ambiguity_confidence_audit.csv` lists min/quartiles/median/max and ≥.85 counts for each A class, domain and split. All labelled voiced errors (down/up/other) have confidence ≥.85 **because the detector's first-below-.15 selection implies `1−CMND >.85`**. Real development correct median **.986** vs down **.894**; real held-out correct **.980** vs down **.909**. Original synthetic correct **.9993** vs down **.9640**; held-out synthetic correct **.9999** vs down **.9934**. Unvoiced frames have confidence zero. These are not calibrated correctness probabilities; a displayed .90 does not mean 90% chance of correct octave.

## 17. Confidence vs Correctness

The distributions have some ordering, especially on real data, but overlap and the .85 floor makes a simple current-confidence cutoff insufficient. Held-out real risk/coverage using current confidence: at 95% coverage it retains **all 85** wrong frames; only at 80% coverage does it retain 17 wrong while abstaining **98 correct**. Margin ranking at 95% retains 72 wrong and abstains four correct. A candidate-specific diagnostic metric is examined below, but it also overlaps heavily with synthetic errors. Exact bin/ranking counts are in `pitch_ambiguity_risk_coverage.csv`; no confidence calibration model is shipped.

## 18. N12 Release Deep Dive

The frozen annotation remains: stable F4 1.25–2.50 s; release 2.70–3.30 s; background 3.40–8.10 s. `pitch_ambiguity_release_n12.csv` reports **all 565 annotated frames individually** with PCM energy/RMS/peak, A/C candidates, CMND, margin, spectral F/H2/H3/f/2, previous A pitch, onset/silence flags and F1–F5 outcomes. Stable: 108/108 voiced, median RMS **.0743**, CMND **.0294**, spectral margin **2.787**, median confidence **.971**. Release: 46/52 voiced, median RMS **.0286**, voiced CMND **.124**, margin **1.37**, confidence **.877**; 32 A estimates lie near half F4, but **pitch truth is undefined here**. Background: 1/405 voiced, median RMS **.021**, one voiced CMND **.145**. Three large consecutive-pitch jumps occur in release. The release's median `(F+1)/(H2+1)` falls from stable **24.9** to **.06**. These show decaying/changed evidence, not independently proven wrong notes.

## 19. Release Voicing Evidence

Production reports pitch when a non-silent frame yields *any* CMND candidate <.15 in the 80–2000 Hz band; it does not require candidate exclusivity, sustained harmonic support or a separately calibrated voice probability. A decaying but periodic/partly periodic tail can still satisfy that gate. F2 identifies A-versus-C disagreement on **32/52 release frames** while flagging **0/108 stable** frames; it leaves 14 voiced plus six unvoiced release frames. That is useful ambiguity evidence, **not** proof those 32 must become unvoiced: some release tails can have valid pitch. The one voiced background frame is not flagged by F2. Absolute RMS alone cannot safely decide voicing across quiet performances and capture gains.

## 20. Ambiguity Definitions Tested

The audit tests four signal-only cues: a plausible octave-separated CMND alternative close in fit (F1), A/C disagreement by >500 cents (F2), C score margin <.25 (F3), and a causal RMS drop below .35 of the observed maximum together with >700-cent jump from previous A pitch (F4). F5 is a conservative union of F2 with joint F1/F4. These constants are **exploratory diagnostic definitions**, not a tuned or production-approved policy; the same fixed rule was evaluated on prior held-out cases. All policies abstain only from already voiced A output, so they cannot manufacture a voiced frame. None uses case ID, note name, expected MIDI, MusicXML or fixed release time in its decision.

## 21. Abstention Strategies

F0 retains current A; F1 uses CMND ambiguity; F2 uses A/C disagreement; F3 uses small candidate margin; F4 uses envelope/instability; F5 combines F2 with jointly supported F1/F4. `pitch_ambiguity_abstention_comparison.csv` includes labelled/voiced coverage, correct/wrong retained, correct/wrong abstained, high-confidence wrong retained and octave-specific counts. F2 is best on selected real held-out with **85→21** wrong retained and **0** correct abstained; F5 retains the same wrong count but abstains more frames. F1/F3/F4 alone leave **72/82/79** wrong of 85 on real held-out. F2 is not production-safe because coverage collapses in one held-out synthetic family and release truth is incomplete.

## 22. Coverage vs Error

| Split/domain | F0 wrong / correct retained | F2 wrong / correct retained | F2 correct abstained | F2 voiced coverage | F2 wrong abstained |
|---|---:|---:|---:|---:|---:|
| Development real | 251 / 1,382 | 66 / 1,378 | 4 | 88.43% | 185 |
| Held-out real | 85 / 1,033 | 21 / 1,033 | 0 | 94.28% | 64 |
| Original synthetic | 708 / 3,920 | 439 / 3,891 | 29 | 93.56% | 269 |
| Held-out synthetic | 208 / 624 | 52 / 624 | 0 | **81.25%** | 156 |

All wrong labelled voiced frames here also meet the current ≥.85 confidence condition, so “wrong retained” equals “confidently wrong retained” for F0/F2 in these selected regions. F2 does **not** repair a pitch; it declines to emit some observations. Its 18.75% held-out-synthetic abstention and 11.57% development-real voiced abstention are material coverage losses, even where labelled correct frames are mostly preserved. A few other policies abstain from correct frames without comparable wrong reduction.

## 23. Risk/Coverage Analysis

`pitch_ambiguity_risk_coverage.csv` ranks selected labelled frames by current confidence, spectral margin and a candidate-specific research metric at target 100/95/90/80% coverage. This is a retrospective risk curve, not a deployable threshold. On real held-out, wrong retained at 95% coverage: current confidence **85**, margin **72**, candidate-specific **80**; at 90%: **65**, **49**, **50**. At 80%, all methods lose many correct frames (current confidence abstains 98 correct, margin 110, diagnostic metric 100). F2's disagreement cue is more selective on this real split, but its synthetic coverage defect remains decisive. Null truth and unvoiced are not silently treated as correct pitch.

## 24. Correct-Pitch Preservation

F2 retains all 1,033 correct held-out real stable frames and 624 correct held-out synthetic frames, but loses four correct development-real and 29 correct original-synthetic frames. Candidate changes by case and region are in `pitch_ambiguity_candidate_pairs.csv` and can be checked against the frozen `pitch_candidate_annotations.csv`; no region was relabelled to hide a loss. The new N01–N06 healthy spans and previous piano C01–C05 must remain a safety suite in any future implementation. A 0% held-out false-abstention observation from a small split does not establish universal safety.

## 25. Lower-Octave Safety

N01 F3 and N04 E3, plus the lower post/pre regions of N07/N08, remain correctly pitched by the unchanged production engine. F2 does not alter pitch values, so it cannot create false octave-up values; nevertheless it may discard useful lower-note observations if candidate methods disagree. Case/region-specific coverage should be checked against source annotations before any proposal; the aggregate table alone does not prove lower-note retention. No blanket octave-up correction was added.

## 26. Upper-Octave Safety

N03 F5, N06 E5 and upper stable regions of N09/N10 remain as in the frozen baseline. F2 does not reassign upper pitches; it can only abstain. Their short stable regions limit extrapolation to all dynamics/instruments. No upper-register production behavior changed.

## 27. True Octave Leap Safety

N07–N10 true leap labels and split are unchanged. The stable pre/post regions are evaluated under the same F2 cue. The rule does not lock to the previous octave, unlike temporal strategy D's known weakness. However **precise transition latency and abstention duration at true attacks are NOT TESTED** because independent key-down times are absent; a long transient abstention could still be unacceptable. No millisecond safety claim is made.

## 28. Repeated Note Safety

N11 has two independent F4 stable regions separated by a provisional attack window. F2 does not change raw pitch; its region-level abstention can be inspected in the artifact. Whether Phase 6 produces two notes is outside scope. No repeated-note boundary or onset policy changed.

## 29. Synthetic Safety

The existing native 92-case regression stays green and all 16 held-out synthetic feature lines reproduce exactly. That tests the *unchanged* engine, not the proposed abstention rule. F2 abstains 156/832 held-out synthetic stable frames, leaving only **81.25%** voiced coverage; this fails the safety target for a broad production policy despite retaining all 624 correct frames in that small set. C still has the original 448→468 octave-down regression. Neither C nor F2 is production-approved.

## 30. Candidate-Specific Confidence Experiment

The experimental metric for C's candidate is `min(clamp(1−candidateCMND), margin/(margin+.5))`. It uses the *new candidate's* CMND rather than inheriting A's confidence, but its margin is tied to C's shortlist and score. Median metric for real held-out correct/down is **.861/.712**; original synthetic correct/down **.907/.858**; synthetic held-out correct/down **.915/.781**. This is better ordered in some groups but still overlaps; synthetic wrong medians can be high. It is **not a calibrated probability** and did not replace `ma_feature.pitch_confidence`. An eventual candidate change would require a defined, tested confidence meaning or an explicit abstain/unvoiced outcome.

## 31. Runtime / Memory

No production candidate was compiled, so **production before/after runtime does not exist**. The preceding host probe benchmark measured the test-only spectral/CSV probe at ~1.24–1.54× the unchanged native path on three real recordings; CSV I/O and process startup confound this and it is not an Android estimate. The current Dart audit is offline and loads research CSVs into memory; it is never in the mobile production path. Any future F2 would need spectral-candidate evidence and confidence semantics integrated into a bounded native design, then like-for-like host and device CPU/memory measurements. Android device performance: **NOT TESTED**.

## 32. Production Safety Gate

| Required criterion | Result | Reason |
|---|---|---|
| Real stable correct pitch unchanged | PASS for current production; diagnostic F2 held-out correct retained | small/provisional spans |
| Genuine lower/upper notes preserved | PASS for unchanged pitch; abstention coverage requires more validation | N01/N04/N03/N06 and leap plateaus |
| True octave leaps including transition timing | **NOT TESTED** fully | no independent key-down timestamps |
| Original synthetic not worse | FAIL for C; F2 wrong reduction but coverage loss | C 448→468 down; F2 93.56% coverage |
| Held-out synthetic not worse | **FAIL for F2 coverage** | 81.25% voiced coverage |
| Confidently wrong outputs reduced | PASS diagnostically | held-out real 85→21, synthetic 208→52 |
| N12 release better without suppressing valid pitch | **NOT TESTED** | no independent release pitch/voicing truth |
| Coverage acceptable on all groups | **FAIL** | held-out synthetic 81.25%, dev real 88.43% voiced |
| Silence/noise/impulse controls | PASS for unchanged engine; abstention cannot add voicing | native CTest |
| Mobile CPU/memory acceptable | **NOT TESTED** | no production implementation/device benchmark |
| ABI unchanged/Aubio-free | PASS | no production edit |

The combined gate **does not pass**. A reduction in wrong outputs obtained by broadly declining to answer is not sufficient.

## 33. Production Decision

**D — No production change justified.** F2 is the strongest diagnostic abstention policy, but its held-out-synthetic coverage and unmeasured true-release safety block deployment. C's candidate-ranking regression is structurally understood yet unsolved. The question “is this tail still a valid pitched sound?” lacks independent release truth. A limited future voicing/abstention fix may become possible without adopting C, but it is not established by this corpus.

## 34. Production Changes

**None.** No `native/dsp_engine_open.cpp`, C ABI, Dart FFI, segmentation, tempo, assessment or MusicXML code was changed. The 0.15 threshold and confidence semantics remain exactly as before. New code is a host-only offline research audit and self-check.

## 35. Files Changed

| File | Reason |
|---|---|
| `tools/pitch_ambiguity_investigate.dart` | reproducible paired-candidate, taxonomy, confidence, release, abstention and risk audit from frozen CSVs |
| `tools/pitch_ambiguity_selfcheck.dart` | deterministic checks for missing truth, contradictory candidates, recipe provenance and unvoiced preservation |
| `pitch_ambiguity_failure_taxonomy.csv` | counts by set/domain/change/evidence family |
| `pitch_ambiguity_candidate_pairs.csv` | 706 changed A↔C frames with full candidate pair/truth evaluation evidence |
| `pitch_ambiguity_confidence_audit.csv` | confidence quartiles by outcome/domain/split |
| `pitch_ambiguity_release_n12.csv` | all 565 annotated stable/release/background frames |
| `pitch_ambiguity_abstention_comparison.csv` | F0–F5 coverage and error preservation |
| `pitch_ambiguity_risk_coverage.csv` | ranking curves at 100/95/90/80% coverage |
| `pitch_ambiguity_synthetic_regressions.csv` | all changed original synthetic recipes, including S050/S071 |
| `pitch_ambiguity_real_vs_synthetic.csv` | descriptive CMND/spectral/RMS/confidence/margin distributions |
| this report | evidence, safety decision and exact missing data |

All machine-readable output uses case IDs rather than private paths. Prior split, baseline and earlier reports were not overwritten.

## 36. Tests Added

`tools/pitch_ambiguity_selfcheck.dart` adds four deterministic checks: (1) missing release truth remains unlabelled, (2) contradictory A/C candidates trigger F2, (3) synthetic interference taxonomy retains known recipe provenance, and (4) no policy abstains from an already-unvoiced frame. **4/4 passed.** The audit itself reproduces 20,458 frames and writes all eight required diagnostic CSVs. No mirrored production test was added because production behavior did not change.

## 37. Full Regression Results

- Native host Release build, Aubio disabled: `cmake -S native -B .pitch_ambiguity_build -G "Visual Studio 17 2022" -A x64 -DMA_ENABLE_AUBIO=OFF -DBUILD_TESTING=ON`; build and `ctest --test-dir .pitch_ambiguity_build -C Release --output-on-failure`: **4 passed, 0 failed, 0 skipped** (DSP, C ABI, A/B, synthetic control).
- Original 92-case generator rerun: **92 present, 0 mismatches** in case/voiced/octave counts versus frozen CSV.
- Held-out H001–H016 generator and native probe rerun: **16 present, 1,392/1,392 feature lines identical** to frozen CSV.
- `flutter test --no-pub` for Phase 3 audio, Phase 5 FFI integration, Phase 6 segmentation/integration, Phase 7 assessment/integration and calibration harness: **31 passed, 0 failed, 0 skipped**.
- `dart tools/pitch_ambiguity_selfcheck.dart`: **4 passed, 0 failed, 0 skipped**.
- `dart tools/pitch_ambiguity_investigate.dart`: completed **20,458 features, 8,639 labelled frames, 706 changed pairs, 565 N12 rows** with no runtime error. This is an analysis execution, not an accuracy pass criterion.

The test counts are kept by suite because the 92/16 corpus reruns compare data rather than representing CTest/Flutter test cases. No microphone/device test was performed.

## 38. ABI Status

Unchanged: C ABI version 1, `ma_feature` layout, public functions and Dart FFI contract. No candidate-specific confidence was added to public features.

## 39. Aubio Status

`MA_ENABLE_AUBIO=OFF` in the native host verification. The production OpenEngine remains independent of Aubio. No dependency was added, so no new version/license audit is required.

## 40. Build Verification

Only host native **test** targets were compiled. No APK, AAB, IPA, desktop app build, installer or release archive was produced. Android native/app build and Android device performance were **not tested** because production native code was unchanged. iOS build/device test was **not performed**.

## 41. Remaining Risks

Truth is strong for synthetic generated pitches but synthetic mixtures have multiple real spectral sources; intended target is known only from the recipe. Real stable annotations are provisional and some were chosen after viewing baseline output. N12 release has no independent voicing/pitch truth; a still-periodic decay could legitimately remain voiced. Candidate shortlist can omit alternatives, and spectral ratios depend on windowing/frequency resolution. F2 uses C's diagnostic spectrum, whose original synthetic failure makes disagreement a useful warning but not a calibrated posterior. Confidence is conditional on the selected period. No mobile CPU/memory or decoder-parity study was done in this phase. No population-wide statistical claim follows from 27 related real recordings.

## 42. Exact Missing Evidence

The decision needs (1) independent key-down/key-up and release-end timestamps, rather than windows selected from the detector's own contour; (2) direct PCM and matched compressed capture from the same performance to isolate decoder/device effects; (3) source-controlled mixed-tone trials indicating which component is intended and their measured levels; (4) additional timbre/room conditions to test whether F2's 81.25% synthetic coverage generalizes or is an artifact; (5) candidate-specific reliability definition with independently labelled voiced/unvoiced tails; (6) bounded native candidate extraction and mobile CPU/memory benchmark. More threshold sweeps on the same frozen CSVs cannot supply these missing truths.

## 43. Do We Need New Recordings?

**NEW RECORDINGS REQUIRED for a production decision; none requested or collected in this task.** A focused minimum is **eight performances**, each saved both as uncompressed mono WAV (44.1 or 48 kHz, original gain) and the app's corresponding M4A, with synchronized key-down/key-up timestamps to approximately 10 ms and recorded start/stop/pedal state. Four can use the current piano/room: (1) isolated F3 sustain ≥1 s then ≥1 s natural release, (2) F4 same, (3) F3→F4 with ≥0.5 s stable each side, (4) F4→F3 likewise. Four should use a distinct timbre/room: (5) isolated E3 sustain/release, (6) E4 sustain/release, (7) E4 plus an independently generated lower tone at a documented level, (8) F4 plus a lower tone at a second documented level. Include ≥0.5 s ambient-only before and after each take. The mixed-tone trials need isolated source tracks or independently verified frequencies/relative levels, not just a claimed note name. Existing N03/N06/N09/N10 provide upper-register safety controls, so eight focused takes are preferable to an open-ended dataset request. If such paired source/timing evidence cannot be produced, retain the current production detector and describe uncertainty rather than assigning release truth.

## 44. Recommended Next Step

Keep production frozen. First independently annotate the eight focused performances and run the exact current Phase 3→OpenEngine path with source-track/temporal truth. Evaluate F2 and any narrower signal-driven abstention cue **without retuning the previous held-out split**; create a new frozen held-out instrument/room subset before selecting parameters. Require acceptable coverage on both the original 92 and H001–H016 synthetic sets, no lost true octave leaps or low/high notes, honest release voicing behavior, and a measured Android CPU/memory bound. Only then consider a small, C-independent voicing/abstention change; candidate C needs its own separate safety proof.
