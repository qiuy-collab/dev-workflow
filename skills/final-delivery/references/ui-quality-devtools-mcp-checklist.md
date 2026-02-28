# UI Quality Spot-Check via Chrome DevTools MCP (Checklist)

Use this checklist when running `FD-UI-001` in `final-delivery` with `testing.uiQualityCheck.mode=devtools-mcp`.

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
Include DevTools MCP outputs:
- Screenshots or
- Logs/console output references

## Steps
1. Launch the frontend and open target pages.
2. Use DevTools MCP to inspect spacing (layout/padding/margins).
3. Verify component styling against tokens (font/size/radius/shadow).
4. Trigger interaction states and verify visual consistency.
5. Capture evidence and attach to `test/final-delivery/comprehensive-report.md`.

## Result Template
```
FD-UI-001
Pages: <page-1>, <page-2>
Components: Button/Input/Card/List
States: hover/active/focus/disabled
Findings: <pass | issues>
Evidence:
- <screenshot/log ref 1>
- <screenshot/log ref 2>
```
