# Workflow Rules

## 1. Execution Stage
- Run this skill only after `requirement-planning`, `api-design`, and `backend-codegen`.
- Do not start `frontend-dev` until required outputs from this skill exist.

## 2. Data Source Priority
- Use local skill assets as source:
  - `../data/`
  - `../scripts/`
  - `../templates/`
- Use project docs as business constraints:
  - requirement/API outputs listed in `SKILL.md`.
- Use requirement-stage UI drafts as baseline inputs:
  - `output/ui/ui-spec.md`
  - `output/ui/ui-tokens.json`
  - `output/ui/ui-quality-metrics.md`

## 3. Generation Rules (Mandatory Sequence)
- Phase A: generate design-system source artifacts first:
  - `design-system/MASTER.md`
  - `design-system/pages/*.md` (at least one page file)
- Phase B: generate delivery artifacts from Phase A outputs:
  - `output/ui/ui-spec.md`
  - `output/ui/ui-tokens.json`
  - `output/ui/ui-quality-metrics.md`
- Phase B must refine and overwrite requirement-stage drafts; do not keep stale draft content.
- Do not generate `ui-spec.md` or `ui-tokens.json` before Phase A is complete.
- Keep token naming semantic and stable.
- Ensure every page in requirements has a corresponding UI section in `ui-spec.md`.
- `ui-tokens.json` must include:
  - global design tokens
  - component-level tokens (`button/input/card/list`)
  - interaction state tokens (`hover/active/focus/disabled`)

## 4. Mapping Requirements
- `design-system/MASTER.md` must define global layout/style/component conventions.
- Every `design-system/pages/*.md` must map to a real requirement page/flow.
- `ui-spec.md` and `ui-tokens.json` must explicitly align with these design-system files.
- `ui-quality-metrics.md` must define measurable thresholds for hierarchy, spacing, and interaction visibility.

## 5. Quality Gate
- `ui-spec.md` must include:
  - page contracts
  - component contracts
  - state definitions (`default/loading/empty/error/disabled`)
- `ui-tokens.json` must include:
  - color
  - typography
  - spacing
  - radius
  - shadow
  - motion
- `ui-quality-metrics.md` must include:
  - hierarchy criteria
  - layout density criteria
  - component style consistency criteria
  - interaction visibility criteria

## 6. Downstream Linkage
- `frontend-dev` reads `ui-spec.md` + `ui-tokens.json` as implementation baseline.
- `final-delivery` verifies file existence and consistency with actual UI behavior.
