param(
    [string]$Flutter = 'flutter',
    [ValidateSet('android-arm', 'android-arm64', 'android-x64')]
    [string[]]$TargetPlatform = @('android-arm64'),
    [string]$BuildNumber,
    [ValidateRange(1, 1024)]
    [int]$MinimumFreeSpaceGB = 2
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent

function Assert-BuildFreeSpace {
    param([string]$Path, [string]$Purpose)

    $fullPath = [IO.Path]::GetFullPath($Path)
    $volumeRoot = [IO.Path]::GetPathRoot($fullPath)
    try {
        $availableBytes = ([IO.DriveInfo]::new($volumeRoot)).AvailableFreeSpace
    } catch {
        throw "Cannot check free disk space for $Purpose at '$fullPath'. $($_.Exception.Message)"
    }
    if ($availableBytes -lt ($MinimumFreeSpaceGB * 1GB)) {
        throw ("Not enough free disk space for {0} on {1}: {2:N2} GB available; at least {3} GB required. Path: '{4}'. Free space on this volume before retrying; no files were deleted." -f $Purpose, $volumeRoot, ($availableBytes / 1GB), $MinimumFreeSpaceGB, $fullPath)
    }
}

# Prefer this machine's transferred environment when no SDK was explicitly selected.
$offlineActivation = Join-Path $projectRoot '20261022-windows-offline-kit/runtime/Activate-Offline.ps1'
$activateOfflineKit = !$PSBoundParameters.ContainsKey('Flutter') -and (Test-Path -LiteralPath $offlineActivation)
if ($activateOfflineKit) {
    $gradleCachePath = Join-Path (Split-Path $offlineActivation -Parent) 'caches/gradle'
} elseif (![string]::IsNullOrWhiteSpace($env:GRADLE_USER_HOME)) {
    $gradleCachePath = $env:GRADLE_USER_HOME
    if (![IO.Path]::IsPathRooted($gradleCachePath)) {
        $gradleCachePath = Join-Path (Join-Path $projectRoot 'android') $gradleCachePath
    }
} else {
    $gradleCachePath = Join-Path $env:USERPROFILE '.gradle'
}
# Fail before activation, package resolution or Gradle can write to a full volume.
Assert-BuildFreeSpace -Path $projectRoot -Purpose 'project output'
Assert-BuildFreeSpace -Path $gradleCachePath -Purpose 'Gradle cache'
if ($activateOfflineKit) {
    . $offlineActivation -Project $projectRoot
}
$Flutter = (Get-Command $Flutter -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$previousOffline = $env:SORNAZ_GRADLE_OFFLINE
$previousCi = $env:CI
$previousWindows = $env:FLUTTER_WINDOWS
$previousLinux = $env:FLUTTER_LINUX
$previousPubHost = $env:PUB_HOSTED_URL
$previousCargoOffline = $env:CARGO_NET_OFFLINE
$previousCargoJobs = $env:CARGO_BUILD_JOBS
Push-Location $projectRoot
$buildWatch = [Diagnostics.Stopwatch]::StartNew()
$buildStage = 'offline package resolution'
try {
    $env:SORNAZ_GRADLE_OFFLINE = 'true'
    $env:CI = 'true'
    # Android builds do not need desktop plugin symlinks / Windows Developer Mode.
    $env:FLUTTER_WINDOWS = 'false'
    $env:FLUTTER_LINUX = 'false'
    # Match the repository recorded in pubspec.lock and its local cache.
    $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
    $env:CARGO_NET_OFFLINE = 'true'
    $env:CARGO_BUILD_JOBS = '1'
    # Windows PowerShell can turn harmless native stderr warnings into errors.
    # Use the process exit code to decide whether a Flutter command failed.
    $ErrorActionPreference = 'Continue'
    & $Flutter pub get --offline --enforce-lockfile
    $flutterExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($flutterExitCode -ne 0) {
        throw 'Offline package resolution failed. Prepare the locked Dart packages online first.'
    }
    Write-Host ("Offline packages ready after {0:N1}s" -f $buildWatch.Elapsed.TotalSeconds)
    $buildStage = 'native preparation'
    & (Join-Path $PSScriptRoot 'prepare_offline_native.ps1')
    & (Join-Path $PSScriptRoot 'seed_flutter_engine_maven.ps1') -Flutter $Flutter -TargetPlatform $TargetPlatform
    Write-Host ("Native dependencies ready after {0:N1}s" -f $buildWatch.Elapsed.TotalSeconds)
    $buildStage = 'Flutter/Gradle compilation and packaging'
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
} catch {
    $buildWatch.Stop()
    Write-Warning ("Offline build stopped during {0} after {1:N1}s" -f $buildStage, $buildWatch.Elapsed.TotalSeconds)
    throw
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
