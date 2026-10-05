# Sornaz — Video-grounded note-boundary validation

## Executive decision

All four numbered videos were found with the stipulated V01–V04 mapping. Same-take AAC audio was decoded without trimming, gain change, pitch shift or time stretch, then passed through the actual Phase 3 canonical PCM conversion, production Open DSP/FFI and unchanged Phase 6 segmenter. Visual key-action windows were annotated before using the audio features for comparison. Video exposes the two articulations in V03 and the legato movement in V04, but fingers obscure several exact key releases; those are deliberately low-confidence intervals, not millisecond ground truth.

Production returned **14, 4, 13 and 10 segments** for V01–V04, against musical counts **1, 1, 2 and 2**. The two principal V03 F4 segments and the principal V04 F4→E4 segments are already separate. V02's sustained estimate is E3 (MIDI 52) rather than E4 (64), a raw-DSP octave error before segmentation. Other accepted raw pitches, particularly MIDI 50 in nominal silence and octave-down fragments in decay, create many spurious segments. The earlier five controlled-piano F4→E4 merges remain a distinct, defensible segmentation failure; V04 does **not** reproduce that merge. Frozen diagnostic policies B–E did not solve the video count failures and some added segments. **Production safety gate: FAIL. No production segmentation change justified. NO NEW APK REQUIRED.**

## Scope, repository state and prior evidence

The starting production Open DSP, confidence, ABI, FFI and segmenter were frozen. No MusicXML, expected MIDI, filename or expected count enters production analysis. The previous `MUSIC_ANALYSIS_BOUNDARY_SEGMENTATION_CALIBRATION_REPORT.md` and its prior raw-feature, baseline, truth, strategy and sensitivity artifacts were reviewed. That report found 35 real recordings (33 scored monophonic), 13,066 features, five controlled-piano F4→E4 merges, and no safe production candidate. The 35 earlier inputs and the original synthetic/native regression artifacts remain available; R07/R08 are polyphonic and remain outside the monophonic gate. The previous diagnostic policy C separates the five C-family boundaries but regresses R06. The video comparison uses those **frozen** policy definitions, not retuning on the four new takes. No previous artifact was overwritten.

The Phase 6 code starts a voiced candidate at pitch>0, confidence≥0.55, RMS>0.001 and non-silent flag; two invalid frames close it. A valid native onset can split after 0.055 s; a pitch deviation ≥0.8 semitone from the confidence-weighted active mean splits immediately. A candidate needs two frames and ≥0.055 s. There is no dedicated re-articulation, release envelope or pitch-confirmation state. These are the actual current rules, not proposed replacements.

## Input metadata, audio preparation and synchronization

| Case | Mapping | Container / video / audio | Decoded frames | PTS frame step | Phase 3 canonical frames / duration |
| --- | --- | --- | ---: | --- | --- |
| V01 | F4 | MP4, H.264 1280×720, AAC-LC 48 kHz stereo | 207 | 33.31–33.36 ms | 302,938 / 6.869 s |
| V02 | E4 | same codecs and dimensions | 162 | 33.31–63.33 ms | 245,549 / 5.568 s |
| V03 | F4→F4 | same codecs and dimensions | 210 | 33.31–63.34 ms | 316,109 / 7.168 s |
| V04 | F4→E4 | same codecs and dimensions | 159 | 29.99–45.64 ms | 234,259 / 5.312 s |

Nominal video rate is 30 fps. V01 is effectively constant-rate; V02–V04 have observed PTS variation, so annotation uses decoded frame PTS, not frame-index/30. Video and audio streams start at PTS 0 in their containers. Decoded audio durations are 6.869, 5.568, 7.168 and 5.312 s, compatible with the container durations 6.90, 5.60, 7.20 and 5.31 s at stream-end granularity. No arbitrary synchronization offset was applied. Hardware camera/audio latency and exact physical-to-acoustic onset delay are **not independently measured**. Audio was decoded from each corresponding MP4 to 48 kHz stereo signed PCM, then converted by the application's real Phase 3 path to 44.1 kHz mono little-endian float32; timestamps were never trimmed. The local FFmpeg executable was diagnostic-only and no app dependency was added.

## Independent visual event annotation

`video_boundary_ground_truth.csv` records 12 visual key-down/up events with frame indices, actual PTS and conservative earliest/latest intervals. The matched musical sequences are in `video_expected_notes.csv` and are evaluation-only. Finger travel and contact are visible around V03's second articulation (frames 92–101) and V04's second movement (frames 69–77). Approximate V03 second-down window is **3.163–3.467 s**; V04 second-down window is **2.309–2.572 s**. Several release events are occluded by the hand, so their broad intervals are low confidence. They cannot support precise key-up-to-segment-end error or a claim that every voiced decay frame is false. The annotation is visual; raw DSP outputs were not used to set its frames. Frame-level contact sheets and FFmpeg `showinfo` PTS were used for inspection; those temporary images/logs are not ground-truth substitutes.

## Frozen production baseline and attribution

| Case | Expected | All production segments | Principal musical segments | Supported conclusion |
| --- | --- | ---: | --- | --- |
| V01 | 65 | 14 | 65, 1.800–3.088 s | Single note is split and surrounded by low-frequency pre/tail pieces. |
| V02 | 64 | 4 | 52, 1.881–4.122 s | Sustained octave-down mistake occurs in raw DSP; segmentation cannot repair the pitch. |
| V03 | 65→65 | 13 | 65, 1.718–2.728 s; 65, 3.309–4.563 s | Main same-pitch articulations are separate; full output has 11 other pieces. |
| V04 | 65→64 | 10 | 65, 1.800–2.461 s; 64, 2.554–3.495 s | Main legato boundary is present; full output has eight other pieces. |

Total raw features: **2,148** (592/480/618/458). The four outputs contain 41 segments against six expected events, a **count excess of 35**; this is not a claim of 35 independently timed false attacks. Four pre-key-down MIDI-50 fragments in V01 and several similar fragments in the other videos are plainly outside the visible main articulations. Release fragments are harder to classify precisely because physical key-up is occluded and pitched decay may continue. Accepted voiced-frame distributions are V01 65:138/53:56/50:73, V02 52:193/50:30, V03 65:195/53:16/50:88, V04 65:57/64:93/52:14/50:58 plus a few other values. Thus native pitch/voicing artifacts are a substantial *first-layer* cause of extras; Phase 6 also turns these accepted observations into note events under its existing rules. It is not defensible to solve the V02 raw octave error with a segmentation MIDI correction.

At V03's second key-down interval, the second principal segment starts at 3.309 s, inside the broad visual window. At V04's second key-down interval, the E4 principal segment starts at 2.554 s, likewise inside its broad window. These are interval-consistency observations, **not** calibrated audio/video latency or a precise boundary-error estimate. The V04 F4 segment ends at 2.461 s, overlapping the transition interval; the visual record cannot localize exact F4 release more tightly. `video_boundary_evidence.csv` retains nearby voiced counts, median fractional MIDI, onset flags/strength and RMS for each annotated event.

## Candidate policies and safety

The frozen previous diagnostic policies were B (three-frame pitch confirmation without onset), C (onset-assisted three-frame confirmation), D (three-frame invalid gap) and E (combined). None was promoted into production. On V01, all return 14 pieces; on V03, all return 13. V02 returns four pieces with B/C and five with D/E, retaining the wrong E3. V04 returns 12 with B/C/E versus baseline 10, and 10 with D. Consequently no candidate simultaneously preserves V01/V02, improves V03/V04 full sequences and avoids new extras. Policy C remains the best *historical* diagnostic for the five C-family F4→E4 merges, but it is not a safe production policy. No new parameter sweep was justified after these failures; one-off threshold tuning on four correlated takes would be overfit.

`video_segmentation_safety_matrix.csv` records each gate as PASS/FAIL/NOT TESTED. Core video single-note preservation and no-extra requirements fail. Full prior-corpus and synthetic candidate revalidation, device runtime and parameter sensitivity are marked NOT TESTED for a production candidate because no candidate survived the preliminary video gate. Existing native synthetic and DSP regression tests were nevertheless rerun. This is an intentional early stop, not a claim of full candidate safety. Runtime impact of production is **zero by unchanged code**; candidate host slowdown was not benchmarked and device timing is NOT TESTED.

## Artifacts, tests and decision

New task artifacts: `video_boundary_input_manifest.csv`, `video_boundary_ground_truth.csv`, `video_expected_notes.csv`, `video_audio_extraction.csv`, `video_audio_sync_verification.csv`, `video_boundary_raw_features.csv`, `video_segmentation_baseline.csv`, `video_boundary_error_analysis.csv`, `video_boundary_evidence.csv`, `video_segmentation_strategy_comparison.csv`, `video_segmentation_safety_matrix.csv`. They contain no private absolute paths. Reproducible test/diagnostic sources are `tools/video_boundary_extract.ps1`, `tools/video_boundary_baseline_test.dart`, `tools/video_boundary_artifacts.ps1` and `tools/video_boundary_compare.dart`. The baseline audio bytes and contact images are local temporary files and are not committed.

Flutter Phase 3, native FFI, Phase 6, Phase 7, calibration and video baseline: **32 passed, 0 failed, 0 skipped**. Native DSP, C ABI and Open/A-B `ctest`: **3 passed, 0 failed, 0 skipped**. The initial sandboxed Dart/Flutter invocation stalled on SDK access; rerunning with accessible SDK cache completed successfully. Android compilation, iOS build and device performance: **NOT TESTED**; no APK, AAB or IPA was built.

**Production decision: NO PRODUCTION CHANGE.** Raw DSP, native onset implementation, Phase 6, ABI, Dart FFI, tempo, alignment, assessment and MusicXML code are unchanged. Aubio remains excluded from the production native library. The safety gate fails because the available policies leave V01/V02 badly over-segmented, fail the V02 raw octave case and can add extras to V04; full candidate regression and runtime were therefore not claimed. **NO NEW APK REQUIRED.**

**NO NEW RECORDINGS REQUIRED now.** The next useful step is to investigate the existing native raw pitch/voicing artifacts in nominal silence and decay, then rerun segmentation on the same 39 real recordings. Any later release-specific boundary fix should first obtain reliable key-action timing or MIDI-event capture only if the present occluded key-up intervals remain decisive; a broad new recording request is not justified by this run. The earlier C-family F4→E4 merge still needs a separate general policy that passes single-note and repeated-note controls.
