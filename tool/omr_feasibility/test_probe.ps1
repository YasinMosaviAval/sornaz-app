param([string]$DartExe = 'dart')

$probePath = Join-Path $PSScriptRoot 'printed_score_probe.dart'
$imagePath = Join-Path $PSScriptRoot 'scale.png'
$expectedPath = Join-Path $PSScriptRoot 'scale.expected.json'
$outputText = & $DartExe $probePath $imagePath | Out-String
if ($LASTEXITCODE -ne 0) { throw "Probe failed with exit code $LASTEXITCODE" }
$actual = $outputText | ConvertFrom-Json
$expected = Get-Content -LiteralPath $expectedPath -Raw | ConvertFrom-Json
$actualMidi = @($actual.staffs[0].notes | ForEach-Object { $_.midi })
if ($actual.staffCount -ne 1) { throw "Expected one staff, got $($actual.staffCount)" }
if (($actualMidi -join ',') -ne ($expected.midi -join ',')) {
  throw "Pitch mismatch: $($actualMidi -join ',')"
}
if (@($actual.staffs[0].barlines).Count -ne $expected.measures) {
  throw 'Measure boundary count mismatch'
}
Write-Output "PASS: one staff; $($actualMidi.Count) conditional treble pitches; $($actual.staffs[0].barlines.Count) barlines"
