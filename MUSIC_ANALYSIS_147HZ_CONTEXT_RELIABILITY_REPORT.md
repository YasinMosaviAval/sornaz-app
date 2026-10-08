# Sornaz — Targeted 147 Hz context and temporal reliability investigation

## Executive Summary

The approximately 147 Hz component is **present in the recorded pre-key-down waveform**: the previous exact-window native/PCM candidate probe found fundamental and harmonic energy, and this investigation reuses those frozen measurements. It appears in **V01–V04**, with accepted-pitch medians of 148.28–148.82 Hz. The accepted observations form **intermittent 1–14-frame bursts**, rather than one uninterrupted note-length track; several bursts have onset-like peaks. The **physical source is unknown**. Frame-local RMS/CMND cannot separate a periodic background from a quiet note. Temporal evidence helps describe the phenomenon but does not establish a safe rejection rule: the tested new-event strategy rejects 75/136 pre-key-down frames while retaining 61, and background memory rejects none with its 22-frame confirmation. A quiet note and background can also be waveform-identical when they begin at recording start. Same-frequency clear attacks pass the feature-level counterexample, but soft same-frequency attacks and weak-onset legato fail. **Phase 1 FAIL; Phase 2 and full safety regression were not reached. NO SAFE CONTEXTUAL VOICING FIX ESTABLISHED.** Production DSP, candidate selection, Phase 6, FFI/ABI and downstream code remain unchanged. **NO NEW APK REQUIRED.**

## Scope, inputs and frozen evidence

This is a targeted host-only investigation of V01–V04 and the existing Q005/Q007/Q008 controls. The previous report `MUSIC_ANALYSIS_RAW_PITCH_VOICING_ARTIFACT_INVESTIGATION_REPORT.md`, its `raw_voicing_baseline_features.csv`, `raw_voicing_region_annotations.csv`, `raw_voicing_candidate_evidence.csv`, `raw_voicing_silence_analysis.csv` and `raw_voicing_synthetic_silence_noise.csv` were read. The video annotation, old synthetic split and production code were not changed. The earlier 39/39 input availability, 136/565 accepted pre-key-down frames, 14/4/13/10 video segments, V02 octave-down diagnosis and quiet-note failures are accepted baselines, not recomputed claims. The four videos remain present. There was extensive unrelated worktree content before this task; it is excluded from this commit.

`tools/background_147_context.dart` reads the frozen CSVs, uses exact-window **already computed** spectral magnitudes and writes four small task artifacts. It does not decode videos or run the 39-case pipeline. Selected `spectral_F/H2/H3` describe signal energy, not calibrated sound pressure. Candidate `pitch_confidence` remains YIN periodicity evidence.

## Recorded component and cross-video behavior

| Case | Pre accepted / frames | Median detected Hz | Hz MAD | Median accepted RMS | Median confidence | Longest continuous accepted track | Derived post accepted / frames |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| V01 | 39/147 | 148.49 | 0.63 | .00859 | .880 | 10 frames | 34/224 |
| V02 | 18/150 | 148.28 | 1.08 | .00775 | .881 | 7 frames | 12/78 |
| V03 | 37/129 | 148.51 | 0.39 | .00568 | .889 | 12 frames | 27/144 |
| V04 | 42/139 | 148.82 | 0.52 | .00865 | .897 | 14 frames | 9/87 |

The exact-window selected-candidate median fundamental magnitudes are about 7.9–12.1 in the diagnostic probe's relative units; H2 medians are 1.3–1.6. This and low CMND support an actual periodic component in the waveform. They do **not** identify its physical source or prove a single oscillator. Selected-frequency stability within bursts is relatively tight, but accepted tracks recur in separate bursts roughly a few tenths of a second apart. The data support **intermittent periodic background observations**, not a continuously accepted tone. Phase/frequency stability of the underlying waveform between bursts was **not tested**: the frozen candidate trace is not a phase-coherent source measurement. The post-note estimates are compatible with background persistence, but key-up and decay are not independently separated well enough to assert that every post estimate is background. **PHYSICAL SOURCE UNKNOWN.**

## Track and onset evidence

`background_147_temporal_tracks.csv` joins consecutive accepted frames only when their pitch differs by at most 100 cents. This is a diagnostic grouping choice, not a production threshold. The four pre-note windows contain respectively 5, 5, 5 and 4 tracks. Their longest lengths are 10, 7, 12 and 14 frames; the 512-sample hop is about 11.61 ms. A putative onset threshold of .20 marks 3/5, 0/5, 3/5 and 2/4 pre-note tracks as new events. Thus onset-like evidence is sometimes *present in false musical contexts*. The previous frozen attack regions show legitimate attacks with onset often below .20. Requiring that onset would reject real notes.

The diagnostic early-RMS ratio compares the first five accepted track frames with the preceding eight raw frames. The deliberately simple B rule regards ratio ≥2 **or** early onset ≥.20 as new-event evidence. This uses no filename, MIDI or reference input. The C rule remembers an uninterrupted same-pitch track after 22 frames (about .25 s) without new-event evidence. It is retrospective: a real-time decision cannot erase its first 21 accepted frames without adding output latency. None of the observed pre-note tracks is 22 frames long, so C does not address the recorded bursts. There is no evidence of a robust spectral-change discriminator in the frozen features beyond the onset descriptor, which already fires on some background bursts.

## Three strategy comparison and Phase 1 gate

| Strategy | V pre-note accepted retained / 136 | Rejected | Main limitation |
| --- | ---: | ---: | --- |
| A current production | 136 | 0 | Periodicity above RMS gate is accepted. |
| B new-event evidence | 61 | 75 | Background bursts can look like new events; soft/legato starts may lack the required event. |
| C background memory | 136 | 0 | All pre-note accepted tracks are shorter than 22 frames. |

The B result is a **diagnostic track-level counterfactual** over frozen accepted observations, not a production before/after run. Neither B nor C has demonstrated safe rejection with useful note coverage. Thresholds .20, 2 and 22 were only explanatory probes; no broad sweep or held-out tuning was performed. Q005 is 52/52 accepted by the frozen detector despite being labelled periodic background. Q007 and Q008 are legitimate weak/quiet tones (52/52 accepted each). All are periodic; amplitude alone already failed in the previous report. The frozen Q files lack an independently observed physical event cue, so their intention cannot be inferred from a single-frame spectrum.

## Limited deterministic counterexamples

`background_context_counterexamples.csv` contains **feature-level decision controls**, not native-DSP results. T01 and T02 deliberately assign different intent to the *same mathematical waveform* `.008*sin(2π·147t)` starting at recording time zero. This is an identifiability counterexample: any score-free signal-only rule gives them the same answer. B accepts both; C can reject both only after a delay, losing the legitimate quiet note. T03 (different-frequency note after background) and T04 (same-frequency clear attack) have a modelled 3× early RMS ratio and pass B. T05 (same-frequency soft attack) and T06 (weak-onset legato) have only a 1.1× ratio and no strong onset, so B and C fail them. These controlled features test policy logic only; no native synthetic pitch or spectrum outcome is claimed for T01–T06. T04 shows clear re-articulation can survive, but T05 is the critical unsafe same-frequency case.

## Decision, limits and next step

**Phase 1 FAIL.** B reduces pre-note acceptance but fails the soft same-frequency/legato safety controls and leaves 61 false frames. C leaves all 136 false frames and cannot distinguish waveform-identical T01/T02. Consequently **Phase 2: not executed; full 39-file regression: not executed; Production Safety Gate: NOT REACHED.** No production change, subset/full safety artifact, native compilation, APK/AAB/IPA or mobile performance benchmark was warranted. Existing Q controls were reused without rerunning their native generator. The diagnostic script completed successfully; generated totals were checked against the frozen 39+18+37+42 = 136 pre-note count. Android/iOS/device runtime: **NOT TESTED**. Production runtime and memory impact: **zero**, because production is unchanged.

Segmentation, raw YIN/CMND candidate selection, confidence semantics, public ABI, Dart FFI, MusicXML, tempo, alignment and assessment are unchanged. Aubio remains excluded from production. The separate V02 E4→E3 candidate-selection failure and C-family boundary merges remain unresolved and were not used to tune this rule. **NO NEW RECORDINGS REQUIRED** for this decision. A future investigation would need an independently observable onset/intent cue or a narrowly defined recording protocol that can separate matched periodic background from a quiet intentional note; additional recordings are not requested in this task. Next, examine whether a signal-level *change detector with explicit uncertainty and latency* can be validated on independent quiet/legato events before revisiting production; do not promote the tested event/memory heuristics.
