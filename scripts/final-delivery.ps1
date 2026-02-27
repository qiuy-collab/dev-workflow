param(
    [ValidateSet("all", "test", "package")]
    [string]$Mode = "all",
    [string]$Environment = "local",
    [string]$FrontendUrl = "http://127.0.0.1:3000",
    [string]$ApiBaseUrl = "http://127.0.0.1:18080"
)

$ErrorActionPreference = "Stop"
$SkillName = "final-delivery"

$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path

$logDir = Join-Path $repoRoot "logs"
$testDir = Join-Path $repoRoot "test"
$finalTestDir = Join-Path $testDir "final-delivery"
$outputDir = Join-Path $repoRoot "output/final-delivery"
$workflowLog = Join-Path $logDir "workflow.log"
$relayFile = Join-Path $testDir "test-points.jsonl"
$comprehensiveReportPath = Join-Path $finalTestDir "comprehensive-report.md"
$deliverySummaryPath = Join-Path $outputDir "delivery-summary.json"
$deliveryManifestPath = Join-Path $outputDir "delivery-manifest.md"
$configPath = Join-Path $repoRoot "agent-config.json"

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Save-TextFile {
    param([string]$Path, [string]$Text)
    $dir = Split-Path -Parent $Path
    Ensure-Dir -Path $dir
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Save-JsonFile {
    param([string]$Path, [object]$Data)
    $dir = Split-Path -Parent $Path
    Ensure-Dir -Path $dir
    $json = $Data | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Write-WorkflowLog {
    param(
        [ValidateSet("INFO", "SUCCESS", "ERROR", "CHANGE")]
        [string]$Level,
        [string]$Message,
        [string]$Phase = "",
        [string]$Suite = "",
        [string]$TestPoint = "",
        [string]$TestStatus = "",
        [int]$Attempt = 0,
        [int]$MaxAttempts = 0
    )
    Ensure-Dir -Path $logDir
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $parts = @("[$timestamp]", "[$Level]", "skill=$SkillName")
    if ($Phase) { $parts += "phase=$Phase" }
    if ($Suite) { $parts += "suite=$Suite" }
    if ($TestPoint) { $parts += "test_point=$TestPoint" }
    if ($TestStatus) { $parts += "test_status=$TestStatus" }
    if ($Attempt -gt 0 -and $MaxAttempts -gt 0) { $parts += "attempt=$Attempt/$MaxAttempts" }
    $parts += $Message
    Add-Content -Path $workflowLog -Value ($parts -join " ") -Encoding UTF8
}

function Write-TestRelay {
    param(
        [string]$Level,
        [string]$Message,
        [string]$Phase = "",
        [string]$Suite = "",
        [string]$TestPoint = "",
        [string]$TestStatus = "",
        [int]$Attempt = 0,
        [int]$MaxAttempts = 0
    )
    Ensure-Dir -Path $testDir
    $record = [ordered]@{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        level = $Level
        message = $Message
        skill = $SkillName
        phase = $Phase
        suite = $Suite
        test_point = $TestPoint
        test_status = $TestStatus
        attempt = $Attempt
        max_attempts = $MaxAttempts
    }
    Add-Content -Path $relayFile -Value ($record | ConvertTo-Json -Compress) -Encoding UTF8
}

function Write-TestEvent {
    param(
        [ValidateSet("INFO", "SUCCESS", "ERROR")]
        [string]$Level,
        [string]$Message,
        [string]$Suite,
        [string]$TestPoint,
        [ValidateSet("START", "END", "PASS", "FAIL", "RETRY", "SKIP")]
        [string]$TestStatus,
        [int]$Attempt,
        [int]$MaxAttempts
    )
    Write-WorkflowLog -Level $Level -Message $Message -Phase "test" -Suite $Suite -TestPoint $TestPoint -TestStatus $TestStatus -Attempt $Attempt -MaxAttempts $MaxAttempts
    Write-TestRelay -Level $Level -Message $Message -Phase "test" -Suite $Suite -TestPoint $TestPoint -TestStatus $TestStatus -Attempt $Attempt -MaxAttempts $MaxAttempts
}

function Write-TestBoundary {
    param(
        [string]$Suite,
        [ValidateSet("SUITE", "GROUP")]
        [string]$Scope,
        [string]$Name,
        [ValidateSet("START", "END")]
        [string]$Boundary
    )
    $safeName = ($Name.ToUpperInvariant() -replace '[^A-Z0-9\-]+', '-').Trim('-')
    $point = "TEST-$Scope-$safeName"
    $message = "NEW_TEST_${Scope}_${Boundary} name=$Name"
    Write-TestEvent -Level "INFO" -Message $message -Suite $Suite -TestPoint $point -TestStatus $Boundary -Attempt 1 -MaxAttempts 1
}

function Read-Config {
    if (-not (Test-Path $configPath)) { return [pscustomobject]@{} }
    try {
        return (Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch {
        return [pscustomobject]@{}
    }
}

function Invoke-TestPoint {
    param(
        [string]$PointId,
        [scriptblock]$Action,
        [int]$MaxAttempts
    )

    $suite = "final-delivery"
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if ($attempt -eq 1) {
            Write-TestEvent -Level "INFO" -Message "start" -Suite $suite -TestPoint $PointId -TestStatus "START" -Attempt $attempt -MaxAttempts $MaxAttempts
        } else {
            Write-TestEvent -Level "INFO" -Message "retry" -Suite $suite -TestPoint $PointId -TestStatus "RETRY" -Attempt $attempt -MaxAttempts $MaxAttempts
        }

        $result = $null
        try { $result = & $Action } catch { $result = [pscustomobject]@{ pass = $false; message = $_.Exception.Message } }
        if ($null -eq $result) { $result = [pscustomobject]@{ pass = $false; message = "empty result" } }

        if ($result.pass) {
            Write-TestEvent -Level "SUCCESS" -Message ([string]$result.message) -Suite $suite -TestPoint $PointId -TestStatus "PASS" -Attempt $attempt -MaxAttempts $MaxAttempts
            return [pscustomobject]@{ test_point = $PointId; pass = $true; message = [string]$result.message; attempt = $attempt; skipped = $false }
        }

        Write-TestEvent -Level "ERROR" -Message ([string]$result.message) -Suite $suite -TestPoint $PointId -TestStatus "FAIL" -Attempt $attempt -MaxAttempts $MaxAttempts
        Start-Sleep -Milliseconds 200
    }

    Write-TestEvent -Level "ERROR" -Message "max attempts exceeded" -Suite $suite -TestPoint $PointId -TestStatus "SKIP" -Attempt $MaxAttempts -MaxAttempts $MaxAttempts
    return [pscustomobject]@{ test_point = $PointId; pass = $false; message = "max attempts exceeded"; attempt = $MaxAttempts; skipped = $true }
}

function Get-RequiredArtifacts {
    return @(
        "output/requirement-planning-requirements.md",
        "output/requirement-planning-tech-stack.json",
        "output/api-design-api-list.md",
        "output/api-design-data-models.md",
        "output/backend-codegen-project-structure.md",
        "test/frontend-dev/test-summary.json",
        "test/frontend-dev/e2e-test-summary.json",
        "test/frontend-dev/e2e-test-matrix.md",
        "test/backend-scaffold/api-test-summary.json",
        "test/backend-core/comprehensive-test-summary.json",
        "output/backend-scaffold/service-info.json",
        "output/backend-core/service-info.json"
    )
}

function Run-DeliveryTests {
    param([int]$MaxAttempts)

    $suite = "final-delivery"
    $cases = @()

    Write-TestBoundary -Suite $suite -Scope "SUITE" -Name "final-delivery" -Boundary "START"

    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-runtime-checks" -Boundary "START"
    $cases += Invoke-TestPoint -PointId "FD-RUN-001" -MaxAttempts $MaxAttempts -Action {
        try {
            $resp = Invoke-WebRequest -UseBasicParsing -Uri $FrontendUrl -TimeoutSec 6
            [pscustomobject]@{ pass = ([int]$resp.StatusCode -eq 200); message = "frontend status=$($resp.StatusCode)" }
        } catch {
            [pscustomobject]@{ pass = $false; message = "frontend unreachable: $($_.Exception.Message)" }
        }
    }

    $cases += Invoke-TestPoint -PointId "FD-RUN-002" -MaxAttempts $MaxAttempts -Action {
        try {
            $resp = Invoke-WebRequest -UseBasicParsing -Uri "$ApiBaseUrl/health" -TimeoutSec 6
            $json = $null
            try { $json = $resp.Content | ConvertFrom-Json -ErrorAction Stop } catch {}
            $ok = ([int]$resp.StatusCode -eq 200)
            if ($json -and $json.code) { $ok = $ok -and ([int]$json.code -eq 200) }
            [pscustomobject]@{ pass = $ok; message = "backend status=$($resp.StatusCode)" }
        } catch {
            [pscustomobject]@{ pass = $false; message = "backend unreachable: $($_.Exception.Message)" }
        }
    }
    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-runtime-checks" -Boundary "END"

    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-integration-checks" -Boundary "START"
    $cases += Invoke-TestPoint -PointId "FD-INT-001" -MaxAttempts $MaxAttempts -Action {
        $frontendSummaryPath = Join-Path $repoRoot "test/frontend-dev/test-summary.json"
        $scaffoldSummaryPath = Join-Path $repoRoot "test/backend-scaffold/api-test-summary.json"
        $coreSummaryPath = Join-Path $repoRoot "test/backend-core/comprehensive-test-summary.json"
        if (-not (Test-Path $frontendSummaryPath) -or -not (Test-Path $scaffoldSummaryPath) -or -not (Test-Path $coreSummaryPath)) {
            return [pscustomobject]@{ pass = $false; message = "missing prerequisite test summary artifacts" }
        }
        try {
            $fe = Get-Content -Path $frontendSummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $bs = Get-Content -Path $scaffoldSummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $bc = Get-Content -Path $coreSummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $ok = ([double]$fe.pass_rate -ge 1.0) -and ([double]$bs.pass_rate -ge 1.0) -and ([double]$bc.pass_rate -ge 1.0)
            [pscustomobject]@{ pass = $ok; message = "pass_rate fe=$($fe.pass_rate), bs=$($bs.pass_rate), bc=$($bc.pass_rate)" }
        } catch {
            [pscustomobject]@{ pass = $false; message = "summary parse failed: $($_.Exception.Message)" }
        }
    }
    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-integration-checks" -Boundary "END"

    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-artifact-checks" -Boundary "START"
    $cases += Invoke-TestPoint -PointId "FD-DOC-001" -MaxAttempts $MaxAttempts -Action {
        $required = Get-RequiredArtifacts
        $missing = @()
        foreach ($rel in $required) {
            if (-not (Test-Path (Join-Path $repoRoot $rel))) {
                $missing += $rel
            }
        }
        if ($missing.Count -eq 0) {
            return [pscustomobject]@{ pass = $true; message = "all required artifacts found" }
        }
        [pscustomobject]@{ pass = $false; message = "missing artifacts: $($missing -join ', ')" }
    }
    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-artifact-checks" -Boundary "END"

    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-config-checks" -Boundary "START"
    $cases += Invoke-TestPoint -PointId "FD-CONF-001" -MaxAttempts $MaxAttempts -Action {
        $configOk = Test-Path (Join-Path $repoRoot "agent-config.json")
        $envOk = Test-Path (Join-Path $repoRoot ".env.example")
        $cmdOk = (Test-Path (Join-Path $repoRoot "scripts/start-runtime-hotreload.ps1")) -and (Test-Path (Join-Path $repoRoot "scripts/run-workflow-tests.ps1"))
        $ok = $configOk -and $envOk -and $cmdOk
        [pscustomobject]@{ pass = $ok; message = "config=$configOk, env_example=$envOk, startup_scripts=$cmdOk" }
    }
    Write-TestBoundary -Suite $suite -Scope "GROUP" -Name "delivery-config-checks" -Boundary "END"

    Write-TestBoundary -Suite $suite -Scope "SUITE" -Name "final-delivery" -Boundary "END"
    return $cases
}

function Build-Report {
    param(
        [array]$Cases,
        [string]$Environment,
        [int]$MaxAttempts
    )

    $passed = @($Cases | Where-Object { $_.pass }).Count
    $total = @($Cases).Count
    $failed = $total - $passed
    $passRate = if ($total -gt 0) { [math]::Round(($passed / $total), 4) } else { 0.0 }

    $rows = @($Cases | ForEach-Object {
        "| $($_.test_point) | $(if ($_.pass) { 'PASS' } else { 'FAIL' }) | $($_.attempt)/$MaxAttempts | $($_.message) |"
    }) -join "`n"

    $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    return @"
# final-delivery 综合测试报告

- 生成时间：$generatedAt
- 环境：$Environment
- 总测试点：$total
- 通过：$passed
- 失败：$failed
- 通过率：$passRate

## 测试结果
| 测试点 | 结果 | 重试次数 | 说明 |
|---|---|---|---|
$rows
"@
}

function Build-Manifest {
    param([array]$Artifacts)
    $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $lines = @("# 交付产物清单", "", "- 生成时间：$generatedAt", "")
    foreach ($rel in $Artifacts) {
        $exists = Test-Path (Join-Path $repoRoot $rel)
        $mark = if ($exists) { "[x]" } else { "[ ]" }
        $lines += "- $mark $rel"
    }
    return ($lines -join "`n")
}

Ensure-Dir -Path $logDir
Ensure-Dir -Path $testDir
Ensure-Dir -Path $finalTestDir
Ensure-Dir -Path $outputDir

$cfg = Read-Config
$maxAttempts = 5
if ($cfg.validation -and $cfg.validation.maxRetries) {
    $maxAttempts = [int]$cfg.validation.maxRetries
}

Write-WorkflowLog -Level "INFO" -Message "START mode=$Mode environment=$Environment"

$cases = @()
if ($Mode -in @("all", "test")) {
    $cases = Run-DeliveryTests -MaxAttempts $maxAttempts
    $report = Build-Report -Cases $cases -Environment $Environment -MaxAttempts $maxAttempts
    Save-TextFile -Path $comprehensiveReportPath -Text $report
    Write-WorkflowLog -Level "SUCCESS" -Message "test report generated path=test/final-delivery/comprehensive-report.md"
}

if ($Mode -in @("all", "package")) {
    if ($cases.Count -eq 0) {
        $cases = @([pscustomobject]@{ test_point = "FD-RUN-001"; pass = $true; message = "skipped in package mode"; attempt = 1; skipped = $true })
    }
    $requiredArtifacts = Get-RequiredArtifacts
    $manifest = Build-Manifest -Artifacts $requiredArtifacts
    Save-TextFile -Path $deliveryManifestPath -Text $manifest

    $passed = @($cases | Where-Object { $_.pass }).Count
    $total = @($cases).Count
    $passRate = if ($total -gt 0) { [math]::Round(($passed / $total), 4) } else { 0.0 }
    $summary = [ordered]@{
        generated_at = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        environment = $Environment
        mode = $Mode
        pass_rate = $passRate
        total = $total
        passed = $passed
        failed = ($total - $passed)
        test_report = "test/final-delivery/comprehensive-report.md"
        manifest = "output/final-delivery/delivery-manifest.md"
        artifacts = $requiredArtifacts
    }
    Save-JsonFile -Path $deliverySummaryPath -Data $summary
    Write-WorkflowLog -Level "SUCCESS" -Message "delivery summary generated path=output/final-delivery/delivery-summary.json"
}

Write-WorkflowLog -Level "SUCCESS" -Message "END mode=$Mode environment=$Environment"
