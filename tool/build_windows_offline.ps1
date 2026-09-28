param(
    [string]$Flutter = 'flutter',
    [ValidateSet('Debug', 'Profile', 'Release')]
    [string]$Configuration = 'Release',
    [string]$BuildNumber
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$Flutter = (Get-Command $Flutter -CommandType Application -ErrorAction Stop |
    Select-Object -First 1).Source

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (!(Test-Path -LiteralPath $vswhere)) {
    throw 'Visual Studio 2022 with the Desktop development with C++ workload is not installed.'
}

$visualStudio = & $vswhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath
if (!$visualStudio) {
    throw 'The Visual Studio C++ x64 build tools required by Flutter were not found.'
}

$savedEnvironment = @{
    CI = $env:CI
    FLUTTER_WINDOWS = $env:FLUTTER_WINDOWS
    FLUTTER_LINUX = $env:FLUTTER_LINUX
    PUB_HOSTED_URL = $env:PUB_HOSTED_URL
    CARGO_NET_OFFLINE = $env:CARGO_NET_OFFLINE
}

Push-Location $projectRoot
try {
    $env:CI = 'true'
    $env:FLUTTER_WINDOWS = 'true'
    $env:FLUTTER_LINUX = 'false'
    $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
    $env:CARGO_NET_OFFLINE = 'true'

    $ErrorActionPreference = 'Continue'
    & $Flutter pub get --offline --enforce-lockfile
    $flutterExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($flutterExitCode -ne 0) {
        throw 'Offline package resolution failed. Populate the locked Pub cache before building.'
    }

    & (Join-Path $PSScriptRoot 'prepare_offline_native.ps1')

    $mode = $Configuration.ToLowerInvariant()
    $buildArguments = @('build', 'windows', "--$mode", '--no-pub')
    if ($BuildNumber) { $buildArguments += @('--build-number', $BuildNumber) }

    $ErrorActionPreference = 'Continue'
    & $Flutter @buildArguments
    $flutterExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($flutterExitCode -ne 0) {
        throw 'Offline Windows build failed. See the Flutter/CMake error above.'
    }

    Get-Item (Join-Path $projectRoot "build\windows\x64\runner\$mode")
} finally {
    $env:CI = $savedEnvironment.CI
    $env:FLUTTER_WINDOWS = $savedEnvironment.FLUTTER_WINDOWS
    $env:FLUTTER_LINUX = $savedEnvironment.FLUTTER_LINUX
    $env:PUB_HOSTED_URL = $savedEnvironment.PUB_HOSTED_URL
    $env:CARGO_NET_OFFLINE = $savedEnvironment.CARGO_NET_OFFLINE
    Pop-Location
}
