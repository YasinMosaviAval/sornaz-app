param(
    [string]$Flutter = 'flutter',
    [ValidateSet('android-arm', 'android-arm64', 'android-x64')]
    [string[]]$TargetPlatform = @('android-arm', 'android-arm64', 'android-x64'),
    [string]$BuildNumber
)

$ErrorActionPreference = 'Stop'
$Flutter = (Get-Command $Flutter -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$previousOffline = $env:SORNAZ_GRADLE_OFFLINE
$previousCi = $env:CI
$previousWindows = $env:FLUTTER_WINDOWS
$previousLinux = $env:FLUTTER_LINUX
$previousPubHost = $env:PUB_HOSTED_URL
$previousCargoOffline = $env:CARGO_NET_OFFLINE
$previousCargoJobs = $env:CARGO_BUILD_JOBS
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $buildWatch = [Diagnostics.Stopwatch]::StartNew()
    $env:SORNAZ_GRADLE_OFFLINE = 'true'
    $env:CI = 'true'
    # Android builds do not need desktop plugin symlinks / Windows Developer Mode.
    $env:FLUTTER_WINDOWS = 'false'
    $env:FLUTTER_LINUX = 'false'
    # Match the repository recorded in pubspec.lock and its local cache.
    $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
    $env:CARGO_NET_OFFLINE = 'true'
    $env:CARGO_BUILD_JOBS = '2'
    # Windows PowerShell can turn harmless native stderr warnings into errors.
    # Use the process exit code to decide whether a Flutter command failed.
    $ErrorActionPreference = 'Continue'
    & $Flutter pub get --offline --enforce-lockfile
    $flutterExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($flutterExitCode -ne 0) {
        throw 'Offline package resolution failed. Prepare the locked Dart packages online first.'
    }
    & (Join-Path $PSScriptRoot 'prepare_offline_native.ps1')
    & (Join-Path $PSScriptRoot 'seed_flutter_engine_maven.ps1') -Flutter $Flutter
    $buildArguments = @('build', 'apk', '--release', '--no-pub', '--target-platform', ($TargetPlatform -join ','))
    if ($BuildNumber) { $buildArguments += @('--build-number', $BuildNumber) }
    $ErrorActionPreference = 'Continue'
    & $Flutter @buildArguments
    $flutterExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($flutterExitCode -ne 0) {
        throw 'Offline APK build failed. See the Flutter/Gradle error above.'
    }
    $artifact = Get-Item 'build\app\outputs\flutter-apk\app-release.apk'
    $buildWatch.Stop()
    Write-Host ("Offline build elapsed seconds: {0:N3}" -f $buildWatch.Elapsed.TotalSeconds)
    Write-Host ("Artifact SHA256: {0}" -f (Get-FileHash -LiteralPath $artifact.FullName -Algorithm SHA256).Hash)
    $artifact
} finally {
    $env:SORNAZ_GRADLE_OFFLINE = $previousOffline
    $env:CI = $previousCi
    $env:FLUTTER_WINDOWS = $previousWindows
    $env:FLUTTER_LINUX = $previousLinux
    $env:PUB_HOSTED_URL = $previousPubHost
    $env:CARGO_NET_OFFLINE = $previousCargoOffline
    $env:CARGO_BUILD_JOBS = $previousCargoJobs
    Pop-Location
}
