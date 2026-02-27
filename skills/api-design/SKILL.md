---
name: api-design
description: Generate page list, field definitions, and API list based on requirements, supporting RESTful API design conventions
---

# API Design and Interface Planning

## Task Goals
- This Skill converts requirement documents into technical design documents
- Capabilities include page structure analysis, field definition standards, and API interface design
- Trigger condition: user provides requirements list, user flows, and feature priority docs

## Prerequisites
- Dependencies: use [requirement-planning](../requirement-planning/SKILL.md) first to generate:
  - Requirements list (functional requirements, priority, tech stack selection)
  - User flows (operation paths and exception handling)
  - Feature priorities (MVP and iteration plan)

- Tech stack reading: read the tech stack selected in the requirements list to adjust API design conventions

## Analysis Framework

### Mapping Requirements to Pages
Analyze requirement docs to identify needed frontend pages:
1. **Extract page nodes from user flows**: each operation step maps to a page
2. **Group by feature modules**: related features may merge into one page
3. **Split by user roles**: different roles may need different pages
4. **Order by priority**: use feature priority to order page development

### Deriving Fields from Pages
Analyze data needs per page:
1. **Identify business entities**: data objects (users, orders, products, etc.)
2. **Define field types**: text, number, date, select, upload, etc.
3. **Define validation rules**: required, length limits, format requirements
4. **Mark display logic**: read-only, editable, conditional display

### Mapping Pages to APIs
Analyze page-to-backend interaction needs:
1. **Page load APIs**: data needed for initialization
2. **User action APIs**: form submit, button actions
3. **Realtime update APIs**: state changes, data refresh
4. **Error handling APIs**: error prompts, retry mechanisms

## Operational Steps

### Step 1: Read Requirement Documents
- User provides the requirements list, user flows, and feature priority docs
- **Read tech stack selection**: backend language, framework, database, etc.
- Understand project background, core features, and technical constraints
- Adjust API design conventions based on the tech stack
- Identify the page scope to design

### Step 2: Generate Page List
- Follow [references/page-list-template.md](references/page-list-template.md)
- Organize pages by feature module
- Mark page priority and dependencies
- Describe core page functions

### Step 3: Define Page Fields
- Follow [references/field-definitions.md](references/field-definitions.md)
- Define field lists for each page
- Mark field types, validation rules, and display logic
- Distinguish form fields vs display-only fields

### Step 4: Design API List
- Follow [references/api-list-template.md](references/api-list-template.md)
- Organize APIs by page and module
- Follow RESTful API design conventions
- Define URL, method, request params, response params

### Step 5: Output and Confirmation
- Combine the three documents into a complete technical design document
- Ensure consistency across pages, fields, and APIs
- Request user confirmation and feedback

## Resource Index

- Page list template: see [references/page-list-template.md](references/page-list-template.md)
- Field definition spec: see [references/field-definitions.md](references/field-definitions.md)
- API list template: see [references/api-list-template.md](references/api-list-template.md)

## Notes

- Adjust API design conventions based on the chosen tech stack
- **RESTful API conventions apply to most web frameworks** (e.g., FastAPI, Spring Boot, Express)
- Different frameworks may have different naming conventions (URL paths, parameter formats)
- Use plural nouns for endpoint names (e.g., /users, /orders)
- Use JSON for data interchange
- Define clear error codes and error messages for each API
- Consider API idempotency and security
- Use consistent camelCase or snake_case field naming

## Usage Examples

**Example 1: E-commerce API Design**
- Input: requirements list (browse products, cart, order), user flow (login → browse → add to cart → checkout)
- Output: page list (home, product detail, cart, checkout), field definitions (product info, order fields), API list (GET /products, POST /orders)

**Example 2: User System API Design**
- Input: requirements list (register, login, profile), user flow (register → verify → login → profile)
- Output: page list (register, login, profile), field definitions (user info fields), API list (POST /register, POST /login, GET /user/profile)

## Additions (Aligned with agent.md)
1. Build `REQ-xxx -> API-xxx` mapping; core acceptance item coverage must be 100%.
2. Each API must support generating executable test cases (normal/abnormal/auth).
3. After API changes, re-run downstream related tests and write back reports.

## ADDON_AGENT_ALIGNMENT
- source: agent.md
- policy: additive only, do not replace original content
- test_gate: 100%
- retry_per_point: 5
- failure_loop: diagnose -> fix -> retest
- log_file: logs/workflow.log
- req_to_api_mapping: required
- api_case_coverage: required
