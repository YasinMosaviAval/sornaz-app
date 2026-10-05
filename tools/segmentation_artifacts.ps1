# Diagnostic score-side tables. Run after the frozen baseline and strategies.
$ErrorActionPreference = 'Stop'
$rootPath = Split-Path -Parent $PSScriptRoot
$summary = @{}; Import-Csv (Join-Path $rootPath 'segmentation_baseline_summary.csv') | ForEach-Object { $summary[$_.case_id] = $_ }
$truth = @{}; Import-Csv (Join-Path $rootPath 'segmentation_ground_truth.csv') | ForEach-Object { $truth[$_.case_id] = $_ }
$names = @{}
1..12 | ForEach-Object { $names[('N{0:d2}' -f $_)] = 'Sornaz_octave_{0:d2}.m4a' -f $_ }
1..10 | ForEach-Object { $names[('P{0:d2}' -f $_)] = 'Sornaz_{0}.m4a' -f $_ }
$labels = @('اول','دوم','سوم','چهارم','پنجم')
1..5 | ForEach-Object { $names[('C{0:d2}' -f $_)] = 'Sornaz_{0}.m4a' -f $labels[$_ - 1] }
1..8 | ForEach-Object { $names[('R{0:d2}' -f $_)] = 'Sornaz_R{0:d2}.m4a' -f $_ }
$manifest = foreach ($id in ($names.Keys | Sort-Object)) {
  [pscustomobject]@{case_id=$id;filename=$names[$id];availability='FOUND_AND_PROCESSED';canonical_sample_rate=44100;canonical_channels=1;canonical_pcm_frames=$summary[$id].pcm_frames;canonical_duration_seconds=$summary[$id].duration_seconds;raw_feature_count=$summary[$id].raw_feature_count;musical_ground_truth=$truth[$id].expected_midi;ground_truth_quality=$truth[$id].ground_truth_quality;production_scoring=$truth[$id].production_scoring}
}
$manifest | Export-Csv (Join-Path $rootPath 'segmentation_input_manifest.csv') -NoTypeInformation -Encoding utf8
$source = 'lib/screens/Notation/performed_notes.dart'
$parameters = @(
  @('canonical_sample_rate','44100','Hz','lib/screens/Notation/music_analysis_features.dart','feature time base'),
  @('feature_hop','512','samples','native/dsp_engine_open.cpp','upstream frame spacing'),
  @('feature_window','4096','samples','native/dsp_engine_open.cpp','upstream analysis window'),
  @('minimum_pitch_confidence','0.55','fraction',$source,'accepted voiced frame'),
  @('minimum_rms','>0.001','linear',$source,'accepted voiced frame'),
  @('silent_flag','false','boolean',$source,'accepted voiced frame'),
  @('positive_pitch_hz','>0','Hz',$source,'accepted voiced frame'),
  @('invalid_gap_to_close','2','frames',$source,'close active segment'),
  @('pitch_split_difference','0.8','semitones',$source,'immediate pitch boundary'),
  @('pitch_reference','confidence-weighted active mean','MIDI',$source,'pitch comparison'),
  @('minimum_note_duration','0.055','seconds',$source,'candidate emission'),
  @('minimum_accepted_frames','2','frames',$source,'candidate emission'),
  @('onset_minimum_active_age','>0.055','seconds',$source,'onset boundary gate'),
  @('onset_sample_validity','inside feature frame','boolean',$source,'onset boundary gate'),
  @('pitch_confirmation','none','frames',$source,'no pitch hysteresis'),
  @('adjacent_merge_rule','none','rule',$source,'no downstream merge'),
  @('release_envelope_rule','none','rule',$source,'no explicit release state'),
  @('native_onset_strength','>0.38','ratio','native/dsp_engine_open.cpp','upstream candidate'),
  @('native_onset_previous_rms','>0.003','linear','native/dsp_engine_open.cpp','upstream candidate'),
  @('native_onset_rms_ratio','>1.35','ratio','native/dsp_engine_open.cpp','upstream candidate'),
  @('native_onset_refractory','1323','samples','native/dsp_engine_open.cpp','upstream candidate'),
  @('native_fallback_current_rms','>=0.02','linear','native/music_analysis_dsp.cpp','upstream fallback'),
  @('native_fallback_rms_ratio','>4','ratio','native/music_analysis_dsp.cpp','upstream fallback'),
  @('native_fallback_peak','>=0.1','linear','native/music_analysis_dsp.cpp','upstream fallback'),
  @('native_silence_rms','<0.003','linear','native/dsp_engine_open.cpp','upstream silence flag')
)
$parameters | ForEach-Object { [pscustomobject]@{parameter=$_[0];current_value=$_[1];unit=$_[2];source_file=$_[3];purpose=$_[4];production_or_test_only='production'} } | Export-Csv (Join-Path $rootPath 'segmentation_current_parameters.csv') -NoTypeInformation -Encoding utf8
$lookup = @{}; Import-Csv (Join-Path $rootPath 'segmentation_strategy_comparison.csv') | ForEach-Object { $lookup["$($_.case_id):$($_.policy)"] = $_ }
$controls = [ordered]@{
  single_sustained_R01_R02_R05_R06=@('R01','R02','R05','R06');true_octave_up_R03=@('R03');true_octave_down_R04=@('R04');
  semitone_C01_C05=@('C01','C02','C03','C04','C05');repeated_N11_P07_P08=@('N11','P07','P08');short_D4_P09_P10=@('P09','P10');
  stable_pitch_jitter=@();release_independent_timing=@();silence_noise_impulse=@()
}
$policies = @('A_PRODUCTION','B_PITCH_CONFIRM_3','C_ONSET_ASSISTED','D_GAP_3','E_COMBINED')
$safety = foreach ($control in $controls.Keys) { foreach ($policy in $policies) {
  $ids = @($controls[$control]); $exact = 0
  foreach ($id in $ids) { if ($lookup["${id}:$policy"].sequence_exact -eq 'true') { $exact++ } }
  $status = if ($ids.Count -eq 0) {'NOT TESTED'} elseif ($exact -eq $ids.Count) {'PASS'} else {'FAIL'}
  [pscustomobject]@{control=$control;policy=$policy;cases=($ids -join '>');exact_sequences=$exact;total_cases=$ids.Count;status=$status;note='Musical sequence only; independent boundary timestamps unavailable'}
} }
$safety | Export-Csv (Join-Path $rootPath 'segmentation_safety_matrix.csv') -NoTypeInformation -Encoding utf8
