$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
$staging = Join-Path $dist 'openbao-win32'
$zipPath = Join-Path $dist 'openbao-win32.zip'
$cache = Join-Path $dist '.cache'

# Pinned upstream OpenBao release. Keep in sync with service.json "version".
$openbaoVersion = '2.7.1'
$openbaoRepo = 'openbao/openbao'
$asset = "openbao_${openbaoVersion}_windows_amd64.zip"
$assetUrl = "https://github.com/$openbaoRepo/releases/download/v$openbaoVersion/$asset"

New-Item -ItemType Directory -Force -Path $dist, $cache | Out-Null
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Force -Path (Join-Path $staging 'runtime'), (Join-Path $staging 'config') | Out-Null

$archive = Join-Path $cache $asset
if (-not (Test-Path $archive)) {
  Write-Host "Downloading $assetUrl"
  Invoke-WebRequest -Uri $assetUrl -OutFile $archive
}

Expand-Archive -Path $archive -DestinationPath (Join-Path $staging 'runtime') -Force
Copy-Item -Force (Join-Path $root 'config' 'example.env') (Join-Path $staging 'config' 'example.env')

if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath
Write-Host "Created $zipPath"
