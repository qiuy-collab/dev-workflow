# Requirements List Template

## Table of Contents
- [Format Guide](#format-guide)
- [Tech Stack Selection Record](#tech-stack-selection-record)
- [Requirement Examples](#requirement-examples)
- [Acceptance Criteria Definition](#acceptance-criteria-definition)

## Format Guide

### Basic Info
| Field | Description |
|------|------|
| Requirement ID | Unique identifier (e.g., REQ-001) |
| Requirement Name | Concise requirement title |
| Requirement Description | Detailed feature description (include user story format) |
| Priority | P0/P1/P2/P3 (see priority framework) |
| Requirement Type | Functional / Non-functional |
| Related User Roles | User roles involved |

### Priority Definition
| Level | Meaning | Example |
|------|------|------|
| P0 | Must-have, MVP core feature | User registration, login |
| P1 | Important feature, impacts UX | Data export, search |
| P2 | Enhancement, can be deferred | Social sharing, personalization |
| P3 | Optimization or extension | Theme customization, advanced analytics |

## Tech Stack Selection Record

### Backend Tech Stack
| Category | Selection | Description |
|----------|------|------|
| Backend Language | Python / Java / Node.js / Go / Other | Server-side language |
| Web Framework | FastAPI / Spring Boot / Express / Gin / Other | Web framework |
| Database | PostgreSQL / MySQL / MongoDB / Other | Database type |
| ORM | SQLAlchemy / MyBatis / Mongoose / Other | Object-relational mapping |

### Frontend Tech Stack (Optional)
| Category | Selection | Description |
|----------|------|------|
| Frontend Framework | React / Vue / Angular / Other | UI framework |
| State Management | Redux / Vuex / MobX / Other | State library |
| Build Tool | Webpack / Vite / Other | Build/bundle tool |

### Tech Stack Examples

#### Example 1: Python Full Stack
```
Backend Language: Python
Web Framework: FastAPI
Database: PostgreSQL
ORM: SQLAlchemy
Frontend Framework: React
State Management: Redux
```

#### Example 2: Java Enterprise
```
Backend Language: Java
Web Framework: Spring Boot
Database: MySQL
ORM: MyBatis
Frontend Framework: Vue
State Management: Vuex
```

#### Example 3: Node.js Full Stack
```
Backend Language: Node.js
Web Framework: Express
Database: MongoDB
ORM: Mongoose
Frontend Framework: React
State Management: Redux
```


## Requirement Examples

### REQ-001 User Registration

| Field | Content |
|------|------|
| Requirement Name | User Registration |
| Requirement Description | As a new user, I want to register with email or phone so I can use the system. Support email verification and password strength checks. |
| Priority | P0 |
| Requirement Type | Functional |
| Related User Roles | New user |

**Acceptance Criteria:**
- [ ] User can register with an email address
- [ ] User can register with a phone number
- [ ] Send verification email/SMS during registration
- [ ] Password strength check (at least 8 characters, includes letters and numbers)
- [ ] Email/phone format validation
- [ ] Prevent duplicate registration

---

### REQ-002 User Login

| Field | Content |
|------|------|
| Requirement Name | User Login |
| Requirement Description | As a registered user, I want to log in with email/phone and password to access my account and data. Support remember-me and password recovery. |
| Priority | P0 |
| Requirement Type | Functional |
| Related User Roles | Registered user |

**Acceptance Criteria:**
- [ ] User can log in with registered email/phone
- [ ] Password validation is correct
- [ ] Support remember-me (7 days without login)
- [ ] Lock account for 30 minutes after 5 failed logins
- [ ] Provide password recovery
- [ ] Record login logs

---

### REQ-003 Data Response Time

| Field | Content |
|------|------|
| Requirement Name | Data Response Time |
| Requirement Description | The system must ensure key operations respond within an acceptable time to provide a good user experience. |
| Priority | P1 |
| Requirement Type | Non-functional (Performance) |
| Related User Roles | All users |

**Acceptance Criteria:**
- [ ] Page load time < 3 seconds
- [ ] API response time < 1 second (95% of requests)
- [ ] Query response time < 2 seconds
- [ ] Support 1000 concurrent users

## Acceptance Criteria Definition

### Format Rules
- Use [ ] to indicate testable acceptance conditions
- Each acceptance criterion should be verifiable and specific
- Avoid vague descriptions (e.g., "good experience")

### Common Acceptance Types
1. **Functional**: whether features work correctly
2. **UI**: whether UI elements display correctly
3. **Performance**: response time, throughput, etc.
4. **Security**: access control, data encryption, etc.
5. **Compatibility**: browser and device compatibility
