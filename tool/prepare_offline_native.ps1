$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$configFile = Join-Path $projectRoot '.dart_tool\package_config.json'
$config = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
$package = $config.packages | Where-Object name -EQ 'metadata_god'
if (!$package) { return }
$configUri = [Uri]::new($configFile)
$packageUri = [Uri]::new($configUri, [string]$package.rootUri)
$runner = Join-Path $packageUri.LocalPath 'cargokit\run_build_tool.cmd'
if (!(Test-Path -LiteralPath $runner)) { return }
$source = [IO.File]::ReadAllText($runner)
if ($source.Contains('SORNAZ_PUB_ARGS')) { return }
if (!$source.Contains('pub get --no-precompile')) {
    throw 'Cargokit launcher changed; review its offline package resolution before building.'
}
# Cargokit starts its own Dart package resolver, independently of flutter --no-pub.
# Preserve online behavior, and honor the same explicit offline switch as Gradle.
$setup = "setlocal ENABLEDELAYEDEXPANSION`r`nset `"SORNAZ_PUB_ARGS=`"`r`nif /I `"%SORNAZ_GRADLE_OFFLINE%`"==`"true`" set `"SORNAZ_PUB_ARGS=--offline`""
$source = $source.Replace('setlocal ENABLEDELAYEDEXPANSION', $setup)
$source = $source.Replace('pub get --no-precompile', 'pub get --no-precompile %SORNAZ_PUB_ARGS%')
[IO.File]::WriteAllText($runner, $source, [Text.UTF8Encoding]::new($false))
Write-Host 'Prepared the local Cargokit launcher for offline package resolution.'
