---
name: requirement-planning
description: Use structured dialogue to guide users in refining project requirements, output a requirements list, user flow, and feature priority draft
---

# Requirement Planning

## Task Goals
- This Skill converts a user's project idea into a structured requirements document
- Capabilities include guided requirement discovery, requirements list organization, user flow design, and feature priority ranking
- Trigger conditions: user expresses a project idea but lacks complete requirements (e.g., "I want to build an X app", "I have a new idea")
- Change trigger: when the user adds/removes/changes features, adjusts priority, or changes the tech stack, enter “requirements change mode”

## Mandatory Gate (Must Ask First)
- Do not generate `requirements.md` or `tech-stack.json` before requirements collection is complete
- After entering this Skill, the first round must ask questions; do not output a full document immediately
- Questions must cover at least 6 dimensions: project goals, core features, user scenarios, tech stack, constraints, acceptance criteria
- If the user provides only a single sentence (insufficient info), continue asking and do not auto-fill then output
- Only when one of the following is true may you generate documents:
  - Key information has been fully collected
  - The user explicitly confirms “output with current information, missing items to be filled later”
- If the user says “continue / generate directly” but key info is missing, return the missing list and continue asking

## Discussion Framework

### Phase 1: Requirements Collection
Guide the user across these dimensions:
1. **Project background and goals**: problem to solve, target users, core value
2. **Core features**: must-have features (at least 3-5)
3. **User scenarios**: typical scenarios and pain points
4. **Tech stack selection**: backend language, web framework, database, frontend framework
5. **Constraints**: time, resources, other limits
6. **Expected outcomes**: success metrics

### Phase 2: Requirements Confirmation
Confirm the following key information with the user:
- Feature boundaries (what not to build)
- Non-functional requirements (performance, security, availability)
- User roles and permissions
- Integration needs (third-party systems, APIs)
- Tech stack confirmation

### Phase 3: Output Organization
Based on collected information, generate:
1. Requirements list (including tech stack)
2. User flow
3. Feature priority draft

## Operational Steps

### Step 1: Requirements Collection
- Ask the user about the core idea and goals
- Use the discussion framework to refine details
- Record key requirements and constraints

### Step 1.5: Completeness Check (Required Before Document Generation)
- Validate completeness against the 6 dimensions
- Output “confirmed information” and “missing information list”
- If missing items exist, continue asking and do not proceed to Step 2
- If the user explicitly authorizes “output with current info,” mark “to-be-confirmed” items in the document, then proceed to Step 2

### Step 2: Generate Requirements List
- Only execute after Step 1 and Step 1.5 pass
- Follow the format in [references/requirements-template.md](references/requirements-template.md)
- Organize by feature module or user story
- Include requirement description, priority, acceptance criteria
- **Record tech stack**: backend language, framework, database, frontend framework

### Step 3: Design User Flow
- Follow the format in [references/userflow-template.md](references/userflow-template.md)
- Describe key user paths and interaction flows
- Mark exception handling and branch logic

### Step 4: Define Feature Priority
- Follow the framework in [references/priority-framework.md](references/priority-framework.md)
- Use MoSCoW or RICE scoring to prioritize
- Distinguish MVP, short-term goals, and long-term planning

### Step 5: Output and Confirmation
- Combine the three documents into a complete requirements plan
- Request user confirmation and feedback
- Adjust based on feedback

### Step 6: Requirements Change Mode (Incremental Sync)
- Identify change type: add, remove, modify, priority change, tech stack change
- Generate an “impacted documents list,” and require updating output docs first
- Check at least the following docs for impact:
  - `output/requirement-planning-requirements.md`
  - `output/requirement-planning-tech-stack.json` (when tech stack changes)
  - `output/api-design-api-list.md`
  - `output/api-design-data-models.md`
  - `output/api-design-api-documentation.md`
  - `output/backend-codegen-project-structure.md`
- After syncing docs, guide into subsequent Skill execution: code changes -> tests -> logging

## Resource Index

- Requirements list template: see [references/requirements-template.md](references/requirements-template.md)
- User flow template: see [references/userflow-template.md](references/userflow-template.md)
- Priority framework: see [references/priority-framework.md](references/priority-framework.md)

## Notes

- Keep the dialogue guided; avoid asking too many questions at once
- In requirements collection, you must ask and record tech stack selection
- Do not output a full requirements document before collection is complete
- Tech stack info is passed to later API design and code generation
- Focus on user needs rather than implementation details
- Prioritization should be based on business value and user impact
- Requirements should be clear and testable, avoiding ambiguity
- When requirements change, update impacted output docs first before code changes

## Usage Examples

**Example 1: Mobile App Requirement Planning**
- User: "I want to build a fitness check-in app"
- Agent guidance: understand target users, core features (check-ins, stats, social), scenarios
- Output: complete requirements list, user registration and check-in flow, MVP priority

**Example 2: Enterprise System Requirement Planning**
- User: "We need an employee management system"
- Agent guidance: company size, employee roles, current workflows, integration needs
- Output: feature module split, approval flow design, phased rollout plan

## Additions (Aligned with agent.md)
1. When `workflow.forceQuestioningOnFirstSkill=true`, as the first Skill, this phase must ask questions before outputting requirements.
2. Acceptance criteria must be auto-generated by the Agent based on templates, split into testable module items.
3. Start writing `logs/workflow.log` from this phase.
4. If tests fail, execute “diagnose -> fix -> retest,” max 5 retries per point.

## ADDON_AGENT_ALIGNMENT
- source: agent.md
- policy: additive only, do not replace original content
- test_gate: 100%
- retry_per_point: 5
- failure_loop: diagnose -> fix -> retest
- log_file: logs/workflow.log
- first_skill_forced_questioning: true
- acceptance_auto_generated: true
