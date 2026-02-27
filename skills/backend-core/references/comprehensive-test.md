# Comprehensive Test Guide

## Test Objectives

### Functional Tests
- CRUD operations work
- Pagination works
- Filtering works
- Sorting works

### Auth Tests
- Registration works
- Login works
- Token validation works
- Authorization works

### Error Handling Tests
- Invalid params return 400
- Auth failure returns 401
- Permission denied returns 403
- Not found returns 404
- Server error returns 500

### Performance Tests
- Concurrent requests
- Large dataset queries

## Test Flow

### Phase 1: Environment Setup
1. **Verify service is up**
   ```bash
   curl http://localhost:8000/
   ```

2. **Verify DB connection**
   ```bash
   # PostgreSQL
   psql -U postgres -d myapp -c "SELECT 1"

   # MySQL
   mysql -u root -p -e "SELECT 1"

   # MongoDB
   mongo myapp --eval "db.adminCommand('ping')"
   ```

3. **Reset test data**
   ```bash
   # Clear test data
   psql -U postgres -d myapp -f cleanup.sql
   ```

### Phase 2: CRUD Tests

#### 1. Create

**Case 1: normal create**
```bash
curl -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Password123"
  }'

# Expected: 201, user info returned
{
  "code": 201,
  "message": "created",
  "data": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

**Case 2: duplicate username**
```bash
curl -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test2@example.com",
    "password": "Password123"
  }'

# Expected: 400, username already exists
{
  "code": 400,
  "message": "username already exists"
}
```

**Case 3: missing params**
```bash
curl -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser2",
    "password": "Password123"
  }'

# Expected: 400, email required
{
  "code": 400,
  "message": "validation failed",
  "detail": [...]
}
```

**Case 4: invalid param format**
```bash
curl -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser3",
    "email": "invalid-email",
    "password": "Password123"
  }'

# Expected: 400, invalid email
```

#### 2. Read

**Case 1: get existing user**
```bash
curl -X GET http://localhost:8000/api/v1/users/1

# Expected: 200, user info returned
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

**Case 2: get non-existent user**
```bash
curl -X GET http://localhost:8000/api/v1/users/999

# Expected: 404, user not found
{
  "code": 404,
  "message": "user not found"
}
```

**Case 3: list users (pagination)**
```bash
curl -X GET "http://localhost:8000/api/v1/users?page=1&limit=10"

# Expected: 200, user list returned
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 1,
    "page": 1,
    "limit": 10,
    "pages": 1,
    "users": [...]
  }
}
```

#### 3. Update

**Case 1: normal update**
```bash
curl -X PUT http://localhost:8000/api/v1/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "avatar": "https://example.com/avatar.png"
  }'

# Expected: 200, updated user info
```

**Case 2: update non-existent user**
```bash
curl -X PUT http://localhost:8000/api/v1/users/999 \
  -H "Content-Type: application/json" \
  -d '{
    "avatar": "https://example.com/avatar.png"
  }'

# Expected: 404, user not found
```

#### 4. Delete

**Case 1: normal delete**
```bash
curl -X DELETE http://localhost:8000/api/v1/users/1

# Expected: 200, deleted
{
  "code": 200,
  "message": "deleted"
}
```

**Case 2: delete non-existent user**
```bash
curl -X DELETE http://localhost:8000/api/v1/users/999

# Expected: 404, user not found
```

### Phase 3: Pagination, Filtering, Sorting Tests

#### 1. Pagination

**Case 1: first page**
```bash
curl -X GET "http://localhost:8000/api/v1/users?page=1&limit=10"

# Verify:
# - total correct
# - page=1
# - limit=10
# - items count <= 10
```

**Case 2: second page**
```bash
curl -X GET "http://localhost:8000/api/v1/users?page=2&limit=10"

# Verify:
# - second page data
# - does not include first page
```

**Case 3: boundary**
```bash
curl -X GET "http://localhost:8000/api/v1/users?page=999&limit=10"

# Expected: 200, items empty
```

#### 2. Filtering

**Case 1: status filter**
```bash
curl -X GET "http://localhost:8000/api/v1/users?status=active"

# Verify:
# - only status=active
```

**Case 2: keyword search**
```bash
curl -X GET "http://localhost:8000/api/v1/users?keyword=test"

# Verify:
# - username or email contains "test"
```

**Case 3: price range**
```bash
curl -X GET "http://localhost:8000/api/v1/products?min_price=100&max_price=500"

# Verify:
# - price between 100-500
```

**Case 4: combined filters**
```bash
curl -X GET "http://localhost:8000/api/v1/products?status=active&keyword=laptop&min_price=100"

# Verify:
# - meets all conditions
```

#### 3. Sorting

**Case 1: ascending**
```bash
curl -X GET "http://localhost:8000/api/v1/users?sort_by=username&order=asc"

# Verify:
# - usernames ascending
```

**Case 2: descending**
```bash
curl -X GET "http://localhost:8000/api/v1/users?sort_by=created_at&order=desc"

# Verify:
# - created_at descending
```

**Case 3: multi-field**
```bash
curl -X GET "http://localhost:8000/api/v1/products"

# Verify:
# - sort by status, then created_at
```

### Phase 4: Auth Tests

#### 1. Registration

**Case 1: normal registration**
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "email": "newuser@example.com",
    "password": "Password123"
  }'

# Expected: 201, user info (no password)
```

**Case 2: password hash verification**
```bash
# After register, check DB
psql -U postgres -d myapp -c "SELECT username, password_hash FROM users WHERE username='newuser'"

# Verify:
# - password_hash is hashed
# - not plaintext
```

#### 2. Login

**Case 1: normal login**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "password": "Password123"
  }'

# Expected: 200, access_token
{
  "code": 200,
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "user": {...}
  }
}
```

**Case 2: wrong username**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "wronguser",
    "password": "Password123"
  }'

# Expected: 401, invalid username or password
```

**Case 3: wrong password**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "password": "WrongPassword"
  }'

# Expected: 401, invalid username or password
```

#### 3. Token Validation

**Case 1: valid token**
```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"

# Expected: 200, current user info
```

**Case 2: invalid token**
```bash
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer invalid-token"

# Expected: 401, invalid token
```

**Case 3: missing token**
```bash
curl -X GET http://localhost:8000/api/v1/users/me

# Expected: 401, token not provided
```

#### 4. Authorization

**Case 1: user hits admin endpoint**
```bash
# Use user token
USER_TOKEN="..."

curl -X POST http://localhost:8000/api/v1/products \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Product",
    "price": 99.99
  }'

# Expected: 403, forbidden
{
  "code": 403,
  "message": "admin required"
}
```

**Case 2: admin hits admin endpoint**
```bash
# Use admin token
ADMIN_TOKEN="..."

curl -X POST http://localhost:8000/api/v1/products \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Product",
    "price": 99.99
  }'

# Expected: 201, created
```

### Phase 5: Error Handling Tests

#### 1. Invalid Params (400)

**Case 1: missing required**
```bash
curl -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser"
  }'

# Expected: 400, validation failed
{
  "code": 400,
  "message": "validation failed",
  "detail": [...]
}
```

**Case 2: wrong type**
```bash
curl -X GET "http://localhost:8000/api/v1/users?page=abc"

# Expected: 400, invalid type
```

**Case 3: out of range**
```bash
curl -X GET "http://localhost:8000/api/v1/users?page=0"

# Expected: 400, page must be >= 1
```

#### 2. Auth Failure (401)

**Case 1: missing token**
```bash
curl -X GET http://localhost:8000/api/v1/users/me

# Expected: 401, unauthorized
```

**Case 2: invalid token**
```bash
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer invalid-token"

# Expected: 401, invalid token
```

**Case 3: expired token**
```bash
# Use expired token
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer expired-token"

# Expected: 401, token expired
```

#### 3. Permission Denied (403)

**Case 1: user accesses admin endpoint**
```bash
curl -X DELETE http://localhost:8000/api/v1/users/1 \
  -H "Authorization: Bearer user-token"

# Expected: 403, forbidden
```

**Case 2: access other user's private resource**
```bash
curl -X GET http://localhost:8000/api/v1/orders/2 \
  -H "Authorization: Bearer user-1-token"

# Expected: 403, forbidden
```

#### 4. Not Found (404)

**Case 1: get non-existent user**
```bash
curl -X GET http://localhost:8000/api/v1/users/999

# Expected: 404, user not found
```

**Case 2: update non-existent resource**
```bash
curl -X PUT http://localhost:8000/api/v1/users/999 \
  -H "Content-Type: application/json" \
  -d '{"username": "test"}'

# Expected: 404, user not found
```

**Case 3: delete non-existent resource**
```bash
curl -X DELETE http://localhost:8000/api/v1/users/999

# Expected: 404, user not found
```

#### 5. Server Error (500)

**Case 1: DB connection failure**
```bash
# Stop DB service
sudo systemctl stop postgresql

# Make request
curl -X GET http://localhost:8000/api/v1/users

# Expected: 500, server error
{
  "code": 500,
  "message": "server error"
}

# Restore DB service
sudo systemctl start postgresql
```

### Phase 6: Performance Tests

#### 1. Concurrency

**Use Apache Bench**
```bash
# Install
sudo apt-get install apache2-utils

# Test concurrency
ab -n 1000 -c 10 http://localhost:8000/api/v1/users

# Verify:
# - all requests return 200
# - avg response < 100ms
# - no 500 errors
```

**Use wrk**
```bash
# Install
sudo apt-get install wrk

# Test concurrency
wrk -t4 -c100 -d30s http://localhost:8000/api/v1/users

# Verify:
# - Requests/sec > 1000
# - Avg latency < 50ms
```

#### 2. Large Dataset

**Case 1: bulk insert**
```bash
# Insert 10000 records
for i in {1..10000}; do
  curl -X POST http://localhost:8000/api/v1/users \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"user$i\",\"email\":\"user$i@example.com\",\"password\":\"Password123\"}"
done

# Verify:
# - all inserts succeed
# - no DB errors
```

**Case 2: large query**
```bash
# Query 10000 records
curl -X GET "http://localhost:8000/api/v1/users?page=1&limit=10000"

# Verify:
# - response < 1s
# - returns 10000 records
```

### Phase 7: Test Report

#### Report Template

```markdown
# Backend Core Comprehensive Test Report

## Overview
- Test date: 2024-XX-XX
- Tester: XXX
- Service URL: http://localhost:8000
- Database: PostgreSQL

## Summary
- Total tests: 50
- Passed: 47
- Failed: 3
- Pass rate: 94%

## Functional Results

### CRUD Tests
- [x] Create - normal create
- [x] Create - duplicate username
- [x] Create - missing params
- [x] Create - invalid format
- [x] Read - get existing user
- [x] Read - get non-existent user
- [x] Read - list users (pagination)
- [x] Update - normal update
- [x] Update - update non-existent user
- [x] Delete - normal delete
- [x] Delete - delete non-existent user

### Pagination/Filter/Sort
- [x] Pagination - first page
- [x] Pagination - second page
- [x] Pagination - boundary
- [x] Filter - status
- [x] Filter - keyword
- [x] Filter - price range
- [x] Filter - combined
- [x] Sort - ascending
- [x] Sort - descending
- [x] Sort - multi-field

### Auth Tests
- [x] Register - normal
- [x] Register - password hash validation
- [x] Login - normal
- [x] Login - wrong username
- [x] Login - wrong password
- [x] Token - valid
- [x] Token - invalid
- [x] Token - missing
- [x] Authorization - user hits admin endpoint
- [x] Authorization - admin hits admin endpoint

### Error Handling
- [x] Invalid params - missing required
- [x] Invalid params - wrong type
- [x] Invalid params - out of range
- [x] Auth failure - missing token
- [x] Auth failure - invalid token
- [x] Auth failure - expired token
- [x] Forbidden - user hits admin endpoint
- [x] Not found - get non-existent user
- [x] Not found - update non-existent resource
- [x] Not found - delete non-existent resource
- [x] Server error - DB connection failed

### Performance
- [x] Concurrency - 1000 requests
- [x] Large dataset - bulk insert
- [x] Large dataset - large query

## Failures
1. Sorting - multi-field - response too slow
2. Large dataset - bulk insert - partial failures
3. Large dataset - large query - response too slow

## Analysis
1. **Sorting - multi-field**
   - Issue: response time > 500ms
   - Cause: missing index
   - Fix: add index for sort fields

2. **Large dataset - bulk insert**
   - Issue: 5 failures out of 10000
   - Cause: unique constraint violation
   - Fix: add de-dup logic

3. **Large dataset - large query**
   - Issue: query 10000 rows > 2s
   - Cause: pagination not used
   - Fix: enforce pagination

## Conclusion
- **Deliverable**: Yes (pass rate >= 95%)
- **Issues to fix**: recommended before delivery
- **Overall**: feature complete, good performance
```

## Test Checklist

### Functional
- [ ] All CRUD APIs pass
- [ ] Pagination works
- [ ] Filtering works
- [ ] Sorting works

### Auth
- [ ] Registration works
- [ ] Login works
- [ ] Token validation works
- [ ] Authorization works

### Error Handling
- [ ] 400 errors correct
- [ ] 401 errors correct
- [ ] 403 errors correct
- [ ] 404 errors correct
- [ ] 500 errors correct

### Performance
- [ ] Concurrency OK
- [ ] Large dataset OK
- [ ] Response time reasonable

### Report
- [ ] Report generated
- [ ] Failures recorded
- [ ] Analysis complete
- [ ] Fix suggestions provided

## Delivery Criteria

**All of the following must pass:**
1. All CRUD tests pass
2. Pagination/filter/sort tests pass
3. Auth tests pass
4. Error handling tests pass
5. Pass rate >= 95%
6. Performance tests pass
7. Report complete

**If any of the following exist, continue iteration:**
1. Any core test fails
2. Pass rate < 95%
3. Severe performance issues
4. Incomplete test report
