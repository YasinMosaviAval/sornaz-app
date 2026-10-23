param(
    [ValidateSet('All','Arm64','Universal','Bundle','BundleArm64','Debug')]
    [string]$Mode = 'Arm64',
    [switch]$Offline
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$branch = (& git -C $root branch --show-current).Trim()
if ($branch -ne 'release/google-play-v1') { throw "Refusing to build outside release/google-play-v1 (current: $branch)." }
$commit = (& git -C $root rev-parse HEAD).Trim()
$flutterCommand = Get-Command flutter -CommandType Application -ErrorAction Stop | Select-Object -First 1
$flutter = $flutterCommand.Source
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { 'C:\dev\sdk\android-sdk' }
if (!(Test-Path (Join-Path $sdk 'platform-tools/adb.exe'))) { throw "Android SDK not found at $sdk. Set ANDROID_HOME." }
if (!(Test-Path (Join-Path $root 'pubspec.lock'))) { throw 'pubspec.lock is missing.' }
if (!(Test-Path (Join-Path $root '.dart_tool/package_config.json'))) { throw 'Package cache is not prepared. Run flutter pub get --enforce-lockfile once online.' }
$lockHash = (Get-FileHash (Join-Path $root 'pubspec.lock') -Algorithm SHA256).Hash
$pubspec = Get-Content (Join-Path $root 'pubspec.yaml') -Raw
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([^+\s]+)\+(\d+)')
if (!$versionMatch.Success) { throw 'Version name/code not found in pubspec.yaml.' }
$versionName = $versionMatch.Groups[1].Value
$versionCode = [int]$versionMatch.Groups[2].Value
$gradle = Get-Content (Join-Path $root 'android/app/build.gradle') -Raw
$appIdMatch = [regex]::Match($gradle, 'applicationId\s*=\s*"([^"]+)"')
if (!$appIdMatch.Success) { throw 'Application ID not found.' }
$appId = $appIdMatch.Groups[1].Value
$runId = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + ([guid]::NewGuid().ToString('N').Substring(0,6))
$outDir = Join-Path $root "release_outputs/$versionName+$versionCode/$runId"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$logPath = Join-Path $outDir 'build.log'
$reportPath = Join-Path $outDir 'build-report.json'
$started = Get-Date
$previous = @{}
foreach ($name in @('SORNAZ_GRADLE_OFFLINE','CARGO_NET_OFFLINE','CARGO_BUILD_JOBS','FLUTTER_WINDOWS','FLUTTER_LINUX','CI','PUB_HOSTED_URL')) {
    $previous[$name] = [Environment]::GetEnvironmentVariable($name,'Process')
}
$artifacts = [Collections.Generic.List[object]]::new()
$status = 'failed'
$failure = $null
function Invoke-BuildStep([string[]]$Arguments, [string[]]$Names) {
    $stepStart = Get-Date
    Write-Host ('Running: flutter ' + ($Arguments -join ' '))
    # Windows PowerShell represents native stderr warnings as ErrorRecord objects.
    $ErrorActionPreference = 'Continue'
    & $script:flutter @Arguments 2>&1 | ForEach-Object {
        $line = if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { $_.ToString() }
        Add-Content -LiteralPath $script:logPath -Value $line
        Write-Host $line
    }
    if ($LASTEXITCODE -ne 0) {
        $missing = Select-String -LiteralPath $script:logPath -Pattern 'No cached version of ([^ ]+)' -AllMatches | ForEach-Object { $_.Matches | ForEach-Object { $_.Groups[1].Value } } | Select-Object -Unique -First 8
        if ($missing) { throw "Offline cache is incomplete: $($missing -join ', '). Populate these Gradle dependencies once online, then retry. Full log: $script:logPath" }
        throw "Flutter exited $LASTEXITCODE while running: $($Arguments -join ' '). See $script:logPath"
    }
    foreach ($name in $Names) {
        $path = if ($name.EndsWith('.aab')) { Join-Path $script:root "build/app/outputs/bundle/release/$name" } else { Join-Path $script:root "build/app/outputs/flutter-apk/$name" }
        if (!(Test-Path $path)) { throw "Build succeeded but artifact is missing: $path" }
        if ($script:Mode -eq 'BundleArm64' -and $name.EndsWith('.aab')) {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zip = [IO.Compression.ZipFile]::OpenRead($path)
            try {
                $abis = @($zip.Entries | Where-Object { $_.FullName -match '^base/lib/([^/]+)/' } | ForEach-Object { ($_.FullName -split '/')[2] } | Sort-Object -Unique)
                if ($abis.Count -ne 1 -or $abis[0] -ne 'arm64-v8a') { throw ('ARM64-only bundle contains unexpected ABIs: ' + ($abis -join ', ')) }
            } finally { $zip.Dispose() }
        }
        $source = Get-Item $path
        $fresh = $source.LastWriteTime -ge $stepStart.AddSeconds(-2)
        if (!$fresh) { Write-Warning "Gradle reused an existing artifact; this file was not newly produced: $path" }
        $destination = Join-Path $script:outDir $name
        if (Test-Path $destination) { throw "Refusing to overwrite: $destination" }
        Copy-Item -LiteralPath $path -Destination $destination
        $copy = Get-Item $destination
        $cert = $null
        if ($name.EndsWith('.apk')) {
            $apksigner = Get-ChildItem (Join-Path $script:sdk 'build-tools') -Filter apksigner.bat -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
            if ($apksigner) {
                $verify = & $apksigner.FullName verify --print-certs $destination 2>&1
                if ($LASTEXITCODE -eq 0) { $cert = ($verify | Select-String 'Signer #1 certificate SHA-256 digest' | Select-Object -First 1).Line }
            }
        }
        $script:artifacts.Add([ordered]@{ type=$name; path=$copy.FullName; bytes=$copy.Length; sha256=(Get-FileHash $copy.FullName -Algorithm SHA256).Hash; signedCertificate=$cert; producedUtc=$source.LastWriteTimeUtc.ToString('o'); producedThisRun=$fresh })
        Write-Host ("Artifact: {0} ({1:N2} MiB)" -f $copy.FullName, ($copy.Length / 1MB))
    }
}
Push-Location $root
try {
    "Build started: $($started.ToString('o')); mode=$Mode; offline=$Offline" | Set-Content -LiteralPath $logPath -Encoding UTF8
    $env:FLUTTER_WINDOWS = 'false'; $env:FLUTTER_LINUX = 'false'; $env:CI = 'true'
    if ($Offline) {
        $env:SORNAZ_GRADLE_OFFLINE = 'true'; $env:CARGO_NET_OFFLINE = 'true'; $env:CARGO_BUILD_JOBS = '2'
        $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
        # Local native preparation and Flutter-engine Maven seed are required by this repository.
        & (Join-Path $root 'tool/prepare_offline_native.ps1')
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Offline native preparation failed.' }
        $platforms = if ($Mode -in @('Arm64','BundleArm64')) { @('android-arm64') } else { @('android-arm','android-arm64','android-x64') }
        & (Join-Path $root 'tool/seed_flutter_engine_maven.ps1') -Flutter $flutter -TargetPlatform $platforms
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Flutter engine cache preparation failed.' }
    }
    if ($Mode -in @('All','Universal')) { Invoke-BuildStep @('build','apk','--release','--no-pub') @('app-release.apk') }
    if ($Mode -eq 'Arm64') { Invoke-BuildStep @('build','apk','--release','--split-per-abi','--target-platform','android-arm64','--no-pub') @('app-arm64-v8a-release.apk') }
    if ($Mode -eq 'All') { Invoke-BuildStep @('build','apk','--release','--split-per-abi','--no-pub') @('app-armeabi-v7a-release.apk','app-arm64-v8a-release.apk','app-x86_64-release.apk') }
    if ($Mode -in @('All','Bundle')) { Invoke-BuildStep @('build','appbundle','--release','--no-pub') @('app-release.aab') }
    if ($Mode -eq 'BundleArm64') { Invoke-BuildStep @('build','appbundle','--release','--target-platform','android-arm64','--android-project-arg=sornaz-arm64-only=true','--android-project-arg=disable-abi-filtering=true','--no-pub') @('app-release.aab') }
    if ($Mode -eq 'Debug') { Invoke-BuildStep @('build','apk','--debug','--no-pub') @('app-debug.apk') }
    if ((Get-FileHash (Join-Path $root 'pubspec.lock') -Algorithm SHA256).Hash -ne $lockHash) { throw 'pubspec.lock changed unexpectedly.' }
    $status = 'success'
} catch {
    $failure = $_.Exception.Message
    Add-Content -LiteralPath $logPath -Value "ERROR: $failure"
    Write-Warning $failure
} finally {
    $report = [ordered]@{ status=$status; error=$failure; started=$started.ToString('o'); ended=(Get-Date).ToString('o'); elapsedSeconds=[math]::Round(((Get-Date)-$started).TotalSeconds,2); mode=$Mode; offline=[bool]$Offline; branch=$branch; commit=$commit; applicationId=$appId; versionName=$versionName; versionCode=$versionCode; artifacts=@($artifacts) }
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    foreach ($name in $previous.Keys) { [Environment]::SetEnvironmentVariable($name,$previous[$name],'Process') }
    Pop-Location
    Write-Host "Build report: $reportPath"
}
if ($status -ne 'success') { exit 1 }
