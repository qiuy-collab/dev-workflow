---
name: ui-ux-pro-max-local
description: Generate workflow-aligned UI design artifacts (`ui-spec.md`, `ui-tokens.json`) before frontend-dev using local UI/UX Pro Max data and scripts
---

# UI UX Pro Max Local

## Task Goals
- This Skill standardizes UI design outputs for the workflow and bridges requirement/api docs to frontend implementation inputs.
- It must run after `backend-codegen` and before `frontend-dev`.
- It must produce design-system source docs first, then derive executable UI artifacts.

## Prerequisites
- Dependencies:
  - [requirement-planning](../requirement-planning/SKILL.md): requirements, flow, style confirmation, initial UI draft
  - [api-design](../api-design/SKILL.md): API list and data models
  - [backend-codegen](../backend-codegen/SKILL.md): implementation constraints and field consistency
- Required input files:
  - `output/requirement-planning-requirements.md`
  - `output/requirement-planning-tech-stack.json`
  - `output/api-design-api-list.md`
  - `output/api-design-data-models.md`
  - `output/ui/ui-spec.md` (draft from requirement-planning)
  - `output/ui/ui-tokens.json` (draft from requirement-planning)
  - `output/ui/ui-quality-metrics.md` (draft from requirement-planning)

## Workflow

### Phase 1: Read and Normalize Inputs
1. Read requirement docs, user flow, page list, and confirmed UI style.
2. Read API and data model docs to bind fields/states/actions to UI.
3. Read requirement-planning UI draft files and quality metrics, then mark gaps to refine.

### Phase 2: Build Design-System Sources (Mandatory First)
1. Generate `design-system/MASTER.md`:
  - design principles
  - layout grid and spacing system
  - component families and state rules
  - style direction constraints
2. Generate `design-system/pages/*.md` (at least one page file):
  - page goal and route
  - component structure and hierarchy
  - state/interaction behavior
  - API/field mapping

### Phase 3: Derive Executable UI Artifacts (Mandatory Second)
1. Refine and overwrite `output/ui/ui-spec.md` based on design-system docs.
2. Refine and overwrite `output/ui/ui-tokens.json` based on design-system docs.
3. Refine and overwrite `output/ui/ui-quality-metrics.md` with measurable thresholds.
4. Ensure every requirement page has a section in `ui-spec.md`.
5. Ensure token file includes component-level tokens and state tokens (not only global tokens).

### Phase 4: Contract Validation
1. Validate required outputs exist and are non-empty.
2. Validate `ui-spec` and `ui-tokens` are consistent with `design-system/MASTER.md` and `design-system/pages/*.md`.
3. If inconsistent, fix in this Skill and re-validate before exit.

## Required Outputs
- `design-system/MASTER.md`
- `design-system/pages/*.md` (at least one page file)
- `output/ui/ui-spec.md`
- `output/ui/ui-tokens.json`
- `output/ui/ui-quality-metrics.md`

## Handoff Contracts
- `frontend-dev` must treat `output/ui/ui-spec.md` and `output/ui/ui-tokens.json` as implementation baseline.
- `frontend-dev` must treat `output/ui/ui-quality-metrics.md` as visual quality baseline (non-test implementation contract).
- `final-delivery` must verify:
  - required UI artifacts exist
  - UI behavior matches spec and token constraints

## Resource Index
- Workflow rules: `references/workflow-rules.md`
- UI spec template: `references/ui-spec-template.md`
- UI tokens template: `references/ui-tokens-template.json`

## Notes
- Do not skip ordered generation (design-system first, executable artifacts second).
- Do not keep requirement-planning draft values when they conflict with confirmed design-system output.
- Keep naming stable to reduce frontend refactor churn.

## Additions (Aligned with agent.md)
1. This Skill is a mandatory gate before `frontend-dev`.
2. Required output existence check must pass before phase end.
3. No fabricated outputs: files must be generated from real project context and references.
