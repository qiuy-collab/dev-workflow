param(
    [string]$Root = ".",
    [switch]$CreateCombined = $true
)

$rootPath = Resolve-Path $Root
Write-Output "runtime log file sync has been disabled by policy"
Write-Output "root: $rootPath"
Write-Output "frontend/backend logs are now terminal-only"
