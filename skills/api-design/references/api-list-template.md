# API List Template

## Table of Contents
- [RESTful API Conventions](#restful-api-conventions)
- [API Definition Format](#api-definition-format)
- [API Examples](#api-examples)
- [Error Code Definitions](#error-code-definitions)

## RESTful API Conventions

### HTTP Methods
| Method | Description | Idempotent | Example |
|------|------|--------|------|
| GET | Fetch resource | Yes | GET /api/users |
| POST | Create resource | No | POST /api/users |
| PUT | Update entire resource | Yes | PUT /api/users/1 |
| PATCH | Partial update | No | PATCH /api/users/1 |
| DELETE | Delete resource | Yes | DELETE /api/users/1 |

### URL Naming Rules
| Rule | Description | Example |
|------|------|------|
| Use plural nouns | Resources in plural form | /api/users, /api/orders |
| Use lowercase | URL in lowercase | /api/user-profiles |
| Use hyphens | Use hyphens between words | /api/user-profiles |
| Avoid verbs | Do not use verbs | ❌ /api/getUsers ✅ /api/users |
| Versioning | Include version in URL | /api/v1/users |

### URL Path Examples
```
GET    /api/users                    # Get user list
GET    /api/users/:id                # Get single user
POST   /api/users                    # Create user
PUT    /api/users/:id                # Update user
DELETE /api/users/:id                # Delete user

GET    /api/users/:id/orders         # Get user's orders
POST   /api/users/:id/orders         # Create order for user
GET    /api/orders/:id/items         # Get order items
```

### Request Header Conventions
| Header | Description | Example |
|--------|------|------|
| Content-Type | Request content type | application/json |
| Authorization | Auth info | Bearer {token} |
| Accept | Response content type | application/json |
| X-Requested-With | AJAX marker | XMLHttpRequest |

## API Definition Format

### Basic Info
| Field | Description |
|------|------|
| API ID | Unique identifier (e.g., API-001) |
| API Name | Business name of API |
| API Description | Function description |
| URL | Full request path |
| Method | HTTP method (GET/POST/PUT/PATCH/DELETE) |
| Auth | None / Token / OAuth |
| Headers | Required request headers |
| Request Params | URL params / body params |
| Response Format | Response data structure |
| Error Codes | Possible error codes and descriptions |
| Examples | Request and response examples |

### Parameter Types
| Type | Description | Example |
|------|------|------|
| Path | URL path parameter | id in /api/users/:id |
| Query | URL query params | ?page=1&limit=10 |
| Body | Request body | JSON body |
| Header | Request header | Authorization: Bearer {token} |

### Parameter Attributes
| Attribute | Description |
|------|------|
| Name | Parameter name |
| Type | Data type (String/Number/Boolean/Object/Array) |
| Required | true/false |
| Default | Default value |
| Description | Parameter purpose |
| Example | Example value |

## API Examples

### API-001 Get User List

| Field | Content |
|------|------|
| API ID | API-001 |
| API Name | Get User List |
| API Description | Paginated user list with filter and sorting |
| URL | /api/v1/users |
| Method | GET |
| Auth | Token |

#### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

#### Request Params (Query)
| Name | Type | Required | Default | Description | Example |
|--------|------|------|--------|------|--------|
| page | Number | No | 1 | Page number | 1 |
| limit | Number | No | 10 | Page size | 10 |
| keyword | String | No | None | Keyword search (username/email) | admin |
| status | String | No | None | User status (active/inactive) | active |
| sort_by | String | No | created_at | Sort field | created_at |
| order | String | No | desc | Sort order (asc/desc) | desc |

#### Response Format
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 100,
    "page": 1,
    "limit": 10,
    "users": [
      {
        "id": 1,
        "username": "admin",
        "email": "admin@example.com",
        "mobile": "13800138000",
        "avatar": "https://example.com/avatar/1.png",
        "status": "active",
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

---

### API-002 Get Single User

| Field | Content |
|------|------|
| API ID | API-002 |
| API Name | Get Single User |
| API Description | Fetch user details by ID |
| URL | /api/v1/users/:id |
| Method | GET |
| Auth | Token |

#### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

#### Request Params (Path)
| Name | Type | Required | Description | Example |
|--------|------|------|------|--------|
| id | Number | Yes | User ID | 1 |

#### Response Format
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "mobile": "13800138000",
    "avatar": "https://example.com/avatar/1.png",
    "gender": "Male",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

---

### API-003 Create User

| Field | Content |
|------|------|
| API ID | API-003 |
| API Name | Create User |
| API Description | Create a new user account |
| URL | /api/v1/users |
| Method | POST |
| Auth | None |

#### Headers
```
Content-Type: application/json
```

#### Request Params (Body)
| Name | Type | Required | Default | Description | Example |
|--------|------|------|--------|------|--------|
| username | String | Yes | None | Username | john_doe |
| password | String | Yes | None | Password | Password123 |
| email | String | Yes | None | Email | john@example.com |
| mobile | String | No | None | Mobile | 13800138000 |

#### Request Example
```json
{
  "username": "john_doe",
  "password": "Password123",
  "email": "john@example.com",
  "mobile": "13800138000"
}
```

#### Response Format
```json
{
  "code": 201,
  "message": "created",
  "data": {
    "id": 2,
    "username": "john_doe",
    "email": "john@example.com",
    "mobile": "13800138000",
    "avatar": "https://example.com/avatar/default.png",
    "status": "active",
    "created_at": "2024-01-02T00:00:00Z"
  }
}
```

---

### API-004 Update User

| Field | Content |
|------|------|
| API ID | API-004 |
| API Name | Update User |
| API Description | Update user information |
| URL | /api/v1/users/:id |
| Method | PUT |
| Auth | Token |

#### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

#### Request Params (Path)
| Name | Type | Required | Description | Example |
|--------|------|------|------|--------|
| id | Number | Yes | User ID | 1 |

#### Request Params (Body)
| Name | Type | Required | Default | Description | Example |
|--------|------|------|--------|------|--------|
| username | String | No | None | Username | john_doe |
| email | String | No | None | Email | john@example.com |
| mobile | String | No | None | Mobile | 13800138000 |
| avatar | String | No | None | Avatar URL | https://example.com/avatar/1.png |
| gender | String | No | Secret | Gender (Male/Female/Secret) | Male |

#### Request Example
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "mobile": "13800138000",
  "avatar": "https://example.com/avatar/1.png",
  "gender": "Male"
}
```

#### Response Format
```json
{
  "code": 200,
  "message": "updated",
  "data": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "mobile": "13800138000",
    "avatar": "https://example.com/avatar/1.png",
    "gender": "Male",
    "status": "active",
    "updated_at": "2024-01-02T00:00:00Z"
  }
}
```

---

### API-005 Delete User

| Field | Content |
|------|------|
| API ID | API-005 |
| API Name | Delete User |
| API Description | Soft delete user (mark as deleted) |
| URL | /api/v1/users/:id |
| Method | DELETE |
| Auth | Token |

#### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

#### Request Params (Path)
| Name | Type | Required | Description | Example |
|--------|------|------|------|--------|
| id | Number | Yes | User ID | 1 |

#### Response Format
```json
{
  "code": 200,
  "message": "deleted",
  "data": null
}
```

---

### API-006 User Login

| Field | Content |
|------|------|
| API ID | API-006 |
| API Name | User Login |
| API Description | Log in with email/phone and password |
| URL | /api/v1/login |
| Method | POST |
| Auth | None |

#### Headers
```
Content-Type: application/json
```

#### Request Params (Body)
| Name | Type | Required | Default | Description | Example |
|--------|------|------|--------|------|--------|
| account | String | Yes | None | Email or phone | john@example.com |
| password | String | Yes | None | Password | Password123 |

#### Request Example
```json
{
  "account": "john@example.com",
  "password": "Password123"
}
```

#### Response Format
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com",
      "avatar": "https://example.com/avatar/1.png"
    }
  }
}
```

---

### API-007 User Logout

| Field | Content |
|------|------|
| API ID | API-007 |
| API Name | User Logout |
| API Description | Log out and invalidate token |
| URL | /api/v1/logout |
| Method | POST |
| Auth | Token |

#### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

#### Response Format
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

## Error Code Definitions

### Standard Response Format
All APIs return a unified response format:
```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

### Success Codes
| code | message | Description |
|------|---------|------|
| 200 | success | Request succeeded |
| 201 | created | Resource created |
| 204 | no content | Request succeeded with no content |

### Client Error Codes (4xx)
| code | message | Description |
|------|---------|------|
| 400 | bad request | Invalid request parameters |
| 401 | unauthorized | Not authenticated |
| 403 | forbidden | Access denied |
| 404 | not found | Resource not found |
| 409 | conflict | Resource conflict (e.g., duplicate registration) |
| 422 | unprocessable entity | Validation failed |
| 429 | too many requests | Too many requests |

### Server Error Codes (5xx)
| code | message | Description |
|------|---------|------|
| 500 | internal server error | Internal server error |
| 502 | bad gateway | Bad gateway |
| 503 | service unavailable | Service unavailable |
| 504 | gateway timeout | Gateway timeout |

### Business Error Code Examples
| code | message | Description |
|------|---------|------|
| 10001 | username exists | Username already exists |
| 10002 | email exists | Email already exists |
| 10003 | mobile exists | Mobile already exists |
| 10004 | wrong password | Incorrect password |
| 10005 | user not found | User does not exist |
| 10006 | user disabled | User is disabled |
| 10007 | invalid code | Verification code is incorrect |
| 10008 | code expired | Verification code timed out |
| 20001 | product not found | Product does not exist |
| 20002 | insufficient stock | Not enough stock |
| 30001 | order not found | Order does not exist |
| 30002 | order already paid | Order already paid; cannot repay |

### Error Response Examples
```json
{
  "code": 401,
  "message": "unauthorized, please log in",
  "data": null
}
```

```json
{
  "code": 422,
  "message": "validation failed",
  "data": {
    "errors": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Password at least 8 characters with upper/lowercase and numbers"
      }
    ]
  }
}
```
