param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("INFO", "SUCCESS", "ERROR", "CHANGE")]
    [string]$Level,

    [Parameter(Mandatory = $true)]
    [string]$Message,

    [string]$Skill = "",
    [string]$ChangeId = "",
    [string]$Phase = "",
    [string]$Suite = "",
    [string]$TestPoint = "",
    [string]$TestStatus = "",
    [int]$Attempt = 0,
    [int]$MaxAttempts = 0,
    [string]$Root = ".",
    [string]$LogFileName = "workflow.log"
)

$ErrorActionPreference = "Stop"

$rootPath = Resolve-Path $Root
$logsDir = Join-Path $rootPath "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = Join-Path $logsDir $LogFileName
$configPath = Join-Path $rootPath "agent-config.json"
$transportMode = "realtime"
$relayPath = Join-Path $rootPath "test/test-points.jsonl"
$fallbackToRealtime = $true

if (Test-Path $configPath) {
    try {
        $cfg = Get-Content -Path $configPath -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.testing.pointTransportMode) {
            $transportMode = [string]$cfg.testing.pointTransportMode
        }
        if ($cfg.testing.pointTransportOptions.jsonRelayFile) {
            $relayPath = Join-Path $rootPath ([string]$cfg.testing.pointTransportOptions.jsonRelayFile)
        }
        if ($null -ne $cfg.testing.pointTransportOptions.fallbackToRealtimeOnJsonError) {
            $fallbackToRealtime = [bool]$cfg.testing.pointTransportOptions.fallbackToRealtimeOnJsonError
        }
    } catch {
        # Keep defaults if config parsing fails
    }
}

$parts = @("[${time}]", "[${Level}]")
if ($Skill) { $parts += "skill=$Skill" }
if ($ChangeId) { $parts += "change_id=$ChangeId" }
if ($Phase) { $parts += "phase=$Phase" }
if ($Suite) { $parts += "suite=$Suite" }
if ($TestPoint) { $parts += "test_point=$TestPoint" }
if ($TestStatus) { $parts += "test_status=$TestStatus" }
if ($Attempt -gt 0 -and $MaxAttempts -gt 0) {
    $parts += "attempt=${Attempt}/${MaxAttempts}"
} elseif ($Attempt -gt 0) {
    $parts += "attempt=${Attempt}"
}
$parts += $Message
$line = ($parts -join " ")

function Write-RealtimeLog {
    param([string]$Line)
    $max = 10
    for ($i = 1; $i -le $max; $i++) {
        try {
            Add-Content -Path $logFile -Value $Line -Encoding UTF8
            return
        } catch {
            if ($i -eq $max) { throw }
            Start-Sleep -Milliseconds 120
        }
    }
}

function Write-JsonRelay {
    $relayDir = Split-Path -Parent $relayPath
    if (-not (Test-Path $relayDir)) {
        New-Item -ItemType Directory -Path $relayDir -Force | Out-Null
    }
    $record = [ordered]@{
        timestamp = $time
        level = $Level
        message = $Message
        skill = $Skill
        change_id = $ChangeId
        phase = $Phase
        suite = $Suite
        test_point = $TestPoint
        test_status = $TestStatus
        attempt = $Attempt
        max_attempts = $MaxAttempts
    }
    $jsonLine = $record | ConvertTo-Json -Compress
    $max = 10
    for ($i = 1; $i -le $max; $i++) {
        try {
            Add-Content -Path $relayPath -Value $jsonLine -Encoding UTF8
            return
        } catch {
            if ($i -eq $max) { throw }
            Start-Sleep -Milliseconds 120
        }
    }
}

switch ($transportMode.ToLowerInvariant()) {
    "realtime" {
        Write-RealtimeLog -Line $line
    }
    "json" {
        try {
            Write-JsonRelay
        } catch {
            if ($fallbackToRealtime) {
                Write-RealtimeLog -Line $line
            } else {
                throw
            }
        }
    }
    "hybrid" {
        Write-RealtimeLog -Line $line
        try {
            Write-JsonRelay
        } catch {
            if (-not $fallbackToRealtime) {
                throw
            }
        }
    }
    default {
        Write-RealtimeLog -Line $line
    }
}

Write-Output "written: $line"
Write-Output "log_file: $logFile"
if ($transportMode -in @("json", "hybrid")) {
    Write-Output "relay_file: $relayPath"
}
