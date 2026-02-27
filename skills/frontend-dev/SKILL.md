---
name: frontend-dev
description: Develop frontend code based on API docs and page structure, with continuous testing and iteration until all requirements pass
---

# Frontend Development and Acceptance

## Task Goals

- This Skill develops a complete frontend app based on backend API docs and page structure
- Capabilities include project structure generation, component development, API client integration, acceptance testing, and iterative optimization
- Trigger condition: requirements planning, API design, and backend codegen completed

## Prerequisites

- Dependencies: generate docs using:
  - [requirement-planning](../requirement-planning/SKILL.md): requirements list, user flows, feature priority, tech stack
  - [api-design](../api-design/SKILL.md): page list, field definitions, API list
  - [backend-codegen](../backend-codegen/SKILL.md): data models, backend implementation
- Tech stack reading: read frontend stack selection, including:
  - Frontend framework (React / Vue / Angular / other)
  - State management (Redux / Vuex / MobX / other)
  - Build tool (Webpack / Vite / other)
  - UI framework (Ant Design / Element UI / Material-UI / other)
- Required contract checks (prevent missing outputs):
  - Read `agent-config.json -> skills.frontend-dev.validation.required`
  - Convert required outputs into a phase acceptance checklist
  - Before phase ends, verify these paths exist:
    - `test/frontend-dev/test-report.md`
    - `test/frontend-dev/test-summary.json`
    - `test/frontend-dev/e2e-test-report.md`
    - `test/frontend-dev/e2e-test-summary.json`
    - `test/frontend-dev/e2e-test-matrix.md`

## Development Flow

### Phase 1: Initialize Project

1. **Read documents**
  - Page list: understand pages to build
  - Field definitions: fields and validation rules per page
  - API list: available APIs
  - Requirements list: functional requirements and acceptance criteria
  - Tech stack: confirm framework and tooling
2. **Plan project structure**
  - Follow [references/project-structure.md](references/project-structure.md)
  - Create layered structure (components, pages, api, utils, store)
  - Configure routing
  - Configure state management
  - **Must create real project directory**: create frontend project at repo root (e.g., `frontend/`)

### Phase 2: Develop Components

1. **Generate page components**
  - Follow [references/component-template.md](references/component-template.md)
  - Build component code per page
  - Implement common page types (forms, lists, detail)
  - Implement validation and error prompts
2. **Develop API client**
  - Follow [references/api-client-template.md](references/api-client-template.md)
  - Wrap HTTP client (axios / fetch)
  - Implement request/response interceptors
  - Implement token auth and error handling
3. **Implement user flows**
  - Connect pages based on user flow docs
  - Implement navigation logic
  - Implement exception handling and error prompts

### Phase 3: Test and Acceptance

1. **Read acceptance criteria**
  - Read all requirements from requirements doc
  - Extract acceptance criteria for each requirement (defined in planning)
  - Generate test checklist
2. **Test against acceptance criteria**
  - Follow [references/test-checklist.md](references/test-checklist.md)
  - Verify each acceptance criterion
  - Record failed items
3. **Functional tests**
  - Verify all page functions
  - Test form submit and validation
  - Test API calls and data display
  - Verify complete user flows
4. **UI tests**
  - Check layout correctness
  - Check field display matches design
  - Check responsive layout
  - Check interaction feedback

### Phase 4: Iterative Optimization

1. **Analyze test results**
  - List all failed acceptance criteria
  - Analyze root causes (logic, UI, API)
  - Create fix plan
2. **Modify code**
  - Follow [references/iteration-guide.md](references/iteration-guide.md)
  - Fix defects
  - Optimize UX
  - Improve code quality
3. **Retest**
  - Re-run acceptance tests
  - Confirm fixes
  - Check for regressions
4. **Iterate**
  - Repeat test → fix → test
  - Until all acceptance criteria pass

### Phase 5: Delivery Confirmation

1. **Final acceptance**
  - Confirm all acceptance criteria item-by-item
  - Confirm all functions work
  - Confirm code quality
2. **Delivery docs**
  - Organize frontend code
  - Provide deployment instructions
  - Provide usage docs
  - Write test docs to `test/frontend-dev/`
  - Write code to project directory at repo root (do not write into `output/`)

## Iteration Mechanism

### Test-Driven Iteration

```
Dev → Test acceptance → All pass?
                       ↙        ↘
                      Yes       No
                      ↓         ↓
                   Deliver    Fix code
                               ↓
                           Retest
```

### Acceptance Checklist

- [ ] REQ-001 acceptance 1
- [ ] REQ-001 acceptance 2
- [ ] REQ-002 acceptance 1

- ... (all acceptance criteria)

### Iteration Exit Criteria

**All of the following must pass to deliver:**

1. All P0 acceptance criteria pass
2. All P1 acceptance criteria pass
3. Code quality meets standard (no critical bugs, no performance issues)
4. Good UX (responsive, friendly interactions)

**If any of the following exist, continue iterating:**

1. Any acceptance criteria fail
2. Critical bug exists (feature unusable)
3. Performance issues (slow, lag)
4. Security issues (XSS, CSRF, etc.)

## Resource Index

- Frontend project structure: see [references/project-structure.md](references/project-structure.md)
- Component template: see [references/component-template.md](references/component-template.md)
- API client template: see [references/api-client-template.md](references/api-client-template.md)
- Test checklist: see [references/test-checklist.md](references/test-checklist.md)
- Iteration guide: see [references/iteration-guide.md](references/iteration-guide.md)

## Notes

- Strictly test against acceptance criteria
- If not passing, keep fixing; do not lower criteria
- Retest after each change to avoid regressions
- Maintain code quality, avoid hacks
- Fix P0 and P1 issues first
- Record each test and fix
- **Output isolation**: `output/` for docs/reports only; source code must be in project directory at repo root

## Usage Examples

**Example 1: E-commerce Frontend (React)**

- Input: page list (home, product list, cart, checkout) + API list + requirements list
- Output:
  - React project structure
  - Page components (product list, cart, checkout)
  - API client (axios wrapper)
  - Test acceptance report (all pass after 3 iterations)

**Example 2: User System Frontend (Vue)**

- Input: page list (register, login, profile) + API list + requirements list
- Output:
  - Vue project structure
  - Page components (register, login, profile)
  - API client (axios wrapper)
  - Test acceptance report (all pass after 2 iterations)

**Example 3: Admin Frontend (Angular)**

- Input: page list (user management, analytics, settings) + API list + requirements list
- Output:
  - Angular project structure
  - Page components (user list, charts)
  - API client (HttpClient wrapper)
  - Test acceptance report (all pass after 4 iterations)

## Supported Frontend Tech Stacks

### React Stack

- Framework: React 18+
- State management: Redux Toolkit / Zustand
- Routing: React Router v6
- UI framework: Ant Design / Material-UI
- HTTP client: axios
- Build tool: Vite / Create React App

### Vue Stack

- Framework: Vue 3
- State management: Pinia / Vuex 4
- Routing: Vue Router 4
- UI framework: Element Plus / Ant Design Vue
- HTTP client: axios
- Build tool: Vite / Vue CLI

### Angular Stack

- Framework: Angular 16+
- State management: NgRx / Signals
- Routing: Angular Router
- UI framework: Angular Material / NG-ZORRO
- HTTP client: HttpClient
- Build tool: Angular CLI

## Additions (Aligned with agent.md)

1. Frontend testable coverage must be 100%.
2. Report uses `REQ item -> FE test point -> result -> evidence` trace matrix.
3. Interaction acceptance must be covered by E2E, not API-only cases.
4. E2E points auto-derived from `output/requirement-planning-requirements.md`.
5. Must produce: `test/frontend-dev/test-report.md`, `test/frontend-dev/test-summary.json`, `test/frontend-dev/e2e-test-report.md`, `test/frontend-dev/e2e-test-summary.json`, `test/frontend-dev/e2e-test-matrix.md`.
6. Single-point failure max 5 retries; after limit SKIP allowed with impact logged.

## ADDON_AGENT_ALIGNMENT

- source: agent.md
- policy: additive only, do not replace original content
- test_gate: 100%
- retry_per_point: 5
- failure_loop: diagnose -> fix -> retest
- log_file: logs/workflow.log
- report_mode: requirement_traceability
- e2e_required_for_interaction: true
- required_outputs: test/frontend-dev/test-report.md,test/frontend-dev/test-summary.json,test/frontend-dev/e2e-test-report.md,test/frontend-dev/e2e-test-summary.json,test/frontend-dev/e2e-test-matrix.md
