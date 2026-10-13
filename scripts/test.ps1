$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$serviceId = '@openbao'

$service = Get-Content (Join-Path $root 'service.json') -Raw | ConvertFrom-Json
if ($service.id -ne $serviceId) {
  throw "service.json id mismatch: expected $serviceId, got $($service.id)"
}

$contract = Get-Content (Join-Path $root 'verify\service-harness.json') -Raw | ConvertFrom-Json
if ($contract.serviceId -ne $serviceId) {
  throw "service-harness.json serviceId mismatch: expected $serviceId, got $($contract.serviceId)"
}

$binary = Join-Path $root 'dist\openbao-win32\runtime\bao.exe'
if (-not (Test-Path $binary)) {
  throw "OpenBao runtime not found at $binary; run scripts/package.ps1 first"
}

$version = (& $binary version 2>&1 | Out-String).Trim()
if ($version -notmatch 'OpenBao v') {
  throw "OpenBao runtime version check failed: $version"
}

Write-Host "Service tests passed (Windows: $serviceId, $version)"
