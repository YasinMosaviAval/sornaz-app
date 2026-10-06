# Sornaz — Raw pitch, voicing and octave-artifact investigation

## 1. Executive Summary

All **39/39** real sources were found. Frozen V01–V04 Phase 3→Open DSP/FFI→unchanged Phase 6 reproduced **592/480/618/458** features and **14/4/13/10** segments, with no change to the committed video ground truth or baseline. The four videos contain **136 accepted pitch frames in 565 visually pre-key-down frames**. Those frames carry a persistent ~147 Hz component, have RMS above the native .003 silence gate, and often confidence ≥.85. Its physical source is unknown; it is not proof that YIN invented a frequency from digital silence. In derived release windows, 231/394 frames remain accepted, but key-up is partly occluded and pitched decay may be real; their correctness cannot be labelled frame-by-frame.

V02 is a distinct stable octave failure: in 121/121 conservative E4 sustain frames, production reports E3. An upper candidate near E4 **is generated**, but its median CMND is **.3112** versus **.0069** for selected E3. The first-minimum-below-.15 rule therefore chooses E3 with median confidence **.9931**. Median spectral support is F/H2 **43.1/95.1** for the lower candidate and **95.1/17.9** for the upper candidate. Both are plausible signal components; the intended musical source is known from video/user mapping, not inferable from CMND alone. Frozen spectral Strategy C does not fix V02 and its original-synthetic regression reproduces exactly (448→468 octave-down; 29 newly wrong in S050/S071). Thus candidate generation is not the demonstrated blocker; candidate selection **and** pre-note voicing acceptance are separate problems. Confidence is periodicity evidence, not calibrated note correctness.

The best narrow *diagnostic* silence policy, B (`RMS ≥ .010`), cuts visually pre-note accepted frames **136→30** (−77.9%) and preserves 3,287/3,287 previously correct labelled real stable frames. It simultaneously removes **52/52** frames of a deterministic legitimate weak tone and **36/52** of a quiet tone. Raising confidence to .95 removes all 136 video pre-note frames but accepts **52/52** periodic-background frames and rejects **532** correct real stable frames. No voicing or candidate-selection policy passes its independent safety gate. **Decision A: No production DSP change justified.** Segmentation remains unchanged; V01–V04 stay **14/4/13/10**, and the five older controlled-piano F4→E4 merges remain. **NO NEW APK REQUIRED.** Next: characterize the recorded 147 Hz source/context with existing audio and design a source-independent way to express uncertainty without sacrificing quiet notes; do not threshold-tune these four takes into production.

## 2. Scope / Non-Goals

This is a host-only, score-independent investigation. Production DSP, Phase 6, FFI/ABI, MusicXML, tempo, alignment, assessment, persistence and UI were frozen. No new recording or app binary was requested or made. R07/R08 remain polyphonic stress controls and are excluded from monophonic accuracy gates.

## 3. Repository State

The worktree contained unrelated modifications before this task; none was staged. Current native source, not historical prose, determines thresholds. Diagnostic tools compile with `MA_TRACE_YIN`; production shared library does not. The previous split and reports remain unchanged.

## 4. Previous Reports Reviewed

Phase 4B Open DSP, Phase 5 FFI, Phase 6 segmentation, Phase 7 assessment, controlled-piano and boundary calibration, blinded candidate ranking, release/voicing ambiguity, targeted real-audio DSP validation, and video-grounded segmentation validation were read against current code and frozen artifacts. In particular, prior F2 abstention's held-out synthetic coverage loss and Strategy C's S050/S071 regression were treated as blockers, not forgotten results.

## 5. Input Availability

N01–N12, P01–P10, C01–C05, R01–R08 and V01–V04: **39/39 source files present**. `raw_voicing_input_manifest.csv` lists safe case IDs and filenames only. The 27 prior N/P/C frames, eight R frames and four regenerated V frames total **10,374 + 2,692 + 2,148 = 15,214**. The original 92 synthetic signals and frozen H001–H016 generator/annotations are available. No source was substituted or renamed for analysis.

## 6. Ground Truth Quality

`video_boundary_ground_truth.csv` and `video_expected_notes.csv` were reused unchanged. Visible pre-key-down is independent negative note evidence. Musical labels support stable sustain pitch, but video key-up windows are broad/occluded. R release/background windows and N/P/C stable windows are previously derived annotations, not independent millisecond attack/release truth. Region provenance is explicit in `raw_voicing_region_annotations.csv`; undefined release pitch is never scored as zero or as a proven error.

## 7. Current Open DSP Architecture

The production 44.1 kHz mono stream is processed in 512-sample hops using a 2048-sample sliding window. Open DSP computes spectral flux and FFT-assisted YIN/CMND for 80–2000 Hz. The first qualifying minimum below .15 is selected, with parabolic lag interpolation. There is no score or instrument information.

## 8. Current Pitch / Voicing Rules

Native sets `is_silent = RMS < .003`; silent frames do not enter the pitch engine. For a selected candidate, `pitch_confidence = 1 − selected CMND`. `signal_quality` is zero if silent and otherwise `max(0, 1 − 4×clipping_fraction)`; it does not independently judge musical pitch. Phase 6 additionally requires pitch>0, non-silent, confidence≥.55 and RMS>.001. Since native non-silent already means RMS≥.003, the .001 Phase 6 gate adds no protection against these background frames. Onset is a separate spectral-flux/impulse descriptor, not a voicing veto.

## 9. Baseline Reproduction

The four MP4 AAC tracks were again decoded from their same takes without trim or gain; the actual Phase 3 converter produced 44.1 kHz mono f32le. The host trace and frozen video raw CSV agree on case/sample IDs and pitch to <5×10⁻¹⁰ Hz numerical difference. Feature counts and segment counts match the prior report exactly. `raw_voicing_baseline_features.csv` freezes all 39 real cases with flags, peak/clipping, derived quality, regions and candidate fields where exact evidence exists. No threshold changed before capture.

## 10. V01 Deep Dive

Before the visible F4 key-down, **39/147** frames are accepted as pitch, all rounded MIDI 50, all confidence≥.85. Median accepted RMS **.00859**, confidence **.8804**, selected CMND **.1196**. Example at 0.952 s: 147.06 Hz, RMS .00743, confidence .8918, CMND .1082, with a visible spectral component near 147 Hz. This exceeds the native silence gate and qualifies the first CMND minimum. The source of the periodic background is unknown. In the broad decay/key-up window, **101/118** frames remain accepted, median confidence .9047, with F3/F4 and lower fragments; physical key-up and acoustic pitch truth are insufficient to declare all 101 false.

## 11. V02 Deep Dive

The conservative stable window contains **121/121 octave-down E3** frames at median RMS .0778 and confidence .9931. Lower candidate median CMND .0069, F 43.1, H2 95.1; upper E4 candidate CMND .3112, F 95.1, H2 17.9. E4 is present as a local-minimum alternative but fails the .15 qualification. The lower lag explains more periodicity of this particular mixed/harmonic waveform. A qualitative timbre difference is known; no instrument spectrum or physical subharmonic source is asserted. A simple voicing gate cannot repair this strong voiced error. A first-qualifying-minimum *selection rule* is involved, but no score-agnostic safe replacement has been established.

## 12. V03 Deep Dive

The two main F4 articulations remain separate. **37/129** pre-note frames are accepted, mostly MIDI 50; broad release and post windows contain 31/90 and 27/144 accepted frames. The 13 total segments are therefore not evidence of a missed same-pitch boundary in this take. Extras trace primarily to accepted raw low-frequency observations; exact release-specific false counts remain unproven.

## 13. V04 Deep Dive

The principal F4→E4 legato boundary remains present, unlike the five C-family merges. **42/139** pre-note frames are accepted, mostly MIDI 50; broad release and post windows contain 46/86 and 9/87 accepted frames. V04 does not justify changing the existing pitch-change boundary rule. The difference from C-family may be raw pitch stability, timing, articulation or capture conditions; a unique causal factor is not established.

## 14. Pre-Note Silence Analysis

Video pre-key-down windows contain 565 frames, 136 accepted as voiced/pitched, **136/136** with confidence≥.85. MIDI 50 dominates (133 frames), with three MIDI 51 frames. The physical note has not yet been pressed, but the recorded waveform has a real periodic component; the precise acoustic source remains unknown. These windows provide independent evidence that the current *musical voicing acceptance* is too permissive in this context.

## 15. Post-Note Background Analysis

The four post windows contain 533 frames and 82 accepted pitches, usually MIDI 50. This is weaker ground truth than pre-key-down because video key-up is partly occluded and residual acoustic decay may persist. `raw_voicing_silence_analysis.csv` therefore calls these pitch **estimates**, not confirmed false notes.

## 16. Release / Decay Analysis

The broad video decay/key-up windows contain 394 frames and 231 accepted estimates. Median confidence among accepted frames ranges .889–.918 across cases. V01 and V04 include octave-down fragments while the envelope falls. CMND can remain low because a decaying periodic signal is still periodic; its confidence need not fall with RMS. This is a semantics mismatch if interpreted as certainty of an active key, but a pitched tail may be legitimate. No timestamp-precise release false-voiced reduction is claimed.

## 17. Noise Floor Analysis

Video median pre-note RMS is .00490–.00673 across takes, above the native .003 gate; accepted pre-note frames have median RMS .00568–.00865. Earlier R leading regions are ~.0011–.0015 RMS and have zero accepted frames, showing a capture-domain difference. Synthetic periodic background Q005 has median RMS .00573, while a legitimate weak note Q007 has .00424. Their energy ranges overlap, making a universal amplitude-only rejection unsafe. `raw_voicing_noise_floor.csv` separates visually grounded V background from derived R leading windows.

## 18. CMND / YIN Analysis

Pre-note V01's selected 147 Hz CMND .1082 passes .15. V02's selected E3 median .0069 passes strongly, whereas the E4 local minimum median .3112 does not. Interpolation changes the selected frequency slightly; it is not the source of the octave choice. The V02 failure is not a missing upper candidate. CMND is a periodicity measure; it cannot by itself identify the user's intended musical source when lower-frequency periodic energy and upper harmonics coexist.

## 19. Candidate Generation Analysis

**No demonstrated generation failure** for V02: the diagnostic trace contains an upper candidate in every analysed stable frame. Some background windows have only one viable minimum, so a candidate-margin abstention has no useful competing candidate there. Absence of a second candidate is not evidence of a correct musical note.

## 20. Candidate Selection Analysis

**Yes, selection is implicated** for V02: first CMND minimum below .15 selects the lower candidate. Frozen A/B/C/E ranking outputs all remain octave-down in 121/121 V02 stable frames (`raw_voicing_candidate_selection.csv`). An unconditional upper preference would harm true E3/F3 and real octave leaps. Strategy C's source-confusion counterexamples rule out promoting it.

## 21. Voicing Acceptance Analysis

**Yes, acceptance is implicated** for visually pre-note frames: RMS≥.003, pitch>0 and confidence≈.88 allow repeated 147 Hz estimates through both native and Phase 6 gates. Because a genuine weak sinusoid can have lower RMS than this background, a single larger absolute threshold cannot distinguish them in general.

## 22. Confidence Audit

All 136 accepted video pre-note frames exceed .85 confidence, though no target key is down. V02's wrong octave reaches median .9931. Confidence correctly states `1−CMND` but is overconfident if interpreted as correctness or active-note probability. Quality remains ~1 in unclipped non-silent frames; it is not an independent rescue signal.

## 23. Spectral Diagnostic Evidence

Exact-window Goertzel F/H2/H3/f/2 measurements and diagnostic C scores for all four videos are in `raw_voicing_candidate_evidence.csv`; V02 paired lower/upper rows are in `raw_voicing_v02_octave_analysis.csv`. V02's lower candidate has substantial own-F and upper-as-H2 support. A large score margin (median **2.145** in C score units) can accompany the wrong lower candidate. These are relative spectral magnitudes, not calibrated SPL or instrument-specific labels.

## 24. Failure Taxonomy

`raw_voicing_failure_taxonomy.csv` records 136 independently pre-note false-pitch frames, 82 post-window estimates with weak release truth, 231 decay-or-sustain uncertain estimates, and 121 independently labelled V02 stable-sustain octave-down frames. Attack transient and low-energy unstable categories are not assigned a proven count without independent timing/pitch truth. V01/V03/V04 have no stable-window octave-down in their conservative labels. No aggregate release estimate is silently called a confirmed false event.

## 25. Real Corpus Distribution

Across all 39 real cases, labelled stable slices include **3,287** correct accepted frames and **457** wrong accepted frames (336 previous N/P/C, zero R, 121 V02) under the current gate. This is a selected-window diagnostic, not population accuracy. Previous N/P/C regions are partly selected from contours; R regions are derived; only V pre-key-down has stronger independent negative timing truth.

## 26. Synthetic Silence / Noise Tests

The 18 new deterministic Q controls are development diagnostics only. Digital silence, seeded low/strong white noise, low-frequency-noise mixture and impulse produce zero accepted frames in their labelled windows. Q005, a steady 147 Hz low-amplitude periodic background, produces **52/52** accepted frames at confidence≈.990. This is a deliberate counterexample: a periodic background and a quiet legitimate tone can be indistinguishable to a frame-local pitch detector without source/context evidence.

## 27. Synthetic Decay Tests

Clean decaying Q010 has 36/52 accepted frames; harmonic-rich Q011 39/52; decay+noise Q012 28/52; decay+subharmonic Q013 52/52 with a lower-octave median. These are controlled waveform recipes, not physical key-up truth. RMS .010 rejection removes substantial legitimate decaying periodic tails, so a blanket decay veto is unjustified.

## 28. Synthetic Octave Grid

Q014 true E3 and Q015 true E5 retain all 52/52 stable frames. In a three-gain f/2 grid at intended E4, weak lower component Q016 remains near E4 but has median confidence .924; moderate/strong Q017/Q018 select E3 with confidence≈.9999. A .95 confidence gate would reject Q016's correct frames yet retain the confidently wrong Q017/Q018 frames. The recipe is exact; real V02 component amplitude ratio is **not** inferred from it.

## 29. Previous Strategy C Regression Recheck

The original 92 signals were regenerated and run through the current production engine and exact-window probe. All **8,692 feature lines** and **36,096 evidence lines** equal frozen artifacts, and 92 case-level baseline counts match. The unchanged C scorer reran: A octave-down **448**, C **468**; 29 newly wrong frames occur only in **S050 (14)** and **S071 (15)**, offset by nine corrections elsewhere. These interference recipes demonstrate that the true upper target can become H2 evidence for a wrong lower candidate. The 16 held-out signals regenerated with **1,392/1,392** feature lines and their evidence identical to frozen records; the prior held-out split was not retuned.

## 30. Diagnostic Strategies

A is current production. B requires RMS≥.010. C requires confidence≥.950. D combines B+C. E abstains when a viable spectral alternative outranks production and differs by >7 semitones. B–E are **offline** rules, not native changes. A/B/C/E frozen candidate ranking was separately evaluated on video stable regions. No adaptive-floor rule was promoted or tuned: the measured quiet-note/background overlap and absence of a validated causal noise-floor protocol make a first-seconds calibration assumption unsafe.

## 31. Coverage vs Error

| Policy | Video pre-note retained / 136 | Correct real stable retained / 3,287 | V02 wrong stable retained / 121 | Quiet Q007 retained / 52 |
| --- | ---: | ---: | ---: | ---: |
| A | 136 | 3,287 | 121 | 52 |
| B RMS .010 | 30 | 3,287 | 121 | 0 |
| C confidence .950 | 0 | 2,755 | 121 | 52 |
| D B+C | 0 | 2,755 | 121 | 0 |
| E spectral disagreement | 136 | 3,281 | 121 | not evaluated on new Q exact candidates |

E removes 249/336 wrong previous-real stable frames but four correct previous and two correct R stable frames; it catches **none** of the video pre-note or V02 failures. C rejects 311/336 previous-real wrong frames but also 452 correct there, 34 correct R and 46 correct V. Coverage must be read with both error and correct-loss counts, not as an accuracy score alone.

## 32. Quiet-Note Preservation

B rejects Q007 52/52 and Q008 36/52, despite both being valid E4 sinusoidal notes. This decisive safety failure blocks amplitude threshold promotion. C retains those two quiet tones but not Q005 periodic background. The real corpus does not contain an independently calibrated matched-volume quiet-note/background pair; its absence is recorded, not replaced by a synthetic claim of real-world generalization.

## 33. Lower-Octave Safety

The frozen real E3/F3 controls and Q014 remain stable under B; C loses some correct lower-octave real frames (e.g. N01/N04). Candidate C or an always-up rule is not justified. No production octave correction was implemented.

## 34. Upper-Octave Safety

Q015 retains all true E5 frames under B/C. Real N03/N06 correct upper frames lose 7/30 and 14/41 under C, respectively. A stricter periodicity threshold therefore has an observable upper-register coverage cost.

## 35. Octave-Leap Safety

B retains existing labelled stable N07/N08 and R03/R04 pre/post leap frames. C rejects 25 correct N07 and 19 correct N08 frames. Exact transition latency is not independently labelled; no new continuity rule was tested or promoted.

## 36. Semitone Safety

Existing C/P small-interval stable annotations and V04 F4/E4 remain baseline material. B does not alter their labelled correct stable coverage, but cannot fix the five C-family F4→E4 segmentation merges. C/E lose some healthy frames in the broader corpus. Segmentation was not changed.

## 37. Original Synthetic Safety

Of 89 pitch-labelled original synthetic cases (three silence/noise/impulse controls carry no expected pitch), A retains 3,920 correct and 708 wrong stable frames. B changes neither total; C retains 3,380 correct and 448 wrong, rejecting **540 correct**. Candidate Strategy C separately increases octave-down 448→468. Passing only an aggregate wrong-frame reduction would hide this coverage and octave regression.

## 38. Held-Out Synthetic Safety

H001–H016 remain frozen. A and B retain 624 correct and 208 wrong labelled frames; C confidence .950 retains all 624 correct and 104 wrong on this set, but fails the original synthetic/real/periodic-background gates. Frozen previous F2 disagreement abstention still has its previously documented 81.25% voiced coverage on this held-out corpus. No threshold was retuned after examining held-out results.

## 39. Voicing Production Gate

**FAIL.** B has meaningful pre-note reduction but fails weak/quiet legitimate tones; C misses high-confidence periodic background and loses 532 correct real stable frames; D combines their losses; E does not reduce the video pre-note artifact. Release truth is insufficient for a claimed false-voiced improvement. Lower/upper/leap checks alone cannot override these failures. Detailed PASS/FAIL/NOT TESTED entries are in `raw_voicing_safety_matrix.csv`.

## 40. Candidate-Selection Production Gate

**FAIL.** V02 remains 121/121 octave-down under frozen B/C/E candidate ranking; original-synthetic C regression is exactly reproduced. A new generic candidate policy that distinguishes V02 from true lower notes, mixed-source controls and leaps was not established. Instrument/name/MIDI/score hardcodes were not considered.

## 41. Combined Production Gate

**NOT TESTED** because neither independent fix passed. Combining failed strategies would not establish safety.

## 42. Production Decision

**A. No production DSP change justified.** The current evidence establishes two distinct failures but also a quiet-note/background identifiability limit for simple static thresholds. No policy meets accuracy, coverage, synthetic, release-truth and safety requirements simultaneously.

## 43. Exact Production Changes

None. No YIN/CMND, threshold, confidence, native onset, FFT, segmentation or downstream behavior was changed.

## 44. Files Changed

Only this report, test-only tools and new `raw_voicing_*.csv` diagnostics were added. Existing reports, video ground truth, frozen split, production code and unrelated worktree files were not changed in the commit.

## 45. Tests Added

`tools/raw_voicing_pcm_test.dart` reproduces Phase 3 canonical PCM for the four same-take videos. `tools/raw_voicing_synthetic.dart` creates 18 deterministic test-only controls. `tools/raw_voicing_investigate.dart` and `tools/raw_voicing_recheck_c.dart` produce auditable comparisons; `tools/raw_voicing_selfcheck.dart` asserts the key safety counterexamples. They are not app dependencies. No production regression test was added because production behavior did not change.

## 46. Full Regression Results

Flutter Phase 3, Phase 5 FFI, Phase 6, Phase 7, calibration, video baseline and new PCM test: **33 passed, 0 failed, 0 skipped**. Native DSP/C ABI/Open-A-B/original-synthetic CTest: **4 passed, 0 failed, 0 skipped**. Three existing diagnostic self-check scripts passed (4 candidate, 4 ambiguity and 6 targeted assertions), as did the new five-assertion raw-voicing self-check. The 92 original and 16 held-out synthetic reproduction checks passed with zero frozen-line mismatches. Android/iOS/device tests were not run, not counted as passes.

## 47. ABI Status

Unchanged; `ma_feature` layout and public C symbols were not edited.

## 48. FFI Status

Unchanged. The real Dart↔native integration tests passed.

## 49. Aubio Status

Excluded from the production host build (`MA_ENABLE_AUBIO=OFF`); no Aubio dependency was added. Existing A/B test tooling is research-only.

## 50. Android Native Build Status

**NOT TESTED.** No native production code changed, so no app/native platform output was built merely for this diagnostic task.

## 51. iOS Build Status

**NOT TESTED.** This environment is Windows and has no Xcode/iOS build verification.

## 52. Runtime / Memory

Production runtime and memory impact are **zero by unchanged code**. Diagnostic traces require offline candidate storage and were not benchmarked as a mobile production candidate. No performance claim for B–E on Android devices is made.

## 53. Segmentation Revalidation

There is no accepted DSP change, so unchanged Phase 6 remains the valid before/after comparison: V01 **14→14**, V02 **4→4**, V03 **13→13**, V04 **10→10**. The same-take video baseline was rerun and matched its frozen artifact. A speculative diagnostic gate was not passed to production segmentation and is not labelled an after result.

## 54. Remaining Segmentation Failures

The five controlled-piano C-family F4→E4 merges remain **5/5** in the unchanged prior baseline. V04 itself already separates F4→E4. No Phase 6 code or policy was changed.

## 55. Remaining DSP Risks

The recorded 147 Hz pre-note component's source is unknown; a frame-local detector cannot know whether an otherwise identical quiet sinusoid is background or an intended note. V02's strong lower-period fit remains unresolved without a generic candidate rule that preserves true lower notes and synthetic mixtures. Release correctness remains weakly labelled due occluded key-ups. `signal_quality` does not address these ambiguities. No reference leakage is acceptable as a workaround.

## 56. Need For More Recordings

**NO NEW RECORDINGS REQUIRED now.** Existing video, real and synthetic corpora are sufficient to reject the tested rules. Further work should first use the existing waveform/recording context and diagnostic source comparisons. If a future proposed policy fundamentally needs independently labelled weak note versus matched periodic background, that requirement should be specified then, not requested speculatively here.

## 57. APK Decision

**NO NEW APK REQUIRED.** No APK, AAB or IPA was built. No production runtime code changed.

## 58. Recommended Next Step

Investigate the shared ~147 Hz background source and model reliability using evidence beyond single-frame RMS/CMND, with a protocol that can preserve weak notes. Separately seek a candidate-selection criterion that beats V02 **and** S050/S071 while preserving real lower notes and octave leaps. Evaluate each on the frozen split before revisiting a production fix; only after a safe DSP change should unchanged Phase 6 be revalidated on all 39 recordings.
