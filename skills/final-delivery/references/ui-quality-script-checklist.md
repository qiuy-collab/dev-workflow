# UI Quality Verification via Script (Checklist)

Use this checklist when running `FD-UI-001` in `final-delivery` with `testing.uiQualityCheck.mode=script`.

## Scope (Mandatory)
- Spacing consistency on **all pages**
- Style consistency for at least **4 component types**:
  - Button
  - Input
  - Card
  - List
- Interaction states:
  - hover
  - active
  - focus
  - disabled

## Evidence (Mandatory)
Include script outputs:
- Test assertions
- Command logs
- Report references

## Steps
1. Run frontend UI/script verification in delivery stage.
2. Verify all pages/views are covered by script cases.
3. Verify 4 component types and 4 interaction states are asserted.
4. Capture command output and assertion summaries.
5. Attach evidence to `test/final-delivery/comprehensive-report.md`.

## Result Template
```
FD-UI-001
Mode: script
Pages: <all covered page names>
Components: Button/Input/Card/List
States: hover/active/focus/disabled
Findings: <pass | issues>
Evidence:
- <test command output ref>
- <assertion/report ref>
```
