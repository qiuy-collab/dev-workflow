param(
    [string]$Root = ".",
    [string]$AppHost = "127.0.0.1",
    [int]$Port = 0,
    [switch]$ReplaceExisting = $true,
    [string]$FrontendCommand = ""
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

function Resolve-FrontendCommand {
    param(
        [object]$Config,
        [string]$FrontendDir,
        [string]$AppHost,
        [int]$Port,
        [string]$OverrideCommand
    )

    if ($OverrideCommand) {
        return $OverrideCommand
    }

    $template = $null
    if ($Config -and $Config.runtime -and $Config.runtime.hotReload -and $Config.runtime.hotReload.frontendCommand) {
        $template = [string]$Config.runtime.hotReload.frontendCommand
    }

    if (-not $template) {
        $packagePath = Join-Path $FrontendDir "package.json"
        if (Test-Path $packagePath) {
            $packageJson = Get-Content -Path $packagePath -Encoding UTF8 | ConvertFrom-Json
            if ($packageJson.scripts.dev) {
                $template = "npm run dev -- --host {HOST} --port {PORT}"
            } elseif ($packageJson.scripts.start) {
                $template = "npm start"
            }
        }
    }

    if (-not $template) {
        throw "cannot resolve frontend start command"
    }

    $resolved = $template `
        -replace "\{HOST\}", $AppHost `
        -replace "\{PORT\}", "$Port"

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
$frontendDir = Join-Path $rootPath "frontend"
$configPath = Join-Path $rootPath "agent-config.json"
$runtimeDir = Join-Path $rootPath "runtime"

if (-not (Test-Path $frontendDir)) {
    throw "frontend directory not found: $frontendDir"
}

if (-not (Test-Path $runtimeDir)) {
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
}

$config = Read-JsonFile -Path $configPath

if ($Port -le 0) {
    if ($config -and $config.deployment -and $config.deployment.frontend -and $config.deployment.frontend.port) {
        $Port = [int]$config.deployment.frontend.port
    } else {
        $Port = 3000
    }
}

$pidFile = Join-Path $runtimeDir "frontend-hotreload.pid"
$cmdFile = Join-Path $runtimeDir "frontend-hotreload.command.txt"

if ($ReplaceExisting) {
    if (Test-Path $pidFile) {
        $oldPid = (Get-Content -Path $pidFile -Encoding UTF8 | Select-Object -First 1).Trim()
        if ($oldPid -match "^\d+$") {
            try {
                Stop-Process -Id ([int]$oldPid) -Force -ErrorAction Stop
                Write-Output "stopped previous frontend hotreload supervisor: pid=$oldPid"
            } catch {
                Write-Output "warn: failed to stop previous pid=${oldPid}: $($_.Exception.Message)"
            }
        }
    }

    Stop-ProcessesByCommandline -Names @("node.exe", "npm.cmd", "powershell.exe") -MatchText $frontendDir

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

$resolvedCommand = Resolve-FrontendCommand `
    -Config $config `
    -FrontendDir $frontendDir `
    -AppHost $AppHost `
    -Port $Port `
    -OverrideCommand $FrontendCommand

Set-Content -Path $cmdFile -Value $resolvedCommand -Encoding UTF8

$launch = @"
Set-Location '$frontendDir'
`$env:HOST='$AppHost'
`$env:PORT='$Port'
$resolvedCommand
"@

$proc = Start-Process -FilePath "powershell" `
    -ArgumentList @("-NoProfile", "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $launch) `
    -PassThru `
    -WindowStyle Normal

Set-Content -Path $pidFile -Value $proc.Id -Encoding UTF8

Start-Sleep -Seconds 2

Write-Output "frontend hot reload started"
Write-Output "pid: $($proc.Id)"
Write-Output "command: $resolvedCommand"
Write-Output "url: http://${AppHost}:${Port}"
Write-Output "logs: terminal only (no file sink)"
Write-Output "pid_file: $pidFile"
Write-Output "command_file: $cmdFile"
