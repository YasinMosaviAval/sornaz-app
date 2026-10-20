$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$manifest = Join-Path $projectRoot '.flutter-plugins-dependencies'
if (!(Test-Path -LiteralPath $manifest)) { throw 'Run flutter pub get first.' }
$plugins = (Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).plugins.windows
$links = Join-Path $projectRoot 'windows\flutter\ephemeral\.plugin_symlinks'
New-Item -ItemType Directory -Path $links -Force | Out-Null
foreach ($plugin in $plugins) {
    $link = Join-Path $links $plugin.name
    $target = [IO.Path]::GetFullPath($plugin.path)
    if (!(Test-Path -LiteralPath $target)) { throw "Plugin cache missing: $($plugin.name)" }
    if (Test-Path -LiteralPath $link) {
        $existing = Get-Item -LiteralPath $link -Force
        if (!$existing.LinkType) { throw "Plugin path is not a link: $link" }
        if ([IO.Path]::GetFullPath($existing.Target[0]).TrimEnd('\') -ne $target.TrimEnd('\')) {
            throw "Plugin link targets an old cache; review it before replacing: $link"
        }
        continue
    }
    # Directory junctions work without Administrator/Developer Mode. Flutter
    # accepts existing directory links; no machine-wide setting is changed.
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}
