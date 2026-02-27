---
name: backend-core
description: Implement backend core interfaces: CRUD, pagination, filtering, sorting, basic auth, error handling, and comprehensive testing
---

# Backend Core Interface Implementation

## Task Goals
- This Skill implements core business logic on top of the backend scaffold (CRUD, pagination, filtering, sorting, auth, error handling)
- Capabilities include CRUD, pagination/filter/sort, basic auth, error handling, and comprehensive testing
- Trigger condition: backend-scaffold has generated the scaffold and started the service

## Prerequisites
- Dependencies: generate docs and code using:
  - [requirement-planning](../requirement-planning/SKILL.md): requirements list, tech stack
  - [api-design](../api-design/SKILL.md): API list, field definitions
  - [backend-codegen](../backend-codegen/SKILL.md): data models, project structure
  - [backend-scaffold](../backend-scaffold/SKILL.md): running backend service

- Environment readiness:
  - Backend service running (via backend-scaffold)
  - Database initialized with test data
  - Service address and port known

## Workflow

### Phase 1: Read Inputs
1. **Read tech stack**: backend language, web framework, database, ORM
2. **Read data models**: entity definitions, field types, relationships
3. **Read API list**: CRUD APIs, filter conditions, sort rules
4. **Understand auth needs**: registration/login, permission rules

### Phase 2: Implement CRUD APIs
1. **Create**: implement POST with validation and inserts
2. **Read**: implement GET for single and list queries
3. **Update**: implement PUT with validation and updates
4. **Delete**: implement DELETE, cascade handling

### Phase 3: Implement Pagination, Filtering, Sorting
1. **Pagination**: support page and limit, return total and items
2. **Filtering**: support multiple filters (status, keyword, category, etc.)
3. **Sorting**: support sort_by and order, multi-field sorting

### Phase 4: Implement Basic Auth
1. **Registration**: register API, hash passwords, create user
2. **Login**: login API, verify password, issue token
3. **Token verification**: DI to validate token
4. **Authorization**: role-based access control, deny unauthorized access

### Phase 5: Implement Error Handling
1. **Validation**: use framework validation
2. **Exception handling**: global exception handler
3. **Unified error response**: standard format with code, message, detail
4. **Status mapping**: proper HTTP codes (400, 401, 403, 404, 500)

### Phase 6: Restart Service
1. **Stop old service**: stop backend-scaffold service
2. **Apply code**: ensure core code saved
3. **Start new service**: run service with core features
4. **Verify startup**: ensure service runs normally

### Phase 7: Comprehensive Testing
1. **CRUD tests**: all CRUD APIs
2. **Pagination tests**: verify pagination
3. **Filtering tests**: verify filters
4. **Sorting tests**: verify sorting
5. **Auth tests**: registration/login, token, permissions
6. **Error handling tests**: invalid params, auth errors, not found
7. **Performance tests**: concurrent requests, large datasets
8. **Generate test report**: record results and pass rate

### Phase 8: Iterative Fixes
1. **Analyze failures**: check logs and responses
2. **Fix issues**: code/config/logic
3. **Restart service**: stop old, start new
4. **Retest**: rerun comprehensive tests
5. **Iterate**: until all tests pass

### Phase 9: Delivery Confirmation
1. **Final testing**: full test of all functions
2. **Generate report**: record results and pass rate
3. **Provide service info**: address, port, docs URL
4. **Feature list**: list all implemented features

## Module Details

### Module 1: CRUD APIs

#### Create
- **Path**: POST /api/v1/resources
- **Body**: includes all required fields
- **Response**: created resource (with id)
- **Validation**: format, required fields, uniqueness

#### Read
- **Single**: GET /api/v1/resources/{id}
- **List**: GET /api/v1/resources?page=1&limit=10
- **Response**: resource detail or list
- **Handling**: return 404 if not found

#### Update
- **Path**: PUT /api/v1/resources/{id}
- **Body**: fields to update
- **Response**: updated resource
- **Validation**: format, existence

#### Delete
- **Path**: DELETE /api/v1/resources/{id}
- **Response**: success message
- **Handling**: cascade delete related data

### Module 2: Pagination

#### Parameter Design
```python
page: int = 1  # current page
limit: int = 10  # page size
```

#### Response Format
```json
{
  "code": 200,
  "data": {
    "total": 100,
    "page": 1,
    "limit": 10,
    "pages": 10,
    "items": [...]
  }
}
```

#### Implementation Notes
- Total pages: pages = ceil(total / limit)
- Offset: offset = (page - 1) * limit
- Boundary checks: page >= 1, limit >= 1

### Module 3: Filtering

#### Common Filters
```python
# Status filter
status: str  # active/inactive

# Keyword search
keyword: str  # fuzzy match

# Range query
price_min: float
price_max: float

# Date range
start_date: datetime
end_date: datetime

# Category filter
category_id: int
```

#### Implementation Notes
- Build query conditions dynamically
- Handle default values
- Combine conditions (AND/OR)

### Module 4: Sorting

#### Parameter Design
```python
sort_by: str = "created_at"  # sort field
order: str = "desc"  # sort order (asc/desc)
```

#### Implementation Notes
- Validate sort field
- Support desc and asc
- Support multi-field sorting

### Module 5: Basic Auth

#### Registration
- **Path**: POST /api/v1/auth/register
- **Body**: username, email, password
- **Handling**: hash password, create user
- **Response**: user info (no password)

#### Login
- **Path**: POST /api/v1/auth/login
- **Body**: username/email, password
- **Handling**: verify password, issue token
- **Response**: access_token, user

#### Token Verification
- **Method**: Bearer Token
- **Location**: Authorization Header
- **Handling**: parse token, verify signature, check expiration

#### Authorization
- **Roles**: admin, user
- **Permissions**: normal resources (user), admin resources (admin)
- **Handling**: deny unauthorized access (403)

### Module 6: Error Handling

#### Validation Error (400)
```json
{
  "code": 400,
  "message": "invalid parameters",
  "detail": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

#### Auth Failure (401)
```json
{
  "code": 401,
  "message": "unauthorized",
  "detail": "Token invalid or expired"
}
```

#### Permission Denied (403)
```json
{
  "code": 403,
  "message": "forbidden",
  "detail": "You do not have permission to access this resource"
}
```

#### Not Found (404)
```json
{
  "code": 404,
  "message": "not found",
  "detail": "Resource ID 100 not found"
}
```

#### Server Error (500)
```json
{
  "code": 500,
  "message": "server error",
  "detail": "Internal error, contact admin"
}
```

## Resource Index

- CRUD implementation guide: see [references/crud-implementation.md](references/crud-implementation.md)
- Pagination/filter/sort: see [references/pagination-filter-sort.md](references/pagination-filter-sort.md)
- Auth implementation guide: see [references/authentication-authorization.md](references/authentication-authorization.md)
- Error handling guide: see [references/error-handling.md](references/error-handling.md)
- Comprehensive test guide: see [references/comprehensive-test.md](references/comprehensive-test.md)

## Notes

- **Code style**: follow best practices and coding standards of each stack
- **Validation**: strictly validate all inputs to prevent injection
- **Password security**: use bcrypt or similar
- **Token security**: use JWT with reasonable expiration
- **Error details**: avoid leaking sensitive info
- **Performance**: use pagination for large datasets
- **Logging**: record key operations and errors for debugging
- **Test coverage**: ensure all features have test cases

## Usage Examples

**Example 1: Python + FastAPI Core Backend**
- Input: stack (Python, FastAPI, PostgreSQL) + API list + data models
- Output:
  - CRUD APIs (POST/GET/PUT/DELETE)
  - Pagination/filter/sort
  - Registration/login
  - Token validation and RBAC
  - Robust error handling
  - Comprehensive test report (all passing)

**Example 2: Java + Spring Boot Core Backend**
- Input: stack (Java, Spring Boot, MySQL) + API list + data models
- Output:
  - CRUD APIs (Entity, Repository, Controller)
  - Pagination/filter/sort (Pageable)
  - Spring Security auth
  - Unified exception handling (@ControllerAdvice)
  - Comprehensive test report (all passing)

**Example 3: Node.js + Express Core Backend**
- Input: stack (Node.js, Express, MongoDB) + API list + data models
- Output:
  - CRUD APIs (Express Router)
  - Pagination/filter/sort (Mongoose queries)
  - JWT auth
  - Error handling middleware
  - Comprehensive test report (all passing)

## Relationship with Other Skills

```
1. requirement-planning → requirements docs + tech stack
2. api-design → API list + field definitions
3. backend-codegen → data models + backend structure
4. backend-scaffold → backend scaffold (structure, config)
5. backend-core → backend core features (CRUD, auth, error handling) (this Skill)
6. frontend-dev → frontend app (calls backend from this Skill)
```

## Outputs

Generate and implement:
1. Full CRUD API code
2. Pagination/filter/sort code
3. Registration/login code
4. Token validation and RBAC code
5. Error handling code
6. Comprehensive test report
7. Service access info (address, port, docs)

## Test Pass Criteria

**All of the following must pass for delivery:**
1. CRUD API tests pass (Create, Read, Update, Delete)
2. Pagination tests pass
3. Filtering tests pass
4. Sorting tests pass
5. Registration/login tests pass
6. Token validation tests pass
7. Authorization tests pass
8. Error handling tests pass (400, 401, 403, 404, 500)
9. Comprehensive test pass rate >= 95%

**If any of the following exist, continue iterating:**
1. Any CRUD API fails
2. Pagination/filter/sort issues
3. Auth issues
4. Error handling not compliant
5. Pass rate < 95%

## Additions (Aligned with agent.md)
1. Comprehensive test pass rate must be 100%.
2. Cover requirement acceptance items, API cases, and comprehensive gates.
3. Failures must follow “diagnose -> fix -> retest,” max 5 retries per point.
4. Exceeded retries SKIP must record root cause and impact.
5. Must produce `test/backend-core/comprehensive-test-summary.json` and `output/backend-core/service-info.json`.

## ADDON_AGENT_ALIGNMENT
- source: agent.md
- policy: additive only, do not replace original content
- test_gate: 100%
- retry_per_point: 5
- failure_loop: diagnose -> fix -> retest
- log_file: logs/workflow.log
- required_output: test/backend-core/comprehensive-test-summary.json,output/backend-core/service-info.json
