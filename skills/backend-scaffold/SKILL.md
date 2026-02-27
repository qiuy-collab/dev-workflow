---
name: backend-scaffold
description: Generate a runnable backend scaffold, initialize database, start service, and test frontend API calls
---

# Backend Scaffold and Integration

## Task Goals
- This Skill generates a runnable backend scaffold, initializes the database, starts services, and performs frontend-backend integration tests
- Capabilities include scaffold generation, database initialization, service startup, API testing, issue fixing, and iterative integration
- Trigger condition: user completes requirement planning, API design, and backend model design

## Prerequisites
- Dependencies: generate docs and code using:
  - [requirement-planning](../requirement-planning/SKILL.md): requirements list, tech stack selection
  - [api-design](../api-design/SKILL.md): API list, field definitions
  - [backend-codegen](../backend-codegen/SKILL.md): data models, project structure

- Tech stack reading: read the backend tech stack selected in requirements

## Workflow

### Phase 1: Read Inputs
1. **Read tech stack**: backend language, web framework, database, ORM
2. **Read data models**: DB schema, entity relationships
3. **Read API list**: endpoints, request params, response formats
4. **Understand structure**: directory and file organization

### Phase 2: Generate Scaffold Code
1. **Create project directory**: establish full project structure
2. **Generate config files**: DB connection, env vars
3. **Generate model code**: ORM models
4. **Generate API handlers**: routes and controllers
5. **Generate entrypoint**: app startup code
6. **Generate dependency files**: package.json, requirements.txt

### Phase 3: Initialize Database
1. **Install dependencies**: install required packages
2. **Create database**: create DB and users
3. **Run schema scripts**: execute SQL DDL
4. **Insert test data**: seed data for testing
5. **Verify database**: confirm tables and data created

### Phase 4: Start Service
1. **Check config**: verify env vars and config
2. **Start service**: run start command
3. **Wait for readiness**: ensure service is up and accessible
4. **Record process info**: save process ID for management

### Phase 5: API Testing
1. **Test basic endpoints**: health check, root path
2. **Test CRUD**: create, read, update, delete
3. **Test business APIs**: user registration, order creation, etc.
4. **Validate response format**: confirm response matches spec
5. **Record results**: log passed/failed APIs

### Phase 6: Iterative Fixes
1. **Analyze failures**: inspect logs and responses
2. **Fix issues**: code, config, SQL
3. **Restart service**: stop old service, start new one
4. **Retest**: re-run API tests
5. **Iterate**: until all tests pass

### Phase 7: Delivery Confirmation
1. **Final testing**: complete test of all APIs
2. **Generate test report**: record results
3. **Provide service info**: address, port, docs URL
4. **Clean up process**: stop test service (optional)

## Iteration Mechanism

### Integration Test Loop
```
Generate scaffold → Initialize DB → Start service → Test APIs
                                          ↓
                                     All pass?
                                       ↙        ↘
                                      Yes         No
                                      ↓           ↓
                                   Deliver      Fix code
                                                ↓
                                           Restart service
                                                ↓
                                            Retest
```

### Test Checklist
- [ ] Service starts successfully
- [ ] Database connection works
- [ ] All GET endpoints accessible
- [ ] All POST endpoints accessible
- [ ] All PUT endpoints accessible
- [ ] All DELETE endpoints accessible
- [ ] Response format correct
- [ ] Error handling correct

### Iteration Exit Criteria
**Delivery requires all of the following:**
1. Backend service starts successfully
2. Database connection works
3. All API tests pass
4. Response format conforms to spec
5. Error handling is correct

**If any of the following exist, continue iterating:**
1. Service fails to start
2. Database connection fails
3. API errors
4. Response format incorrect
5. Missing required APIs

## Resource Index

- Quickstart script: see [references/quickstart-script.md](references/quickstart-script.md)
- API test script: see [references/api-test-script.md](references/api-test-script.md)
- Database init script: see [references/database-init-script.md](references/database-init-script.md)
- Common issues and fixes: see [references/common-issues.md](references/common-issues.md)

## Notes

- Ensure DB service is running and accessible
- Ensure ports are not in use
- Restart service after each code change
- Save process ID for management
- Test data should not include sensitive info
- Record logs after startup for debugging

## Usage Examples

**Example 1: Python + FastAPI Backend Scaffold**
- Input: stack (Python, FastAPI, PostgreSQL) + API list + data models
- Output:
  - FastAPI project scaffold
  - DB DDL scripts
  - Running backend service (http://localhost:8000)
  - API test report (all passing)

**Example 2: Java + Spring Boot Backend Scaffold**
- Input: stack (Java, Spring Boot, MySQL) + API list + data models
- Output:
  - Spring Boot project scaffold
  - DB DDL scripts
  - Running backend service (http://localhost:8080)
  - API test report (all passing)

## Supported Backend Tech Stacks

### Python Stack
- Framework: FastAPI / Flask
- ORM: SQLAlchemy / Django ORM
- Database: PostgreSQL / MySQL
- Start command: `uvicorn app.main:app --reload`

### Java Stack
- Framework: Spring Boot
- ORM: MyBatis / JPA
- Database: PostgreSQL / MySQL
- Start command: `mvn spring-boot:run`

### Node.js Stack
- Framework: Express / NestJS / Koa
- ORM: Mongoose / Sequelize
- Database: MongoDB / PostgreSQL / MySQL
- Start command: `npm run dev`

## Relationship with Other Skills

```
1. requirement-planning → requirements docs + tech stack
2. api-design → API list + field definitions
3. backend-codegen → data models + backend structure
4. backend-scaffold → runnable backend service (this Skill)
5. frontend-dev → frontend app (calls backend from this Skill)
```

## Outputs

Generate and run:
1. Full backend project code
2. Database DDL scripts
3. Test data scripts
4. Running backend service
5. API test report
6. Service access info (address, port, docs)

## Additions (Aligned with agent.md)
1. Smoke test pass rate must be 100%.
2. Any failure must follow “diagnose -> fix -> retest,” max 5 retries per point.
3. Test log fields must be complete: skill/suite/test_point/test_status/attempt/max_attempts/message.
4. Must produce `test/backend-scaffold/api-test-summary.json` and `output/backend-scaffold/service-info.json`.

## ADDON_AGENT_ALIGNMENT
- source: agent.md
- policy: additive only, do not replace original content
- test_gate: 100%
- retry_per_point: 5
- failure_loop: diagnose -> fix -> retest
- log_file: logs/workflow.log
- required_output: test/backend-scaffold/api-test-summary.json,output/backend-scaffold/service-info.json
