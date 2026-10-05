# Sornaz — Targeted Real-Audio DSP Validation

## 1. Executive Summary

All eight R01–R08 files were present, mapped exactly as supplied, decoded and converted by the existing Phase 3 PCM converter. All 27 earlier real recordings remain available. The original 92-case synthetic suite reran with **0 baseline count mismatches**; H001–H016 reran with **1,392/1,392 identical feature lines**. The prior frozen split and eight ambiguity artifacts reproduced (`20,458` features, `706` A/C outcome changes, `565` N12 annotated frames).

Production A correctly identifies all voiced stable frames of R01–R04 and R06; R05 has 122 correct and seven unvoiced of 129 selected stable frames. Both true octave leaps preserve their stable pre/post plateaus. The new timbre does **not** demonstrate a production octave failure, but diagnostic C creates **two other-pitch errors** on R06 and F2 abstains on those two correctly pitched A frames. R07 and R08 are explicitly polyphonic stress tests: A chooses the lower candidate in **94/94** and **108/108** stable-combined frames, respectively, with median confidence **.995/.993**; F2 flags zero. This demonstrates that a large spectral margin or high CMND confidence is not proof of a unique musical source. It is **not** a monophonic V1 correctness failure.

Release remains unresolved: R01/R02/R05/R06 have 13/30, 30/39, 42/56 and 53/82 voiced frames in *derived* release windows, often with high confidence. No independently measured key-up or tail-pitch truth exists; these cannot simply be called wrong. The previous F2 disagreement cue abstains on only 7/207 release frames and loses two correct R06 stable frames. C still fails the original synthetic safety control (448→468 octave-down frames); F2 still reduces held-out synthetic voiced coverage to 81.25%. **Decision A — No production change justified.** No DSP, ABI, segmentation, tempo, assessment or runtime UI changed. **NO NEW APK REQUIRED.** Next: obtain independent release/source truth and design a smaller cue that preserves R06 and synthetic coverage before any merge.

## 2. Scope / Non-Goals

This is score-independent, test-only validation of the existing Phase 3→OpenEngine path and the frozen A/B/C/D/E and F2 diagnostics. The eight new recordings were never passed as expected MIDI/filename/score to the native detector. No MusicXML, phase-6 boundary, alignment, tempo, phase-7 assessment, public FFI, production DSP or educational score was altered. R07/R08 are outside monophonic V1 accuracy scoring.

## 3. Repository State

The previous report `MUSIC_ANALYSIS_RELEASE_VOICING_AMBIGUITY_INVESTIGATION_REPORT.md`, `MUSIC_ANALYSIS_BLINDED_PITCH_CANDIDATE_RANKING_REPORT.md`, the Phase 2–7C reports and current source/tools/tests were consulted. Current `native/dsp_engine_open.cpp` still uses first qualifying YIN/CMND minimum below .15 and reports `1−selected CMND` confidence. `pitch_candidate_split.json` remains unchanged. Unrelated pre-existing worktree modifications were not staged. Previous report numbers were treated as hypotheses and checked against current artifacts/code.

## 4. Previous Reports Reviewed

Phase 2 Reference Timeline; Phase 3 Audio→PCM; Phase 4B Open DSP; Phase 5 FFI; Phase 6 Segmentation/Tempo/Alignment; Phase 7 Assessment; Phase 7B Calibration; Phase 7C Device Test UI; real calibrations 001, 002–004; controlled piano and boundary investigations; open-DSP octave/subharmonic report; blinded candidate-ranking report; release/voicing/ambiguity report. The current implementation, not a report sentence, determines behavior.

## 5. Input Availability

R01–R08: **8/8 present**. Previous N01–N12, P01–P10, C01–C05: **27/27 present**. Source identity, byte count and SHA-256 for each R file are in `targeted_audio_input_manifest.csv`; no private absolute source path is in an artifact. The frozen 92-case and H001–H016 inputs, evidence, annotations and prior ambiguity CSVs are available. R07 has qualitatively softer E3 than E4; R08 was played with approximately equal strength; neither has a measured dB ratio.

## 6. Exact R01–R08 Mapping

| Case | Musical label | MIDI | Contract |
|---|---|---|---|
| R01 | F3 sustained + natural release | 53 | mono |
| R02 | F4 sustained + natural release | 65 | mono |
| R03 | F3→F4 | 53→65 | mono, true upward leap |
| R04 | F4→F3 | 65→53 | mono, true downward leap |
| R05 | E3 sustained, different timbre | 52 | mono |
| R06 | E4 sustained, different timbre | 64 | mono |
| R07 | E4 + deliberately softer E3, near-simultaneous | 64+52 | polyphonic stress |
| R08 | F4 + approximately equally played F3, near-simultaneous | 65+53 | polyphonic stress |

## 7. Ground Truth Limitations

Musical labels and ordering are user-supplied. Key-down, key-up, physical release, source amplitudes and SPL were not independently measured. All region boundaries below are **derived annotations** from 250-ms RMS/energy/onset/pitch inspection, with coarse timing only. Release and background carry **null pitch truth**; null was never converted to zero. A polyphonic mixture has no unique monophonic expected candidate.

## 8. Phase 3 Verification

All eight sources are M4A/AAC-LC at 44,100 Hz stereo; FFmpeg decoded to bounded signed 16-bit stereo, then the exact existing Dart `convertS16ToAnalysisPcm` wrote headerless **44,100-Hz mono float32 little-endian** with channel averaging. This is a host reproduction of the production *converter*, not an Android MediaCodec device test. No new resampling was needed (same source rate), no AGC/normalization/noise reduction or gain was introduced, and originals were untouched. Duration matches the container to within container precision; stable observed pitch is near nominal, but no external laboratory reference establishes absolute decoder error.

| Case | source s | PCM frames | PCM s | RMS | peak | clipped fraction | leading RMS<.003 s |
|---|---:|---:|---:|---:|---:|---:|---:|
| R01 | 4.06 | 179,200 | 4.063 | .0582 | .582 | 0 | 1.080 |
| R02 | 3.97 | 175,104 | 3.971 | .0585 | .578 | 0 | .511 |
| R03 | 3.58 | 157,696 | 3.576 | .0724 | .638 | 0 | .824 |
| R04 | 3.58 | 157,696 | 3.576 | .0732 | .565 | 0 | .917 |
| R05 | 4.30 | 189,440 | 4.296 | .0759 | .578 | 0 | .546 |
| R06 | 3.58 | 157,696 | 3.576 | .0526 | .559 | 0 | .337 |
| R07 | 3.97 | 175,104 | 3.971 | .0672 | .578 | 0 | .313 |
| R08 | 4.23 | 186,368 | 4.226 | .0700 | .465 | 0 | .360 |

`targeted_audio_phase3_verification.csv` also contains trailing low-energy time. The .003 measure is a reproducible signal threshold, **not** a manually measured silence or key event.

## 9. Derived Region Annotation

`targeted_audio_regions.csv` records all leading/attack/stable/transition/release/background intervals with sample positions and nullable MIDI. For example, R03 first stable 1.10–1.55 s, transition 1.55–1.95 s, second stable 1.95–2.75 s; R04 first stable 1.15–1.70 s, transition 1.70–2.20 s, second stable 2.20–2.85 s. R07 combined 1.65–2.75 s and R08 combined 1.40–2.65 s. These windows avoid using attack/release uncertainty as exact pitch truth. Temporal error/latency to a physical key event is **not measured**.

## 10. Production Baseline

The unchanged OpenEngine and private exact-window trace probe produced **2,692 raw feature rows** and **6,856 candidate-evidence rows** in frozen `targeted_audio_production_baseline.csv` and `targeted_audio_candidate_evidence.csv` before running strategy comparisons. Rows include sample start/time, pitch Hz, confidence, RMS, energy, peak, clipping, onset strength/flag, silence/partial flags, CMND and spectral evidence. The private `MA_TRACE_YIN` instrumentation is test-only. These two baseline files were not overwritten by strategy evaluation.

## 11. R01 F3

Stable 1.25–2.20 s: A **82/82 correct-octave**, median error **+5.57 cents**, median confidence .997. C and F2 retain all 82. Release 2.20–2.55 s has 13/30 voiced, median voiced confidence .998; evidence may still be a pitched tail. F2 abstains on zero release frames. No false octave-up is seen in the stable plateau.

## 12. R02 F4

Stable 1.45–2.40 s: A **82/82 correct-octave**, median +0.63 cents, confidence .998. C/F2 retain all. Release 2.40–2.85 s has 30/39 voiced, median confidence .996; F2 flags zero. This is not independently labelled wrong.

## 13. R03 F3→F4

First stable F3: **39/39** correct, median +7.31 cents. Second stable F4: **69/69** correct, median +2.19 cents. A/C/F2 retain both plateaus. Diagnostic D temporal strategy reports octave-down on **69/69** second-plateau frames: continuity can lock to the old octave even though production A transitions correctly. Transition latency is not measured against key-down.

## 14. R04 F4→F3

First stable F4: **47/47** correct, median +1.24 cents. Second stable F3: **56/56** correct, median +5.60 cents. A/C/F2 retain both. Diagnostic D already reports the lower octave on 47/47 *first* F4 stable frames, showing a history/initialization weakness in that test strategy, not in production A. No continuity-based fix is approved.

## 15. R05 E3 / New Timbre

Stable 1.10–2.60 s: A has **122/129 correct**, seven unvoiced, zero false-up; C and F2 do not change these counts. Voiced median confidence .995. This timbre does not establish a new lower-octave confusion, but the dropout means coverage is not perfect. Release 2.60–3.25 s: 42/56 voiced, median confidence .959; F2 flags 1.

## 16. R06 E4 / New Timbre

Stable 1.20–2.25 s: A **90/90 correct**, median +3.92 cents, confidence .991. C selects an `other` pitch on **2** frames; F2 abstains on those **2 correct A** frames. Diagnostic D reports octave-down throughout this selected plateau (90/90). Release 2.25–3.20 s: 53/82 voiced, median confidence .941 and six large frame-to-frame pitch jumps; F2 flags only six. This is direct new-timbre evidence against deploying C or F2 unchanged.

## 17. R07 E4+E3 Stress Test

Combined 1.65–2.75 s: A/B/C/D/E choose the lower E3 vicinity in **94/94** frames, median A confidence **.995**; F2 abstains on **0**. Lower candidate median CMND **.00497**, upper candidate median CMND **.676**. Candidate spectral-score margin median **4.666**. Both tones were intentionally played, so a single lower candidate is not a monophonic ground-truth error. It does show that high confidence and a large winner margin can coexist with multiple physical sources. Exact source ratio is unknown.

## 18. R08 F4+F3 Stress Test

Combined 1.40–2.65 s: all A–E choose the lower F3 vicinity in **108/108** frames, median A confidence **.993**; F2 abstains on **0**. Lower candidate median CMND **.00719**, upper candidate **.795**, margin median **4.407**. Again no unique monophonic truth exists. Both recordings expose a failure of F2 as a general *polyphonic ambiguity detector*, but do not alone fail the monophonic V1 contract.

## 19. Pre-Tuning Validation

The pre-existing A/B/C/D/E parameters and F2 >500-cent A/C disagreement rule were applied to R01–R08 **without retuning**. `targeted_audio_pretuning_validation.csv` contains each monophonic stable region and policy. For 594 labelled frames, A and B have 587 correct + 7 unvoiced; C and E have 585 correct + 2 other + 7 unvoiced; D has 381 correct + 206 down + 7 unvoiced; F2 retains 585 correct, abstains on 2 previously correct and leaves 7 unvoiced. No R-file result was used to tune a policy afterward. `targeted_audio_strategy_comparison.csv` includes these rows and R07/R08 stress comparisons without inventing a unique expected pitch.

## 20. Previous Strategy Reproduction

The unchanged earlier audit reran: **20,458** feature records, **8,639** labelled frames, **706** changed A/C pairs and **565** N12 annotated rows. C retains its real diagnostic improvements but original-synthetic octave-down changes **448→468** (29 new errors in S050/S071 offset by nine corrections). Prior held-out synthetic octave-down **104→52** under C, while F2's held-out synthetic voiced coverage remains **81.25%**. These results are not overwritten by the new 8-file experiment. The existing split remained frozen.

## 21. CMND Evidence

R01–R06 stable A CMND medians span **.0016–.0093**. R07/R08 lower candidates have very low median CMND (~.005/.007), whereas their listed upper alternatives have .676/.795. The candidate shortlist is diagnostic and can omit a more distant lag; these upper values therefore describe retained candidates, not every possible interpretation. The current confidence `1−selected CMND` cannot express whether another intentional source exists.

## 22. Spectral/Harmonic Evidence

`targeted_audio_timbre_analysis.csv` contains per-region median fundamental/H2/H3/subharmonic-bin support, CMND, margin, RMS and confidence. R01 F3 selected F/H2 magnitudes are ~104/76; R05 E3 ~146/44; R02 F4 ~108/8; R06 E4 ~104/10. These reflect different recorded profiles but do **not** isolate timbre from note frequency, touch or room. In R07/R08 the lower candidate can count upper-frequency energy as its H2, exactly the structural ambiguity seen in prior synthetic interference families.

## 23. Candidate Margin

R07/R08 have large median spectral-score margins (4.666/4.407) despite two known simultaneous notes. Thus a small-margin-only rule misses this source ambiguity. R06 stable median margin is 2.952 yet C changes two correct frames. Margin is a diagnostic score gap, not a calibrated probability. Previous S050/S071 likewise had non-small false-winner margins (~.87/.72).

## 24. Confidence Behavior

R07/R08 median selected confidences .995/.993 reflect excellent periodicity at the chosen lag, not certainty about which musical source should be preferred. Their polyphonic status makes “wrong pitch” undefined under V1, but clearly refutes interpreting confidence as source uniqueness. In the previous labelled corpus all voiced octave errors had confidence ≥.85 because selected CMND<.15; current confidence remains overoptimistic **if interpreted as pitch-correctness probability**. Its public meaning was not changed.

## 25. Release/Decay Analysis

Derived R01/R02/R05/R06 release windows have **138/207 voiced** frames (13+30+42+53), many with high median confidence (.998/.996/.959/.941 by case). R05/R06 RMS and energy fall, while some pitch remains coherent; R06 has six large pitch jumps. F2 flags 0/0/1/6 respectively, only **7/207**. This does not prove 138 false voiced frames: decaying tones can remain periodic after key-up, and physical key-up is unknown. The old N12 observation reproduces **46/52 voiced** release frames and F2 flags 32/52. Release behavior differs across recordings; a time or absolute-RMS gate would be unjustified.

## 26. Timbre Generalization

R05 lower E3 is mostly stable (122 correct, seven unvoiced), but R06 middle E4 is a **new counterexample for C and F2**. Qualitative timbre groups differ, without controlled source-level matching. The table of CMND, harmonic support and margin does not establish causality or a population-level timbre effect. It does reject claiming the previous held-out success generalizes to every new timbre.

## 27. f/f2 Ambiguity Analysis

R07/R08 simultaneously contain f and f/2 at unknown acoustic levels. A chooses f/2 with high confidence, C agrees, and F2 abstains on zero frames. This is physically plausible for the mixed waveform; it cannot be scored against a single intended fundamental. Controlled synthetic mixtures show why either f or f/2 can win as lower-component strength changes. An ambiguity rule based solely on A/C disagreement cannot detect cases where both algorithms agree on a single mixture period.

## 28. Synthetic f/f2 Grid

`tools/targeted_audio_synthetic.dart` creates 24 two-second, deterministic **development-only** E4/F4 signals across fundamental/H2-rich profiles and exact synthetic f/2 relative gains 0, .03, .10, .30, .60, 1.00, plus four decay controls. For a representative E4 fundamental profile, 39/39 stable frames: at gain .10 A/C choose target; at .30 A stays target but C picks lower and F2 abstains on all 39; at .60 and 1.00 **A and C both choose lower**, so F2 flags zero. The same transition appears in the F4 profile. These are controlled signal-generation ratios, **not estimates of R07/R08 acoustic dB**. They expose both C's early octave-down switch and F2's blind spot when selectors agree. The grid is development evidence, never substituted for H001–H016.

## 29. Synthetic Release Tests

Four generated F4 decays (clean, harmonic-rich, added weak deterministic high-frequency component, and weak f/2) provide 51 sampled frames each in a 1.15–1.75 s decaying tail. All 51/51 remain voiced for each recipe and F2 abstains zero. The generated tail retains substantial periodic signal, so this is **not** a demonstrated false-voicing bug. It illustrates why a rule that unvoices all release frames would remove valid pitched evidence. More realistic independently labelled tail/noise transitions are needed.

## 30. Abstention Evaluation

F2 is still the best *older selected-real* diagnostic policy: on older held-out real windows it retains 1,033/1,033 correct and reduces wrong/high-confidence frames **85→21** (94.28% voiced coverage). But on new R01–R06 stable frames it reduces **zero** confidently wrong A frames, drops **two correct R06 frames**, and leaves R07/R08 ambiguity unflagged. On H001–H016 it retains only **81.25%** voiced coverage. No new conservative rule was promoted, because the new evidence contradicts the safety hypothesis for the existing one and exact release truth is absent.

## 31. Coverage vs Wrong-Pitch Tradeoff

New monophonic stable A: **587 correct / 594 labelled** (98.82%), seven unvoiced, zero pitch-wrong. F2: 585 correct retained, seven unvoiced and two correct abstained; total labelled coverage 592/594 (99.66%), but useful correct retention falls 587→585 with **no wrong-frame reduction**. The older real held-out 85→21 reduction is real for that selected split, but cannot offset the new counterexample or held-out synthetic 81.25% coverage. Accuracy after selective rejection is never reported without its coverage denominator.

## 32. Candidate Ranking Evaluation

A/B agree on all 594 new labelled stable frames. C/E each introduce two `other` errors in R06; D produces 206 octave-down frames due to its temporal continuity behavior (69 R03 post-leap, 47 R04 pre-leap, 90 R06). The diagnostic D result is not a shipped engine error. Original synthetic C still has the S050/S071 structural regression. **No safe ranking candidate** emerges. Candidate selection should not infer intended MusicXML note or favor higher octave by fiat.

## 33. Full Safety Matrix

`targeted_audio_safety_matrix.csv` gives every requested control and C/F2 result as PASS, FAIL, NOT TESTED or NOT APPLICABLE. Fatal failures: R06 correct-pitch preservation under C/F2; C on original synthetic; F2 on H001–H016 coverage; controlled f/f2 mixtures where C chooses lower before A or both agree on lower. True lower notes and R03/R04 stable leaps remain intact under unchanged A, but this is insufficient for a candidate fix. R07/R08 are reported as stress, not scored mono failures. Existing native silence/noise/impulse and other controls pass unchanged-engine regression; independent transition/release timing remains NOT TESTED.

## 34. Runtime / Memory

`targeted_audio_runtime.csv` has three Windows-host wall-time trials on R01/R06/R07. Median unchanged-engine vs exact-window probe (ms): **120/170**, **167/223**, **202/285**. Probe includes repeated spectral calculations, trace CSV output and filesystem overhead, so the ratios (~1.42×/1.34×/1.41×) are **not** a deployable C/F2 runtime estimate. Native streaming remains chunked; private probe keeps one bounded 4096-sample window plus candidate list while CSV is streamed. Host Dart audit loads CSVs offline and is not runtime architecture. Android device CPU/memory: **NOT TESTED**.

## 35. Production Safety Gate

| Gate | Result | Evidence |
|---|---|---|
| Reduce real mono octave errors | NOT TESTED on R set | A has zero stable octave errors; old real gains cannot alone approve C |
| Reduce confidently wrong, preserve correct | **FAIL** | R06 two correct A frames lost by C/F2, no new wrong reduction |
| True lower and upper safety | PASS for unchanged A; candidate generalization NOT TESTED | R01/R05 lower and old controls; no new upper-octave file |
| Both true octave leaps | PASS for A/C/F2 stable windows; D FAIL | R03/R04 plateaus; exact latency not measured |
| Semitone/repeated controls | PASS unchanged native suite; candidate-specific NOT TESTED | no new R semitone/repeated recording |
| Original 92 synthetic not worse | **FAIL C** | octave-down 448→468 |
| H001–H016 coverage | **FAIL F2** | 81.25% voiced coverage |
| Release evidence | NOT TESTED for correctness | no key-up/tail truth; F2 flags 7/207 new release frames |
| No coverage collapse | **FAIL F2** | synthetic held-out 18.75% abstention |
| Silence/noise/impulse | PASS unchanged native tests | 4/4 CTest suite |
| New timbre / f/f2 robustness | **FAIL C/F2** | R06 and controlled grid |
| Runtime/memory bound on device | NOT TESTED | host probe not product implementation |
| ABI unchanged and Aubio-free | PASS | C ABI v1 unchanged; CMake Aubio OFF |

One fatal FAIL prohibits a production fix; several are present.

## 36. Production Decision

**A. No production change justified.** C improves some previous real windows but worsens the original synthetic corpus and introduces R06 errors. F2 helps older selected real data yet drops correct R06 frames, misses R07/R08 source ambiguity and collapses held-out-synthetic coverage. Neither ranking nor abstention satisfies the full gate. No parameter was retuned after viewing R01–R08, and no file/note/timbre/MusicXML special case was created.

## 37. Production Changes

**None.** No before/after production CSV exists because there is no second production build. Prior baseline outputs are not mislabeled as a shipped fix.

## 38. Files Changed

| File(s) | Reason |
|---|---|
| `tools/targeted_audio_validate.dart` | deterministic host PCM audit, derived-region evaluation and strategy comparison |
| `tools/targeted_audio_synthetic.dart` | development-only controlled f/f2 and decay probe inputs |
| `tools/targeted_audio_selfcheck.dart` | six checks for mapping, feature counts, stable truth, R06 coverage and polyphonic truth discipline |
| `targeted_audio_input_manifest.csv` | eight input identities/hashes and supplied musical mapping |
| `targeted_audio_phase3_verification.csv`, `targeted_audio_regions.csv` | canonical PCM stats and provisional time windows |
| `targeted_audio_production_baseline.csv`, `targeted_audio_candidate_evidence.csv` | frozen pre-tuning OpenEngine frames/exact-window candidates |
| `targeted_audio_pretuning_validation.csv`, `targeted_audio_strategy_comparison.csv` | unchanged A–E/F2 evaluation; polyphonic rows kept unscored |
| `targeted_audio_release_analysis.csv`, `targeted_audio_timbre_analysis.csv`, `targeted_audio_octave_stress.csv` | release, timbre and mixed-source evidence |
| `targeted_audio_synthetic_ff2_grid.csv`, `targeted_audio_safety_matrix.csv`, `targeted_audio_runtime.csv` | controlled mechanisms, explicit gate and bounded host timing |
| this report | interpretation, limits and decision |

All temporary PCM, synthetic waveforms, executable build files and the one-off Flutter conversion test are removed after validation; no unrelated existing worktree file is part of this task commit.

## 39. Tests Added

`tools/targeted_audio_selfcheck.dart` asserts the eight fixed IDs, 2,692/6,856 baseline/evidence row counts, zero A octave errors in eight selected mono stable regions, two correct R06 F2 abstentions, polyphonic stress truth not coerced into mono correctness, and null release truth. **6/6 pass.** A temporary Flutter test invoked the actual Phase 3 `convertS16ToAnalysisPcm` on all eight decoded inputs, checked nonempty frame counts and exactly four output bytes per frame; **1/1 pass**, removed after verification. No production implementation changed, so no mirrored production regression was added.

## 40. Full Regression Results

| Command / check | Passed | Failed | Skipped |
|---|---:|---:|---:|
| CMake Release with `MA_ENABLE_AUBIO=OFF`; `ctest --test-dir .targeted_audio_build -C Release --output-on-failure` | 4 | 0 | 0 |
| `flutter test --no-pub` on Phase 3, Phase 5 FFI, Phase 6 unit/integration, Phase 7 unit/integration, calibration and temporary eight-file conversion | 32 | 0 | 0 |
| `dart tools/pitch_candidate_selfcheck.dart` | 4 | 0 | 0 |
| `dart tools/pitch_ambiguity_selfcheck.dart` | 4 | 0 | 0 |
| `dart tools/targeted_audio_selfcheck.dart` | 6 | 0 | 0 |
| **Total test/check cases** | **50** | **0** | **0** |

The 92-case executable rerun gave **92/92** rows and zero count mismatches against frozen baseline. H001–H016 regenerated and reprobed **1,392/1,392** identical feature lines. The previous audit reran with 20,458 frames and no changed aggregate counts. New 28-case synthetic grid is a research data run, **not** a passed/failed mono test for intentionally mixed rows. Initial 92-run failed only because its optional PCM-export directory did not exist; the directory was created and the rerun completed successfully. No test is silently counted as passed from that initial invocation.

## 41. ABI Status

Public C ABI version 1, `ma_feature` layout and Dart FFI contract: **unchanged**. The candidate trace hook remains private/test-only. No score or expected MIDI enters it.

## 42. Aubio Status

Host native build used `MA_ENABLE_AUBIO=OFF`; the unchanged production library remains OpenEngine-only. Aubio was not introduced into production or the new tools. No new dependency was added; existing locally installed FFmpeg (host decode), Flutter/Dart and CMake/MSVC were used.

## 43. Build Verification

Windows host native Release targets compiled and CTest passed. This is native **test-tool compilation**, not an app output. Android native compilation/device benchmark: **NOT TESTED**, because production native source did not change. iOS build/test: **NOT TESTED** (no macOS/iOS toolchain here). No APK, AAB, IPA, desktop or web application output was created.

Reproduction used locally installed FFmpeg 5.1.1 (test-only decode), CMake 3.22.1/MSVC and the existing Flutter/Dart toolchain; no package or product dependency was added. The sequence was: decode each named M4A to bounded interleaved s16le; invoke `convertS16ToAnalysisPcm(input.openRead(), output, sampleRate: 44100, channels: 2)` in a temporary Flutter test; run `music_analysis_pitch_candidate_probe Rxx <f32le> targeted_audio_production_baseline.csv targeted_audio_candidate_evidence.csv` after writing CSV headers; run `dart tools/targeted_audio_validate.dart`, `dart tools/targeted_audio_synthetic.dart`, then `dart tools/targeted_audio_selfcheck.dart`. The test-only synthetic script expects the host probe in `.targeted_audio_build/Release/`. Private input locations and temporary PCM are deliberately excluded from committed artifacts.

## 44. Segmentation Observation

**Not applicable:** Raw production DSP and its feature stream did not change. Phase 6 was regression-tested, not reinterpreted with hypothetical diagnostic candidate outputs. Segmentation, alignment, tempo and assessment policy remain frozen.

## 45. Remaining Risks

Region boundaries are derived from the detector/waveform, not independent key sensors. AAC/host FFmpeg decoding is not an Android MediaCodec device parity measurement. No source-separated or calibrated f/f2 amplitudes exist for R07/R08. R05 has seven unvoiced selected-stable frames and the cause is not proven. Candidate shortlist may omit alternatives, diagnostic C uses costly spectral evidence without mobile benchmark, and the four synthetic decays do not model a measured key-up/background boundary. The new set has zero A stable-octave errors, so it cannot directly estimate a general improvement rate for a correction policy.

## 46. Need For More Recordings

**No new recordings are needed to reject C/F2 as currently defined.** A future production voicing/ambiguity fix needs independent truth; a minimum focused set is **four** direct, uncompressed 44.1-kHz captures with simultaneous key-down/key-up logs (target ±10 ms, actual logging uncertainty stated): (1) isolated E4 from the R05–R08 timbre at soft touch with full natural tail, to reproduce/locate R06's two changed frames; (2) isolated E3 from that timbre with full tail, protecting true lower-octave coverage; (3) E4+E3 with the two source tracks recorded separately and mixed at **measured** levels including a quiet lower component; (4) F4+F3 likewise at measured near-equal levels. Each should retain isolated stems, mix, device gain and room/preset metadata. These are for future source/release attribution, not a request to upload during this task; further broad, unlabeled recordings would have lower information gain.

## 47. APK Decision

**NO NEW APK REQUIRED.** No production runtime code changed. No APK/AAB/IPA was built.

## 48. Recommended Next Step

Keep production frozen. First independently label attack/key-up and source-separated mixtures, then test a signal-only cue that recognizes disagreement *and* cases where both methods agree on a mixture period. Freeze a new unseen timbre/room subset before final parameter selection. Require R06 correct-coverage preservation, lower/upper/true-leap safety, no original or held-out synthetic regression, interpretable release behavior and measured Android CPU/memory before reopening a small DSP-only fix. Boundary segmentation remains a separate later calibration.
