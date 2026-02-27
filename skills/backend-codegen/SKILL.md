---
name: backend-codegen
description: Generate FastAPI + SQLAlchemy data models and backend code structure based on API and requirement documents
---

# Backend Code Generation

## Task Goals
- This Skill turns API design documents into runnable backend code
- Capabilities include data model design, entity relationship analysis, ORM code generation, and API handler generation
- Trigger condition: user provides API list and requirement documents

## Prerequisites
- Dependencies: generate docs using:
  - [requirement-planning](../requirement-planning/SKILL.md): requirements list, user flows, feature priority, tech stack
  - [api-design](../api-design/SKILL.md): API list, field definitions

- Tech stack reading: read tech stack selection from requirements list, including:
  - Backend language (Python / Java / Node.js / Go, etc.)
  - Web framework (FastAPI / Spring Boot / Express / Gin, etc.)
  - Database (PostgreSQL / MySQL / MongoDB, etc.)
  - ORM (SQLAlchemy / MyBatis / Mongoose, etc.)

## Analysis Framework

### Derive Data Models from APIs
Analyze request params and response data in API list:
1. **Identify core entities**: main nouns (users, orders, products)
2. **Extract field attributes**: from body params and response data
3. **Determine field types**: map API definitions to DB types
4. **Add system fields**: id, created_at, updated_at, deleted_at

### Design Entity Relationships
Analyze relationships between entities:
1. **One-to-many**: user → orders, category → products
2. **Many-to-many**: order ↔ product (via join table)
3. **Self-referencing**: comment parent/child, category hierarchy

### Define Foreign Key Constraints
- Cascade delete: whether deleting user deletes orders
- Non-null constraints: whether FK can be null
- Index optimization: add indexes on FK fields

## Operational Steps

### Step 1: Read Input Docs
- User provides API list document (api-list-template.md)
- User provides requirements document (requirements-template.md)
- **Read tech stack selection**: backend language, framework, database, ORM
- Select code templates based on tech stack
- Understand business logic and data flow

### Step 2: Design Data Models
- Follow [references/data-model-design.md](references/data-model-design.md)
- Identify all data entities and attributes
- Design entity relationships
- Define primary keys, foreign keys, indexes

### Step 3: Plan Project Structure
- Follow [references/project-structure.md](references/project-structure.md)
- Create standard layered architecture directories
- Configure project dependencies and environment
- **Must create real directories**: create project directory at repo root based on `project-structure.md` (e.g., `backend/`)

### Step 4: Generate ORM Model Code
- Follow [references/orm-model-template.md](references/orm-model-template.md)
- Generate SQLAlchemy model class for each entity
- Define field types, constraints, relationships
- Generate database migration scripts

### Step 5: Generate API Handler Code
- Follow [references/api-handler-template.md](references/api-handler-template.md)
- Generate route handlers for each API
- Implement CRUD operations
- Define Pydantic schemas for validation

### Step 6: Generate Database DDL
- Follow [references/database-schema.md](references/database-schema.md)
- Generate CREATE TABLE statements
- Define indexes and foreign key constraints
- Provide initialization data scripts

### Step 7: Output and Confirmation
- Combine all code files into a complete project structure
- Ensure the code runs normally
- Request user confirmation and adjustments
- Write documentation to `output/backend-codegen-project-structure.md` (docs only)
- Write code to project folder at repo root (do not write into `output/`)

## Resource Index

- Project structure template: see [references/project-structure.md](references/project-structure.md)
- Data model design spec: see [references/data-model-design.md](references/data-model-design.md)
- ORM model code template: see [references/orm-model-template.md](references/orm-model-template.md)
- API handler code template: see [references/api-handler-template.md](references/api-handler-template.md)
- Database schema template: see [references/database-schema.md](references/database-schema.md)

## Notes

- Generate code and docs based on the chosen tech stack
- **Multiple stacks supported**: Python+FastAPI, Java+Spring Boot, Node.js+Express, etc.
- Follow best practices for each stack (e.g., FastAPI DI, Spring Boot layered architecture)
- **Output isolation**: `output/` is for docs only; source code, scripts, dependencies, and runnable projects must be in the new project directory
- Implement pagination (page, limit)
- Handle errors (404, 400, 500)
- Consider soft delete (deleted_at field)
- Add indexes on foreign key fields to optimize performance

## Supported Tech Stack Combinations

### Python Stack
- Language: Python 3.9+
- Framework: FastAPI / Flask
- ORM: SQLAlchemy / Django ORM
- Database: PostgreSQL / MySQL
- Validation: Pydantic

### Java Stack
- Language: Java 11+
- Framework: Spring Boot
- ORM: MyBatis / JPA
- Database: PostgreSQL / MySQL
- Validation: Hibernate Validator

### Node.js Stack
- Language: Node.js 16+
- Framework: Express / NestJS / Koa
- ORM: Mongoose (MongoDB) / Sequelize (SQL)
- Database: MongoDB / PostgreSQL / MySQL
- Validation: Joi / class-validator

### Go Stack
- Language: Go 1.18+
- Framework: Gin / Echo
- ORM: GORM
- Database: PostgreSQL / MySQL
- Validation: validator

## Usage Examples

**Example 1: E-commerce Backend Codegen (Python + FastAPI)**
- Input: API list (GET /api/products, POST /api/orders) + stack (Python, FastAPI, PostgreSQL)
- Output:
  - Data models: User, Product, Order, OrderItem (SQLAlchemy)
  - API handlers: product list, create order routes (FastAPI)
  - Database schema: PostgreSQL DDL

**Example 2: User System Backend Codegen (Java + Spring Boot)**
- Input: API list (POST /api/register, POST /api/login) + stack (Java, Spring Boot, MySQL)
- Output:
  - Data models: User model (JPA Entity)
  - API handlers: register/login controllers (Spring MVC)
  - Auth middleware: Spring Security + JWT

**Example 3: Blog Backend Codegen (Node.js + Express)**
- Input: API list (GET /api/posts, POST /api/posts) + stack (Node.js, Express, MongoDB)
- Output:
  - Data models: Post model (Mongoose Schema)
  - API handlers: list/create post routes (Express)
  - DB init: MongoDB collection structure

## Additions (Aligned with agent.md)
1. Code outputs go to `backend/`, docs to `output/`.
2. Structure and field naming must align with `api-design` outputs.
3. If validation fails after generation, log and fix before handoff.

## ADDON_AGENT_ALIGNMENT
- source: agent.md
- policy: additive only, do not replace original content
- test_gate: 100%
- retry_per_point: 5
- failure_loop: diagnose -> fix -> retest
- log_file: logs/workflow.log
- code_output_dir: backend/
- doc_output_dir: output/
