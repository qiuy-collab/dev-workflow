param(
    [string]$Root = ".",
    [string]$FrontendHost = "127.0.0.1",
    [int]$FrontendPort = 0,
    [string]$BackendHost = "127.0.0.1",
    [int]$BackendPort = 0,
    [switch]$ReplaceExisting = $true
)

$ErrorActionPreference = "Stop"

$rootPath = Resolve-Path $Root

& (Join-Path $PSScriptRoot "start-frontend-hotreload.ps1") `
    -Root $rootPath `
    -AppHost $FrontendHost `
    -Port $FrontendPort `
    -ReplaceExisting:$ReplaceExisting | Out-Host

& (Join-Path $PSScriptRoot "start-backend-hotreload.ps1") `
    -Root $rootPath `
    -AppHost $BackendHost `
    -Port $BackendPort `
    -ReplaceExisting:$ReplaceExisting | Out-Host

Write-Output "runtime hot reload for frontend+backend is ready"
