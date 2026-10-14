$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$dist = Join-Path $root 'dist'
$staging = Join-Path $dist 'openbao-win32'
$runtimeDir = Join-Path $staging 'runtime'
$binary = Join-Path $runtimeDir 'bao.exe'

if (-not (Test-Path $binary)) {
  throw "OpenBao runtime not found at $binary; run scripts/package.ps1 first"
}

$port = if ($env:OPENBAO_E2E_PORT) { [int]$env:OPENBAO_E2E_PORT } else { 18200 }

# Materialize the server config from the canonical service.json config.files block.
$service = Get-Content (Join-Path $root 'service.json') -Raw | ConvertFrom-Json
$configContent = $service.config.files[0].content -replace '\$\{SERVICE_PORT\}', "$port"
$configPath = Join-Path $runtimeDir 'openbao.hcl'
Set-Content -Path $configPath -Value $configContent -Encoding utf8
New-Item -ItemType Directory -Force -Path (Join-Path $runtimeDir 'data') | Out-Null

$stdout = Join-Path $dist 'e2e-openbao.out'
$stderr = Join-Path $dist 'e2e-openbao.err'
$proc = Start-Process -FilePath $binary -ArgumentList 'server', "-config=$configPath" -WorkingDirectory $runtimeDir -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr

try {
  $reachable = $false
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 500
    try {
      $response = Invoke-WebRequest -Uri "http://127.0.0.1:$port/v1/sys/health" -UseBasicParsing -TimeoutSec 2
      $status = $response.StatusCode
      $reachable = $true
      break
    } catch {
      if ($_.Exception.Response) {
        $status = [int]$_.Exception.Response.StatusCode
        $reachable = $true
        break
      }
    }
  }
  if (-not $reachable) {
    Get-Content $stderr -ErrorAction SilentlyContinue | Select-Object -Last 20
    throw "OpenBao API did not become reachable on port $port"
  }
  # A freshly started (non-dev) node is sealed/uninitialized, so 501/503 is the expected healthy API response.
  if ($status -notin @(200, 429, 501, 503)) {
    throw "Unexpected OpenBao health status: $status"
  }
  Write-Host "OpenBao runtime e2e passed: packaged server started and served /v1/sys/health (status $status) on port $port"
}
finally {
  if (-not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
    $proc.WaitForExit()
  }
}
