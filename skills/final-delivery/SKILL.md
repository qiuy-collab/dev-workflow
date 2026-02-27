---
name: final-delivery
description: Final delivery stage. Run integration validation and delivery completeness checks, and generate the final test report and delivery manifest. Use only after requirement-planning, api-design, backend-codegen, frontend-dev, backend-scaffold, and backend-core are completed.
---

# final-delivery

## Goals
- Verify that front end and back end can run and are integrated.
- Recheck that required documents, configurations, and test summaries are complete.
- Generate the final delivery report and delivery manifest.

## Prerequisites
- The following skills must be completed:
  - `requirement-planning`
  - `api-design`
  - `backend-codegen`
  - `frontend-dev`
  - `backend-scaffold`
  - `backend-core`
- Required inputs must exist:
  - `output/requirement-planning-requirements.md`
  - `output/requirement-planning-tech-stack.json`
  - `output/api-design-api-list.md`
  - `output/api-design-data-models.md`
  - `test/frontend-dev/test-summary.json`
  - `test/backend-scaffold/api-test-summary.json`
  - `test/backend-core/comprehensive-test-summary.json`
- Preflight must run before execution:
  - `scripts/check-workflow-preflight.ps1 -Root .`

## Script
Use: `scripts/final-delivery.ps1`

Example:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/final-delivery.ps1 -Mode all -Environment local
```

## Outputs
- `test/final-delivery/comprehensive-report.md`
- `output/final-delivery/delivery-summary.json`
- `output/final-delivery/delivery-manifest.md`
- Test point relay: `test/test-points.jsonl`

## Execution Rules
1. Execute test points in order: `FD-RUN-001`, `FD-RUN-002`, `FD-INT-001`, `FD-DOC-001`, `FD-CONF-001`.
2. Each test point may retry up to 5 times; record `FAIL` on failure, `RETRY` on retries, `SKIP` when the limit is exceeded.
3. Write test logs to `logs/workflow.log`, and also to `test/test-points.jsonl`.
4. All file writes must explicitly use UTF-8 encoding.
5. Must write test-level boundary logs:
   - `NEW_TEST_SUITE_START/END`
   - `NEW_TEST_GROUP_START/END`

## Modes
- `all`: run tests and generate delivery outputs (default)
- `test`: run final-delivery tests only and generate the comprehensive report
- `package`: only generate delivery summary and manifest (do not rerun tests)

## Gate Requirements
- final-delivery pass rate must be `100%`.
- Delivery manifest must match actual outputs one-to-one.
- If upstream outputs are missing, list missing files and impact scope clearly in the report.
