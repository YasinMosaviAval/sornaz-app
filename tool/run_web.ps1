param(
  [ValidateSet('chrome','firefox','server')][string]$Browser = 'chrome',
  [ValidateRange(1024,65534)][int]$Port = 8080,
  [string]$Flutter = 'A:\tools\flutter-3.47.2\flutter\bin\flutter.bat'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (!(Test-Path -LiteralPath $Flutter)) { $Flutter = (Get-Command flutter -ErrorAction Stop).Source }
$node = (Get-Command node -ErrorAction Stop).Source
if (!(Test-Path '.dart_tool/package_config.json')) {
  throw 'Dependencies are missing. Run flutter pub get --offline first.'
}
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:SORNAZ_WEB_PORT = "$Port"
$env:SORNAZ_PROXY_PORT = "$($Port + 1)"
# Match the Windows trust store without disabling TLS verification.
$certificateFile = Join-Path (Get-Location) '.dart_tool/web-preview-roots.pem'
$certificates = Get-ChildItem Cert:\CurrentUser\Root,Cert:\LocalMachine\Root
$pem = ($certificates | ForEach-Object {
 "-----BEGIN CERTIFICATE-----`n" + [Convert]::ToBase64String($_.RawData, [Base64FormattingOptions]::InsertLineBreaks) + "`n-----END CERTIFICATE-----"
}) -join "`n"
[IO.File]::WriteAllText($certificateFile, $pem, [Text.UTF8Encoding]::new($false))
$env:NODE_EXTRA_CA_CERTS = $certificateFile
$proxyScript = Join-Path $PSScriptRoot 'web_proxy.cjs'
$proxy = Start-Process -FilePath $node -ArgumentList ('"' + $proxyScript + '"') -WindowStyle Hidden -PassThru
try {
  Start-Sleep -Milliseconds 500
  if ($proxy.HasExited) { throw 'Could not start API relay. Check whether the proxy port is in use.' }
  $target = if ($Browser -eq 'chrome') { 'chrome' } else { 'web-server' }
  Write-Host "Preview: http://localhost:$Port (open this address in Firefox when requested)."
  Write-Host 'Keep this terminal open. Use r for hot reload, R for restart, q to stop.'
  $ErrorActionPreference = 'Continue'
  & $Flutter run --no-pub --no-web-resources-cdn -d $target --web-hostname localhost --web-port $Port --dart-define="Sornaz_API_BASE_URL=http://localhost:$($Port + 1)/api/sornaz/v1" --dart-define="SORNAZ_API_BASE_URL=http://localhost:$($Port + 1)/api/sornaz/v1"
  $runExitCode = $LASTEXITCODE
} finally {
  if (!$proxy.HasExited) { Stop-Process -Id $proxy.Id -ErrorAction SilentlyContinue }
}
exit $runExitCode
