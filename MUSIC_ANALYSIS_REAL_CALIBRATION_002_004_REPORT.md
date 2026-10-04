# Sornaz: real-performance calibration investigation, cases 001–004

## 1. Executive summary

Four real AAC recordings were compared with the **same, unchanged** MusicXML using the current Phase 3 → Phase 5 open DSP → Phase 6 → Phase 7 code. Host results reproduce the device screenshots' main pattern: cases 002–004 contain high-confidence raw pitch observations approximately one octave above the surrounding contour; case 004 alternates between those observations and lower pitches, producing 19 performed segments for seven reference attacks. Alignment then pairs some octave segments with score notes and reports four-digit cent differences. The cause is therefore **not solely Phase 7 arithmetic or alignment**. The audio's annotated fundamental is unknown, so the underlying cause of octave selection—source acoustics versus detector robustness—is not yet proven. No implementation defect was sufficiently demonstrated to justify a production algorithm change. No production code, threshold, ABI, or score was changed. Next: obtain time-aligned hand annotations and controlled recordings of isolated pitches and dynamics, then compare raw detector output against those truths before considering a general fix.

## 2. Scope and non-goals

The investigation covers file identity, host AAC decode, Phase 3 PCM, raw open-engine features, Phase 6 segmentation/tempo/alignment, Phase 7 assessments, and existing regressions. It does not implement Phase 8, persistence, history, sync, backend, final UI, educational pass/fail or 0–100 grading. Aubio was not used. The supplied recordings are a small diagnostic set, not population calibration data. Absolute user file paths are intentionally omitted.

## 3. Input files

| Case | Recording | Size bytes | SHA-256 |
|---|---|---:|---|
| 001 | `Sornaz_صدای تستی جدید.m4a` | 509,926 | `5A0C404C75E562EFE6254C67EE264545EBE86ACE5D3F6784D991E3A895EF28F7` |
| 002 | `test_1.m4a` | 91,255 | `039989DD63D3104CF06790173A4B4F2767C2689509091A1EBE731E1DF9924325` |
| 003 | `test_2.m4a` | 93,961 | `6E58EA4A05A57AA3D1A628E20718CA3E1BFB86156D458018780A06008AB515B5` |
| 004 | `test_3.m4a` | 99,105 | `7B80C597CDA7826650CFD2E3C34957FD1574877F7E328521EED3BCDF41F8AB68` |

All use `تست جدید-1791061731114.musicxml`, 1,414 bytes, SHA-256 `22BB46A6AA7FE9BE4A61C7B64336133A7A66A0D6F791F7A4C18C96D0E3D2F92A`. Case 001's hash matches the previous report even though the file was moved. No substitute XML was generated.

## 4. MusicXML reference summary

The current `ReferenceTimelineParser` returns one part, one measure (`measureIndex=0`), seven attacks, then a rest. Active quarter tempo is 100 BPM throughout. No ties occur. Written-pitch reference:

| Index / ID suffix | Pitch | MIDI | Quarter start | Quarter duration | Expected start s | Expected duration s |
|---:|---|---:|---:|---:|---:|---:|
| 0 | C4 | 60 | 0.00 | 0.75 | 0.00 | 0.45 |
| 1 | D4 | 62 | 0.75 | 0.25 | 0.45 | 0.15 |
| 2 | E4 | 64 | 1.00 | 0.50 | 0.60 | 0.30 |
| 3 | F4 | 65 | 1.50 | 0.50 | 0.90 | 0.30 |
| 4 | E4 | 64 | 2.00 | 0.50 | 1.20 | 0.30 |
| 5 | D4 | 62 | 2.50 | 0.50 | 1.50 | 0.30 |
| 6 | C4 | 60 | 3.00 | 0.50 | 1.80 | 0.30 |
| 7 | rest | — | 3.50 | 0.50 | 2.10 | 0.30 |

IDs are `P1:0:0` through `P1:0:7`. The recording contour resembles C–D–E–F–E–D–C in some intervals, but that is **not** proof that every attack, pitch, duration or octave matches the XML. Real performances begin later and sustain/reverb continues past the score's 2.4 s endpoint. There is no hand-labelled audio truth.

## 5. Audio / PCM verification

`ffmpeg` host probe shows an MP4/M4A container with AAC-LC, 44,100 Hz, stereo for all four. Host FFmpeg decoded each file to interleaved s16le, then the actual Dart `AnalysisAudioPreparer` averaged channels and wrote **headerless mono float32 little-endian 44,100 Hz** PCM. Because input rate equals target, no sample-rate interpolation was needed. Phase 3 divides signed 16-bit samples by 32768 and averages channels; there is no peak normalization or gain target. `PcmAudioData.frames` and duration below are measured, not inferred from the container header. Peak/RMS are post-downmix feature statistics; RMS is square root of mean feature energy, not a manually selected loud segment. `clipped` counts native frames with nonzero clipping fraction.

| Case | Container duration s | PCM frames | PCM duration s | Peak | RMS overall | Clipped frames | Lead before first accepted note s | Tail after last accepted note s |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 001 | 6.87 | 303,104 | 6.873 | 0.779 | 0.0793 | 0 | 0.441 | 2.879 |
| 002 | 5.57 | 245,760 | 5.573 | 0.544 | 0.0624 | 0 | 1.544 | 0.929 |
| 003 | 5.74 | 252,928 | 5.735 | 0.561 | 0.0620 | 0 | 1.300 | 0.569 |
| 004 | 6.06 | 267,264 | 6.060 | 0.537 | 0.0700 | 0 | 1.219 | 0.441 |

The lead/tail figures are **not acoustic silence measurements**: they include unaccepted noise/attack/tail and must not be read as silent PCM. Native `isSilent` frames are respectively 5/19/20/18; silence flag and missing pitch are different states. Signal is non-clipped after downmix. Time difference between rounded container and PCM durations is <0.005 s. Common low-note estimates remain at nearly identical MIDI ~59.24–59.26 across cases, arguing against an obvious time/pitch scaling error in this 44.1 kHz host path. Device-native AAC decode was not captured or bitwise compared; its exact PCM parity remains untested. Stereo downmix can cancel phase-opposed content, but no evidence here demonstrates that as the cause.

## 6. Pipeline configuration and provenance

Current code was inspected directly: `analysis_audio.dart`, `music_analysis_ffi.dart`, `music_analysis_features.dart`, `performed_notes.dart`, `note_alignment.dart`, `performance_assessment.dart`, `reference_timeline.dart`, `music_analysis_calibration.dart`, native open DSP source and related tests; previous Phase 2/3/4B/5/6/7/7B/7C and 001 reports were cross-checked. A temporary test harness used the repository's production host DLL `.native-host-prod/Release/music_analysis_dsp.dll` and actual Dart Phase 3/5/6/7 components. Only AAC-to-s16le decoding was done by host FFmpeg in place of Android's platform method channel. This distinction explains why host BPM differs slightly from screenshot BPM (e.g. 002 host 84.03 versus screenshot about 84.53): device decoder and exact bytes were not verified. Production configuration remains open DSP only; native ABI unchanged. DSP uses a 4096-sample window, 512-sample hop; Phase 6 uses confidence ≥0.55, minimum duration 0.055 s, 0.8-semitone pitch boundary, and two consecutive unvoiced frames to close a note. Those constants were **observed, not adjusted**. Phase 6 aligner uses a global scale search 0.5–2.0, insertion/deletion cost 1.25 and pitch match tolerance 0.65 semitone; no cost was optimized here.

## 7. Raw DSP findings – Case 001

592 feature frames, 262 accepted voiced frames, 9 onset candidates. Main stable 0.1 s window medians: 1.0–1.2 s MIDI 63.10–63.25; 1.4–1.5 s 64.38–64.39; 1.7–1.9 s 63.04–63.19; 2.1–2.2 s 61.34–61.35; 2.5–3.4 s 59.27–59.36. Early stable first note is MIDI 59.25. Confidence in these windows is generally ~0.86–0.99. Six pitch-unaccepted gaps occur inside the region from first to last voiced note; one at **3.518–3.576 s is five hops / 58 ms**, median RMS 0.0184, and has **no onset**. This gap precedes a second ~59.33 segment, an important plausible false extra. Other transition gaps at 0.731–0.906, 1.974–2.067 and 2.299–2.438 s could reflect actual note boundaries. Onsets include 0.313, 0.345, 0.813, 0.998, 1.312, 1.602, 1.978, 2.299, 5.608 s; an onset candidate alone is not a final note.

## 8. Raw DSP findings – Case 002

480 feature frames, 225 accepted voiced, 8 onset candidates. Window median MIDI: 1.5–1.7 s ~59.26; 1.9 s **61.36**; 2.0–2.3 s **75.31–75.38** at confidence roughly 0.89–0.94; 2.4–2.6 s ~64.36–64.47; 2.7–2.9 s **75.31–75.33** at confidence ~0.94–0.97; 3.1–3.2 s ~61.36; 3.4–4.6 s ~59.23–59.28. Thus the high segment is already in raw DSP; segmentation did not invent its pitch. MIDI 75.3 is near twice the frequency of MIDI 63.3, a plausible harmonic/octave choice, but unlabelled audio cannot prove which physical component is fundamental. Eight unaccepted runs include 2.020–2.055 s with RMS median 0.237 (high-energy attack dropout), and 3.809–3.855 s inside the sustained low tail. Raw onsets: 1.382, 1.416, 1.741, 1.869, 2.368, 2.682, 3.019, 3.332 s.

## 9. Raw DSP findings – Case 003

494 feature frames, 286 accepted voiced, 9 onset candidates. Main medians: 1.3–1.5 s ~59.24; 1.8 s ~75.30, 1.9–2.0 s ~63.33; 2.1 s ~75.37, 2.2 s ~63.46; 2.3 s ~76.21, 2.4–2.5 s ~64.40; 2.7–2.8 s ~75.30–75.33, 2.9–3.0 s ~63.19–63.31; 3.2–3.3 s ~61.32–61.34; 3.5–5.0 s ~59.23–59.29, then 5.1 s ~47.26. Confidence is ~0.87–0.99 even on octave toggles. The 75↔63 and 76↔64 transitions occur in raw frames **without corresponding onset candidates at every toggle**. Eight unaccepted runs include 2.299–2.322 and 2.682–2.705 s (two hops each, RMS ~0.25–0.28), and a 0.174 s tail gap. Onsets: 0.325, 0.488, 1.161, 1.707, 1.811, 2.299, 2.682, 3.065, 3.448 s.

## 10. Raw DSP findings – Case 004

522 feature frames, 336 accepted voiced, 8 onset candidates. Sequence of diagnostic 0.1 s median MIDI: 1.2–1.5 s ~59.25; 1.7–1.8 s ~61.35; **1.9 s 63.32 → 2.0 s 75.33 → 2.1 s 63.30 → 2.2 s 75.33**; 2.4–2.6 s ~64.34–64.40; **2.8–3.1 s 75.24–75.38**; 3.3–3.6 s ~61.32–61.36; 3.8–4.0 s ~59.23–59.26; **4.1 s 71.23 → 4.2–4.4 s 59.22–59.23 → 4.5–4.6 s 71.24 → 4.7–5.0 s 59.22–59.23 → 5.1–5.2 s 71.25 → 5.3 s 59.23 → 5.4–5.5 s 47.24**. Confidence of 71/75 observations ~0.86–0.95. The sustained 59↔71 alternation after 4.1 s has no new raw onsets, strongly linking several extras to pitch-estimator octave switching plus the current pitch-change segmentation rule. Five pitch-unaccepted runs occur; one 2.740–2.763 s has RMS 0.173. Onsets: 0.499, 1.091, 1.110, 1.660, 2.333, 2.752, 3.228, 3.692 s. `isSilent` does not explain the octave toggles.

## 11. Segmentation findings

All times are seconds; MIDI values are fractional. Stable diagnostic MIDI is the median of raw pitched frames 30 ms away from each segment's edges where available (a diagnostic calculation only, not production behavior). This generally tracks production MIDI closely, so simple robust aggregation **within each already-split segment** would not remove the octave problem.

| Case | Performed segments: index `start–end / MIDI` |
|---|---|
| 001 | 0 `.441–.731/59.26`; 1 `.906–.975/61.38`; 2 `1.010–1.312/63.17`; 3 `1.312–1.602/64.31`; 4 `1.602–1.974/63.32`; 5 `2.078–2.299/61.36`; 6 `2.438–3.518/59.30`; 7 `3.576–3.994/59.33` |
| 002 | 0 `1.544–1.741/59.26`; 1 `2.067–2.345/75.35`; 2 `2.426–2.694/64.43`; 3 `2.705–2.961/75.32`; 4 `2.961–3.019/63.26`; 5 `3.135–3.309/61.36`; 6 `3.425–3.808/59.26`; 7 `3.855–4.644/59.24` |
| 003 | 0 `1.300–1.521/59.24`; 1 `1.846–1.950/75.29`; 2 `1.950–2.101/63.34`; 3 `2.101–2.159/75.39`; 4 `2.159–2.299/63.40`; 5 `2.322–2.415/76.21`; 6 `2.415–2.682/64.29`; 7 `2.705–2.937/75.32`; 8 `2.937–3.042/63.24`; 9 `3.181–3.402/61.33`; 10 `3.541–5.097/59.24`; 11 `5.097–5.166/47.26` |
| 004 | 0 `1.219–1.544/59.25`; 1 `1.753–1.846/61.35`; 2 `1.927–2.020/63.28`; 3 `2.020–2.090/75.32`; 4 `2.090–2.183/63.29`; 5 `2.183–2.299/75.34`; 6 `2.299–2.740/64.19`; 7 `2.786–2.879/75.39`; 8 `2.879–2.949/63.30`; 9 `2.949–3.216/75.28`; 10 `3.332–3.599/61.35`; 11 `3.796–4.098/59.24`; 12 `4.098–4.249/71.23`; 13 `4.249–4.470/59.22`; 14 `4.470–4.656/71.25`; 15 `4.656–5.108/59.23`; 16 `5.108–5.283/71.25`; 17 `5.283–5.433/59.23`; 18 `5.433–5.619/47.24` |

Some short segments at 0.058–0.105 s are admitted by the 0.055 s rule. Phase 6 does not expose boundary-reason metadata. Code plus raw-frame timing indicates 003/004 same-note octave flips are pitch-change boundaries, not new onsets; 001 final low-note split follows two or more unaccepted pitch frames without onset. Repeated real attacks cannot be certified without audio annotation. A 0.8-semitone difference rule necessarily splits 12-semitone raw flips; changing that rule to fit these recordings would be ungrounded.

## 12. Alignment findings

Table entries are `reference index→performed index: mark [pitch cents, onset beat offset, duration ratio]`; `—` is **null**, never zero. Full production event order is retained.

| Case | Alignment events |
|---|---|
| 001 | `0→0 wrong [-73.6,0,.58]`; `1→1 matched [-62.2,-.05]`; `—→2 extra`; `2→3 matched [+30.5,+.31]`; `3→4 wrong [-168.1,+.24]`; `4→— missed`; `5→5 matched [-64.5,-.04]`; `6→6 wrong [-70.1,0]`; `—→7 extra` |
| 002 | `0→0 wrong [-74.3,0]`; `1→1 wrong [+1335.1,-.02]`; `2→2 matched [+42.6,+.24]`; `3→3 wrong [+1032.1,+.13]`; `4→4 wrong [-74.1,-.02]`; `5→5 matched [-64.1,-.27]`; `—→6 extra`; `6→7 wrong [-76.4,+.24]` |
| 003 | `0→0 wrong [-76.1,-.14]`; `1→1 wrong [+1328.8,0]`; `—→2 extra`; `—→3 extra`; `2→4 matched [-60.1,+.26]`; `3→5 wrong [+1121.1,+.02]`; `4→6 matched [+29.4,-.33]`; `—→7 extra`; `5→8 wrong [+123.7,+.02]`; `6→9 wrong [+132.7,-.08]`; `—→10 extra`; `—→11 extra` |
| 004 | `0→0 wrong [-74.9,+.05]`; `1→1 matched [-64.8,-.21]`; `—→2,3,4,5 extra`; `2→6 matched [+19.0,+.05]`; `3→7 wrong [+1038.7,0]`; `—→8,9 extra`; `4→10 wrong [-265.2,0]`; `5→11 wrong [-275.8,-.07]`; `—→12,13 extra`; `6→14 wrong [+1125.2,+.05]`; `—→15,16,17,18 extra` |

For the handful of matched labels, `matched` means within 0.65 MIDI semitone by Phase 6; it is **not** an educational correctness statement. All 001/002/003/004 `wrongNote` cent values trace to observed performed MIDI and reference MIDI, not Phase 7 unit conversion. In 003/004, extra segments create possible cascading correspondence shifts: e.g. case 003 reference D4 index 5 pairs with performed MIDI 63.24 after extra MIDI 75.32, whereas a later MIDI 61.33 might be a D-like observation, but this alternative cannot be certified without onset labels. No `missed` exists in 002–004 because the global path paired all seven references, even when the pairing is musically questionable.

## 13. Pitch root-cause analysis

Signed cents from **aligned pairs** are `100 × (performed MIDI − reference MIDI)`; they are not independent detector errors without ground-truth correspondence. Medians below use the conventional middle/two-middle average rounded to nearest cent; their interpretation is affected by pairing.

| Case | Signed median cents | Absolute median cents | Paired range cents | Small-offset evidence | Octave/harmonic evidence |
|---|---:|---:|---|---|---|
| 001 | about -67 | about 67 | -168…+31 | stable lower C/D ~-60 to -74 | none sustained |
| 002 | about -64 | about 74 | -76…+1335 | lower C/D ~-64 to -76 | MIDI 75.3 during D/F-side intervals |
| 003 | about +124 | about 124 | -76…+1329 | first low C -76 | 75↔63 and 76↔64 raw flips |
| 004 | about -65 | about 265 | -276…+1125 | early low C/D -65 to -75 | 75↔63 and 71↔59 raw flips |

MIDI 75.3 vs 63.3 and 71.2 vs 59.2 are ~12 semitones: an **octave-scale raw observation**, often with high pitch confidence (0.86–0.97) and moderate RMS, so confidence alone does not reject it. They occur both at attacks and within sustained, decaying regions; the late case 004 59↔71 toggle occurs with RMS falling roughly 0.04 to 0.02, suggesting amplitude/spectral-balance dependence, not proof. The ~-65 to -76 cent low contour repeats across recordings and may reflect instrument tuning, recording playback, or detector bias. No independent pitch label, tuning reference, or instrument identity has established which. `+1032/+1125/+1335` cents cannot be attributed entirely to DSP: the raw octave is real in DSP output, while the **amount relative to score** also depends on which reference was paired. Case 004 `-265/-276` cents are primarily alignment-induced apparent pitch errors: raw performed MIDI ~61 and ~59 were paired to reference 64 and 62 after extra segments. A single fixed -70-cent correction is not supported by the distribution.

## 14. Onset / segmentation root-cause analysis

Candidate onset counts (9/8/9/8) differ sharply from performed counts (8/8/12/19). In 004, the ~59↔71 alternation from 4.1–5.3 s produces seven+ segments with **no corresponding new onsets**; the raw pitch-change boundary is the immediate cause. Case 001 final low note is split by a 58-ms unaccepted-pitch gap without onset, a candidate general robustness issue, but a single unannotated sustained note does not establish a safe gap-bridging rule: it could be a real repeated note or a noisy boundary. No segmenter change was justified. High-RMS pitch dropouts near attacks (e.g. 002 at 2.020–2.055 s) show onset/pitch-estimator coupling, not acoustic silence. Extra trace examples: 003 extra performed 2 (MIDI 63.34) arises directly after extra/paired 75.29→63.34 raw jump; 004 extras 12/13/15/16/17 correspond to alternating raw MIDI 71.23/59.23 in the tail. Case 001 missed E4 index 4 is a path decision after observed MIDI 63.32 is paired with F4 index 3; the raw MIDI 64.3 at 1.3–1.6 s is instead paired with E4 index 2. This is a possible alignment/observation combination, **not proof** the musician omitted E4.

## 15. Tempo analysis

All reference attacks are under 100 quarter BPM. Production estimates/time scales/start offsets:

| Case | Reference BPM | Estimated BPM | Scale | Offset s | Performed onset sequence s |
|---|---:|---:|---:|---:|---|
| 001 | 100 | 90.139 | 1.1094 | .441 | `.441,.906,1.010,1.312,1.602,2.078,2.438,3.576` |
| 002 | 100 | 84.032 | 1.1900 | 1.544 | `1.544,2.067,2.426,2.705,2.961,3.135,3.425,3.855` |
| 003 | 100 | 97.509 | 1.0255 | 1.384 | `1.300,1.846,1.950,2.101,2.159,2.322,2.415,2.705,2.937,3.181,3.541,5.097` |
| 004 | 100 | 55.371 | 1.8060 | 1.165 | `1.219,1.753,1.927,2.020,2.090,2.183,2.299,2.786,2.879,2.949,3.332,3.796,4.098,4.249,4.470,4.656,5.108,5.283,5.433` |

The offset is an optimization parameter, not necessarily acoustic first-note onset; in 003/004 it differs from first accepted performed onset. The very low 004 BPM is coupled to the alignment pairing of late tail MIDI 71.25 with final reference C4, after many octave extras. It does **not** establish that the musician played at 55 BPM. As a diagnostic cross-check, main low-to-low first/last observations are ~0.441→2.438 s (001), 1.544→3.425 s (002), 1.300→3.541 s (003), 1.219→3.796 s (004); if these correspond to reference C0→C6 (1.8 reference seconds), the implied BPMs are ~90, ~96, ~80, ~70, respectively. This correspondence assumption is unverified, so none is a replacement tempo estimator. A high-confidence *manually annotated* set of attacks is needed to isolate tempo from segmentation and alignment.

## 16. Cross-case comparison

Absolute/signed pitch and onset medians use only paired events; `—` denotes unavailable truth, not zero. The summary's absolute median values can differ from Phase 7's median implementation for even sample counts by rounding convention; exact event values above take precedence.

| Case | Duration s | Raw frames | Notes | BPM | Matched | Wrong | Missed | Extra | Signed pitch median ¢ | Absolute pitch median ¢ | Abs onset median beat | Median duration ratio | Unaccepted internal runs | Suspected octave intervals |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 001 | 6.873 | 592 | 8 | 90.139 | 3 | 3 | 1 | 2 | -67 | 67 | .047 | .767 | 6 | none sustained |
| 002 | 5.573 | 480 | 8 | 84.032 | 2 | 5 | 0 | 1 | -64 | 74 | .126 | .715 | 8 | 2.0–2.3, 2.7–2.9 s |
| 003 | 5.735 | 494 | 12 | 97.509 | 2 | 5 | 0 | 5 | +124 | 124 | .080 | .478 | 8 | 1.8–2.3, 2.7–2.9, 5.1 s |
| 004 | 6.060 | 522 | 19 | 55.371 | 2 | 5 | 0 | 12 | -65 | 265 | .050 | .400 | 5 | 2.0–2.3, 2.8–3.2, 4.1–5.3 s |

No clipping occurred. Internal unaccepted runs include low-confidence/zero-pitch frames, not necessarily `isSilent`. Pitch-error distribution is bimodal/multimodal rather than a single offset. Severity of raw octave alternation and segment fragmentation rises markedly from 001→004, while signal amplitude is not monotonically ordered by case.

## 17. Failure traceback

| Case/event | Assessment → alignment | Performed note → raw DSP | Supported inference |
|---|---|---|---|
| 002 D4 `wrongNote` +1335¢ | reference 62 paired to performed 75.35 | 2.067–2.345 s; raw 2.0–2.3 s median ~75.3, confidence ~0.90–0.94; raw 1.9 s ~61.36 | octave-like raw switch precedes alignment; exact +1335¢ includes this pairing |
| 003 first extra 63.34 | no reference paired | 1.950–2.101 s; raw 1.9–2.0 s ~63.33, flanked by ~75.3 | split follows raw octave reversal, not Phase 7 fabrication |
| 004 tail extra 71.23 | no reference paired | 4.098–4.249 s, raw 4.1 s ~71.23; no new onset | pitch-change segmentation creates an extra candidate from raw octave switch |
| 004 final `wrongNote` +1125¢ | C4 reference 60 paired with 71.25 | 4.470–4.656 s; raw 4.5–4.6 s ~71.24; nearby 59.22 alternate | both detector octave choice and alignment path contribute |
| 001 E4 `missed` | reference index 4 deleted | raw ~64.39 exists at 1.4–1.5 s, but paired to reference E4 index 2; ~63.17 at 1.7–1.8 paired to F4 index 3 | missed label cannot be read as proven non-performance |
| 001 final `extra` | no reference paired | 3.576–3.994 s MIDI 59.33; preceding 3.518–3.576 s pitch dropout, RMS nonzero, no onset | probable fragment, not a proven repeated note |

## 18. Classification of findings

**REPRODUCIBLE:** host pipeline produces case-specific 8/8/12/19 segments; raw 12-semitone-like alternatives in 002/003/004 precede segmentation; 004 extra tail segments track raw alternation without new onset; all four have stable low MIDI ~59.2–59.3 early; no post-downmix clipping. **LIKELY:** detector harmonic/subharmonic ambiguity contributes to octave observations; fragmentation alters alignment correspondence and estimated tempo, especially 004. **POSSIBLE:** recording/instrument tuning produces the shared ~-70¢ low-note offset; 001 tail extra follows a false dropout boundary; Android-native decoded PCM differs enough to explain small host/device tempo differences. **NOT SUPPORTED BY CURRENT DATA:** a universal fixed tuning offset, a decoder rate conversion error, gain normalization, clipping, all extra labels representing actual added notes, all missed labels representing omissions, a specific DSP implementation defect, or a calibrated educational grade.

## 19. Implementation bugs

**No implementation defect was sufficiently demonstrated to justify a production algorithm change.** Raw octave observations are real outputs, but the true fundamental and signal spectrum at each moment are unannotated; a common detector weakness is plausible, not yet proven as an implementation bug. Phase 6's current rules deterministically magnify raw toggles; this is a robustness limitation, but no evidence-based replacement rule has been validated on non-problematic repeated notes and instrument attacks. The 001 no-onset tail fragmentation is one example, not a general regression proof. The previous reports' host decode qualification remains accurate; device-path parity is still unknown.

## 20. Production changes

**None.** No threshold, DSP, FFI ABI, decoder, segmentation, alignment, tempo, assessment, or UI code changed. The only permanent task file is this report. Temporary diagnostic source and decoded audio were removed after measurements. No before/after algorithm claim applies.

## 21. Test results

Command: installed Flutter SDK `flutter_tools.snapshot test --no-pub --reporter json` over `test/analysis_audio_test.dart`, `test/music_analysis_ffi_integration_test.dart`, `test/music_analysis_phase6_test.dart`, `test/music_analysis_phase6_integration_test.dart`, `test/music_analysis_phase7_test.dart`, `test/music_analysis_phase7_integration_test.dart`, `test/music_analysis_calibration_test.dart`, `test/music_analysis_test_page_test.dart`, and `test/reference_timeline_test.dart`. Machine-readable `testDone` count: **52 passed, 0 failed, 0 skipped**. A temporary four-file diagnostic Flutter test separately passed **1/1** and was removed. Host FFmpeg decoding succeeded for all four. No Android device test was run; `adb` was not on PATH in this shell. No Android/iOS build or APK/AAB/IPA was made. iOS was not tested. The test suite verifies existing contracts, not ground-truth acoustic accuracy.

## 22. Files changed

| File | Status | Reason |
|---|---|---|
| `MUSIC_ANALYSIS_REAL_CALIBRATION_002_004_REPORT.md` | added | independent multi-case diagnostic record and decision |

All pre-existing uncommitted work was left untouched. No private absolute paths or user audio were added to the repository. Diagnostic raw JSON, s16le copies, and temporary harness were used locally and deleted.

## 23. Remaining limitations

No manual onset/pitch labels, instrument tuning reference, or verified note-by-note audio/XML correspondence; no independent spectrum/fundamental oracle; host FFmpeg substitutes Android's decoder; no bytewise host/device PCM comparison; no iOS path; four recordings from one phrase cannot establish population thresholds. Phase 6 does not persist boundary-reason metadata, so boundary causes were inferred from code and neighboring raw frames. The diagnostic 100-ms window medians can hide shorter glitches; exact raw frames were inspected for cited boundaries, but the full raw frame dump was not retained in the report. The current confidence value is a DSP internal confidence, not calibrated probability of the *correct octave*.

## 24. Calibration decision

**A: no production algorithm change is justified yet; obtain labelled evidence.** There is a reproducible raw octave-selection/fragmentation pattern, but not enough truth to choose between source overtone dominance, instrument-specific fundamental ambiguity, a decoder discrepancy, or a general open-engine implementation defect. We should not tune 0.8 semitone, confidence, insertion/deletion costs, or a -70¢ correction on these four takes.

## 25. Recommended next step

Record or annotate a small controlled set through the **same phone and Phase 3 path**, with per-attack start/end and actual sounding fundamental (not merely MusicXML) marked by a musician or independent spectral inspection: isolated C4/D4/E4/F4 at soft/medium/strong dynamics, each ≥1 s; paired repeated same-pitch notes with 0/50/150 ms intentional gaps; sustained C4/E4 with strong/weak attacks and decay; one clean C–D–E–F–E–D–C take at measured 80/100/120 BPM; silent/noise-only lead and tail; optional direct PCM and Android-decoded AAC of the same signal. Specifically sample the MIDI ~59↔71 and ~63↔75 regions, which separate genuine octave playing from overtone selection. Compare raw frame pitch to these hand labels before segmentation; then test candidate general octave-stability and short-dropout handling on **both problematic and clean/repeated-note controls**, without using XML to force detection. Keep this diagnostic corpus separate from training/selection data used for any later threshold choice.

## 26. Acceptance criteria for closing calibration

Documented same-file device/host decode parity or quantified difference; hand-labelled acoustic pitch/octave and onsets across multiple dynamics and tempo controls; per-layer precision/error statistics with uncertainty and held-out recordings; demonstrated no reference-score leakage into DSP/segmentation; any proposed general change reproduced by a failing non-dataset-specific regression and validated against repeated notes and clean controls; all Phase 3/5/6/7 regressions passing; no Aubio production dependency or uncalibrated educational score. These criteria are **not yet met** by the four current recordings.

## Appendix A. Complete performed-note observations

Fractional MIDI is the actual Phase 6 output; cents below are relative to its *nearest equal-tempered MIDI*, not to the MusicXML. Stable MIDI is a diagnostic median of raw frames away from segment edges. `—` means unavailable.

### Case 001

| # | Start s | End s | Duration s | MIDI | Nearest MIDI | Local cents | Confidence | Mean RMS | Stable raw median MIDI |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0.441 | 0.731 | 0.290 | 59.26 | 59 | 26.4 | 0.97 | 0.0714 | 59.25 |
| 1 | 0.906 | 0.975 | 0.070 | 61.38 | 61 | 37.8 | 0.91 | 0.0496 | 61.36 |
| 2 | 1.010 | 1.312 | 0.302 | 63.17 | 63 | 17.1 | 0.98 | 0.1853 | 63.13 |
| 3 | 1.312 | 1.602 | 0.290 | 64.31 | 64 | 30.5 | 0.96 | 0.1112 | 64.39 |
| 4 | 1.602 | 1.974 | 0.372 | 63.32 | 63 | 31.9 | 0.97 | 0.1628 | 63.17 |
| 5 | 2.078 | 2.299 | 0.221 | 61.36 | 61 | 35.5 | 0.93 | 0.0594 | 61.34 |
| 6 | 2.438 | 3.518 | 1.080 | 59.30 | 59 | 29.9 | 0.92 | 0.0383 | 59.29 |
| 7 | 3.576 | 3.994 | 0.418 | 59.33 | 59 | 33.4 | 0.87 | 0.0203 | 59.34 |

### Case 002

| # | Start s | End s | Duration s | MIDI | Nearest MIDI | Local cents | Confidence | Mean RMS | Stable raw median MIDI |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 1.544 | 1.741 | 0.197 | 59.26 | 59 | 25.7 | 0.93 | 0.0533 | 59.26 |
| 1 | 2.067 | 2.345 | 0.279 | 75.35 | 75 | 35.1 | 0.91 | 0.1056 | 75.35 |
| 2 | 2.426 | 2.694 | 0.267 | 64.43 | 64 | 42.6 | 0.96 | 0.0557 | 64.46 |
| 3 | 2.705 | 2.961 | 0.255 | 75.32 | 75 | 32.1 | 0.95 | 0.1088 | 75.32 |
| 4 | 2.961 | 3.019 | 0.058 | 63.26 | 63 | 25.9 | 0.95 | 0.0220 | — |
| 5 | 3.135 | 3.309 | 0.174 | 61.36 | 61 | 35.9 | 0.90 | 0.0196 | 61.37 |
| 6 | 3.425 | 3.808 | 0.383 | 59.26 | 59 | 26.5 | 0.92 | 0.0296 | 59.26 |
| 7 | 3.855 | 4.644 | 0.789 | 59.24 | 59 | 23.6 | 0.92 | 0.0150 | 59.24 |

### Case 003

| # | Start s | End s | Duration s | MIDI | Nearest MIDI | Local cents | Confidence | Mean RMS | Stable raw median MIDI |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 1.300 | 1.521 | 0.221 | 59.24 | 59 | 23.9 | 0.96 | 0.0447 | 59.24 |
| 1 | 1.846 | 1.950 | 0.104 | 75.29 | 75 | 28.8 | 0.91 | 0.1693 | 75.29 |
| 2 | 1.950 | 2.101 | 0.151 | 63.34 | 63 | 34.1 | 0.95 | 0.1080 | 63.34 |
| 3 | 2.101 | 2.159 | 0.058 | 75.39 | 75 | 39.0 | 0.87 | 0.0907 | — |
| 4 | 2.159 | 2.299 | 0.139 | 63.40 | 63 | 39.9 | 0.97 | 0.0548 | 63.33 |
| 5 | 2.322 | 2.415 | 0.093 | 76.21 | 76 | 21.1 | 0.87 | 0.1563 | 76.22 |
| 6 | 2.415 | 2.682 | 0.267 | 64.29 | 64 | 29.4 | 0.97 | 0.0530 | 64.40 |
| 7 | 2.705 | 2.937 | 0.232 | 75.32 | 75 | 31.9 | 0.95 | 0.1096 | 75.32 |
| 8 | 2.937 | 3.042 | 0.104 | 63.24 | 63 | 23.7 | 0.95 | 0.0153 | 63.23 |
| 9 | 3.181 | 3.402 | 0.221 | 61.33 | 61 | 32.7 | 0.93 | 0.0211 | 61.33 |
| 10 | 3.541 | 5.097 | 1.556 | 59.24 | 59 | 24.2 | 0.92 | 0.0157 | 59.24 |
| 11 | 5.097 | 5.166 | 0.070 | 47.26 | 47 | 25.8 | 0.89 | 0.0185 | 47.26 |

### Case 004

| # | Start s | End s | Duration s | MIDI | Nearest MIDI | Local cents | Confidence | Mean RMS | Stable raw median MIDI |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 1.219 | 1.544 | 0.325 | 59.25 | 59 | 25.1 | 0.90 | 0.0430 | 59.25 |
| 1 | 1.753 | 1.846 | 0.093 | 61.35 | 61 | 35.2 | 0.95 | 0.0668 | 61.34 |
| 2 | 1.927 | 2.020 | 0.093 | 63.28 | 63 | 28.1 | 0.94 | 0.1778 | 63.32 |
| 3 | 2.020 | 2.090 | 0.070 | 75.32 | 75 | 32.3 | 0.88 | 0.0853 | 75.33 |
| 4 | 2.090 | 2.183 | 0.093 | 63.29 | 63 | 29.3 | 0.99 | 0.0907 | 63.30 |
| 5 | 2.183 | 2.299 | 0.116 | 75.34 | 75 | 34.4 | 0.91 | 0.1069 | 75.33 |
| 6 | 2.299 | 2.740 | 0.441 | 64.19 | 64 | 19.0 | 0.95 | 0.0680 | 64.37 |
| 7 | 2.786 | 2.879 | 0.093 | 75.39 | 75 | 38.7 | 0.89 | 0.1284 | 75.39 |
| 8 | 2.879 | 2.949 | 0.070 | 63.30 | 63 | 30.1 | 0.99 | 0.0885 | 63.30 |
| 9 | 2.949 | 3.216 | 0.267 | 75.28 | 75 | 27.6 | 0.93 | 0.1104 | 75.30 |
| 10 | 3.332 | 3.599 | 0.267 | 61.35 | 61 | 34.8 | 0.96 | 0.0451 | 61.35 |
| 11 | 3.796 | 4.098 | 0.302 | 59.24 | 59 | 24.2 | 0.95 | 0.0524 | 59.24 |
| 12 | 4.098 | 4.249 | 0.151 | 71.23 | 71 | 23.0 | 0.87 | 0.0378 | 71.23 |
| 13 | 4.249 | 4.470 | 0.221 | 59.22 | 59 | 22.4 | 0.98 | 0.0380 | 59.23 |
| 14 | 4.470 | 4.656 | 0.186 | 71.25 | 71 | 25.2 | 0.87 | 0.0330 | 71.25 |
| 15 | 4.656 | 5.108 | 0.453 | 59.23 | 59 | 22.6 | 0.94 | 0.0230 | 59.23 |
| 16 | 5.108 | 5.283 | 0.174 | 71.25 | 71 | 25.5 | 0.87 | 0.0212 | 71.25 |
| 17 | 5.283 | 5.433 | 0.151 | 59.23 | 59 | 23.0 | 0.89 | 0.0186 | 59.23 |
| 18 | 5.433 | 5.619 | 0.186 | 47.24 | 47 | 23.7 | 0.89 | 0.0152 | 47.24 |

## Appendix B. Complete alignment events

Expected onset is `offset + timeScale × reference.startSeconds`; onset error is in quarter beats. Duration ratio is Phase 7 production output. `—` is null.

### Case 001

| Mark | Ref # | Ref MIDI | Performed # | Perf MIDI | Pitch ¢ | Expected onset s | Perf onset s | Onset beats | Duration ratio |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| wrongNote | 0 | 60.00 | 0 | 59.26 | -73.6 | 0.441 | 0.441 | 0.000 | 0.581 |
| matched | 1 | 62.00 | 1 | 61.38 | -62.2 | 0.940 | 0.906 | -0.052 | 0.419 |
| extra | — | — | 2 | 63.17 | — | — | 1.010 | — | — |
| matched | 2 | 64.00 | 3 | 64.31 | 30.5 | 1.107 | 1.312 | 0.308 | 0.872 |
| wrongNote | 3 | 65.00 | 4 | 63.32 | -168.1 | 1.440 | 1.602 | 0.244 | 1.116 |
| missed | 4 | 64.00 | — | — | — | 1.772 | — | — | — |
| matched | 5 | 62.00 | 5 | 61.36 | -64.5 | 2.105 | 2.078 | -0.041 | 0.663 |
| wrongNote | 6 | 60.00 | 6 | 59.30 | -70.1 | 2.438 | 2.438 | 0.000 | 3.244 |
| extra | — | — | 7 | 59.33 | — | — | 3.576 | — | — |

### Case 002

| Mark | Ref # | Ref MIDI | Performed # | Perf MIDI | Pitch ¢ | Expected onset s | Perf onset s | Onset beats | Duration ratio |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| wrongNote | 0 | 60.00 | 0 | 59.26 | -74.3 | 1.544 | 1.544 | 0.000 | 0.369 |
| wrongNote | 1 | 62.00 | 1 | 75.35 | 1,335.1 | 2.080 | 2.067 | -0.018 | 1.561 |
| matched | 2 | 64.00 | 2 | 64.43 | 42.6 | 2.258 | 2.426 | 0.236 | 0.748 |
| wrongNote | 3 | 65.00 | 3 | 75.32 | 1,032.1 | 2.615 | 2.705 | 0.126 | 0.715 |
| wrongNote | 4 | 64.00 | 4 | 63.26 | -74.1 | 2.972 | 2.961 | -0.016 | 0.163 |
| matched | 5 | 62.00 | 5 | 61.36 | -64.1 | 3.329 | 3.135 | -0.272 | 0.488 |
| extra | — | — | 6 | 59.26 | — | — | 3.425 | — | — |
| wrongNote | 6 | 60.00 | 7 | 59.24 | -76.4 | 3.686 | 3.855 | 0.236 | 2.211 |

### Case 003

| Mark | Ref # | Ref MIDI | Performed # | Perf MIDI | Pitch ¢ | Expected onset s | Perf onset s | Onset beats | Duration ratio |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| wrongNote | 0 | 60.00 | 0 | 59.24 | -76.1 | 1.384 | 1.300 | -0.137 | 0.478 |
| wrongNote | 1 | 62.00 | 1 | 75.29 | 1,328.8 | 1.846 | 1.846 | 0.000 | 0.679 |
| extra | — | — | 2 | 63.34 | — | — | 1.950 | — | — |
| extra | — | — | 3 | 75.39 | — | — | 2.101 | — | — |
| matched | 2 | 64.00 | 4 | 63.40 | -60.1 | 2.000 | 2.159 | 0.259 | 0.453 |
| wrongNote | 3 | 65.00 | 5 | 76.21 | 1,121.1 | 2.307 | 2.322 | 0.024 | 0.302 |
| matched | 4 | 64.00 | 6 | 64.29 | 29.4 | 2.615 | 2.415 | -0.325 | 0.868 |
| extra | — | — | 7 | 75.32 | — | — | 2.705 | — | — |
| wrongNote | 5 | 62.00 | 8 | 63.24 | 123.7 | 2.923 | 2.937 | 0.024 | 0.340 |
| wrongNote | 6 | 60.00 | 9 | 61.33 | 132.7 | 3.230 | 3.181 | -0.080 | 0.717 |
| extra | — | — | 10 | 59.24 | — | — | 3.541 | — | — |
| extra | — | — | 11 | 47.26 | — | — | 5.097 | — | — |

### Case 004

| Mark | Ref # | Ref MIDI | Performed # | Perf MIDI | Pitch ¢ | Expected onset s | Perf onset s | Onset beats | Duration ratio |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| wrongNote | 0 | 60.00 | 0 | 59.25 | -74.9 | 1.165 | 1.219 | 0.050 | 0.400 |
| matched | 1 | 62.00 | 1 | 61.35 | -64.8 | 1.978 | 1.753 | -0.207 | 0.343 |
| extra | — | — | 2 | 63.28 | — | — | 1.927 | — | — |
| extra | — | — | 3 | 75.32 | — | — | 2.020 | — | — |
| extra | — | — | 4 | 63.29 | — | — | 2.090 | — | — |
| extra | — | — | 5 | 75.34 | — | — | 2.183 | — | — |
| matched | 2 | 64.00 | 6 | 64.19 | 19.0 | 2.248 | 2.299 | 0.046 | 0.814 |
| wrongNote | 3 | 65.00 | 7 | 75.39 | 1,038.7 | 2.790 | 2.786 | -0.004 | 0.171 |
| extra | — | — | 8 | 63.30 | — | — | 2.879 | — | — |
| extra | — | — | 9 | 75.28 | — | — | 2.949 | — | — |
| wrongNote | 4 | 64.00 | 10 | 61.35 | -265.2 | 3.332 | 3.332 | 0.000 | 0.493 |
| wrongNote | 5 | 62.00 | 11 | 59.24 | -275.8 | 3.874 | 3.796 | -0.071 | 0.557 |
| extra | — | — | 12 | 71.23 | — | — | 4.098 | — | — |
| extra | — | — | 13 | 59.22 | — | — | 4.249 | — | — |
| wrongNote | 6 | 60.00 | 14 | 71.25 | 1,125.2 | 4.416 | 4.470 | 0.050 | 0.343 |
| extra | — | — | 15 | 59.23 | — | — | 4.656 | — | — |
| extra | — | — | 16 | 71.25 | — | — | 5.108 | — | — |
| extra | — | — | 17 | 59.23 | — | — | 5.283 | — | — |
| extra | — | — | 18 | 47.24 | — | — | 5.433 | — | — |
