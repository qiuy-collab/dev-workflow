# Project Structure Template

## Directory Structure

```
project_name/
├── app/                          # Main app directory
│   ├── __init__.py              # App init
│   ├── main.py                  # FastAPI entrypoint
│   ├── config.py                # Config
│   ├── database.py              # DB connection
│   │
│   ├── models/                  # SQLAlchemy ORM models
│   │   ├── __init__.py
│   │   ├── user.py              # User model
│   │   ├── product.py           # Product model
│   │   └── order.py             # Order model
│   │
│   ├── schemas/                 # Pydantic schemas (request/response)
│   │   ├── __init__.py
│   │   ├── user.py              # User schema
│   │   ├── product.py           # Product schema
│   │   └── order.py             # Order schema
│   │
│   ├── routers/                 # API route handlers
│   │   ├── __init__.py
│   │   ├── auth.py              # Auth routes
│   │   ├── users.py             # User routes
│   │   ├── products.py          # Product routes
│   │   └── orders.py            # Order routes
│   │
│   ├── services/                # Business logic layer
│   │   ├── __init__.py
│   │   ├── user_service.py      # User logic
│   │   └── order_service.py     # Order logic
│   │
│   ├── utils/                   # Utilities
│   │   ├── __init__.py
│   │   ├── auth.py              # Auth utils (JWT)
│   │   └── password.py          # Password hashing
│   │
│   └── core/                    # Core configuration
│       ├── __init__.py
│       ├── security.py          # Security settings
│       └── deps.py              # Dependency injection
│
├── alembic/                     # DB migrations
│   ├── versions/
│   └── env.py
│
├── tests/                       # Tests
│   ├── __init__.py
│   ├── conftest.py
│   └── test_users.py
│
├── .env                         # Env vars
├── .env.example                 # Env var example
├── requirements.txt             # Python dependencies
├── alembic.ini                  # Alembic config
├── pyproject.toml               # Project config
└── README.md                    # Project docs
```

## Core File Descriptions

### app/main.py
FastAPI entrypoint, configure CORS, middleware, and route registration.

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, users, products, orders

app = FastAPI(
    title="Project Name",
    description="Project description",
    version="1.0.0"
)

# CORS config
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(products.router, prefix="/api/v1/products", tags=["products"])
app.include_router(orders.router, prefix="/api/v1/orders", tags=["orders"])

@app.get("/")
async def root():
    return {"message": "Hello World"}
```

### app/config.py
Config file that reads environment variables.

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database config
    DATABASE_URL: str = "postgresql://user:password@localhost/dbname"

    # JWT config
    SECRET_KEY: str = "your-secret-key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # App config
    APP_NAME: str = "My App"
    DEBUG: bool = True

    class Config:
        env_file = ".env"

settings = Settings()
```

### app/database.py
DB connection and session management.

```python
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

## Layered Architecture Overview

### Models Layer (Data Models)
- Define DB table structure
- Define field types and constraints
- Define table relationships (one-to-many, many-to-many)

### Schemas Layer (Data Validation)
- Define request param validation
- Define response data formats
- Handle serialization/deserialization

### Routers Layer (Routing)
- Define API endpoints
- Handle HTTP requests
- Call Services layer

### Services Layer (Business Logic)
- Implement business logic
- Data processing and transformation
- Call Models layer

### Utils Layer (Utilities)
- Auth (JWT generation and verification)
- Password hashing (bcrypt)
- Other common utilities

## requirements.txt

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
alembic==1.12.1
pydantic==2.5.0
pydantic-settings==2.1.0
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
```

## .env Example

```bash
# Database config
DATABASE_URL=postgresql://postgres:password@localhost:5432/myapp

# JWT config
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# App config
APP_NAME=My Application
DEBUG=True
```

## Run Commands

### Start dev server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Database migrations
```bash
# Generate migration
alembic revision --autogenerate -m "description"

# Apply migration
alembic upgrade head
```

### View auto-generated API docs
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
