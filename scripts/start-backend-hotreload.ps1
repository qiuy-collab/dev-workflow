param(
    [string]$Root = ".",
    [string]$AppHost = "127.0.0.1",
    [int]$Port = 0,
    [switch]$ReplaceExisting = $true,
    [string]$BackendCommand = ""
)

$ErrorActionPreference = "Stop"

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try {
        return Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Resolve-Command {
    param(
        [object]$Config,
        [string]$BackendStack,
        [string]$BackendDir,
        [string]$AppHost,
        [int]$Port,
        [string]$OverrideCommand
    )

    if ($OverrideCommand) {
        return $OverrideCommand
    }

    $startCommand = $null
    if ($Config -and $Config.deployment -and $Config.deployment.backend -and $Config.deployment.backend.startCommand) {
        $startCommand = [string]$Config.deployment.backend.startCommand
    }

    $template = $null
    if ($Config -and $Config.runtime -and $Config.runtime.hotReload -and $Config.runtime.hotReload.backendCommands) {
        $map = $Config.runtime.hotReload.backendCommands
        $exact = $map.PSObject.Properties | Where-Object { $_.Name -eq $BackendStack } | Select-Object -First 1
        if ($exact) {
            $template = [string]$exact.Value
        } elseif ($BackendStack -match "Rust" -and $map.PSObject.Properties["Rust (Axum)"]) {
            $template = [string]$map.PSObject.Properties["Rust (Axum)"].Value
        } elseif ($BackendStack -match "FastAPI|Python" -and $map.PSObject.Properties["Python (FastAPI)"]) {
            $template = [string]$map.PSObject.Properties["Python (FastAPI)"].Value
        } elseif ($BackendStack -match "Spring|Java" -and $map.PSObject.Properties["Java (Spring Boot)"]) {
            $template = [string]$map.PSObject.Properties["Java (Spring Boot)"].Value
        } elseif ($BackendStack -match "Express|Node" -and $map.PSObject.Properties["Node.js (Express)"]) {
            $template = [string]$map.PSObject.Properties["Node.js (Express)"].Value
        }
    }

    if (-not $template) {
        if (Test-Path (Join-Path $BackendDir "Cargo.toml")) {
            $template = "cargo watch -x run"
        } elseif (Test-Path (Join-Path $BackendDir "package.json")) {
            $template = "npm run dev"
        } elseif (Test-Path (Join-Path $BackendDir "pom.xml")) {
            $template = "mvn spring-boot:run"
        } elseif (Test-Path (Join-Path $BackendDir "requirements.txt") -or Test-Path (Join-Path $BackendDir "pyproject.toml")) {
            $template = "uvicorn app.main:app --reload --host {HOST} --port {PORT}"
        } elseif ($startCommand) {
            $template = $startCommand
        } else {
            throw "cannot resolve backend start command (stack=$BackendStack)"
        }
    }

    $resolved = $template `
        -replace "\{HOST\}", $AppHost `
        -replace "\{PORT\}", "$Port"

    if ($startCommand) {
        $resolved = $resolved -replace "\{startCommand\}", $startCommand
    } else {
        $resolved = $resolved -replace "\{startCommand\}", ""
    }

    if ($resolved -match "^cargo watch" -and -not (Get-Command cargo-watch -ErrorAction SilentlyContinue)) {
        $resolved = "cargo run"
    }

    return $resolved.Trim()
}

function Stop-ProcessesByCommandline {
    param(
        [string[]]$Names,
        [string]$MatchText
    )
    $targets = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        ($Names -contains $_.Name) -and $_.CommandLine -and ($_.CommandLine -like "*$MatchText*")
    }
    foreach ($target in $targets) {
        try {
            Stop-Process -Id $target.ProcessId -Force -ErrorAction Stop
            Write-Output "stopped process by commandline: name=$($target.Name) pid=$($target.ProcessId)"
        } catch {
            Write-Output "warn: failed to stop pid=$($target.ProcessId): $($_.Exception.Message)"
        }
    }
}

$rootPath = Resolve-Path $Root
$backendDir = Join-Path $rootPath "backend"
$configPath = Join-Path $rootPath "agent-config.json"
$techStackPath = Join-Path $rootPath "output/requirement-planning-tech-stack.json"
$runtimeDir = Join-Path $rootPath "runtime"

if (-not (Test-Path $backendDir)) {
    throw "backend directory not found: $backendDir"
}

if (-not (Test-Path $runtimeDir)) {
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
}

$config = Read-JsonFile -Path $configPath
$techStack = Read-JsonFile -Path $techStackPath
$backendStack = if ($techStack -and $techStack.backend) { [string]$techStack.backend } else { "" }

if ($Port -le 0) {
    if ($config -and $config.deployment -and $config.deployment.backend -and $config.deployment.backend.port) {
        $Port = [int]$config.deployment.backend.port
    } else {
        $Port = 18080
    }
}

$pidFile = Join-Path $runtimeDir "backend-hotreload.pid"
$cmdFile = Join-Path $runtimeDir "backend-hotreload.command.txt"

if ($ReplaceExisting) {
    if (Test-Path $pidFile) {
        $oldPid = (Get-Content -Path $pidFile -Encoding UTF8 | Select-Object -First 1).Trim()
        if ($oldPid -match "^\d+$") {
            try {
                Stop-Process -Id ([int]$oldPid) -Force -ErrorAction Stop
                Write-Output "stopped previous backend hotreload supervisor: pid=$oldPid"
            } catch {
                Write-Output "warn: failed to stop previous pid=${oldPid}: $($_.Exception.Message)"
            }
        }
    }

    Stop-ProcessesByCommandline -Names @("cargo-watch.exe", "cargo.exe", "backend.exe", "powershell.exe") -MatchText $backendDir

    $listeners = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        try {
            Stop-Process -Id $listener.OwningProcess -Force -ErrorAction Stop
            Write-Output "stopped process on port ${Port}: pid=$($listener.OwningProcess)"
        } catch {
            Write-Output "warn: failed to stop pid=$($listener.OwningProcess): $($_.Exception.Message)"
        }
    }
}

$resolvedCommand = Resolve-Command `
    -Config $config `
    -BackendStack $backendStack `
    -BackendDir $backendDir `
    -AppHost $AppHost `
    -Port $Port `
    -OverrideCommand $BackendCommand

Set-Content -Path $cmdFile -Value $resolvedCommand -Encoding UTF8

$launch = @"
Set-Location '$backendDir'
`$env:APP_HOST='$AppHost'
`$env:APP_PORT='$Port'
`$env:PORT='$Port'
$resolvedCommand
"@

$proc = Start-Process -FilePath "powershell" `
    -ArgumentList @("-NoProfile", "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $launch) `
    -PassThru `
    -WindowStyle Normal

Set-Content -Path $pidFile -Value $proc.Id -Encoding UTF8

Start-Sleep -Seconds 3

Write-Output "backend hot reload started"
Write-Output "pid: $($proc.Id)"
Write-Output "stack: $backendStack"
Write-Output "command: $resolvedCommand"
Write-Output "url: http://${AppHost}:${Port}"
Write-Output "logs: terminal only (no file sink)"
Write-Output "pid_file: $pidFile"
Write-Output "command_file: $cmdFile"
