# Sornaz — controlled note-boundary calibration and conditional segmentation decision

## Executive summary and decision

All ten supplied files, including the subsequently supplied `Sornaz_7.m4a`, were processed through the **unchanged** Phase 3 PCM preparer, production-open Phase 5 FFI/DSP and Phase 6 segmenter. The baseline was saved before considering a fix. Contrary to the previous five-take piano result, the dominant failure in this new set often begins **before segmentation**: for declared F4/E4 notes, the raw open engine repeatedly reports F3/E3 (exactly one octave down), sometimes alternating with the correct octave. A separate diagnostic frequency analysis of the same decoded audio shows a strong F4/E4 fundamental in selected misread windows. For example, in case 01 at 1.95 s the F4-bin magnitude is 46.95 versus F3 2.63, while raw DSP in that region predominantly reports F3. The current YIN-like algorithm chooses the first lag whose CMND falls below 0.15; an independently computed 4096-sample window near that time has CMND 0.256 at the F4 lag versus 0.122 at the double/F3 lag, providing a concrete mechanism consistent with the wrong-octave choice. The independent window is not byte-for-byte the native rolling window, so it does not prove every individual frame's internal decision.

The resulting 5–9 performed segments in several two-note files are **not** evidence for a general segmenter threshold fix: many reflect high-confidence wrong-octave raw frames and noise/tail observations. Both repeated-note files visibly contain two target-note regions; case 07's raw pitch is F3 for both despite strong F4 spectral energy, while case 08 contains two E4 regions plus release octave artifacts. The very short D4 in case 09 is **not dropped**: one 0.220 s D4 segment is emitted, as compared with 0.476 s in case 10. No production change was made. The appropriate next step is a separately scoped, ground-truth-independent investigation of open-DSP octave/subharmonic selection, with exact native-window traces and clean controls. A segmentation fix should follow only after the raw observation issue is isolated and onset times are annotated.

## Scope, source mapping and guardrails

The case mapping is **exactly** the user's declaration; it was never inferred from audio names or supplied to the production observation pipeline:

| Case | Recording | Declared ground truth | Condition | SHA-256 |
|---:|---|---|---|---|
| 01 | `Sornaz_1.m4a` | F4→E4 (65→64) | Detached | `943E2FA6F3E2EBFB8956CA4D77A4143965B0D110C6F023EBD3690C382E8DB5FA` |
| 02 | `Sornaz_2.m4a` | F4→E4 (65→64) | Legato | `0BD9FE8890FED10B83B843A4BBBF3BA877E557460316E2264EB95E9DF27A2980` |
| 03 | `Sornaz_3.m4a` | F4→E4 (65→64) | Slow | `5ADCA412DAC3DE67B13E2BA32CA76FD0C1C34975E2CB4C187B2B9E05A40504EF` |
| 04 | `Sornaz_4.m4a` | F4→E4 (65→64) | Fast | `1452E9AAFCDB0FB0CBE0394B7AFD6ADB48B12DB62FC69C876DDA3EDAAF5A81D2` |
| 05 | `Sornaz_5.m4a` | F4→E4 (65→64) | Soft | `5958E0FB5CB6840104ABBD1628AA6CA038B5B1F6218DFB706073274E6E920553` |
| 06 | `Sornaz_6.m4a` | F4→E4 (65→64) | Loud | `8D95F06BC371FCB9F36D62AC834A71408A21D9F21A90CB5782EBE73E4CCFF6BC` |
| 07 | `Sornaz_7.m4a` | F4→F4 (65→65) | Repeated same note | `27A78CEA820965CB3BB6B3570A68E62485CF5D04B2F01F0FD8BC0C41D7A720E2` |
| 08 | `Sornaz_8.m4a` | E4→E4 (64→64) | Repeated same note | `9492779D9631CAED8CF23A164EE5ADBD6E820310366611C4F8E4604484E2A27A` |
| 09 | `Sornaz_9.m4a` | D4 (62) | Very short | `0B91D5B4070DC517F00BE53EC272D82B18686246267D4136BC64D3DA9A469D4B` |
| 10 | `Sornaz_10.m4a` | D4 (62) | Normal duration | `7EAECC62A467A8C8399AB5B7D89FF64A7695AB46CEC6582D7DCF531A209959D9` |

This task did not create a new MusicXML, new reference sequence, Phase 8 functionality, score, app UI, APK or other application output. The previous Phase 2/3/4B/5/6/7/7B/7C and real-calibration reports, especially `MUSIC_ANALYSIS_CONTROLLED_PIANO_CALIBRATION_REPORT.md`, were read against the current implementation. That report's five F4/E4 merges are a **different observed pattern**: its stable raw pitch was near target, whereas these new takes have raw octave-down errors. The current code remains the authority if historical prose differs.

## Audio, decoder and PCM verification

Host probe identifies all ten as AAC-LC in M4A/MP4, original **44,100 Hz stereo**; native Android/iOS decoding was not exercised. For investigation, FFmpeg decoded each source to bounded-size s16le files; the existing Dart `AnalysisAudioPreparer` then averaged stereo to **44,100 Hz, mono, headerless IEEE float32 little-endian** PCM. Because source rate equals the output rate, no resampling interpolation was used. Phase 3 code performs no gain normalization. Exact decoded frame counts, overall feature-energy RMS, peak and clipping are in `controlled_note_boundary_cross_case.csv` and below. Lead/tail columns are time with hop RMS below .003, **not** measured digital silence; trailing below-threshold time is nearly zero because low-level background/tails remain. There is no post-downmix clipping, and decoded frame lengths match rounded container durations. Stable D4 and E4 estimates where present are at the expected frequency, arguing against a global pitch/time scaling error. Mobile decoder parity is untested.

| Case | Duration s | PCM frames | RMS | Peak | Clipped frames | Lead below .003 RMS s | Tail below .003 RMS s |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 01 | 4.226 | 186,368 | .0476 | .664 | 0 | .186 | .000 |
| 02 | 5.016 | 221,184 | .0441 | .628 | 0 | .163 | .000 |
| 03 | 5.968 | 263,168 | .0346 | .510 | 0 | .186 | .000 |
| 04 | 3.506 | 154,624 | .0414 | .567 | 0 | .174 | .000 |
| 05 | 4.690 | 206,848 | .0248 | .200 | 0 | .186 | .000 |
| 06 | 4.063 | 179,200 | .0489 | .661 | 0 | .186 | .000 |
| 07 | 3.738 | 164,864 | .0376 | .640 | 0 | .197 | .000 |
| 08 | 3.901 | 172,032 | .0556 | .636 | 0 | .186 | .000 |
| 09 | 2.461 | 108,544 | .0519 | .607 | 0 | .186 | .000 |
| 10 | 2.694 | 118,784 | .0530 | .490 | 0 | .174 | .000 |

## Actual production boundary state machine

The unchanged `PerformedNoteSegmenter` accepts a frame only if `!isSilent`, `pitchHz>0`, confidence ≥.55 and RMS >.001. Two consecutive unaccepted frames close the active note at its last voiced end. On an accepted frame, a new segment begins when a valid onset candidate occurs after `minDuration=.055 s` **or** its pitch differs from the active confidence-weighted mean by ≥.8 semitone. Finalization rejects any candidate shorter than .055 s or with fewer than two frames. There is no persistence test for a pitch jump, no general noise class, no explicit release detector and no stored boundary-reason field. The open DSP emits onset candidates when spectral-flux strength >.38, previous RMS >.003, current RMS >1.35×previous and at least 1323 samples since last onset. These are exact current-code rules, not tuned values. DSP window/hop are 4096/512 samples. The native FFI ABI and Phase 2/7 code did not change.

## Baseline, raw features and boundary windows

Baseline was recorded **before any proposed fix** in `controlled_note_boundary_raw_features.csv` (every feature: sample/time, Hz, fractional MIDI, confidence, RMS/energy, onset strength/flag, silence, clipping and quality), `controlled_note_boundary_segments.csv` (all emitted notes), `controlled_note_boundary_cross_case.csv`, `controlled_note_boundary_diagnostic_windows.csv` and `controlled_note_boundary_spectrum.csv`. No source file path appears in those artifacts. Diagnostic windows are selected approximate regions of the declared note order, **not attack-time ground truth**; case 03 F4 and cases 04/05 F4 cannot be confidently assigned from raw frames, so their zero counts mean *insufficient detected evidence in those windows*, not proven unplayed notes. The window table counts accepted raw frames within ±.7 semitone of the declared note and one octave below, never feeds those pitches to the DSP or segmenter.

| Case / declared region | Window s | Accepted raw frames | Near target | Octave below | Other | Key observation |
|---|---|---:|---:|---:|---:|---|
| 01 F4 | 1.75–2.36 | 41 | 7 | 34 | 0 | F3 dominates raw observations despite F4 spectrum |
| 01 E4 | 2.85–3.46 | 43 | 33 | 9 | 1 | E4 mostly correct, tail E3 |
| 02 F4 | 1.75–2.25 | 32 | 9 | 23 | 0 | same sub-octave pattern |
| 02 E4 | 2.85–4.10 | 101 | 45 | 56 | 0 | sustained E4↔E3 switch |
| 03 E4 | 3.55–4.65 | 75 | 39 | 36 | 0 | repeated E4↔E3 switch; F4 region unassigned |
| 04 E4 | 1.85–2.25 | 23 | 17 | 6 | 0 | F4 region has no accepted frame in selected window |
| 05 E4 | 2.55–3.20 | 25 | 0 | 21 | 4 | soft take mostly E3; F4 region has no accepted frame |
| 06 F4 | 1.35–2.05 | 39 | 8 | 31 | 0 | strong F4 spectrum with raw F3 |
| 06 E4 | 2.40–3.40 | 70 | 34 | 36 | 0 | E4↔E3 switch |
| 07 F4 #1/#2 | 1.45–1.85 / 2.05–2.55 | 14 / 27 | 0 / 0 | 12 / 26 | 2 / 1 | two F3 observations despite declared repeated F4 |
| 08 E4 #1/#2 | 1.55–2.12 / 2.20–2.80 | 38 / 45 | 32 / 41 | 6 / 4 | 0 / 0 | two E4 plateaus, release E3 tails |
| 09 D4 | 1.30–1.80 | 28 | 19 | 9 | 0 | 0.220 s D4 segment survives |
| 10 D4 | .72–1.35 | 48 | 41 | 7 | 0 | 0.476 s D4 segment survives |

The selected F4 windows for 03/04/05 are not counted as raw-pitch accuracy denominators. Complete numerical windows are in the CSV; no missing observation was converted to zero pitch error.

## Independent spectral and YIN-lag diagnostics

An investigation-only 4096-sample Hann-window frequency projection was computed directly on the host s16le stereo downmix at selected times. Values are relative magnitudes, not calibrated SPL. The same script also directly computed a normalized difference/CMND curve on that window. Its time origin differs from the native rolling feature's exact window and therefore tests a mechanism, not native state byte equality.

| Case/time s | Declared note | Magnitude at expected fundamental | Magnitude one octave below | Lower/expected ratio | CMND expected lag | CMND double lag | Raw outcome |
|---|---|---:|---:|---:|---:|---:|---|
| 01 / 1.95 | F4 | 46.95 | 2.63 | .056 | .256 | .122 | F3 dominant |
| 02 / 1.87 | F4 | 45.42 | 2.13 | .047 | .271 | .128 | F3 dominant |
| 06 / 1.62 | F4 | 47.04 | 2.85 | .060 | .217 | .089 | F3 dominant |
| 07 / 1.59 | F4 | 37.84 | 1.66 | .044 | .672 | .185 | F3 detected nearby; this window alone does not reproduce native threshold crossing |
| 07 / 2.30 | F4 | 37.31 | 2.03 | .054 | .450 | .125 | F3 dominant |
| 05 / 2.80 | E4 | 46.58 | .73 | .016 | .394 | .113 | E3 dominant |
| 08 / 1.80 | E4 | 107.53 | .86 | .008 | .023 | .014 | E4 dominant (control) |

In cases 01/02/06, the diagnostic CMND at the shorter F4 lag exceeds the current .15 selection threshold while the double-period F3 lag falls below it; current native code selects the first lag under threshold. This is direct algorithmic evidence for **period doubling/subharmonic selection** despite a strong spectral F4 component. Case 07's 1.59 s diagnostic CMND values show why exact native-frame replication is still needed before a DSP fix. The frequencies here are F4 ~349 Hz, F3 ~175 Hz, E4 ~330 Hz, E3 ~165 Hz. There is no evidence that Phase 3 rescaled them.

## Cases 01–06: boundary trace and comparisons

No manual attack timestamps were supplied, so “correct boundary” cannot be measured to millisecond accuracy. The trace uses raw contour, onset flags, silence and emitted segments. Full frame-level values are in the CSV.

| Case | Raw F/E boundary evidence | Onset candidates total | Emitted notes | State-machine explanation / limit |
|---:|---|---:|---:|---|
| 01 detached | F-region 34/41 F3 frames; E-region 33/43 E4; F4↔F3 toggles within first region | 7 | 7 | pitch jumps and gaps yield multiple segments; not a clean two-note segmentation even though declared detached. Boundary timing unknown. |
| 02 legato | F-region 23/32 F3; E-region 56/101 E3; both switch octaves | 4 | 9 | raw octave jumps exceed .8 semitone and can split without a new attack; weak onset evidence limits actual F/E boundary attribution. |
| 03 slow | F-region not confidently assigned; E-region 39 E4 / 36 E3 | 5 | 7 | E4↔E3 toggles create segments, so count cannot be assigned to tempo sensitivity alone. |
| 04 fast | selected F-region 0 accepted; E-region 17 E4 / 6 E3 | 5 | 5 | absence of stable F evidence in window prevents a segmentation-only conclusion. |
| 05 soft | selected F-region 0 accepted; E-region 21 E3 / 0 E4 | 2 | 3 | low overall RMS and raw octave/voicing failure precede segmentation; an absolute RMS threshold adjustment is not justified. |
| 06 loud | F-region 31/39 F3; E-region 36/70 E3 | 4 | 8 | high amplitude does not prevent octave choice; pitch-change splitter responds to raw toggles. |

Detached vs legato: case 01 has more onset candidates (7 vs 4), but both have large octave contamination, so this pair does **not** isolate an onset-versus-pitch boundary rule. Slow vs fast: case 03 emits 7 vs case 04 5, yet their raw-pitch availability differs; attribution to min duration or latency would be speculative. Soft vs loud: overall RMS .0248 vs .0489, and both have raw octave/availability problems, so fitting an amplitude threshold to these two is unsafe. No claim is made that the physical performer omitted a declared note merely because the raw DSP has no stable target estimate.

## Repeated notes: cases 07 and 08

Case 07 declares two F4 attacks. It emits segments at 1.533–1.672 s (MIDI 53.07) and 2.194–2.473 s (53.01), plus an earlier 0.279–0.372 s ~50.24 observation. The two target regions are **separate in time**, but pitch is an octave low; spectral F4 magnitudes at 1.59 and 2.30 s are 37.84 and 37.31, versus F3 1.66 and 2.03. The current output count of three cannot be called a successful F4 repeated-note analysis. Case 08 declares two E4 attacks and has E4 segments 1.649–2.020 and 2.252–2.728 s, plus E3 tails and early noise-like ~50 observations. The two E4 regions are separated by an observed gap / release artifact. These controls show that pitch change alone cannot establish same-note attacks; the segmenter can produce two regions when raw gaps/attacks exist, but onset-candidate counts (3 and 2 overall) do not directly certify attack locations. A future boundary fix must use independent attack evidence and avoid splitting a sustained note merely due to octave flips.

## Short note: cases 09 and 10

Case 09's declared very short D4 yields a D4 segment **1.382–1.602 s, duration .220 s, MIDI 62.03, confidence .92, mean RMS .096**, followed by 1.602–1.707 s MIDI 49.99 release/sub-octave artifact. Case 10's normal D4 yields **.789–1.265 s, duration .476 s, MIDI 62.00, confidence .97, mean RMS .085**, followed by a .059 s MIDI 50.00 release artifact. Both D4s pass the .055 s minimum duration. Thus these controls do **not** reproduce the earlier two missing D4s, and lowering `minDuration` would add risk of accepting release/noise artifacts while solving no demonstrated failure here. No measured physical onset/offset annotation exists beyond the declared “very short”/“normal” labels.

## Baseline counts and root-cause classification

| Case | Expected events | Emitted segments | Count excess | Demonstrated raw-octave issue | Confirmed wrong boundary count |
|---:|---:|---:|---:|---|---|
| 01 | 2 | 7 | +5 | F3 predominant in F4 region | unavailable without attack timestamps |
| 02 | 2 | 9 | +7 | F3 and E3 predominant/mixed | unavailable |
| 03 | 2 | 7 | +5 | E4↔E3 | unavailable |
| 04 | 2 | 5 | +3 | E4/E3 and F-region dropout | unavailable |
| 05 | 2 | 3 | +1 | E3 in E4 region | unavailable |
| 06 | 2 | 8 | +6 | F3/E3 common | unavailable |
| 07 | 2 | 3 | +1 | F3 for both declared F4s | unavailable |
| 08 | 2 | 6 | +4 | E3 release after two E4 plateaus | unavailable |
| 09 | 1 | 2 | +1 | D3 release only; D4 emitted | one candidate release artifact, not adjudicated attack |
| 10 | 1 | 2 | +1 | D3 release only; D4 emitted | one candidate release artifact, not adjudicated attack |

“Count excess” is **not** equated to a confirmed false boundary: wrong-octave observations, early noise, release tails and possible true attacks are mixed, and the dataset lacks time-labelled attacks. Likewise merge, fragmentation, dropped and spurious counts cannot be honestly decomposed from count alone; the raw/segment CSVs preserve what can be audited. **RAW DSP** is the first demonstrated pitch-identity failure for F/E cases. **ONSET** evidence is limited and sometimes absent around declared boundaries, but no independent acoustic onset truth proves an onset implementation defect. **SEGMENTATION** deterministically splits on octave jumps and after two unvoiced frames, amplifying raw errors; a separate generic bug is not isolated. **AUDIO/PCM** has no proven global corruption. Alignment/tempo/assessment were not run on these snippets because no time-labelled score for them was supplied; creating a synthetic score would conflate declared order with unknown timing. No Phase 7 score or grade was created.

## Production fix decision and before/after

**No segmentation production fix is justified in this task.** The strongest repeatable issue is sub-octave raw pitch selection. A segmenter rule that simply ignores 12-semitone jumps could suppress real octave leaps and some repeated-note boundaries; setting thresholds to force two notes per file would leak ground truth into observation and overfit. The previous five-piano-take F4/E4 merge remains a legitimate separate boundary limitation, but these ten files do not isolate a safe general solution to it. A DSP algorithm change is outside this conditional **segmentation** task and would require exact native-window tracing, independent synthetic controls and a before/after on both datasets. **No production algorithm change was made; before/after is not applicable.** No filename-, MIDI- or instrument-specific correction was added.

## Regression, build and Aubio status

Offline Flutter command: installed `flutter_tools.snapshot test --no-pub --reporter json` over Phase 3 audio, Phase 5 FFI, both Phase 6 suites, both Phase 7 suites, calibration tooling, 7C test-page and Phase 2 reference tests. JSON `testDone`: **52 passed, 0 failed, 0 skipped**. A temporary ten-file end-to-end diagnostic test additionally passed **1/1** and was removed. Native production-host command `ctest --test-dir .native-host-prod -C Release --output-on-failure`: **3 passed, 0 failed, 0 skipped**. Total 56 passed across these runs. No Android device or iOS test/build was performed, and **no APK/AAB/IPA** or other app output was built. `native/CMakeLists.txt` defaults `MA_ENABLE_AUBIO=OFF`, Android explicitly passes `-DMA_ENABLE_AUBIO=OFF`, host production cache says `OFF`, and FFI rejects a production engine that advertises Aubio. No production binary or ABI changed; this task did not link Aubio into production.

## Files and next step

Added: this Markdown report plus `controlled_note_boundary_raw_features.csv`, `controlled_note_boundary_segments.csv`, `controlled_note_boundary_cross_case.csv`, `controlled_note_boundary_diagnostic_windows.csv` and `controlled_note_boundary_spectrum.csv`. They contain only safe case IDs, numbers and declared ground-truth labels; no private absolute paths or compressed user recordings. Temporary PCM, scripts and logs were removed. Unrelated worktree changes were not included.

Next step: first instrument the **development-only** open engine to record exact native CMND minima/candidate lags and spectrum at the affected frames, then use synthetic single-pitch signals with piano-like harmonics and labelled held-out device recordings to test a generic subharmonic-choice improvement. Compare all ten cases, the previous five-piano-take corpus, the earlier octave-heavy takes, synthetic octave leaps and silence/noise/release controls. Only after raw pitch is stable should time-labelled detached, legato and repeated-note attacks drive an independent segmentation proposal. Acceptance requires a failure reproduced without these filenames or expected MIDI values, no score-to-detector leakage, held-out improvement without new false splits, complete regression and production Aubio exclusion.
