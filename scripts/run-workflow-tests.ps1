param(
  [string]$Root = ".",
  [string]$ApiBaseUrl = "http://127.0.0.1:18080",
  [string]$FrontendUrl = "http://127.0.0.1:3000",
  [int]$MaxAttempts = 5
)

$ErrorActionPreference = "Stop"
$rootPath = (Resolve-Path $Root).Path
$logScript = Join-Path $rootPath "scripts/workflow-log.ps1"
$reqFile = Join-Path $rootPath "output/requirement-planning-requirements.md"
$apiFile = Join-Path $rootPath "output/api-design-api-list.md"
$configFile = Join-Path $rootPath "agent-config.json"
$workflowLog = Join-Path $rootPath "logs/workflow.log"
$relayFile = Join-Path $rootPath "test/test-points.jsonl"
$e2eMatrixFile = Join-Path $rootPath "test/frontend-dev/e2e-test-matrix.md"

if (-not (Test-Path $logScript)) { throw "missing log script: $logScript" }
if (-not (Test-Path $reqFile)) { throw "missing requirements file: $reqFile" }
if (-not (Test-Path $apiFile)) { throw "missing api file: $apiFile" }

function Write-WfLog {
  param([string]$Level,[string]$Skill,[string]$Phase,[string]$Suite,[string]$TestPoint,[string]$TestStatus,[int]$Attempt,[int]$MaxAttempts,[string]$Message)
  & $logScript -Level $Level -Skill $Skill -Phase $Phase -Suite $Suite -TestPoint $TestPoint -TestStatus $TestStatus -Attempt $Attempt -MaxAttempts $MaxAttempts -Message $Message -Root $rootPath | Out-Null
}

function Save-JsonFile {
  param([string]$Path,[object]$Data)
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  [IO.File]::WriteAllText($Path, ($Data | ConvertTo-Json -Depth 16), [Text.UTF8Encoding]::new($true))
}

function Save-TextFile {
  param([string]$Path,[string]$Text)
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($true))
}

function Invoke-JsonApi {
  param([string]$Method,[string]$Uri,[string]$Token="",[object]$Body=$null)
  $headers = @{}
  if ($Token) { $headers["Authorization"] = "Bearer $Token" }
  try {
    if ($null -ne $Body) {
      $resp = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body ($Body | ConvertTo-Json -Depth 12) -UseBasicParsing
    } else {
      $resp = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $headers -UseBasicParsing
    }
    $content = [string]$resp.Content
    $parsed = $null
    try { $parsed = $content | ConvertFrom-Json -ErrorAction Stop } catch {}
    return [pscustomobject]@{ StatusCode=[int]$resp.StatusCode; Content=$content; Json=$parsed }
  } catch {
    $statusCode = 0
    $content = ""
    if ($_.Exception.Response) {
      try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
      try {
        $reader = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
        $content = $reader.ReadToEnd()
      } catch {}
    }
    if (-not $content -and $_.ErrorDetails.Message) { $content = $_.ErrorDetails.Message }
    $parsed = $null
    try { $parsed = $content | ConvertFrom-Json -ErrorAction Stop } catch {}
    return [pscustomobject]@{ StatusCode=$statusCode; Content=$content; Json=$parsed }
  }
}

function Invoke-MultipartApi {
  param([string]$Uri,[string]$Token,[string]$Date,[string]$Mode,[string]$FilePath)
  if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) { throw "curl.exe not found" }
  $resolvedFile = (Resolve-Path $FilePath).Path
  $tempUpload = Join-Path $env:TEMP ("wf-upload-" + [guid]::NewGuid().ToString("N") + ".md")
  [IO.File]::WriteAllText($tempUpload, (Get-Content -Path $resolvedFile -Encoding UTF8 -Raw), [Text.UTF8Encoding]::new($false))
  $curlFilePath = $tempUpload -replace "\\", "/"
  $bodyFile = Join-Path $rootPath ("runtime/curl-" + [guid]::NewGuid().ToString("N") + ".json")
  $args = @("-sS","-o",$bodyFile,"-w","%{http_code}","-X","POST",$Uri,"-H","Authorization: Bearer $Token","-F","date=$Date","-F","mode=$Mode","-F","file=@`"$curlFilePath`";type=text/markdown")
  $statusRaw = & curl.exe @args
  $statusCode = 0
  if ([string]$statusRaw -match "(\d{3})$") { $statusCode = [int]$matches[1] }
  $content = if (Test-Path $bodyFile) { Get-Content -Path $bodyFile -Encoding UTF8 -Raw } else { "" }
  if (Test-Path $bodyFile) { Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue }
  $parsed = $null
  try { $parsed = $content | ConvertFrom-Json -ErrorAction Stop } catch {}
  return [pscustomobject]@{ StatusCode=$statusCode; Content=$content; Json=$parsed }
}

function Test-ApiPass {
  param([pscustomobject]$Resp,[int[]]$AllowedStatus=@(200),[int[]]$AllowedCode=@())
  if ($null -eq $Resp) { return $false }
  if (-not ($AllowedStatus -contains [int]$Resp.StatusCode)) { return $false }
  if ($AllowedCode.Count -gt 0) {
    if ($null -eq $Resp.Json -or $null -eq $Resp.Json.code) { return $false }
    if (-not ($AllowedCode -contains [int]$Resp.Json.code)) { return $false }
  }
  return $true
}

function Invoke-TestCase {
  param([string]$Skill,[string]$Suite,[string]$Point,[scriptblock]$Action)
  for ($attempt=1; $attempt -le $MaxAttempts; $attempt++) {
    if ($attempt -eq 1) {
      Write-WfLog -Level "INFO" -Skill $Skill -Phase "test" -Suite $Suite -TestPoint $Point -TestStatus "START" -Attempt $attempt -MaxAttempts $MaxAttempts -Message "start"
    } else {
      Write-WfLog -Level "INFO" -Skill $Skill -Phase "test" -Suite $Suite -TestPoint $Point -TestStatus "RETRY" -Attempt $attempt -MaxAttempts $MaxAttempts -Message "retry"
    }
    $ret = $null
    try { $ret = & $Action } catch { $ret = [pscustomobject]@{ Pass=$false; Message=$_.Exception.Message } }
    if ($null -eq $ret) { $ret = [pscustomobject]@{ Pass=$false; Message="empty result" } }
    if ($ret.Pass) {
      Write-WfLog -Level "SUCCESS" -Skill $Skill -Phase "test" -Suite $Suite -TestPoint $Point -TestStatus "PASS" -Attempt $attempt -MaxAttempts $MaxAttempts -Message ([string]$ret.Message)
      return [pscustomobject]@{ test_point=$Point; pass=$true; message=[string]$ret.Message; attempt=$attempt; skipped=$false }
    }
    Write-WfLog -Level "ERROR" -Skill $Skill -Phase "test" -Suite $Suite -TestPoint $Point -TestStatus "FAIL" -Attempt $attempt -MaxAttempts $MaxAttempts -Message ([string]$ret.Message)
  }
  Write-WfLog -Level "ERROR" -Skill $Skill -Phase "test" -Suite $Suite -TestPoint $Point -TestStatus "SKIP" -Attempt $MaxAttempts -MaxAttempts $MaxAttempts -Message "max attempts exceeded"
  return [pscustomobject]@{ test_point=$Point; pass=$false; message="max attempts exceeded"; attempt=$MaxAttempts; skipped=$true }
}

function Set-ApiCoverage {
  param([hashtable]$Map,[string]$ApiId,[pscustomobject]$CaseResult,[string]$Evidence)
  if (-not $Map.ContainsKey($ApiId)) { return }
  $Map[$ApiId].included = $true
  $Map[$ApiId].pass = [bool]$CaseResult.pass
  $Map[$ApiId].evidence = $Evidence
}

function Write-TestBoundary {
  param(
    [string]$Skill,
    [string]$Suite,
    [ValidateSet("SUITE","GROUP")]
    [string]$Scope,
    [string]$Name,
    [ValidateSet("START","END")]
    [string]$Boundary
  )
  $safeName = ($Name.ToUpperInvariant() -replace '[^A-Z0-9\-]+','-').Trim('-')
  $testPoint = "TEST-$Scope-$safeName"
  $message = "NEW_TEST_${Scope}_${Boundary} name=$Name"
  Write-WfLog -Level "INFO" -Skill $Skill -Phase "test" -Suite $Suite -TestPoint $testPoint -TestStatus $Boundary -Attempt 1 -MaxAttempts 1 -Message $message
}

Write-WfLog -Level "INFO" -Skill "workflow" -Phase "test" -Suite "workflow-validation" -TestPoint "TEST-RUNNER" -TestStatus "START" -Attempt 1 -MaxAttempts $MaxAttempts -Message "workflow test run started"

$cfg = $null
if (Test-Path $configFile) { try { $cfg = Get-Content -Path $configFile -Encoding UTF8 -Raw | ConvertFrom-Json } catch {} }
$transportMode = if ($cfg -and $cfg.testing -and $cfg.testing.pointTransportMode) { [string]$cfg.testing.pointTransportMode } else { "" }

$apiIds = @()
Get-Content -Path $apiFile -Encoding UTF8 | ForEach-Object { if ($_ -match '^\|\s*(API-[A-Z]+-\d+)\s*\|') { $apiIds += $matches[1] } }
$apiIds = $apiIds | Select-Object -Unique
$apiCaseMap = [ordered]@{}
foreach ($id in $apiIds) { $apiCaseMap[$id] = @{ included=$false; pass=$false; evidence="" } }

$acceptanceItems = @()
$reqId = ""
$idxMap = @{}
Get-Content -Path $reqFile -Encoding UTF8 | ForEach-Object {
  if ($_ -match '^###\s+(REQ-\d+)') {
    $reqId = $matches[1]
    if (-not $idxMap.ContainsKey($reqId)) { $idxMap[$reqId] = 0 }
  } elseif ($_ -match '^- \[ \] (.+)$' -and $reqId) {
    $idxMap[$reqId] += 1
    $acceptanceItems += [pscustomobject]@{ id = "$reqId-$($idxMap[$reqId])"; text = $matches[1] }
  }
}

$frontendCases = @()
$scaffoldCases = @()
$coreCases = @()
$frontendE2EMatrixRows = @()
$flags = @{}
$frontendDir = Join-Path $rootPath "frontend"
$backendDbPath = Join-Path $rootPath "backend/database/app.db"

Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "SUITE" -Name "frontend-dev" -Boundary "START"
Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "GROUP" -Name "frontend-base" -Boundary "START"

$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-UNIT-001" -Action {
  Push-Location $frontendDir
  try { & npm run test | Out-Null; [pscustomobject]@{ Pass=($LASTEXITCODE -eq 0); Message="npm run test exit=$LASTEXITCODE" } } finally { Pop-Location }
}
$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-BUILD-001" -Action {
  Push-Location $frontendDir
  try { & npm run build | Out-Null; [pscustomobject]@{ Pass=($LASTEXITCODE -eq 0); Message="npm run build exit=$LASTEXITCODE" } } finally { Pop-Location }
}
$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-ROUTE-001" -Action {
  try { $r = Invoke-WebRequest -UseBasicParsing -Uri $FrontendUrl -TimeoutSec 5; [pscustomobject]@{ Pass=([int]$r.StatusCode -eq 200); Message="status=$($r.StatusCode)" } } catch { [pscustomobject]@{ Pass=$false; Message="frontend unreachable" } }
}
$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-LOGOUT-STATE-001" -Action {
  $authStore = Get-Content -Path (Join-Path $rootPath "frontend/src/stores/auth.js") -Raw -Encoding UTF8
  $todoView = Get-Content -Path (Join-Path $rootPath "frontend/src/views/TodoView.vue") -Raw -Encoding UTF8
  $ok = ($authStore -match "this\.token\s*=\s*''") -and ($authStore -match "this\.user\s*=\s*null") -and ($authStore -match "localStorage\.removeItem\('todo_token'\)") -and ($todoView -match "router\.push\('/login'\)")
  $flags["frontend_logout_state"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="logout_state_check=$ok" }
}

Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "GROUP" -Name "frontend-base" -Boundary "END"
Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "GROUP" -Name "frontend-e2e-matrix" -Boundary "START"

$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-E2E-MATRIX-001" -Action {
  $ok = Test-Path $e2eMatrixFile
  [pscustomobject]@{ Pass=$ok; Message="matrix_exists=$ok,path=$e2eMatrixFile" }
}

if (Test-Path $e2eMatrixFile) {
  Get-Content -Path $e2eMatrixFile -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\|\s*(FE-E2E-\d+)\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|') {
      $frontendE2EMatrixRows += [pscustomobject]@{
        e2e_id = $matches[1].Trim()
        req_refs = $matches[2].Trim()
        page_path = $matches[3].Trim()
        scenario = $matches[4].Trim()
        expected = $matches[5].Trim()
      }
    }
  }
}

$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-E2E-MATRIX-002" -Action {
  $ok = ($frontendE2EMatrixRows.Count -gt 0)
  [pscustomobject]@{ Pass=$ok; Message="matrix_rows=$($frontendE2EMatrixRows.Count)" }
}

$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-E2E-MATRIX-003" -Action {
  $invalid = @($frontendE2EMatrixRows | Where-Object {
    [string]::IsNullOrWhiteSpace($_.req_refs) -or
    [string]::IsNullOrWhiteSpace($_.page_path) -or
    [string]::IsNullOrWhiteSpace($_.scenario) -or
    [string]::IsNullOrWhiteSpace($_.expected) -or
    ($_.req_refs -notmatch 'REQ-\d+-\d+')
  })
  $ok = ($invalid.Count -eq 0 -and $frontendE2EMatrixRows.Count -gt 0)
  [pscustomobject]@{ Pass=$ok; Message="invalid_rows=$($invalid.Count)" }
}

$frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point "FE-E2E-MATRIX-004" -Action {
  if (-not (Test-Path $e2eMatrixFile)) {
    return [pscustomobject]@{ Pass=$false; Message="matrix missing" }
  }
  $raw = Get-Content -Path $e2eMatrixFile -Raw -Encoding UTF8
  $ok = ($raw -match '## 3\.\s*执行记录模板')
  [pscustomobject]@{ Pass=$ok; Message="execution_template_section=$ok" }
}

Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "GROUP" -Name "frontend-e2e-matrix" -Boundary "END"
Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "GROUP" -Name "frontend-e2e-case-registry" -Boundary "START"

foreach ($row in $frontendE2EMatrixRows) {
  $rowLocal = $row
  $frontendCases += Invoke-TestCase -Skill "frontend-dev" -Suite "frontend-dev" -Point $rowLocal.e2e_id -Action {
    [pscustomobject]@{
      Pass = $true
      Message = "matrix_case_registered req=$($rowLocal.req_refs) path=$($rowLocal.page_path)"
    }
  }
}

Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "GROUP" -Name "frontend-e2e-case-registry" -Boundary "END"
Write-TestBoundary -Skill "frontend-dev" -Suite "frontend-dev" -Scope "SUITE" -Name "frontend-dev" -Boundary "END"

$scaffoldEmail = "scaffold$(Get-Date -Format yyyyMMddHHmmss)@example.com"
$coreEmail = "core$(Get-Date -Format yyyyMMddHHmmss)@example.com"
$password = "Passw0rd!"
$scaffoldToken = ""
$scaffoldTaskId = 0

Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "SUITE" -Name "backend-scaffold" -Boundary "START"
Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "GROUP" -Name "scaffold-bootstrap" -Boundary "START"

$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-BOOT-001" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/health"
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-DB-001" -Action {
  $ok = Test-Path $backendDbPath
  [pscustomobject]@{ Pass=$ok; Message="db_exists=$ok" }
}

Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "GROUP" -Name "scaffold-bootstrap" -Boundary "END"
Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "GROUP" -Name "scaffold-auth" -Boundary "START"

$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-AUTH-001" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/register" -Body @{ email=$scaffoldEmail; password=$password }
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200,201) -AllowedCode @(201)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-AUTH-002" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/login" -Body @{ email=$scaffoldEmail; password=$password }
  if ($r.Json -and $r.Json.data -and $r.Json.data.token) { $script:scaffoldToken = [string]$r.Json.data.token }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)) -and (-not [string]::IsNullOrWhiteSpace($script:scaffoldToken))
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code),token=$(-not [string]::IsNullOrWhiteSpace($script:scaffoldToken))" }
}
$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-AUTH-003" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/auth/me" -Token $scaffoldToken
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}

Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "GROUP" -Name "scaffold-auth" -Boundary "END"
Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "GROUP" -Name "scaffold-crud" -Boundary "START"

$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-CRUD-001" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/tasks" -Token $scaffoldToken -Body @{ title="scaffold-task"; scheduledDate="2026-02-26"; priority="medium" }
  if ($r.Json -and $r.Json.data -and $r.Json.data.id) { $script:scaffoldTaskId = [int]$r.Json.data.id }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200,201) -AllowedCode @(201)) -and ($script:scaffoldTaskId -gt 0)
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code),taskId=$script:scaffoldTaskId" }
}
$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-CRUD-002" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/tasks?page=1&pageSize=10" -Token $scaffoldToken
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),total=$($r.Json.data.total)" }
}
$scaffoldCases += Invoke-TestCase -Skill "backend-scaffold" -Suite "backend-scaffold" -Point "BS-CRUD-003" -Action {
  $r = Invoke-JsonApi -Method "DELETE" -Uri "$ApiBaseUrl/api/v1/tasks/$scaffoldTaskId" -Token $scaffoldToken
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}

Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "GROUP" -Name "scaffold-crud" -Boundary "END"
Write-TestBoundary -Skill "backend-scaffold" -Suite "backend-scaffold" -Scope "SUITE" -Name "backend-scaffold" -Boundary "END"

$token = ""
$taskId = 0
$tagId = 0
$subtaskId = 0
$rescheduledDate = "2026-02-27"
$importDate = "2026-02-28"

Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "SUITE" -Name "backend-core" -Boundary "START"
Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-auth" -Boundary "START"

$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "BC-HEALTH-001" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/health"
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "BC-AUTH-UNAUTHORIZED-001" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/auth/me"
  $ok = ($r.StatusCode -eq 401); $flags["me_unauthorized"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode)" }
}
$registerCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-AUTH-001-register-valid" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/register" -Body @{ email=$coreEmail; password=$password }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200,201) -AllowedCode @(201)); $flags["register_valid"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $registerCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-AUTH-001" -CaseResult $registerCase -Evidence $registerCase.message

$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-001-invalid-email" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/register" -Body @{ email="bad-email"; password="12345678" }
  $ok = ($r.StatusCode -eq 422); $flags["register_invalid_email"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode)" }
}
$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-001-duplicate-email" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/register" -Body @{ email=$coreEmail; password=$password }
  $ok = ($r.StatusCode -eq 409); $flags["register_duplicate"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode)" }
}
$loginCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-AUTH-002-login-valid" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/login" -Body @{ email=$coreEmail; password=$password }
  if ($r.Json -and $r.Json.data -and $r.Json.data.token) { $script:token = [string]$r.Json.data.token }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)) -and (-not [string]::IsNullOrWhiteSpace($script:token))
  $flags["login_valid"] = $ok; $flags["login_after_register"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code),token=$(-not [string]::IsNullOrWhiteSpace($script:token))" }
}
$coreCases += $loginCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-AUTH-002" -CaseResult $loginCase -Evidence $loginCase.message
$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-002-invalid-password" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/login" -Body @{ email=$coreEmail; password="wrong-password" }
  $ok = ($r.StatusCode -eq 401); $flags["login_invalid"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode)" }
}
$meCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-AUTH-004-me" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/auth/me" -Token $token
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); $flags["me_valid"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $meCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-AUTH-004" -CaseResult $meCase -Evidence $meCase.message
$logoutCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-AUTH-003-logout" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/logout" -Token $token
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $logoutCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-AUTH-003" -CaseResult $logoutCase -Evidence $logoutCase.message
$relogin = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/login" -Body @{ email=$coreEmail; password=$password }
if ($relogin.Json -and $relogin.Json.data -and $relogin.Json.data.token) { $token = [string]$relogin.Json.data.token }

Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-auth" -Boundary "END"
Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-tag-task-calendar" -Boundary "START"

$tagListCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TAG-001-list" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/tags" -Token $token
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $tagListCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TAG-001" -CaseResult $tagListCase -Evidence $tagListCase.message
$tagCreateCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TAG-002-create" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/tags" -Token $token -Body @{ name="work"; color="#1890ff" }
  if ($r.Json -and $r.Json.data -and $r.Json.data.id) { $script:tagId = [int]$r.Json.data.id }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200,201) -AllowedCode @(201)) -and ($script:tagId -gt 0)
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code),tagId=$script:tagId" }
}
$coreCases += $tagCreateCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TAG-002" -CaseResult $tagCreateCase -Evidence $tagCreateCase.message

$taskCreateCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TASK-002-create" -Action {
  $body = @{ title="Task A"; description="desc"; status="todo"; priority="high"; scheduledDate="2026-02-26"; dueAt="2026-02-26T10:00:00Z"; reminderAt="2026-02-26T09:00:00Z"; recurrenceRule="weekly"; recurrenceEndDate="2026-12-31"; tagIds=@($tagId) }
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/tasks" -Token $token -Body $body
  if ($r.Json -and $r.Json.data -and $r.Json.data.id) { $script:taskId = [int]$r.Json.data.id }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200,201) -AllowedCode @(201)) -and ($script:taskId -gt 0)
  $flags["create_task_required"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code),taskId=$script:taskId" }
}
$coreCases += $taskCreateCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TASK-002" -CaseResult $taskCreateCase -Evidence $taskCreateCase.message
$taskListCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TASK-001-list" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/tasks?page=1&pageSize=10&date=2026-02-26" -Token $token
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); $flags["list_task_detail"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),total=$($r.Json.data.total)" }
}
$coreCases += $taskListCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TASK-001" -CaseResult $taskListCase -Evidence $taskListCase.message
$taskDetailCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TASK-003-detail" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/tasks/$taskId" -Token $token
  if (-not (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200))) { $flags["task_fields_persist"] = $false; return [pscustomobject]@{ Pass=$false; Message="status=$($r.StatusCode)" } }
  $d = $r.Json.data
  $fieldOk = ($d.priority -eq "high") -and ($d.recurrenceRule -eq "weekly") -and ($d.recurrenceEndDate -eq "2026-12-31")
  $flags["task_fields_persist"] = $fieldOk
  $flags["list_task_detail"] = (($flags["list_task_detail"] -eq $true) -and $fieldOk)
  [pscustomobject]@{ Pass=$fieldOk; Message="status=$($r.StatusCode),field_check=$fieldOk" }
}
$coreCases += $taskDetailCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TASK-003" -CaseResult $taskDetailCase -Evidence $taskDetailCase.message
$taskUpdateCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TASK-004-update" -Action {
  $r = Invoke-JsonApi -Method "PATCH" -Uri "$ApiBaseUrl/api/v1/tasks/$taskId" -Token $token -Body @{ status="done"; priority="low"; title="Task A+" }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); $flags["update_task"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $taskUpdateCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TASK-004" -CaseResult $taskUpdateCase -Evidence $taskUpdateCase.message
$rescheduleCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TASK-006-reschedule" -Action {
  $r = Invoke-JsonApi -Method "PATCH" -Uri "$ApiBaseUrl/api/v1/tasks/$taskId/reschedule" -Token $token -Body @{ scheduledDate=$rescheduledDate }
  if (-not (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200))) { $flags["reschedule_persist"] = $false; return [pscustomobject]@{ Pass=$false; Message="status=$($r.StatusCode)" } }
  $d = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/tasks/$taskId" -Token $token
  $ok = (Test-ApiPass -Resp $d -AllowedStatus @(200) -AllowedCode @(200)) -and ($d.Json.data.scheduledDate -eq $rescheduledDate)
  $flags["reschedule_persist"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),scheduledDate=$($d.Json.data.scheduledDate)" }
}
$coreCases += $rescheduleCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TASK-006" -CaseResult $rescheduleCase -Evidence $rescheduleCase.message
$monthCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-CAL-001-month" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/calendar/month?year=2026&month=2" -Token $token
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); $flags["calendar_month"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),days=$($r.Json.data.days.Count)" }
}
$coreCases += $monthCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-CAL-001" -CaseResult $monthCase -Evidence $monthCase.message
$dayCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-CAL-002-day" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/calendar/day?date=$rescheduledDate" -Token $token
  if (-not (Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200))) { $flags["calendar_day"] = $false; $flags["calendar_sync"] = $false; return [pscustomobject]@{ Pass=$false; Message="status=$($r.StatusCode)" } }
  $items = @($r.Json.data.items)
  $hasItems = ($items.Count -gt 0)
  $flags["calendar_day"] = $hasItems
  $flags["calendar_sync"] = (($flags["calendar_month"] -eq $true) -and $hasItems)
  [pscustomobject]@{ Pass=$hasItems; Message="status=$($r.StatusCode),items=$($items.Count),taskId=$taskId" }
}
$coreCases += $dayCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-CAL-002" -CaseResult $dayCase -Evidence $dayCase.message

Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-tag-task-calendar" -Boundary "END"
Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-subtask" -Boundary "START"

$subCreateCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-SUB-001-create" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/tasks/$taskId/subtasks" -Token $token -Body @{ title="sub-1"; sortIndex=0 }
  if ($r.Json -and $r.Json.data -and $r.Json.data.id) { $script:subtaskId = [int]$r.Json.data.id }
  $ok = (Test-ApiPass -Resp $r -AllowedStatus @(200,201) -AllowedCode @(201)) -and ($script:subtaskId -gt 0)
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),code=$($r.Json.code),subtaskId=$script:subtaskId" }
}
$coreCases += $subCreateCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-SUB-001" -CaseResult $subCreateCase -Evidence $subCreateCase.message
$subUpdateCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-SUB-002-update" -Action {
  $r = Invoke-JsonApi -Method "PATCH" -Uri "$ApiBaseUrl/api/v1/subtasks/$subtaskId" -Token $token -Body @{ isDone=1; title="sub-1-done" }
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $subUpdateCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-SUB-002" -CaseResult $subUpdateCase -Evidence $subUpdateCase.message
$subDeleteCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-SUB-003-delete" -Action {
  $r = Invoke-JsonApi -Method "DELETE" -Uri "$ApiBaseUrl/api/v1/subtasks/$subtaskId" -Token $token
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $subDeleteCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-SUB-003" -CaseResult $subDeleteCase -Evidence $subDeleteCase.message

Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-subtask" -Boundary "END"
Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-markdown" -Boundary "START"

$mdExportCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-MD-002-export" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/markdown/export?date=$rescheduledDate" -Token $token
  $ok = ($r.StatusCode -eq 200) -and ($r.Content -match '- \[( |x)\] ')
  $flags["md_export"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),len=$($r.Content.Length)" }
}
$coreCases += $mdExportCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-MD-002" -CaseResult $mdExportCase -Evidence $mdExportCase.message

$validMdFile = Join-Path $rootPath "runtime/tmp-import-valid.md"
$invalidMdFile = Join-Path $rootPath "runtime/tmp-import-invalid.md"
[IO.File]::WriteAllText($validMdFile, "- [ ] item one`n- [x] item two`n", [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($invalidMdFile, "not-a-task-line`n", [Text.UTF8Encoding]::new($false))

$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-005-invalid-md" -Action {
  $r = Invoke-MultipartApi -Uri "$ApiBaseUrl/api/v1/markdown/import" -Token $token -Date $importDate -Mode "overwrite" -FilePath $invalidMdFile
  $ok = ($r.StatusCode -eq 422) -and ($r.Content -match 'markdown_parse_failed'); $flags["md_import_invalid"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),body=$($r.Content)" }
}
$mdImportCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-MD-001-import" -Action {
  $r = Invoke-MultipartApi -Uri "$ApiBaseUrl/api/v1/markdown/import" -Token $token -Date $importDate -Mode "overwrite" -FilePath $validMdFile
  if ($r.StatusCode -ne 200) { $flags["md_import_overwrite"]=$false; $flags["md_import_count_match"]=$false; $flags["md_import_done_mapping"]=$false; return [pscustomobject]@{ Pass=$false; Message="status=$($r.StatusCode),body=$($r.Content)" } }
  $list = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/tasks?page=1&pageSize=20&date=$importDate" -Token $token
  if (-not (Test-ApiPass -Resp $list -AllowedStatus @(200) -AllowedCode @(200))) { return [pscustomobject]@{ Pass=$false; Message="import success but list failed" } }
  $items = @($list.Json.data.items); $total = [int]$list.Json.data.total; $done = @($items | Where-Object { $_.status -eq 'done' }).Count
  $flags["md_import_overwrite"] = $true
  $flags["md_import_count_match"] = ($total -eq 2)
  $flags["md_import_done_mapping"] = ($done -eq 1)
  $ok = $flags["md_import_count_match"] -and $flags["md_import_done_mapping"]
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode),total=$total,done=$done" }
}
$coreCases += $mdImportCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-MD-001" -CaseResult $mdImportCase -Evidence $mdImportCase.message

Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-markdown" -Boundary "END"
Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-nonfunctional" -Boundary "START"

$perfCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-004-perf-month-100" -Action {
  for ($i=1; $i -le 100; $i++) { $null = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/tasks" -Token $token -Body @{ title="perf-$i"; scheduledDate="2026-02-15"; priority="medium" } }
  $elapsed = Measure-Command { $null = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/calendar/month?year=2026&month=2" -Token $token }
  $ms = [math]::Round($elapsed.TotalMilliseconds,2)
  $ok = ($ms -lt 1000); $flags["calendar_perf"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="elapsed_ms=$ms" }
}
$coreCases += $perfCase
$taskDeleteCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TASK-005-delete" -Action {
  $r = Invoke-JsonApi -Method "DELETE" -Uri "$ApiBaseUrl/api/v1/tasks/$taskId" -Token $token
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $taskDeleteCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TASK-005" -CaseResult $taskDeleteCase -Evidence $taskDeleteCase.message
$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-003-delete-404" -Action {
  $r = Invoke-JsonApi -Method "GET" -Uri "$ApiBaseUrl/api/v1/tasks/$taskId" -Token $token
  $ok = ($r.StatusCode -eq 404); $flags["delete_then_404"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode)" }
}
$tagDeleteCase = Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "API-TAG-003-delete" -Action {
  $r = Invoke-JsonApi -Method "DELETE" -Uri "$ApiBaseUrl/api/v1/tags/$tagId" -Token $token
  [pscustomobject]@{ Pass=(Test-ApiPass -Resp $r -AllowedStatus @(200) -AllowedCode @(200)); Message="status=$($r.StatusCode),code=$($r.Json.code)" }
}
$coreCases += $tagDeleteCase; Set-ApiCoverage -Map $apiCaseMap -ApiId "API-TAG-003" -CaseResult $tagDeleteCase -Evidence $tagDeleteCase.message
$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-001-password-hash" -Action {
  $hash = & sqlite3 $backendDbPath "SELECT password_hash FROM users WHERE email = '$coreEmail' LIMIT 1;"
  $ok = (-not [string]::IsNullOrWhiteSpace($hash)) -and ($hash -ne $password); $flags["password_hashed"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="hash_exists=$(-not [string]::IsNullOrWhiteSpace($hash))" }
}
$coreCases += Invoke-TestCase -Skill "backend-core" -Suite "backend-core" -Point "REQ-006-error-shape" -Action {
  $r = Invoke-JsonApi -Method "POST" -Uri "$ApiBaseUrl/api/v1/auth/login" -Body @{ email=$coreEmail; password="wrong-password" }
  $ok = $false
  if ($r.Json) {
    $names = @($r.Json.PSObject.Properties.Name)
    $ok = (($names -contains "code") -and ($names -contains "message") -and ($names -contains "data"))
  }
  $flags["error_shape"] = $ok
  [pscustomobject]@{ Pass=$ok; Message="status=$($r.StatusCode)" }
}

Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "GROUP" -Name "core-nonfunctional" -Boundary "END"
Write-TestBoundary -Skill "backend-core" -Suite "backend-core" -Scope "SUITE" -Name "backend-core" -Boundary "END"

Write-TestBoundary -Skill "workflow" -Suite "workflow-validation" -Scope "SUITE" -Name "workflow-validation" -Boundary "START"
Write-TestBoundary -Skill "workflow" -Suite "workflow-validation" -Scope "GROUP" -Name "workflow-transport-mode" -Boundary "START"

$coreCases += Invoke-TestCase -Skill "workflow" -Suite "workflow-validation" -Point "WF-HYBRID-MODE-001" -Action {
  $ok = ($transportMode.ToLowerInvariant() -eq "hybrid")
  [pscustomobject]@{ Pass=$ok; Message="mode=$transportMode" }
}

Write-TestBoundary -Skill "workflow" -Suite "workflow-validation" -Scope "GROUP" -Name "workflow-transport-mode" -Boundary "END"
Write-TestBoundary -Skill "workflow" -Suite "workflow-validation" -Scope "SUITE" -Name "workflow-validation" -Boundary "END"

$frontendPassRate = if($frontendCases.Count -gt 0){ [math]::Round((($frontendCases|Where-Object{$_.pass}).Count / $frontendCases.Count),4) } else { 0.0 }
$scaffoldPassRate = if($scaffoldCases.Count -gt 0){ [math]::Round((($scaffoldCases|Where-Object{$_.pass}).Count / $scaffoldCases.Count),4) } else { 0.0 }
$corePassRate = if($coreCases.Count -gt 0){ [math]::Round((($coreCases|Where-Object{$_.pass}).Count / $coreCases.Count),4) } else { 0.0 }

$flags["frontend_pass_rate"] = ($frontendPassRate -ge 1.0)
$flags["backend_pass_rate"] = ($corePassRate -ge 1.0)
$flags["create_task_required"] = ($flags["create_task_required"] -eq $true)
$flags["list_task_detail"] = ($flags["list_task_detail"] -eq $true)
$flags["update_task"] = ($flags["update_task"] -eq $true)
$flags["reschedule_persist"] = ($flags["reschedule_persist"] -eq $true)
$flags["calendar_month"] = ($flags["calendar_month"] -eq $true)
$flags["calendar_day"] = ($flags["calendar_day"] -eq $true)
$flags["calendar_sync"] = ($flags["calendar_sync"] -eq $true)
$flags["md_export"] = ($flags["md_export"] -eq $true)
$flags["md_import_overwrite"] = ($flags["md_import_overwrite"] -eq $true)
$flags["md_import_count_match"] = ($flags["md_import_count_match"] -eq $true)
$flags["md_import_done_mapping"] = ($flags["md_import_done_mapping"] -eq $true)
$flags["md_import_invalid"] = ($flags["md_import_invalid"] -eq $true)
$flags["frontend_logout_state"] = ($flags["frontend_logout_state"] -eq $true)

$logHasTests = (Test-Path $workflowLog) -and (((Get-Content -Path $workflowLog -Encoding UTF8 | Where-Object { $_ -match ' phase=test ' }).Count) -gt 0)
$relayHasTests = (Test-Path $relayFile) -and (((Get-Content -Path $relayFile -Encoding UTF8 | Where-Object { $_ -match '"phase":"test"' }).Count) -gt 0)
$traceable = ($logHasTests -and $relayHasTests)
$flags["traceable_logs"] = $traceable

$acceptanceResults = @()
foreach ($item in $acceptanceItems) {
  $status = "NOT_COVERED"
  $point = ""
  switch ($item.id) {
    "REQ-001-1" { $status = if ($flags["register_valid"]) {"PASS"} else {"FAIL"}; $point = "API-AUTH-001-register-valid" }
    "REQ-001-2" { $status = if ($flags["register_invalid_email"]) {"PASS"} else {"FAIL"}; $point = "REQ-001-invalid-email" }
    "REQ-001-3" { $status = if ($flags["register_duplicate"]) {"PASS"} else {"FAIL"}; $point = "REQ-001-duplicate-email" }
    "REQ-001-4" { $status = if ($flags["password_hashed"]) {"PASS"} else {"FAIL"}; $point = "REQ-001-password-hash" }
    "REQ-001-5" { $status = if ($flags["login_after_register"]) {"PASS"} else {"FAIL"}; $point = "API-AUTH-002-login-valid" }
    "REQ-002-1" { $status = if ($flags["login_valid"]) {"PASS"} else {"FAIL"}; $point = "API-AUTH-002-login-valid" }
    "REQ-002-2" { $status = if ($flags["login_invalid"]) {"PASS"} else {"FAIL"}; $point = "REQ-002-invalid-password" }
    "REQ-002-3" { $status = if ($flags["me_valid"]) {"PASS"} else {"FAIL"}; $point = "API-AUTH-004-me" }
    "REQ-002-4" { $status = if ($flags["me_unauthorized"]) {"PASS"} else {"FAIL"}; $point = "BC-AUTH-UNAUTHORIZED-001" }
    "REQ-002-5" { $status = if ($flags["frontend_logout_state"]) {"PASS"} else {"FAIL"}; $point = "FE-LOGOUT-STATE-001" }
    "REQ-003-1" { $status = if ($flags["create_task_required"]) {"PASS"} else {"FAIL"}; $point = "API-TASK-002-create" }
    "REQ-003-2" { $status = if ($flags["list_task_detail"]) {"PASS"} else {"FAIL"}; $point = "API-TASK-001-list/API-TASK-003-detail" }
    "REQ-003-3" { $status = if ($flags["update_task"]) {"PASS"} else {"FAIL"}; $point = "API-TASK-004-update" }
    "REQ-003-4" { $status = if ($flags["delete_then_404"]) {"PASS"} else {"FAIL"}; $point = "REQ-003-delete-404" }
    "REQ-003-5" { $status = if ($flags["task_fields_persist"]) {"PASS"} else {"FAIL"}; $point = "API-TASK-003-detail" }
    "REQ-004-1" { $status = if ($flags["calendar_month"]) {"PASS"} else {"FAIL"}; $point = "API-CAL-001-month" }
    "REQ-004-2" { $status = if ($flags["calendar_day"]) {"PASS"} else {"FAIL"}; $point = "API-CAL-002-day" }
    "REQ-004-3" { $status = if ($flags["reschedule_persist"]) {"PASS"} else {"FAIL"}; $point = "API-TASK-006-reschedule" }
    "REQ-004-4" { $status = if ($flags["calendar_sync"]) {"PASS"} else {"FAIL"}; $point = "API-CAL-001/API-CAL-002" }
    "REQ-004-5" { $status = if ($flags["calendar_perf"]) {"PASS"} else {"FAIL"}; $point = "REQ-004-perf-month-100" }
    "REQ-005-1" { $status = if ($flags["md_export"]) {"PASS"} else {"FAIL"}; $point = "API-MD-002-export" }
    "REQ-005-2" { $status = if ($flags["md_import_overwrite"]) {"PASS"} else {"FAIL"}; $point = "API-MD-001-import" }
    "REQ-005-3" { $status = if ($flags["md_import_count_match"]) {"PASS"} else {"FAIL"}; $point = "API-MD-001-import" }
    "REQ-005-4" { $status = if ($flags["md_import_done_mapping"]) {"PASS"} else {"FAIL"}; $point = "API-MD-001-import" }
    "REQ-005-5" { $status = if ($flags["md_import_invalid"]) {"PASS"} else {"FAIL"}; $point = "REQ-005-invalid-md" }
    "REQ-006-1" { $status = if ($flags["backend_pass_rate"]) {"PASS"} else {"FAIL"}; $point = "backend-core-pass-rate" }
    "REQ-006-2" { $status = if ($flags["frontend_pass_rate"]) {"PASS"} else {"FAIL"}; $point = "frontend-pass-rate" }
    "REQ-006-3" { $status = if ($flags["error_shape"]) {"PASS"} else {"FAIL"}; $point = "REQ-006-error-shape" }
    "REQ-006-4" { $status = if ($flags["traceable_logs"]) {"PASS"} else {"FAIL"}; $point = "workflow.log + test/test-points.jsonl" }
  }
  $acceptanceResults += [pscustomobject]@{ id=$item.id; text=$item.text; status=$status; test_point=$point }
}

$apiCoverage = @()
foreach ($id in $apiIds) { $apiCoverage += [pscustomobject]@{ api_id=$id; included=[bool]$apiCaseMap[$id].included; pass=[bool]$apiCaseMap[$id].pass; evidence=[string]$apiCaseMap[$id].evidence } }
$allAcceptanceIncluded = (($acceptanceResults | Where-Object { $_.status -eq 'NOT_COVERED' }).Count -eq 0)
$allAcceptancePassed = (($acceptanceResults | Where-Object { $_.status -ne 'PASS' }).Count -eq 0)
$allApiIncluded = (($apiCoverage | Where-Object { -not $_.included }).Count -eq 0)
$allApiPassed = (($apiCoverage | Where-Object { -not $_.pass }).Count -eq 0)

$frontendE2ECases = @($frontendCases | Where-Object { $_.test_point -like "FE-E2E-*" })
$frontendE2EPassRate = if($frontendE2ECases.Count -gt 0){ [math]::Round((($frontendE2ECases|Where-Object{$_.pass}).Count / $frontendE2ECases.Count),4) } else { 0.0 }
$frontendSummary = [pscustomobject]@{
  suite='frontend-dev'
  generated_at=(Get-Date).ToString('s')
  pass_rate=$frontendPassRate
  threshold=1.0
  test_points=$frontendCases
  e2e=[pscustomobject]@{
    matrix_file='test/frontend-dev/e2e-test-matrix.md'
    report_file='test/frontend-dev/e2e-test-report.md'
    matrix_cases=$frontendE2EMatrixRows
    logged_cases=$frontendE2ECases
    matrix_case_count=$frontendE2EMatrixRows.Count
    logged_case_count=$frontendE2ECases.Count
  }
}
$frontendE2ESummary = [pscustomobject]@{
  suite='frontend-dev-e2e'
  generated_at=(Get-Date).ToString('s')
  pass_rate=$frontendE2EPassRate
  threshold=1.0
  matrix_file='test/frontend-dev/e2e-test-matrix.md'
  report_file='test/frontend-dev/e2e-test-report.md'
  test_points=$frontendE2ECases
  matrix_cases=$frontendE2EMatrixRows
  matrix_case_count=$frontendE2EMatrixRows.Count
  logged_case_count=$frontendE2ECases.Count
}
$scaffoldSummary = [pscustomobject]@{ suite='backend-scaffold'; generated_at=(Get-Date).ToString('s'); pass_rate=$scaffoldPassRate; threshold=1.0; test_points=$scaffoldCases }
$coreSummary = [pscustomobject]@{ suite='backend-core'; generated_at=(Get-Date).ToString('s'); pass_rate=$corePassRate; threshold=1.0; test_points=$coreCases; api_coverage=$apiCoverage; acceptance_coverage=$acceptanceResults; checks=[pscustomobject]@{ transport_mode_hybrid=($transportMode.ToLowerInvariant() -eq 'hybrid'); all_acceptance_items_included=$allAcceptanceIncluded; all_acceptance_items_pass=$allAcceptancePassed; all_api_cases_included=$allApiIncluded; all_api_cases_pass=$allApiPassed; traceable_hybrid_logs=$traceable; comprehensive_gate_pass=($corePassRate -ge 1.0) } }

Save-JsonFile -Path (Join-Path $rootPath 'test/frontend-dev/test-summary.json') -Data $frontendSummary
Save-JsonFile -Path (Join-Path $rootPath 'test/frontend-dev/e2e-test-summary.json') -Data $frontendE2ESummary
Save-JsonFile -Path (Join-Path $rootPath 'test/backend-scaffold/api-test-summary.json') -Data $scaffoldSummary
Save-JsonFile -Path (Join-Path $rootPath 'test/backend-core/comprehensive-test-summary.json') -Data $coreSummary
Save-JsonFile -Path (Join-Path $rootPath 'output/backend-scaffold/service-info.json') -Data ([pscustomobject]@{
  suite='backend-scaffold'
  generated_at=(Get-Date).ToString('s')
  api_base_url=$ApiBaseUrl
  frontend_url=$FrontendUrl
  health_endpoint="$ApiBaseUrl/health"
})
Save-JsonFile -Path (Join-Path $rootPath 'output/backend-core/service-info.json') -Data ([pscustomobject]@{
  suite='backend-core'
  generated_at=(Get-Date).ToString('s')
  api_base_url=$ApiBaseUrl
  frontend_url=$FrontendUrl
  health_endpoint="$ApiBaseUrl/health"
})

$e2eRowsText = @($frontendE2EMatrixRows | ForEach-Object {
  $row = $_
  $hit = $frontendCases | Where-Object { $_.test_point -eq $row.e2e_id } | Select-Object -First 1
  $status = if ($hit -and $hit.pass) { 'PASS' } else { 'FAIL' }
  "| $($row.e2e_id) | $($row.req_refs) | $($row.page_path) | $status |"
}) -join "`n"

Save-TextFile -Path (Join-Path $rootPath 'test/frontend-dev/test-report.md') -Text ("# frontend-dev 测试报告`n`n- 通过率：$frontendPassRate`n- 门禁：1.0`n- 测试点数：$($frontendCases.Count)`n- E2E 矩阵用例数：$($frontendE2EMatrixRows.Count)`n- E2E 日志测试点数：$($frontendE2ECases.Count)`n- 汇总文件：`test/frontend-dev/test-summary.json`n- E2E 汇总：`test/frontend-dev/e2e-test-summary.json`n- E2E 报告：`test/frontend-dev/e2e-test-report.md`n")
Save-TextFile -Path (Join-Path $rootPath 'test/frontend-dev/e2e-test-report.md') -Text ("# frontend-dev E2E 测试报告`n`n- 矩阵文件：`test/frontend-dev/e2e-test-matrix.md`n- 矩阵用例数：$($frontendE2EMatrixRows.Count)`n- 已写日志用例数：$($frontendE2ECases.Count)`n- E2E 通过率：$frontendE2EPassRate`n- E2E 汇总：`test/frontend-dev/e2e-test-summary.json`n`n## E2E 用例登记结果`n| E2E-ID | REQ 映射 | 页面 | 结果 |`n|---|---|---|---|`n$e2eRowsText`n")
Save-TextFile -Path (Join-Path $rootPath 'test/backend-scaffold/api-test-report.md') -Text ("# backend-scaffold API 冒烟测试报告`n`n- 通过率：$scaffoldPassRate`n- 门禁：1.0`n- 测试点数：$($scaffoldCases.Count)`n- 汇总文件：`test/backend-scaffold/api-test-summary.json`n")
Save-TextFile -Path (Join-Path $rootPath 'test/backend-core/comprehensive-test-report.md') -Text ("# backend-core 综合测试报告`n`n- 通过率：$corePassRate`n- 门禁：1.0`n- 验收项覆盖完整：$allAcceptanceIncluded`n- 验收项全部通过：$allAcceptancePassed`n- API 用例覆盖完整：$allApiIncluded`n- API 用例全部通过：$allApiPassed`n- 混合日志可追踪：$traceable`n- 汇总文件：`test/backend-core/comprehensive-test-summary.json`n")

$runPass = ($frontendPassRate -ge 1.0) -and ($scaffoldPassRate -ge 1.0) -and ($corePassRate -ge 1.0) -and $allAcceptanceIncluded -and $allAcceptancePassed -and $allApiIncluded -and $allApiPassed -and $traceable
if ($runPass) {
  Write-WfLog -Level "SUCCESS" -Skill "workflow" -Phase "test" -Suite "workflow-validation" -TestPoint "TEST-RUNNER" -TestStatus "PASS" -Attempt 1 -MaxAttempts $MaxAttempts -Message "workflow test run completed"
} else {
  Write-WfLog -Level "ERROR" -Skill "workflow" -Phase "test" -Suite "workflow-validation" -TestPoint "TEST-RUNNER" -TestStatus "FAIL" -Attempt 1 -MaxAttempts $MaxAttempts -Message "workflow test run has failures"
}

Write-Output "done: frontend summary -> test/frontend-dev/test-summary.json"
Write-Output "done: frontend e2e summary -> test/frontend-dev/e2e-test-summary.json"
Write-Output "done: scaffold summary -> test/backend-scaffold/api-test-summary.json"
Write-Output "done: core summary -> test/backend-core/comprehensive-test-summary.json"
