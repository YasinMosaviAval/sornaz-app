param(
  [Parameter(Mandatory=$true)][string]$InputDirectory,
  [Parameter(Mandatory=$true)][string]$FfmpegPath,
  [string]$OutputDirectory = '.video_boundary_tmp'
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
for ($i=1; $i -le 4; $i++) {
  $number = '{0:D2}' -f $i
  $id = 'V' + $number
  $source = Join-Path $InputDirectory ($number + '.mp4')
  if (-not (Test-Path -LiteralPath $source)) { throw "Missing video $number" }
  $pcm = Join-Path $OutputDirectory ($id + '.s16le')
  $trace = Join-Path $OutputDirectory ($id + '-showinfo.txt')
  # Decode the original audio track without a timestamp-changing trim/filter.
  & $FfmpegPath -hide_banner -loglevel error -y -i $source -map 0:a:0 -acodec pcm_s16le -ar 48000 -ac 2 -f s16le $pcm
  if ($LASTEXITCODE -ne 0) { throw "Audio extraction failed for $id" }
  # Preserve actual decoded video PTS for interval-based visual annotation.
  & $FfmpegPath -hide_banner -i $source -map 0:v:0 -vf showinfo -an -f null NUL 2> $trace
  if ($LASTEXITCODE -ne 0) { throw "Video PTS extraction failed for $id" }
}
