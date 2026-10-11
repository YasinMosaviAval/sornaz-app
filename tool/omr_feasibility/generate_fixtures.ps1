param(
  [string]$ChromeExe = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
  [string]$DartExe = 'dart'
)

$html = (Join-Path $PSScriptRoot 'render_fixtures.html') -replace '\\','/'
$uri = "file:///$html"
foreach ($case in @('treble','bass','rhythm','accidentals','piano','chords','multi','invalid')) {
  $destination = Join-Path $PSScriptRoot "$case.png"
  $started = Get-Date
  $profile = Join-Path $env:TEMP "sornaz-omr-fixture-$case"
  & $ChromeExe --headless --no-sandbox --disable-gpu --disable-extensions `
    --hide-scrollbars "--user-data-dir=$profile" --window-size=1200,420 `
    "--screenshot=$destination" "$uri`?case=$case" 2>$null
  $ready = $false
  for ($attempt = 0; $attempt -lt 80; $attempt++) {
    $item = Get-Item -LiteralPath $destination -ErrorAction SilentlyContinue
    if ($item -and $item.LastWriteTime -ge $started.AddSeconds(-1) -and $item.Length -gt 1000) {
      $ready = $true
      break
    }
    Start-Sleep -Milliseconds 250
  }
  if (-not $ready) { throw "Chrome did not create $destination" }
  Write-Output "$case $($item.Length) bytes"
}
Push-Location $PSScriptRoot
try {
  & $DartExe generate_skew_fixture.dart
  if ($LASTEXITCODE -ne 0) { throw "Dart skew generator failed: $LASTEXITCODE" }
} finally { Pop-Location }
