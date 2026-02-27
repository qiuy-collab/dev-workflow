# API Test Script

## Test Tools

Recommended tools for API testing:
- **curl**: command-line HTTP client
- **httpie**: friendly command-line HTTP client
- **Postman**: graphical API test tool
- **pytest**: Python automated test framework

## curl Test Script

### Health Check

```bash
# Check service is up
curl -X GET http://localhost:8000/

# Expected response
{"message":"Hello World"}
```

### User API Tests

#### 1. User Registration

```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Password123"
  }'

# Expected response (201)
{
  "code": 201,
  "message": "registered",
  "data": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

#### 2. User Login

```bash
# User login
curl -X POST http://localhost:8000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "Password123"
  }'

# Expected response (200)
{
  "code": 200,
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "user": {
      "id": 1,
      "username": "testuser"
    }
  }
}
```

#### 3. Get User List

```bash
# Get user list (requires token)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X GET "http://localhost:8000/api/v1/users?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN"

# Expected response (200)
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 1,
    "page": 1,
    "limit": 10,
    "users": [
      {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com"
      }
    ]
  }
}
```

#### 4. Get Single User

```bash
# Get user detail
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X GET http://localhost:8000/api/v1/users/1 \
  -H "Authorization: Bearer $TOKEN"

# Expected response (200)
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "avatar": null,
    "status": "active"
  }
}
```

#### 5. Update User

```bash
# Update user info
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X PUT http://localhost:8000/api/v1/users/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "avatar": "https://example.com/avatar.png"
  }'

# Expected response (200)
{
  "code": 200,
  "message": "updated",
  "data": {
    "id": 1,
    "username": "testuser",
    "avatar": "https://example.com/avatar.png"
  }
}
```

#### 6. Delete User

```bash
# Delete user
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X DELETE http://localhost:8000/api/v1/users/1 \
  -H "Authorization: Bearer $TOKEN"

# Expected response (200)
{
  "code": 200,
  "message": "deleted",
  "data": null
}
```

### Product API Tests

#### 1. Get Product List

```bash
# Get product list
curl -X GET "http://localhost:8000/api/v1/products?page=1&limit=10&keyword=laptop"

# Expected response (200)
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 5,
    "products": [...]
  }
}
```

#### 2. Get Product Detail

```bash
# Get product detail
curl -X GET http://localhost:8000/api/v1/products/1

# Expected response (200)
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "name": "Laptop",
    "price": 999.99,
    "stock": 100
  }
}
```

#### 3. Create Product

```bash
# Create product (requires admin)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X POST http://localhost:8000/api/v1/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Product",
    "description": "Product description",
    "price": 99.99,
    "stock": 50
  }'

# Expected response (201)
{
  "code": 201,
  "message": "created",
  "data": {
    "id": 2,
    "name": "New Product"
  }
}
```

### Order API Tests

#### 1. Create Order

```bash
# Create order
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X POST http://localhost:8000/api/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "product_id": 1,
        "quantity": 2
      }
    ],
    "receiver_name": "Zhang San",
    "receiver_mobile": "13800138000",
    "receiver_address": "Chaoyang District, Beijing"
  }'

# Expected response (201)
{
  "code": 201,
  "message": "created",
  "data": {
    "id": 1,
    "order_no": "ORD20240101001",
    "total_amount": 1999.98
  }
}
```

#### 2. Get Order List

```bash
# Get current user's orders
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -X GET "http://localhost:8000/api/v1/orders?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN"

# Expected response (200)
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 1,
    "orders": [...]
  }
}
```

## Python pytest Test Script

### test_api.py

```python
import pytest
import requests
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root():
    """Test root path"""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()

def test_register_user():
    """Test user registration"""
    response = client.post(
        "/api/v1/users/register",
        json={
            "username": "testuser",
            "email": "test@example.com",
            "password": "Password123"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["code"] == 201
    assert "id" in data["data"]

def test_login_user():
    """Test user login"""
    response = client.post(
        "/api/v1/users/login",
        json={
            "username": "testuser",
            "password": "Password123"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data["data"]
    return data["data"]["access_token"]

def test_get_users():
    """Test get user list"""
    token = test_login_user()
    response = client.get(
        "/api/v1/users?page=1&limit=10",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "users" in data["data"]

def test_get_product():
    """Test get product detail"""
    response = client.get("/api/v1/products/1")
    assert response.status_code == 200
    data = response.json()
    assert "id" in data["data"]
    assert "name" in data["data"]
```

### Run Tests

```bash
# Run all tests
pytest

# Run specific test
pytest test_api.py::test_root

# Verbose output
pytest -v

# Generate test report
pytest --html=report.html
```

## Test Checklist

### Functional Tests
- [ ] GET requests work
- [ ] POST requests work
- [ ] PUT requests work
- [ ] DELETE requests work
- [ ] Pagination works
- [ ] Filtering works
- [ ] Sorting works

### Auth Tests
- [ ] Unauthorized requests rejected (401)
- [ ] Invalid token rejected (401)
- [ ] Valid token accepted (200)
- [ ] Expired token rejected (401)

### Authorization Tests
- [ ] Regular users cannot access admin APIs (403)
- [ ] Users can only access their own data (403)
- [ ] Admin can access all data (200)

### Error Handling Tests
- [ ] Invalid params return 400
- [ ] Missing resource returns 404
- [ ] Permission denied returns 403
- [ ] Server errors return 500

### Response Format Tests
- [ ] Success response includes code=200
- [ ] Error response includes error message
- [ ] Data structure matches spec
- [ ] Data types are correct

## Test Report Template

```markdown
# API Test Report

## Overview
- Test date: 2024-XX-XX
- Tester: XXX
- Service URL: http://localhost:8000

## Results

### Health Check
- [ ] GET / - Pass/Fail

### User APIs
- [ ] POST /api/v1/users/register - Pass/Fail
- [ ] POST /api/v1/users/login - Pass/Fail
- [ ] GET /api/v1/users - Pass/Fail
- [ ] GET /api/v1/users/:id - Pass/Fail
- [ ] PUT /api/v1/users/:id - Pass/Fail
- [ ] DELETE /api/v1/users/:id - Pass/Fail

### Product APIs
- [ ] GET /api/v1/products - Pass/Fail
- [ ] GET /api/v1/products/:id - Pass/Fail
- [ ] POST /api/v1/products - Pass/Fail

### Order APIs
- [ ] GET /api/v1/orders - Pass/Fail
- [ ] POST /api/v1/orders - Pass/Fail

## Summary
- Total tests: XX
- Passed: XX
- Failed: XX
- Pass rate: XX%

## Failures
1. [API Path] - [Root cause]
2. [API Path] - [Root cause]

## Conclusion
- Deliverable: [Yes/No]
- Issues to fix: [List]
```
