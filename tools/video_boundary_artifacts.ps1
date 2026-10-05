param([string]$Workspace = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $Workspace
$culture = [Globalization.CultureInfo]::InvariantCulture
function Csv($name, $rows) { $rows | Export-Csv -LiteralPath $name -NoTypeInformation -Encoding UTF8 }
$cases = @(
  @{id='V01';file='01.mp4';duration=6.90;frames=207;fps='30/1';note='F4';midi='65';expected='65';gt=1},
  @{id='V02';file='02.mp4';duration=5.60;frames=162;fps='28.95 average; 30 nominal';note='E4';midi='64';expected='64';gt=1},
  @{id='V03';file='03.mp4';duration=7.20;frames=210;fps='29.18 average; 30 nominal';note='F4>F4';midi='65>65';expected='65>65';gt=2},
  @{id='V04';file='04.mp4';duration=5.31;frames=159;fps='29.97 average; 30 nominal';note='F4>E4';midi='65>64';expected='65>64';gt=2}
)
$pts = @{}; $manifest = @()
foreach ($c in $cases) {
  $p = @{}
  foreach ($line in [IO.File]::ReadLines((Join-Path (Get-Location) ".video_boundary_tmp/$($c.id)-showinfo.txt"))) {
    if ($line -match 'showinfo.*\bn:\s*(\d+).*\bpts_time:\s*([0-9.]+)') { $p[[int]$Matches[1]] = [double]::Parse($Matches[2],$culture) }
  }
  $pts[$c.id]=$p
  $deltas = @(); for($i=1;$i -lt $c.frames;$i++){if($p.ContainsKey($i) -and $p.ContainsKey($i-1)){$deltas += $p[$i]-$p[$i-1]}}
  $min=($deltas | Measure-Object -Minimum).Minimum; $max=($deltas | Measure-Object -Maximum).Maximum
  $manifest += [pscustomobject]@{case_id=$c.id;video_file=$c.file;container='MP4';duration_seconds=$c.duration;video_codec='H.264';video_width=1280;video_height=720;nominal_fps=30;average_fps=$c.fps;decoded_video_frames=$c.frames;first_video_pts=0;last_video_pts=$p[$c.frames-1];min_frame_step_seconds=$min;max_frame_step_seconds=$max;vfr_observed=($max-$min -gt .002);audio_codec='AAC-LC';audio_sample_rate=48000;audio_channels=2;audio_start_pts_seconds=0;mapping=$c.note;source_present=$true}
}
Csv 'video_boundary_input_manifest.csv' $manifest
$events = @(
  @('V01',1,'F4',65,'key_down',51,56,'medium','finger moves onto target key; depression obscured'),
  @('V01',2,'F4',65,'key_up',90,128,'low','finger remains over key; exact release obscured'),
  @('V02',1,'E4',64,'key_down',50,57,'medium','visible finger movement onto target key'),
  @('V02',2,'E4',64,'key_up',107,135,'low','release obscured by hand'),
  @('V03',1,'F4',65,'key_down',43,54,'medium','first downward articulation visible'),
  @('V03',2,'F4',65,'key_up',78,93,'low','first articulation releases before second movement'),
  @('V03',3,'F4',65,'key_down',92,101,'medium','second downward articulation visible'),
  @('V03',4,'F4',65,'key_up',133,160,'low','second release partially occluded'),
  @('V04',1,'F4',65,'key_down',48,57,'medium','first finger movement visible'),
  @('V04',2,'E4',64,'key_down',69,77,'medium','second finger movement while first held'),
  @('V04',3,'F4',65,'key_up',70,86,'low','legato overlap; release occluded'),
  @('V04',4,'E4',64,'key_up',101,129,'low','final release obscured by hand')
)
$gt = foreach($e in $events){
  $p=$pts[$e[0]]; $lo=[int]$e[5];$hi=[int]$e[6];$mid=[int][math]::Floor(($lo+$hi)/2)
  [pscustomobject]@{case_id=$e[0];video_file=(($cases|Where-Object id -eq $e[0]).file);event_index=$e[1];note=$e[2];midi=$e[3];event_type=$e[4];video_frame_index=$mid;video_timestamp_seconds=$p[$mid];earliest_seconds=$p[$lo];latest_seconds=$p[$hi];temporal_resolution_seconds=(($manifest|Where-Object case_id -eq $e[0]).max_frame_step_seconds);annotation_confidence=$e[7];annotation_method="visual frame inspection; $($e[8])"}
}
Csv 'video_boundary_ground_truth.csv' $gt
$expected = foreach($c in $cases){$notes=$c.expected.Split('>'); for($i=0;$i -lt $notes.Count;$i++){[pscustomobject]@{case_id=$c.id;note_index=$i+1;expected_midi=$notes[$i];expected_note=if($notes[$i] -eq 65){'F4'}else{'E4'};expected_count=$c.gt;label_source='user musical mapping; evaluation only'}}}
Csv 'video_expected_notes.csv' $expected
$extraction=Import-Csv 'video_audio_extraction.csv';$sync=foreach($c in $cases){$a=$extraction|Where-Object case_id -eq $c.id;[pscustomobject]@{case_id=$c.id;video_first_pts=0;audio_stream_start_pts=0;extraction_trim='none';arbitrary_offset_seconds=0;decoded_audio_duration_seconds=[math]::Round(([double]$a.decoded_source_frames/48000),6);video_duration_seconds=$c.duration;duration_difference_seconds=[math]::Round(([double]$a.decoded_source_frames/48000)-$c.duration,6);common_mp4_timeline='yes';hardware_av_latency='not independently measured';sync_status='container PTS consistent; subframe physical-to-acoustic delay unknown'}}
Csv 'video_audio_sync_verification.csv' $sync
$segments=Import-Csv 'video_segmentation_baseline.csv';$raw=Import-Csv 'video_boundary_raw_features.csv'
$errors=foreach($c in $cases){
  $s=@($segments|Where-Object case_id -eq $c.id);$g=@($gt|Where-Object case_id -eq $c.id)
  $core=@(if($c.id -eq 'V01'){$s|Where-Object rounded_midi -eq '65'|Where-Object {[double]$_.duration_seconds -gt .5}}elseif($c.id -eq 'V02'){$s|Where-Object rounded_midi -eq '52'|Where-Object {[double]$_.duration_seconds -gt .5}}elseif($c.id -eq 'V03'){$s|Where-Object rounded_midi -eq '65'|Where-Object {[double]$_.duration_seconds -gt .5}}else{$s|Where-Object {($_.rounded_midi -eq '65' -or $_.rounded_midi -eq '64') -and [double]$_.duration_seconds -gt .4}})
  [pscustomobject]@{case_id=$c.id;expected_count=$c.gt;detected_total=$s.Count;dominant_musical_segments=$core.Count;dominant_sequence=($core.rounded_midi -join '>');expected_sequence=$c.expected;spurious_or_fragment_segments=$s.Count-$core.Count;key_down_interval_seconds=(($g|Where-Object event_type -eq 'key_down'|ForEach-Object {"$($_.earliest_seconds)-$($_.latest_seconds)"}) -join ';');main_segment_starts=(($core|ForEach-Object {$_.start_seconds}) -join ';');main_segment_ends=(($core|ForEach-Object {$_.end_seconds}) -join ';');primary_attribution=if($c.id -eq 'V02'){'RAW_DSP octave-down stable'}else{'RAW_DSP spurious pitch plus SEGMENTATION accepts voiced artifacts'};note='Key-up intervals are low-confidence; acoustic decay may legitimately continue after release.'}
}
Csv 'video_boundary_error_analysis.csv' $errors
$evidence=foreach($g in $gt){
 $near=@($raw|Where-Object {$_.case_id -eq $g.case_id -and [double]$_.timestamp_seconds -ge [double]$g.earliest_seconds-.12 -and [double]$_.timestamp_seconds -le [double]$g.latest_seconds+.12});
 $voiced=@($near|Where-Object {[double]$_.pitch_hz -gt 0 -and [double]$_.confidence -ge .55 -and [double]$_.rms -gt .001 -and $_.is_silent -eq '0'});
 [pscustomobject]@{case_id=$g.case_id;event_index=$g.event_index;event_type=$g.event_type;event_interval_start=$g.earliest_seconds;event_interval_end=$g.latest_seconds;nearby_feature_count=$near.Count;voiced_feature_count=$voiced.Count;median_midi=if($voiced.Count){$m=@($voiced|ForEach-Object {[math]::Round(69+12*[math]::Log([double]$_.pitch_hz/440,2),2)}|Sort-Object);$m[[int][math]::Floor($m.Count/2)]}else{$null};max_onset_strength=if($near.Count){($near|Measure-Object onset_strength -Maximum).Maximum}else{$null};onset_candidate_count=@($near|Where-Object onset_candidate -eq '1').Count;max_rms=if($near.Count){($near|Measure-Object rms -Maximum).Maximum}else{$null};independent_boundary_precision='video-frame interval only'}
}
Csv 'video_boundary_evidence.csv' $evidence
