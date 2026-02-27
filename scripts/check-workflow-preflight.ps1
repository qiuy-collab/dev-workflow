param(
  [string]$Root = '.',
  [string]$ConfigPath = 'agent-config.json'
)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path $Root).Path
$cfgFile = Join-Path $rootPath $ConfigPath

if (-not (Test-Path $cfgFile)) {
  throw "missing config: $cfgFile"
}

$cfg = Get-Content -Path $cfgFile -Raw -Encoding UTF8 | ConvertFrom-Json
$pre = $cfg.testing.preflight
if (-not $pre) {
  Write-Output 'preflight_not_configured=true'
  exit 0
}

$missing = @()
foreach ($rel in @($pre.requiredFilesBeforeWorkflowTests)) {
  $path = Join-Path $rootPath ([string]$rel)
  if (-not (Test-Path $path)) { $missing += [string]$rel }
}

$endpointDown = @()
foreach ($url in @($pre.requiredServiceEndpoints)) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri ([string]$url) -TimeoutSec 6
    if ([int]$resp.StatusCode -lt 200 -or [int]$resp.StatusCode -ge 400) {
      $endpointDown += ([string]$url + ' status=' + [int]$resp.StatusCode)
    }
  } catch {
    $endpointDown += ([string]$url + ' unreachable')
  }
}

$ok = ($missing.Count -eq 0) -and ($endpointDown.Count -eq 0)

$result = [ordered]@{
  timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  pass = $ok
  missing_files = $missing
  endpoint_issues = $endpointDown
  checked_files = @($pre.requiredFilesBeforeWorkflowTests)
  checked_endpoints = @($pre.requiredServiceEndpoints)
}

$outDir = Join-Path $rootPath 'output/final-delivery'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$outFile = Join-Path $outDir 'preflight-check.json'
[System.IO.File]::WriteAllText($outFile, ($result | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))

if ($ok) {
  Write-Output 'preflight_pass=true'
  Write-Output "report=$outFile"
  exit 0
}

Write-Output 'preflight_pass=false'
Write-Output ("missing_files=" + ($missing -join ','))
Write-Output ("endpoint_issues=" + ($endpointDown -join ','))
Write-Output "report=$outFile"
exit 1
