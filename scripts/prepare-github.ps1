param(
    [string]$Root = ".",
    [switch]$PurgeArtifacts = $false,
    [switch]$RemoveNestedBackendGit = $false
)

$ErrorActionPreference = "Stop"
$rootPath = Resolve-Path $Root

Write-Output "repo_root: $rootPath"
Write-Output "purge_artifacts: $PurgeArtifacts"
Write-Output "remove_nested_backend_git: $RemoveNestedBackendGit"

$artifactPaths = @(
    "test/test-points.jsonl",
    "runtime/curl-resp.json",
    "runtime/curl-valid.md",
    "runtime/tmp-import.md",
    "runtime/tmp-import-valid.md",
    "runtime/tmp-import-invalid.md",
    "test/frontend-dev/test-report.md",
    "test/frontend-dev/test-summary.json",
    "test/frontend-dev/e2e-test-report.md",
    "test/frontend-dev/e2e-test-summary.json",
    "test/frontend-dev/e2e-test-matrix.md",
    "test/backend-scaffold/api-test-report.md",
    "test/backend-scaffold/api-test-summary.json",
    "test/backend-core/comprehensive-test-report.md",
    "test/backend-core/comprehensive-test-summary.json",
    "test/final-delivery/comprehensive-report.md",
    "output/sync-hash-report.json"
)

if ($PurgeArtifacts) {
    foreach ($rel in $artifactPaths) {
        $path = Join-Path $rootPath $rel
        if (Test-Path $path) {
            Remove-Item -Force $path
            Write-Output "removed: $rel"
        }
    }
} else {
    Write-Output "skip purge (use -PurgeArtifacts to remove generated test artifacts)"
}

if ($RemoveNestedBackendGit) {
    $nestedGit = Join-Path $rootPath "backend/.git"
    if (Test-Path $nestedGit) {
        Remove-Item -Recurse -Force $nestedGit
        Write-Output "removed: backend/.git"
    }
} else {
    Write-Output "skip nested git cleanup (use -RemoveNestedBackendGit to remove backend/.git)"
}

Write-Output "prepare-github done"
