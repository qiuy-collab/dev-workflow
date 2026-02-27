# Page List Template

## Table of Contents
- [Format Guide](#format-guide)
- [Page List Examples](#page-list-examples)
- [Page Classification Rules](#page-classification-rules)

## Format Guide

### Basic Info
| Field | Description |
|------|------|
| Page ID | Unique identifier (e.g., PG-001) |
| Page Name | Concise page title |
| Function Description | Core page functions and purpose |
| Page Type | List / Detail / Form / Confirmation |
| Priority | P0/P1/P2/P3 (aligned with requirement priority) |
| Dependency Pages | Prerequisite pages (if any) |
| Related APIs | APIs called by this page |

### Page Type Description
| Type | Characteristics | Example |
|------|------|------|
| List | Displays multiple records | Product list, order list |
| Detail | Displays details of a single record | Product detail, order detail |
| Form | User input page | Registration, edit page |
| Confirmation | User confirms action | Payment confirmation, delete confirmation |

## Page List Examples

### PG-001 Home

| Field | Content |
|------|------|
| Page ID | PG-001 |
| Page Name | Home |
| Function Description | Show system overview, recommended content, quick entry points; first page users see |
| Page Type | List |
| Priority | P0 |
| Dependency Pages | None |
| Related APIs | GET /api/products/featured, GET /api/banners |

---

### PG-002 Product List

| Field | Content |
|------|------|
| Page ID | PG-002 |
| Page Name | Product List |
| Function Description | Show product list with category filters, price sorting, keyword search |
| Page Type | List |
| Priority | P0 |
| Dependency Pages | PG-001 (Home) |
| Related APIs | GET /api/products, GET /api/categories |

---

### PG-003 Product Detail

| Field | Content |
|------|------|
| Page ID | PG-003 |
| Page Name | Product Detail |
| Function Description | Show product details (price, specs, stock, reviews) and support add-to-cart |
| Page Type | Detail |
| Priority | P0 |
| Dependency Pages | PG-002 (Product List) |
| Related APIs | GET /api/products/:id, POST /api/cart/items |

---

### PG-004 Cart

| Field | Content |
|------|------|
| Page ID | PG-004 |
| Page Name | Cart |
| Function Description | Show cart items, support quantity updates, delete, checkout |
| Page Type | List |
| Priority | P0 |
| Dependency Pages | PG-003 (Product Detail) |
| Related APIs | GET /api/cart, PUT /api/cart/items/:id, DELETE /api/cart/items/:id |

---

### PG-005 Checkout

| Field | Content |
|------|------|
| Page ID | PG-005 |
| Page Name | Checkout |
| Function Description | Confirm order info (items, address, payment method), submit order and pay |
| Page Type | Confirmation |
| Priority | P0 |
| Dependency Pages | PG-004 (Cart) |
| Related APIs | GET /api/addresses, POST /api/orders, POST /api/payments |

---

### PG-006 User Registration

| Field | Content |
|------|------|
| Page ID | PG-006 |
| Page Name | User Registration |
| Function Description | User enters registration info (email/phone, password) to register and verify |
| Page Type | Form |
| Priority | P0 |
| Dependency Pages | None |
| Related APIs | POST /api/register, POST /api/verify-code |

---

### PG-007 User Login

| Field | Content |
|------|------|
| Page ID | PG-007 |
| Page Name | User Login |
| Function Description | Registered users enter credentials to log in |
| Page Type | Form |
| Priority | P0 |
| Dependency Pages | PG-006 (User Registration) |
| Related APIs | POST /api/login |

---

### PG-008 Profile Center

| Field | Content |
|------|------|
| Page ID | PG-008 |
| Page Name | Profile Center |
| Function Description | Show user info, order history, settings entry |
| Page Type | List |
| Priority | P1 |
| Dependency Pages | PG-007 (User Login) |
| Related APIs | GET /api/user/profile, GET /api/orders |

---

### PG-009 Edit Profile

| Field | Content |
|------|------|
| Page ID | PG-009 |
| Page Name | Edit Profile |
| Function Description | User edits personal info (nickname, avatar, phone, etc.) |
| Page Type | Form |
| Priority | P2 |
| Dependency Pages | PG-008 (Profile Center) |
| Related APIs | PUT /api/user/profile |

## Page Classification Rules

### By Feature Module
1. **User module**: registration, login, profile center, settings
2. **Product module**: product list, product detail, search
3. **Order module**: cart, checkout, order list, order detail
4. **Payment module**: payment selection, payment result, payment history
5. **Admin module**: analytics, user management, product management

### By Priority
- **P0 (Must have)**: core flow pages (home, product list, detail, checkout)
- **P1 (Should have)**: important pages (profile center, order list)
- **P2 (Could have)**: enhancement pages (edit profile, favorites)
- **P3 (Deferred)**: optimization pages (theme settings, advanced filters)

### By Access Control
- **Public pages**: no login required (home, product list, register, login)
- **Authenticated pages**: login required (profile center, order list, cart)
- **Admin pages**: admin-only (admin console, analytics)

### Page Dependencies
Dependencies should follow:
- Base pages (home, login) have no dependencies
- Flow pages (detail, checkout) depend on previous flow pages
- Feature pages (profile, settings) depend on login page
- Admin pages depend on admin permissions

When drawing dependency graphs, use arrows for direction:
```
PG-001 (Home) → PG-002 (Product List) → PG-003 (Product Detail)
                                                    ↓
PG-006 (Register) → PG-007 (Login) → PG-004 (Cart) → PG-005 (Checkout)
                                      ↓
                                PG-008 (Profile Center) → PG-009 (Edit Profile)
```
