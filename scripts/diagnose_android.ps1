param(
    [string]$Serial,
    [string]$PackageId,
    [int]$CaptureSeconds = 20
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$gradle = Get-Content (Join-Path $root 'android/app/build.gradle') -Raw
if (!$PackageId) {
    $match = [regex]::Match($gradle, 'applicationId\s*=\s*"([^"]+)"')
    if (!$match.Success) { throw 'Application ID not found in android/app/build.gradle. Pass -PackageId.' }
    $PackageId = $match.Groups[1].Value
}
$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { 'C:\dev\sdk\android-sdk' }
$adb = if ($adbCommand) { $adbCommand.Source } else { Join-Path $sdk 'platform-tools/adb.exe' }
if (!(Test-Path $adb)) { throw "ADB not found. Install Android SDK Platform Tools or set ANDROID_HOME. Expected: $adb" }
$devices = @(& $adb devices -l | Select-String '^([^\s]+)\s+device\b' | ForEach-Object { $_.Matches[0].Groups[1].Value })
if (!$devices.Count) { Write-Host 'No authorized Android device connected. Enable USB debugging and accept the phone prompt.'; exit 2 }
if (!$Serial) {
    if ($devices.Count -gt 1) { Write-Host ('Devices: ' + ($devices -join ', ')); throw 'Pass -Serial to select a device.' }
    $Serial = $devices[0]
}
if ($Serial -notin $devices) { throw "Device $Serial is not connected and authorized." }
Write-Host "Device: $Serial; package: $PackageId"
$installed = & $adb -s $Serial shell pm path $PackageId
if ($LASTEXITCODE -ne 0 -or !$installed) {
    Write-Host "Application is not installed. Install with: & '$adb' -s '$Serial' install -r '<path-to-apk>'"
    exit 3
}
$started = Get-Date
$before = & $adb -s $Serial shell pidof $PackageId
$launch = & $adb -s $Serial shell monkey -p $PackageId -c android.intent.category.LAUNCHER 1 2>&1
if ($LASTEXITCODE -ne 0) { throw "Launch failed: $($launch -join ' ')" }
Start-Sleep -Seconds ([Math]::Max(1, [Math]::Min($CaptureSeconds, 120)))
$after = & $adb -s $Serial shell pidof $PackageId
$activity = & $adb -s $Serial shell dumpsys activity activities 2>&1 | Select-String -Pattern ([regex]::Escape($PackageId)) | Select-Object -First 8
$log = & $adb -s $Serial logcat -d -v threadtime -t 12000 2>&1
$selected = @($log | Where-Object { $_ -match [regex]::Escape($PackageId) -or $_ -match 'Flutter|flutter|AndroidRuntime|FATAL EXCEPTION|Dart|MissingPlugin|PlatformException|UnsatisfiedLinkError|ClassNotFoundException' })
$safe = foreach ($line in $selected) {
    $line = $line -replace '(?i)(authorization\s*[:=]\s*bearer\s+)[^\s]+', '$1[REDACTED]'
    $line = $line -replace '(?i)(token|password|secret|api[_-]?key|cookie)\s*[:=]\s*[^\s,;]+', '$1=[REDACTED]'
    $line = $line -replace '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[EMAIL]'
    $line = $line -replace 'https?://\S+', '[URL]'
    $line
}
$dir = Join-Path $root ('release_outputs/diagnostics/' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$report = Join-Path $dir 'startup.txt'
@(
    "Started: $($started.ToString('o'))"
    "Device: $Serial"
    "Package: $PackageId"
    "PID before: $before"
    "PID after: $after"
    "Process alive: $([bool]$after)"
    "Foreground activity: $($activity -join ' | ')"
    '--- filtered, redacted startup log ---'
    $safe
) | Set-Content -LiteralPath $report -Encoding UTF8
Write-Host "Report: $report"
if (!$after) { Write-Warning 'Application process is not running after launch.' }
elseif (!$safe.Count) { Write-Warning 'No matching errors found; a blocked startup still requires visual confirmation or a longer capture.' }
