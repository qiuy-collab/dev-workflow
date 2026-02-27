# Workflow Configuration Guide

This guide helps users modify `agent-config.json` to customize workflow behavior.

## 1. Pre-Change Checks

1. Back up the current config first:

```powershell
Copy-Item agent-config.json agent-config.backup.json
```

2. Validate JSON after changes:

```powershell
Get-Content -Raw agent-config.json | ConvertFrom-Json | Out-Null
```

## 2. Most Common Settings

### 2.1 Run Mode

- `workflow.autoMode`
  - `true`: automatically execute subsequent steps after requirements are completed
  - `false`: confirm before each step
- `workflow.forceQuestioningOnFirstSkill`
  - `true`: only the first Skill enforces mandatory questioning
- `workflow.forceRequirementClarificationBeforeOutput`
  - `true`: do not output the final requirement document until key requirements are clarified

### 2.2 Testing and Retries

- `validation.testThreshold.frontend` / `validation.testThreshold.backend`
  - `1.0` means 100%
- `validation.maxRetries`
  - Max retries per test point, recommended `5`
- `validation.autoFixOnFailure`
  - Whether to automatically enter fix-and-retest flow on test failure

### 2.3 Test Write Mode

- `testing.pointTransportMode`
  - `realtime`: write only to `logs/workflow.log`
  - `json`: write only to `test/test-points.jsonl`
  - `hybrid`: write to both (recommended)
- `testing.pointTransportOptions.fallbackToRealtimeOnJsonError`
  - Whether to fall back to realtime logs if JSON relay fails

### 2.3.1 Test Level Markers (Suite/Group)

- Logs must include test level boundary markers with level `INFO`:
  - Suite start/end: `NEW_TEST_SUITE_START` / `NEW_TEST_SUITE_END`
  - Group start/end within a suite: `NEW_TEST_GROUP_START` / `NEW_TEST_GROUP_END`
- Recommended field conventions:
  - `phase=test`
  - `suite=<suite-name>`
  - `test_point=TEST-SUITE-*` or `test_point=TEST-GROUP-*`
  - `test_status=START|END`
- Purpose: quickly distinguish “which suite/group is running” in `logs/workflow.log` and `test/test-points.jsonl`, avoiding stacked test points that are hard to track.

### 2.3.2 Pre-Test Required Reads (Prevent Missing Outputs)

- `testing.preflight.requirePreflightGate`
  - `true`: must run preflight checks before `run-workflow-tests.ps1`; do not start if it fails.
- `testing.preflight.requiredFilesBeforeWorkflowTests`
  - The list of files that must be verified before testing (recommended to include requirement/api/codegen outputs and the E2E matrix).
- `testing.preflight.requiredServiceEndpoints`
  - The list of service endpoints that must be reachable before testing (e.g., frontend URL, backend health URL).
- Supporting script:
  - `./scripts/check-workflow-preflight.ps1 -Root .`
  - Purpose: output missing files and unreachable services at once, avoiding the agent missing context due to only the first error.
- Serial requirement:
  - `run-workflow-tests.ps1` and `final-delivery.ps1` must run sequentially, not concurrently, to avoid file locks when both write `test/test-points.jsonl`.

### 2.4 Frontend Acceptance Mode

- `testing.frontendReportMode`
  - `requirement-traceability`: map `REQ` items one-to-one (recommended)
  - `smoke-summary`: smoke summary only
- `testing.frontendReportOptions.requireEvidenceForPass`
  - `true`: PASS must have evidence
- `testing.frontendE2E.enabled`
  - Whether to enable E2E
- `testing.frontendE2E.requireInteractionAcceptance`
  - `true`: interaction acceptance must be covered by E2E

### 2.5 Skills Source Strategy

- `skillResolution.preferredSource`
  - `global`: prefer global `C:/Users/34109/.codex/skills`
  - `local`: prefer repo-local `./skills`
- `skillResolution.fallbackToLocal`
  - Whether to fall back to local if global is unavailable
- `skillResolution.logResolution`
  - Whether to log source resolution decisions

### 2.6 Write Encoding Constraints

- Config files, logs, reports, and JSON outputs must use UTF-8.
- PowerShell writes must explicitly specify `-Encoding UTF8`; do not rely on system defaults.
- This is a workflow implementation constraint and is not recommended to change to other encodings.

### 2.7 Required Output Contract Validation (Prevent Agent Misses)

- `validation.enforceRequiredOutputCheck`
  - `true`: each Skill must read and enforce `skills.<skill>.validation.required`
- `validation.failOnMissingRequiredOutput`
  - `true`: if any required output is missing, immediately mark the phase as failed and do not proceed
- `validation.requiredOutputSource`
  - Recommended fixed value: `skills.<skill>.validation.required`

## 3. Common Configuration Templates

### 3.1 Full Auto Strict Mode (Recommended)

```json
{
  "workflow": {
    "autoMode": true,
    "forceQuestioningOnFirstSkill": true,
    "forceRequirementClarificationBeforeOutput": true
  },
  "validation": {
    "maxRetries": 5,
    "autoFixOnFailure": true,
    "testThreshold": {
      "frontend": 1.0,
      "backend": 1.0
    }
  },
  "testing": {
    "pointTransportMode": "hybrid",
    "frontendReportMode": "requirement-traceability",
    "frontendE2E": {
      "enabled": true,
      "requireInteractionAcceptance": true
    }
  }
}
```

### 3.2 Step-by-Step Confirmation Mode (Manual Gate)

```json
{
  "workflow": {
    "autoMode": false,
    "forceQuestioningOnFirstSkill": true,
    "forceRequirementClarificationBeforeOutput": true
  }
}
```

### 3.3 Lightweight Debug Mode (Local Troubleshooting)

```json
{
  "validation": {
    "maxRetries": 2,
    "continueOnError": true
  },
  "testing": {
    "pointTransportMode": "realtime",
    "frontendReportMode": "smoke-summary",
    "frontendE2E": {
      "enabled": false
    }
  }
}
```

## 4. Changing Workflow Order and Skills

1. Before changing the `workflow.skills` order, check each skill's `dependencies`.
2. If you change the order, ensure dependencies are placed earlier.
3. After changing order, run at least one full end-to-end test and check `logs/workflow.log`.

## 5. Ports and Startup Commands

- Change frontend port: `deployment.frontend.port`
- Change backend port: `deployment.backend.port`
- Change backend start command: `deployment.backend.startCommand`
- Tech stack hot-reload commands: `runtime.hotReload.backendCommands`

## 6. Self-Check List

- [ ] `agent-config.json` parses as valid JSON
- [ ] `autoMode` matches the collaboration mode
- [ ] Test gate thresholds are as expected (e.g., 100%)
- [ ] Retry count and auto-fix switch match expectation
- [ ] Test write mode matches expectation (realtime/json/hybrid)
- [ ] Test preflight check passes (`scripts/check-workflow-preflight.ps1`)
- [ ] Frontend report mode and E2E switches match expectation
- [ ] Skills source strategy matches expectation (global/local)
