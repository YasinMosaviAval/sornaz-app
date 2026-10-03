param([string]$Flutter = 'flutter')

$ErrorActionPreference = 'Stop'
$flutterCommand = (Get-Command $Flutter -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$flutterRoot = Split-Path (Split-Path $flutterCommand -Parent) -Parent
$revision = [IO.File]::ReadAllText((Join-Path $flutterRoot 'bin/internal/engine.version')).Trim()
if ($revision -notmatch '^[0-9a-f]{40}$') { throw 'Invalid Flutter engine revision.' }
$repository = Join-Path (Split-Path $PSScriptRoot -Parent) 'android/offline-maven/io/flutter'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($item in @(
    @{ artifact = 'armeabi_v7a_release'; folder = 'android-arm-release'; abi = 'armeabi-v7a' },
    @{ artifact = 'arm64_v8a_release'; folder = 'android-arm64-release'; abi = 'arm64-v8a' },
    @{ artifact = 'x86_64_release'; folder = 'android-x64-release'; abi = 'x86_64' }
)) {
    $source = Join-Path $flutterRoot ('bin/cache/artifacts/engine/' + $item.folder + '/flutter.jar')
    if (!(Test-Path -LiteralPath $source)) { throw "Missing Flutter SDK artifact: $source" }
    $version = '1.0.0-' + $revision
    $destination = Join-Path $repository ($item.artifact + '/' + $version)
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $jar = Join-Path $destination ($item.artifact + '-' + $version + '.jar')
    $nativePath = 'lib/' + $item.abi + '/libflutter.so'
    $seed = !(Test-Path -LiteralPath $jar)
    if (!$seed) {
        $existing = [IO.Compression.ZipFile]::OpenRead($jar)
        try {
            $seed = $existing.Entries.Count -ne 1 -or $existing.Entries[0].FullName -ne $nativePath
        } finally { $existing.Dispose() }
    }
    if ($seed) {
        $inputZip = [IO.Compression.ZipFile]::OpenRead($source)
        $temporary = $jar + '.tmp'
        try {
            $native = $inputZip.GetEntry($nativePath)
            if (!$native) { throw "Flutter SDK JAR has no $nativePath" }
            if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
            $outputZip = [IO.Compression.ZipFile]::Open($temporary, [IO.Compression.ZipArchiveMode]::Create)
            try {
                $entry = $outputZip.CreateEntry($nativePath, [IO.Compression.CompressionLevel]::NoCompression)
                $inputStream = $native.Open()
                $outputStream = $entry.Open()
                try { $inputStream.CopyTo($outputStream) }
                finally { $outputStream.Dispose(); $inputStream.Dispose() }
            } finally { $outputZip.Dispose() }
            Move-Item -LiteralPath $temporary -Destination $jar -Force
        } finally { $inputZip.Dispose() }
    }
    $pom = Join-Path $destination ($item.artifact + '-' + $version + '.pom')
    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>io.flutter</groupId>
  <artifactId>$($item.artifact)</artifactId>
  <version>$version</version>
  <packaging>jar</packaging>
</project>
"@
    if (!(Test-Path -LiteralPath $pom)) {
        [IO.File]::WriteAllText($pom, $content, [Text.UTF8Encoding]::new($false))
    }
    Write-Host ("Cached {0}: {1} bytes, SHA256 {2}" -f $item.artifact,
        (Get-Item -LiteralPath $jar).Length,
        (Get-FileHash -LiteralPath $jar -Algorithm SHA256).Hash)
}
