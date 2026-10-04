# Sornaz — controlled piano calibration (five recordings)

## 1. Executive Summary

All five supplied piano recordings were decoded and processed with the current Phase 3 → open DSP/FFI → Phase 6 → Phase 7 pipeline against the **same supplied MusicXML**. The seven-note order declared for this investigation is C4–D4–E4–F4–E4–D4–C4. In 35 manually selected *diagnostic stable windows* (seven per recording), raw median pitches differ from those MIDI targets by **-8.9 to +11.2 cents**; none is a stable octave/harmonic substitution. The previous real-recording octave-failure pattern therefore did **not** reproduce on this controlled piano set. Two first-D4 windows contain only four voiced frames and have limited evidence.

The reproducible output defect is downstream: each recording has a clear raw F4 plateau followed by an E4 plateau, but Phase 6 emits **one F4/E4 segment**, yielding five missed E4 labels. Cases 004/005 also have a brief raw D4 (~four accepted frames) that does not survive the 0.055 s minimum-segment rule, yielding two more missed labels. All 28 emitted performed notes were marked `matched`; there were no `wrongNote` or `extra` labels. The apparently flat F4/E4 segment pitch, MIDI 64.54–64.64, is an average of two actual plateaus rather than a raw detector pitch failure. The five recordings establish a reproducible segmentation limitation, but their onset ground truth is only note order, not manually timestamped attacks. A general replacement boundary rule has not yet been validated against legato transitions, repeated notes and reverberation. **No production algorithm change was made.**

## 2. Scope / Non-Goals

This is a diagnostic investigation, not Phase 8. No persistence, sync, backend, final UI, educational score, pass/fail, threshold tuning, XML-guided pitch detection, ABI change or application build was made. The supplied ground-truth order is used only **after** independent audio → PCM → DSP → segmentation observations. Prior Phase 2, 3, 4B, 5, 6, 7, 7B, 7C and real-calibration 001–004 reports and current implementation/tests were reviewed. Code, rather than historical prose, governs all metrics here. Existing unrelated worktree changes were left untouched.

## 3. Input Dataset

| Case | File | SHA-256 | Decoded duration s |
|---|---|---|---:|
| 001 | `Sornaz_اول.m4a` | `9DF634667C8A7580B5629CABC643434A7B8D20E9FA11CD6A984666B9CDE5038F` | 3.251 |
| 002 | `Sornaz_دوم.m4a` | `4B1EE8B7AB38927BA3118A8AF0014C7D4EDBDFA4FFBB60DA8DE9F077603DD1FF` | 4.319 |
| 003 | `Sornaz_سوم.m4a` | `9F4133D90DCDD22F0BBE668C25DC1AE88FDE8251E1E1009936037B7506CB5685` | 4.296 |
| 004 | `Sornaz_چهارم.m4a` | `388E3A163449994C6C4202CCFF35CE8571DA10C83287C7D5E4451557BD05CC4D` | 3.413 |
| 005 | `Sornaz_پنجم.m4a` | `59B9C469AF2A0BD83566B039FD2AC9E1074D0406D3B3DCB7EE81A68C87BF0E18` | 3.320 |

All were compared with `تست جدید-1791061731114.musicxml`, SHA-256 `22BB46A6AA7FE9BE4A61C7B64336133A7A66A0D6F791F7A4C18C96D0E3D2F92A`. The user declares piano-note identity/order; no independent time-labelled waveform annotations were provided. Private absolute source paths are intentionally absent from every retained artifact.

## 4. Reference MusicXML Verification

The current `ReferenceTimelineParser` returns one part, seven attacks and one rest, with quarter tempo **100 BPM**. The first seven MIDI pitches exactly match the declared truth: `60,62,64,65,64,62,60`. Written-score timing is **not** presumed to be the exact performed timing.

| Index | Pitch | MIDI | Quarter position | Quarter duration | Expected onset s | Expected duration s | Active BPM |
|---:|---|---:|---:|---:|---:|---:|---:|
| 0 | C4 | 60 | 0.00 | .75 | .00 | .45 | 100 |
| 1 | D4 | 62 | .75 | .25 | .45 | .15 | 100 |
| 2 | E4 | 64 | 1.00 | .50 | .60 | .30 | 100 |
| 3 | F4 | 65 | 1.50 | .50 | .90 | .30 | 100 |
| 4 | E4 | 64 | 2.00 | .50 | 1.20 | .30 | 100 |
| 5 | D4 | 62 | 2.50 | .50 | 1.50 | .30 | 100 |
| 6 | C4 | 60 | 3.00 | .50 | 1.80 | .30 | 100 |

The following rest begins at quarter 3.5 / 2.10 s and lasts .30 s. No ties occur. The reference has no discrepancy with the declared *pitch order*.

## 5. Audio / PCM Verification

All sources probe as MP4/M4A containers, AAC-LC audio, original **44,100 Hz stereo**. Host FFmpeg decoded only the audio stream to interleaved s16le; the *actual* `AnalysisAudioPreparer` then averaged channels and wrote headerless **44,100 Hz mono f32 little-endian**. No resampling interpolation is needed because source and target rates are equal. Code divides s16 by 32768 and averages channels; it does not normalize to a peak. The original compressed files were untouched. Peak and RMS below are post-downmix raw-feature measurements. `isSilent` counts are DSP flags; the lead/tail column is time below **RMS .003**, not a claim of digital zero. A negative value from rounding was clamped to zero.

| Case | PCM frames | Duration s | Overall RMS | Peak | Clipped frames | `isSilent` frames | Lead/tail below .003 RMS s |
|---|---:|---:|---:|---:|---:|---:|---|
| 001 | 143,360 | 3.251 | .1143 | .666 | 0 | 2 | .012/.012 |
| 002 | 190,464 | 4.319 | .1075 | .710 | 0 | 13 | .000/.000 |
| 003 | 189,440 | 4.296 | .1073 | .712 | 0 | 20 | .000/.000 |
| 004 | 150,528 | 3.413 | .0808 | .490 | 0 | 9 | .012/.000 |
| 005 | 146,432 | 3.320 | .0589 | .240 | 0 | 1 | .000/.000 |

PCM frame counts equal decoded s16le bytes / 4 (two channels × two bytes). Container durations rounded to two decimals match PCM lengths; no unexpected time-stretch is evident. Stable observed pitches are near their declared values, which argues against gross pitch-rate error on this **host** path. No clipping or gain normalization is evident. Android/iOS platform decoders were not run, so native-device PCM parity is **not established**. No arbitrary-rate resampling path was exercised.

## 6. Production Pipeline Configuration

Current production contract is Phase 3 PCM 44.1 kHz mono f32le → Phase 5 FFI ABI 1 using the in-house open DSP engine → timestamped raw features → Phase 6 `PerformedNoteSegmenter` → `ReferenceNoteAligner` → Phase 7 `PerformanceAssessor`. The host production DLL was used; no Aubio comparison or score-guided observation was used. DSP window/hop are 4096/512 samples. Segmenter currently requires pitch confidence ≥.55, RMS >.001, at least .055 s and two voiced frames; it closes after two unvoiced frames and splits on an onset candidate or pitch difference ≥.8 semitone from the active segment's running mean. Alignment searches a global time scale .5–2 and uses match tolerance .65 semitone plus insertion/deletion costs 1.25. These settings were **not changed**. Host FFmpeg replaced only the Android/iOS platform AAC decoder, as in prior calibration; this boundary remains a platform-test limitation.

## 7. Raw DSP Analysis

There are 280/372/370/294/286 raw hop features for cases 001–005. Raw onsets are 5/5/4/3/2 candidates; a candidate is not a confirmed performed attack. Independent stable windows were selected visually from the *raw time/pitch contour*, excluding the obvious attack/transition ranges where possible. This selection is diagnostic and can introduce observer bias; it did not enter production segmentation. The full windows and medians are in `controlled_piano_raw_pitch.csv`. Median absolute pitch errors are small, and **no stable 12-semitone shift** appears in any of the 35 windows. Around F4→E4, the raw pitch moves gradually from ~65.0 to ~64.1 over ~0.1–0.2 s while confidence remains high. For example, case 001 at 1.730 s is MIDI 65.03 (confidence .997), 1.788 s 64.53 (.925), 1.846 s 64.25 (.953), with no onset candidates there. Case 005 similarly changes 65.05 at 1.684 s → 64.50 at 1.730 s → 64.12 at 1.800 s. Raw DSP therefore contains both pitches in stable regions, but the boundary evidence supplied to segmentation is weak.

Cases 004/005 have only four accepted D4 frames in the selected 0.88–0.96/0.83–0.95 s windows: median MIDI 61.92/61.91, confidences in the ~.85–.91 range. They are genuine-looking raw D4 observations but too few to infer accurate attack duration or rule out device/recording effects. These notes are not present in the Phase 6 output. In the tails, a few low-octave ~48 MIDI raw frames appear after final C4, but they do not form emitted note segments and are outside the seven stable instances.

## 8. 35-Note-Instance Ground-Truth Table

`controlled_piano_raw_pitch.csv` contains all **35** selected diagnostic windows with start/end, voiced-frame count, median Hz/MIDI, median confidence/RMS, signed cents against the declared MIDI, and median absolute deviation (MAD) of MIDI converted to cents. Values are observations; note-onset truth was not used to force DSP output. The two four-frame D4 windows are marked as limited support below. The table is included in full in Appendix A.

## 9. Fundamental / Harmonic Analysis

Per-pitch stable medians, including both C/D/E instances where repeated, are all within **±12 cents** of the declared fundamental; there are **0/35 stable octave errors** and **0/35 other semitone-scale stable errors** under that descriptive range. This is an observation of these selected windows, not a general detector accuracy guarantee. The prior dataset's high-confidence 59↔71 / 63↔75 octave toggles were not reproduced on this piano dataset. Short release-tail ~48 MIDI frames occur but do not constitute a stable selected note instance. Because no stable fundamental/harmonic dispute was found, an independent FFT/H2:H1 spectral adjudication would not change the main diagnosis and was not run. It remains needed if octave errors recur on labelled material. No correction for C4/D4/E4/F4 was added.

## 10. Octave Flip Analysis

No C4↔C5 or E4↔E5 flip persists within the 35 stable windows. The F4→E4 raw transition is **one semitone**, not an octave; the important failure is boundary detection, not harmonic selection. Tail 60→48 readings after final C4 are transient/release-adjacent and below the emitted-note duration criterion. There are therefore **zero sustained octave-flipped note regions** to report with before/during/after confidence. The instrument/dynamic range here differs from the earlier real takes; a negative result here does not invalidate those earlier raw observations.

## 11. Segmentation Analysis

Ground truth declares seven attacks per take. Actual Phase 6 counts are **6,6,6,5,5**. In each case, one performed note spans the F4 and E4 stable plateaus, with output mean MIDI **64.62,64.64,64.62,64.61,64.54** and duration **.662,.732,.709,.697,.731 s**. A moving running mean plus .8-semitone split rule does not cross the boundary when the raw pitch drifts gradually, and there is no onset candidate at the transition. That is a repeatable observation; whether the absent onset is due to piano overlap, DSP onset sensitivity or attack timing requires time-labelled audio. In cases 004/005, the first D4 appears as four raw voiced frames, roughly 46 ms, and no performed D4 is emitted; minimum .055 s and nearby dropout/transition behavior plausibly account for it, but a precise causal ablation was not run. There are **no emitted spurious segments**, **no octave-induced fragmentation**, and **one F4/E4 merge per take**. Correctly isolated expected regions are 5/5/5/4/4 if each of the two merged pitches is counted as not individually isolated. This diagnostic count is not a performance grade.

## 12. Per-Recording Segment Tables

Every emitted segment with start/end, duration, fractional/nearest MIDI, confidence and RMS is in `controlled_piano_segments.csv` and repeated in Appendix B. The current `PerformedNote` model does not store a boundary reason; attribution above uses code and neighboring raw frames, not invented metadata.

## 13. Alignment Analysis

All production alignment events, including null fields for missing pairs, exact cents, onset beats and duration ratios, are in `controlled_piano_alignment.csv` and Appendix C. The aligner pairs each emitted segment with the obvious sequential reference where available and marks **all 28 emitted segments matched**. It reports E4 index 4 missed in **5/5**, and D4 index 1 missed in **2/5** (004/005). There are no wrongNote/extra labels. The apparent matched F4 segment is misleading as a single-note representation: its averaged MIDI is 36–46 cents below F4 and its duration ratio ~1.82–1.90 because it covers F4 and E4. This is a segmentation-created measurement problem, not a Phase 7 cents conversion error. No cascading one-cell alignment shift was observed in these five takes.

## 14. Tempo Analysis

| Case | Reference BPM | Estimated BPM | Time scale | Start offset s | Diagnostic interpretation |
|---|---:|---:|---:|---:|---|
| 001 | 100 | 82.47 | 1.213 | .337 | one merged F/E; correspondence otherwise ordered |
| 002 | 100 | 76.00 | 1.316 | .244 | one merged F/E; longer tail |
| 003 | 100 | 78.78 | 1.269 | .397 | one merged F/E; correspondence otherwise ordered |
| 004 | 100 | 80.75 | 1.238 | .244 | F/E merge plus short first D omission |
| 005 | 100 | 77.91 | 1.284 | .226 | F/E merge plus short first D omission |

Unlike previous case 004, the tempo estimate does not collapse to ~55 BPM because no avalanche of extra octave segments shifts correspondence. Still, the estimate is an alignment-derived global scale, **not** verified performance tempo: onset ground truth is unavailable and the F/E merged event is omitted as a distinct beat. A manually annotated attack timeline is needed before attributing the 76–82 BPM range to the musician versus the algorithm. No diagnostic tempo estimator was promoted to production.

## 15. Cross-Recording Comparison

| Case | Duration s | Expected | Emitted | Raw stable pitch failures | Stable octave errors | F/E merges | Short D losses | Spurious | Matched | Wrong | Missed | Extra | BPM |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 001 | 3.251 | 7 | 6 | 0/7 | 0 | 1 | 0 | 0 | 6 | 0 | 1 | 0 | 82.47 |
| 002 | 4.319 | 7 | 6 | 0/7 | 0 | 1 | 0 | 0 | 6 | 0 | 1 | 0 | 76.00 |
| 003 | 4.296 | 7 | 6 | 0/7 | 0 | 1 | 0 | 0 | 6 | 0 | 1 | 0 | 78.78 |
| 004 | 3.413 | 7 | 5 | 0/7* | 0 | 1 | 1 | 0 | 5 | 0 | 2 | 0 | 80.75 |
| 005 | 3.320 | 7 | 5 | 0/7* | 0 | 1 | 1 | 0 | 5 | 0 | 2 | 0 | 77.91 |

`*` Four-frame D4 stable-window support is limited; its median is close, but reliable attack timing/duration is unavailable. “Raw stable pitch failure” here means a persistent semitone/octave-scale mismatch against the declared note in the selected windows; it does not certify every raw frame.

## 16. Per-Pitch Reproducibility Table

| Expected pitch | Instances | Stable fundamental near target | Stable octave errors | Other stable semitone-scale errors | Segment outcome |
|---|---:|---:|---:|---:|---|
| C4 / MIDI 60 | 10 | 10 | 0 | 0 | 10 isolated |
| D4 / MIDI 62 | 10 | 10† | 0 | 0 | 8 isolated; first D4 lost in 004/005 |
| E4 / MIDI 64 | 10 | 10 | 0 | 0 | first E4 isolated 5; second E4 merged into F4 5 |
| F4 / MIDI 65 | 5 | 5 | 0 | 0 | all five emitted with following E4 included |

`†` Two D4 results rest on only four accepted raw frames each and should not be interpreted as robust duration or attack estimates. Per-pitch totals are 35, with five F/E merges and two brief-D losses. This pitch-specific outcome is a segmentation/transition pattern; it is not an octave-detector failure on F4.

## 17. Root-Cause Trace

| Declared truth | Raw DSP | Segment | Alignment | Assessment |
|---|---|---|---|---|
| F4→E4 in 001 | stable F4 MIDI ~65.03 → smooth 65.03 to 64.15 over ~1.73–1.89 s → stable E4 ~64.11; no onset in transition | one 1.428–2.090 s, MIDI 64.62 | F4 matched; following E4 missed | F4 pitch ~-38¢, duration ratio 1.82; E4 null metrics |
| F4→E4 in 005 | stable F4 ~65.04 → smooth 65.05 at 1.684 s to 64.12 at 1.800 s → stable E4 ~64.07 | one 1.382–2.113 s, MIDI 64.54 | F4 matched; E4 missed | F4 ~-46¢, duration ratio 1.90; E4 null |
| First D4 in 004 | four voiced raw frames at ~.906–.940 s, MIDI 61.87–61.96, confidence .86–.91; no corresponding onset candidate | none survives | D4 missed | pitch/onset/duration metrics **null**, not zero |
| First D4 in 005 | four voiced frames at ~.894–.929 s, MIDI 61.86–61.97, confidence .85–.89 | none survives | D4 missed | null metrics |

The first departure from *pitch identity* is **not** raw pitch on these 35 windows. The first departure from *seven-note count* is Phase 6 segmentation, with low/absent onset evidence contributing. Phase 7 faithfully calculates metrics from the flawed pairs; it does not independently create the missing notes.

## 18. Root-Cause Classification

| Layer | Finding |
|---|---|
| AUDIO/PCM | No host-path corruption, clipping, time stretch or normalization demonstrated; device path unverified. |
| RAW DSP | Stable pitch near all 35 declared notes; no stable octave error. Transition pitch is smoothed/blended; this can suppress a sharp boundary but is not proof of wrong fundamental. |
| ONSET | Missing candidate around F→E transition in all five; first D4 in 004/005 also has no clear accepted candidate. Acoustic attack truth unavailable. |
| SEGMENTATION | First demonstrated note-count divergence: five F/E merges and two short-D omissions. |
| TEMPO | Global estimate uses incomplete note sequence; actual played BPM not independently labelled. |
| ALIGNMENT | Correctly marks absent emitted notes as missed under its sequence model; no independent bookkeeping defect demonstrated. |
| ASSESSMENT | Correct arithmetic for paired mean pitches; F4 duration/pitch metrics describe a merged segment, not a single played note. |
| CASCADING | Raw smooth transition / weak onset → merged segment → missed E4 → distorted F4 duration metric; short D4 → omitted segment → missed D4. |

## 19. Reproducibility Classification

**REPRODUCIBLE:** five F4/E4 merges; five E4 missed labels; stable fundamental near target for 35 diagnostic windows; zero stable octave errors; two brief D4 losses in 004/005. **LIKELY:** missing raw onset plus gradual F→E pitch trajectory prevents Phase 6 boundary; .055 s minimum contributes to short D4 loss. **POSSIBLE:** overlapping piano decay or mobile AAC/recorder processing causes the gradual transition/brief D4; host/device decoder differences. **NOT SUPPORTED:** an octave/harmonic detector failure on this controlled set, fixed -70-cent correction, global decoder sample-rate error, wrong Phase 7 cents units, or an alignment cascade in these five takes.

## 20. Production Fix Decision

**A — no production fix yet.** This set proves a repeatable F/E merge but does not supply manual attack times, repeated-note controls, or legato/reverb counterexamples needed to design and validate a general boundary rule. The weak D4 cases also need a duration-labelled reference before changing minimum-duration handling. A threshold change to force seven outputs would overfit this phrase. The detector, segmenter and aligner remain score-independent before alignment.

## 21. Production Changes

**No production algorithm change was made.** No threshold, ABI, DSP, FFI, segmenter, aligner or assessor source was edited.

## 22. Before / After

Not applicable: production did not change. The tables are current baseline for a future independently justified fix; no improvement is claimed.

## 23. Regression Tests

The installed Flutter tool ran `test --no-pub --reporter json` over `analysis_audio_test.dart`, `music_analysis_ffi_integration_test.dart`, both Phase 6 suites, both Phase 7 suites, `music_analysis_calibration_test.dart`, `music_analysis_test_page_test.dart`, and `reference_timeline_test.dart`: **52 passed, 0 failed, 0 skipped** (counted from `testDone` events). A temporary five-file diagnostic integration test passed **1/1** and was removed. Native production host `ctest --test-dir .native-host-prod -C Release --output-on-failure`: **3 passed, 0 failed, 0 skipped**, including DSP, C ABI smoke and AB test target as configured without Aubio. Total executed tests across these runs: **56 passed, 0 failed, 0 skipped**. The five real files completed through Phase 3/5/6/7 in the temporary harness. These tests do not establish Android/iOS decoder parity or handwritten onset truth.

## 24. Build Verification

No APK, AAB, IPA, desktop or other application output was generated, as requested. No new native compilation was needed because production code did not change. Android device and iOS builds/tests were not performed. Existing host production DLL was used for investigation.

## 25. Aubio Production Exclusion

`native/CMakeLists.txt` defaults `MA_ENABLE_AUBIO=OFF`; `android/app/build.gradle` explicitly passes `-DMA_ENABLE_AUBIO=OFF`; the existing production host cache has `MA_ENABLE_AUBIO:BOOL=OFF`; `MusicAnalysisFfi.open` rejects a production library that advertises the Aubio engine. No production binary was rebuilt or changed in this task, so these are configuration/runtime-contract checks, not a new binary-link audit. Aubio was not added or invoked.

## 26. Files Added / Changed

| File | Purpose |
|---|---|
| `MUSIC_ANALYSIS_CONTROLLED_PIANO_CALIBRATION_REPORT.md` | This independent investigation and engineering decision. |
| `controlled_piano_raw_pitch.csv` | 35 diagnostic stable windows, quantitative raw truth comparison. |
| `controlled_piano_segments.csv` | All emitted Phase 6 notes. |
| `controlled_piano_alignment.csv` | All Phase 6/7 alignment events and metrics. |
| `controlled_piano_cross_case.csv` | Per-take PCM, feature, segmentation and alignment summary. |

Temporary decoded PCM, raw feature JSON, test harness and test log were deleted. No private absolute path or user recording is retained in the repository. Previous reports were not overwritten.

## 27. Remaining Risks

The truth consists of note order/pitch, **not onset/offset annotation**; window selection was manual and retrospective; two D4 windows have only four samples. Host FFmpeg stands in for the native mobile decoder. Piano sound may overlap/reverberate at transitions; four additional pitches and varied articulation are untested. The current raw confidence is not a calibrated probability of attack correctness. No independent spectral decomposition was run because this set did not show stable harmonic failures. Device recordings and the prior octave-heavy takes may exercise different instrument spectra, mic processing, or acoustic conditions.

## 28. Recommended Next Step

Create a small labelled boundary-control corpus: isolated F4 then E4 with **measured attack times**, both detached and legato; repeated F4→F4 and E4→E4 with 0/50/100 ms gaps; F4→E4 at quiet/loud dynamics and slow/fast tempo; sustained F4/E4 with reverberation; short D4 attacks around 30/50/80/150 ms; plus at least one held-out pitch pair. Retain direct PCM and the device AAC version of the same take. Compare raw onset time, pitch-trajectory derivative and segment boundaries against those annotations. Only then evaluate a general pitch-change/onset-boundary strategy, with synthetic and held-out regressions. Revisit the earlier octave-heavy non-piano takes separately; do not conflate the two failure classes.

## 29. Acceptance Criteria For Next Step

Independent time-labelled attack/offset truth; quantified host/device PCM parity; repeatable boundary failures and counterexamples; a general score-blind candidate fix; synthetic regression reproducing the failure without these filenames or XML; held-out real recordings showing fewer merges **without** extra splits on repeated/legato controls; unchanged or improved Phase 3/5/6/7 tests; explicit no-Aubio production linkage; no educational score introduced. These conditions are not yet met.

## Appendix A. All 35 diagnostic stable windows

| Case | # | Expected MIDI | Window s | Voiced frames | Median Hz | Median MIDI | Median confidence | Median RMS | Error ¢ | MAD ¢ |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 001 | 0 | 60 | 0.35–0.70 | 30 | 262.01 | 60.025 | 0.996 | 0.1345 | 2.5 | 0.4 |
| 001 | 1 | 62 | 0.91–0.99 | 7 | 294.51 | 62.050 | 0.970 | 0.0783 | 5.0 | 0.9 |
| 001 | 2 | 64 | 1.17–1.32 | 13 | 331.36 | 64.091 | 0.982 | 0.0796 | 9.1 | 0.4 |
| 001 | 3 | 65 | 1.46–1.68 | 19 | 349.76 | 65.027 | 0.996 | 0.1747 | 2.7 | 0.4 |
| 001 | 4 | 64 | 1.88–2.05 | 15 | 331.76 | 64.112 | 0.985 | 0.0774 | 11.2 | 1.3 |
| 001 | 5 | 62 | 2.20–2.40 | 17 | 294.93 | 62.074 | 0.981 | 0.0833 | 7.4 | 0.7 |
| 001 | 6 | 60 | 2.60–2.85 | 22 | 262.06 | 60.029 | 0.990 | 0.1180 | 2.9 | 0.4 |
| 002 | 0 | 60 | 0.30–0.70 | 35 | 262.17 | 60.036 | 0.996 | 0.1396 | 3.6 | 0.4 |
| 002 | 1 | 62 | 0.87–0.98 | 10 | 294.28 | 62.036 | 0.972 | 0.0913 | 3.6 | 0.5 |
| 002 | 2 | 64 | 1.16–1.32 | 14 | 331.17 | 64.081 | 0.987 | 0.0871 | 8.1 | 0.4 |
| 002 | 3 | 65 | 1.48–1.71 | 20 | 350.57 | 65.066 | 0.996 | 0.1282 | 6.6 | 0.4 |
| 002 | 4 | 64 | 1.91–2.08 | 15 | 331.71 | 64.109 | 0.992 | 0.0945 | 10.9 | 1.4 |
| 002 | 5 | 62 | 2.25–2.50 | 22 | 294.38 | 62.042 | 0.991 | 0.1082 | 4.2 | 0.7 |
| 002 | 6 | 60 | 2.70–3.00 | 26 | 262.15 | 60.035 | 0.995 | 0.1252 | 3.5 | 0.3 |
| 003 | 0 | 60 | 0.45–0.80 | 30 | 262.18 | 60.036 | 0.996 | 0.1395 | 3.6 | 0.3 |
| 003 | 1 | 62 | 0.97–1.10 | 11 | 294.26 | 62.035 | 0.950 | 0.1173 | 3.5 | 0.8 |
| 003 | 2 | 64 | 1.28–1.42 | 12 | 330.92 | 64.068 | 0.986 | 0.0853 | 6.8 | 0.8 |
| 003 | 3 | 65 | 1.58–1.80 | 19 | 350.37 | 65.057 | 0.995 | 0.1334 | 5.7 | 0.5 |
| 003 | 4 | 64 | 1.99–2.15 | 14 | 331.51 | 64.098 | 0.993 | 0.0940 | 9.8 | 1.0 |
| 003 | 5 | 62 | 2.32–2.59 | 24 | 294.47 | 62.047 | 0.988 | 0.0977 | 4.7 | 1.1 |
| 003 | 6 | 60 | 2.75–3.05 | 26 | 262.23 | 60.040 | 0.989 | 0.1415 | 4.0 | 0.6 |
| 004 | 0 | 60 | 0.32–0.67 | 30 | 262.12 | 60.033 | 0.995 | 0.1109 | 3.3 | 0.2 |
| 004 | 1 | 62 | 0.88–0.96 | 4 | 292.30 | 61.919 | 0.879 | 0.0530 | -8.1 | 3.8 |
| 004 | 2 | 64 | 1.09–1.25 | 14 | 330.82 | 64.062 | 0.984 | 0.0649 | 6.2 | 0.5 |
| 004 | 3 | 65 | 1.44–1.66 | 18 | 350.54 | 65.065 | 0.995 | 0.1043 | 6.5 | 0.3 |
| 004 | 4 | 64 | 1.80–1.98 | 15 | 331.27 | 64.086 | 0.984 | 0.0722 | 8.6 | 1.2 |
| 004 | 5 | 62 | 2.14–2.37 | 20 | 294.33 | 62.039 | 0.979 | 0.0725 | 3.9 | 1.0 |
| 004 | 6 | 60 | 2.60–2.83 | 20 | 262.08 | 60.030 | 0.977 | 0.0547 | 3.0 | 0.4 |
| 005 | 0 | 60 | 0.30–0.67 | 32 | 261.99 | 60.024 | 0.977 | 0.0608 | 2.4 | 0.2 |
| 005 | 1 | 62 | 0.83–0.95 | 4 | 292.15 | 61.911 | 0.879 | 0.0313 | -8.9 | 2.7 |
| 005 | 2 | 64 | 1.08–1.26 | 15 | 330.51 | 64.046 | 0.972 | 0.0485 | 4.6 | 0.5 |
| 005 | 3 | 65 | 1.46–1.66 | 17 | 350.05 | 65.041 | 0.994 | 0.0872 | 4.1 | 0.4 |
| 005 | 4 | 64 | 1.80–2.02 | 18 | 331.00 | 64.072 | 0.987 | 0.0636 | 7.2 | 1.3 |
| 005 | 5 | 62 | 2.18–2.41 | 20 | 294.06 | 62.023 | 0.966 | 0.0459 | 2.3 | 1.0 |
| 005 | 6 | 60 | 2.62–2.85 | 20 | 262.01 | 60.026 | 0.970 | 0.0551 | 2.6 | 0.3 |

## Appendix B. Every emitted performed segment

| Case | Segment # | Start s | End s | Duration s | Fractional MIDI | Nearest MIDI | Confidence | RMS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 001 | 0 | 0.290 | 0.824 | 0.534 | 60.026 | 60 | 0.984 | 0.1423 |
| 001 | 1 | 0.894 | 1.022 | 0.128 | 62.039 | 62 | 0.950 | 0.0817 |
| 001 | 2 | 1.126 | 1.382 | 0.255 | 64.083 | 64 | 0.967 | 0.0791 |
| 001 | 3 | 1.428 | 2.090 | 0.662 | 64.620 | 65 | 0.974 | 0.1320 |
| 001 | 4 | 2.148 | 2.473 | 0.325 | 62.083 | 62 | 0.968 | 0.0850 |
| 001 | 5 | 2.519 | 2.879 | 0.360 | 60.036 | 60 | 0.966 | 0.1096 |
| 002 | 0 | 0.221 | 0.778 | 0.557 | 60.041 | 60 | 0.979 | 0.1519 |
| 002 | 1 | 0.859 | 0.998 | 0.139 | 62.030 | 62 | 0.953 | 0.0956 |
| 002 | 2 | 1.115 | 1.358 | 0.244 | 64.068 | 64 | 0.968 | 0.0898 |
| 002 | 3 | 1.416 | 2.148 | 0.731 | 64.644 | 65 | 0.968 | 0.1204 |
| 002 | 4 | 2.194 | 2.554 | 0.360 | 62.062 | 62 | 0.972 | 0.1117 |
| 002 | 5 | 2.612 | 3.111 | 0.499 | 60.046 | 60 | 0.974 | 0.1097 |
| 003 | 0 | 0.360 | 0.906 | 0.546 | 60.037 | 60 | 0.981 | 0.1531 |
| 003 | 1 | 0.975 | 1.126 | 0.151 | 62.035 | 62 | 0.931 | 0.1266 |
| 003 | 2 | 1.242 | 1.463 | 0.221 | 64.045 | 64 | 0.966 | 0.0889 |
| 003 | 3 | 1.509 | 2.218 | 0.708 | 64.622 | 65 | 0.965 | 0.1206 |
| 003 | 4 | 2.264 | 2.635 | 0.372 | 62.063 | 62 | 0.970 | 0.0999 |
| 003 | 5 | 2.682 | 3.123 | 0.441 | 60.051 | 60 | 0.966 | 0.1095 |
| 004 | 0 | 0.244 | 0.766 | 0.522 | 60.035 | 60 | 0.985 | 0.1165 |
| 004 | 1 | 1.045 | 1.335 | 0.290 | 64.051 | 64 | 0.970 | 0.0643 |
| 004 | 2 | 1.358 | 2.055 | 0.697 | 64.612 | 65 | 0.965 | 0.0922 |
| 004 | 3 | 2.101 | 2.450 | 0.348 | 62.047 | 62 | 0.961 | 0.0754 |
| 004 | 4 | 2.508 | 2.891 | 0.383 | 60.050 | 60 | 0.959 | 0.0535 |
| 005 | 0 | 0.221 | 0.731 | 0.511 | 60.026 | 60 | 0.967 | 0.0639 |
| 005 | 1 | 1.022 | 1.382 | 0.360 | 64.063 | 64 | 0.954 | 0.0489 |
| 005 | 2 | 1.382 | 2.113 | 0.731 | 64.542 | 65 | 0.964 | 0.0772 |
| 005 | 3 | 2.159 | 2.485 | 0.325 | 62.036 | 62 | 0.950 | 0.0469 |
| 005 | 4 | 2.531 | 2.926 | 0.395 | 60.034 | 60 | 0.957 | 0.0522 |

## Appendix C. Every alignment event

`—` represents unavailable/null, never a numerical zero. Expected performed onset equals `startOffset + timeScale × referenceOnset`.
| Case | Ref # / MIDI | Perf # / MIDI | Mark | Pitch ¢ | Expected onset s | Perf onset s | Onset beats | Duration ratio |
|---|---|---|---|---:|---:|---:|---:|---:|
| 001 | 0 / 60.0 | 0 / 60.03 | matched | 2.6 | 0.337 | 0.290 | -0.064 | 0.979 |
| 001 | 1 / 62.0 | 1 / 62.04 | matched | 3.9 | 0.882 | 0.894 | 0.016 | 0.702 |
| 001 | 2 / 64.0 | 2 / 64.08 | matched | 8.3 | 1.064 | 1.126 | 0.085 | 0.702 |
| 001 | 3 / 65.0 | 3 / 64.62 | matched | -38.0 | 1.428 | 1.428 | 0.000 | 1.819 |
| 001 | 4 / 64.0 | — | missed | — | 1.792 | — | — | — |
| 001 | 5 / 62.0 | 4 / 62.08 | matched | 8.3 | 2.156 | 2.148 | -0.011 | 0.894 |
| 001 | 6 / 60.0 | 5 / 60.04 | matched | 3.6 | 2.519 | 2.519 | 0.000 | 0.989 |
| 002 | 0 / 60.0 | 0 / 60.04 | matched | 4.1 | 0.244 | 0.221 | -0.029 | 0.941 |
| 002 | 1 / 62.0 | 1 / 62.03 | matched | 3.0 | 0.836 | 0.859 | 0.029 | 0.706 |
| 002 | 2 / 64.0 | 2 / 64.07 | matched | 6.8 | 1.033 | 1.115 | 0.103 | 0.618 |
| 002 | 3 / 65.0 | 3 / 64.64 | matched | -35.6 | 1.428 | 1.416 | -0.015 | 1.853 |
| 002 | 4 / 64.0 | — | missed | — | 1.823 | — | — | — |
| 002 | 5 / 62.0 | 4 / 62.06 | matched | 6.2 | 2.218 | 2.194 | -0.029 | 0.912 |
| 002 | 6 / 60.0 | 5 / 60.05 | matched | 4.6 | 2.612 | 2.612 | 0.000 | 1.265 |
| 003 | 0 / 60.0 | 0 / 60.04 | matched | 3.7 | 0.397 | 0.360 | -0.049 | 0.955 |
| 003 | 1 / 62.0 | 1 / 62.04 | matched | 3.5 | 0.968 | 0.975 | 0.009 | 0.793 |
| 003 | 2 / 64.0 | 2 / 64.04 | matched | 4.5 | 1.159 | 1.242 | 0.110 | 0.579 |
| 003 | 3 / 65.0 | 3 / 64.62 | matched | -37.8 | 1.539 | 1.509 | -0.040 | 1.860 |
| 003 | 4 / 64.0 | — | missed | — | 1.920 | — | — | — |
| 003 | 5 / 62.0 | 4 / 62.06 | matched | 6.3 | 2.301 | 2.264 | -0.049 | 0.976 |
| 003 | 6 / 60.0 | 5 / 60.05 | matched | 5.1 | 2.682 | 2.682 | 0.000 | 1.159 |
| 004 | 0 / 60.0 | 0 / 60.03 | matched | 3.5 | 0.244 | 0.244 | 0.000 | 0.938 |
| 004 | 1 / 62.0 | — | missed | — | 0.801 | — | — | — |
| 004 | 2 / 64.0 | 1 / 64.05 | matched | 5.1 | 0.987 | 1.045 | 0.078 | 0.781 |
| 004 | 3 / 65.0 | 2 / 64.61 | matched | -38.8 | 1.358 | 1.358 | 0.000 | 1.875 |
| 004 | 4 / 64.0 | — | missed | — | 1.730 | — | — | — |
| 004 | 5 / 62.0 | 3 / 62.05 | matched | 4.7 | 2.101 | 2.101 | 0.000 | 0.938 |
| 004 | 6 / 60.0 | 4 / 60.05 | matched | 5.0 | 2.473 | 2.508 | 0.047 | 1.031 |
| 005 | 0 / 60.0 | 0 / 60.03 | matched | 2.6 | 0.226 | 0.221 | -0.008 | 0.884 |
| 005 | 1 / 62.0 | — | missed | — | 0.804 | — | — | — |
| 005 | 2 / 64.0 | 1 / 64.06 | matched | 6.3 | 0.997 | 1.022 | 0.033 | 0.935 |
| 005 | 3 / 65.0 | 2 / 64.54 | matched | -45.8 | 1.382 | 1.382 | 0.000 | 1.899 |
| 005 | 4 / 64.0 | — | missed | — | 1.767 | — | — | — |
| 005 | 5 / 62.0 | 3 / 62.04 | matched | 3.6 | 2.152 | 2.159 | 0.010 | 0.844 |
| 005 | 6 / 60.0 | 4 / 60.03 | matched | 3.4 | 2.537 | 2.531 | -0.008 | 1.025 |
