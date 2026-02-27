# Data Model Design Spec

## Table of Contents
- [Entity Identification](#entity-identification)
- [Field Type Mapping](#field-type-mapping)
- [Relationship Design](#relationship-design)
- [Constraint Definitions](#constraint-definitions)
- [Index Optimization](#index-optimization)

## Entity Identification

### Derive Entities from APIs

Analyze API URLs and request/response params to identify core entities:

| API URL | Entity | Entity Type |
|----------|------|----------|
| GET /api/users | User | Core entity |
| GET /api/products | Product | Core entity |
| GET /api/orders | Order | Core entity |
| GET /api/orders/:id/items | OrderItem | Related entity |
| GET /api/categories | Category | Category entity |

### Entity Naming Rules

- Use singular nouns (User, not Users)
- Use PascalCase (ProductCategory, not product_category)
- Avoid DB reserved words (Order, Group, etc.)

### System Field Conventions

All entities should include these system fields:

| Field | Type | Description |
|--------|------|------|
| id | Integer | Primary key, auto-increment |
| created_at | DateTime | Created time, auto-set |
| updated_at | DateTime | Updated time, auto-updated |
| deleted_at | DateTime (nullable) | Soft delete timestamp |

## Field Type Mapping

### Python Type → DB Type

| Python Type | PostgreSQL Type | MySQL Type | Description |
|-------------|-----------------|------------|------|
| int | INTEGER | INT | Integer |
| float | NUMERIC(10,2) | DECIMAL(10,2) | Float (money, etc.) |
| str | VARCHAR(255) | VARCHAR(255) | Short text |
| str (long text) | TEXT | TEXT | Long text |
| bool | BOOLEAN | TINYINT(1) | Boolean |
| datetime | TIMESTAMP | DATETIME | DateTime |
| date | DATE | DATE | Date |
| json | JSONB | JSON | JSON object |
| enum | VARCHAR + CHECK | ENUM | Enum |

### Common Field Examples

| Business Field | Python Type | DB Type | Example |
|----------|-------------|------------|------|
| Username | str | VARCHAR(50) | john_doe |
| Password (hash) | str | VARCHAR(255) | $2b$12$... |
| Email | str | VARCHAR(255) | john@example.com |
| Mobile | str | VARCHAR(20) | 13800138000 |
| Amount | Decimal | NUMERIC(10,2) | 99.99 |
| Quantity | int | INTEGER | 10 |
| Status | str | VARCHAR(20) | active |
| Price | Decimal | NUMERIC(10,2) | 299.00 |
| Stock | int | INTEGER | 100 |
| Image URL | str | TEXT | https://example.com/image.png |
| Extra attributes | dict | JSONB | {"key": "value"} |

## Relationship Design

### One-to-Many

**Scenario**: a user has multiple orders

```python
# User model (one side)
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String(50))

    # Relationship
    orders = relationship("Order", back_populates="user", cascade="all, delete-orphan")

# Order model (many side)
class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    order_no = Column(String(50))

    # Relationship
    user = relationship("User", back_populates="orders")
```

**DB design**:
- orders table contains user_id FK
- Add index on user_id: `CREATE INDEX idx_orders_user_id ON orders(user_id);`

### Many-to-Many

**Scenario**: an order contains multiple products, products belong to multiple orders

```python
# Order model
class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True)
    order_no = Column(String(50))

    # Relationship (via join table)
    items = relationship("OrderItem", back_populates="order")

# Product model
class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True)
    name = Column(String(100))

    # Relationship (via join table)
    order_items = relationship("OrderItem", back_populates="product")

# Join table
class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer, default=1)
    price = Column(Numeric(10,2))

    # Relationship
    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")
```

**DB design**:
- Create join table order_items
- order_items contains order_id and product_id FKs
- Add indexes for both fields

### Self-Referential

**Scenario**: comment parent/child relationship

```python
class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    content = Column(Text)
    parent_id = Column(Integer, ForeignKey("comments.id"), nullable=True)

    # Relationship
    parent = relationship("Comment", remote_side=[id], backref="replies")
```

### One-to-One

**Scenario**: user extended profile info

```python
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String(50))

    # One-to-one
    profile = relationship("UserProfile", back_populates="user", uselist=False)

class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    bio = Column(Text)
    avatar = Column(String(255))

    user = relationship("User", back_populates="profile")
```

## Constraint Definitions

### Primary Key
- Default auto-increment integer PK: `id = Column(Integer, primary_key=True, autoincrement=True)`

### Unique Constraints
```python
# Unique username
username = Column(String(50), unique=True, index=True)

# Unique order number
order_no = Column(String(50), unique=True, index=True)
```

### Not Null
```python
# Required fields
username = Column(String(50), nullable=False)
email = Column(String(255), nullable=False)
```

### Default Values
```python
# Default status
status = Column(String(20), default="active")

# Default quantity
quantity = Column(Integer, default=1)

# Default price
price = Column(Numeric(10,2), default=0.00)
```

### Check Constraints
```python
# Price must be > 0
price = Column(Numeric(10,2), CheckConstraint('price > 0'))

# Status must be in allowed values
status = Column(String(20), CheckConstraint("status IN ('active', 'inactive', 'deleted')"))

# Stock cannot be negative
stock = Column(Integer, CheckConstraint('stock >= 0'))
```

## Index Optimization

### Single-Field Index
```python
# Add indexes for commonly queried fields
email = Column(String(255), index=True)
mobile = Column(String(20), index=True)
username = Column(String(50), unique=True, index=True)
```

### Composite Index
```python
# Use Index in SQLAlchemy
from sqlalchemy import Index

class Order(Base):
    __tablename__ = "orders"

    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String(20))
    created_at = Column(DateTime)

    # Composite indexes: query by user and status
    __table_args__ = (
        Index('idx_user_status', 'user_id', 'status'),
        Index('idx_created_at', 'created_at'),
    )
```

### Index Design Principles

1. **Index foreign keys**: speed up JOINs
2. **Index frequently queried fields**: e.g., username, email, mobile
3. **Composite indexes for combined filters**: e.g., WHERE user_id = ? AND status = ?
4. **Avoid over-indexing**: indexes consume storage and slow writes

## Data Model Design Examples

### User Model

```python
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    mobile = Column(String(20), unique=True, nullable=True, index=True)
    hashed_password = Column(String(255), nullable=False)
    avatar = Column(String(255), nullable=True)
    status = Column(String(20), default="active", nullable=False)
    is_admin = Column(Boolean, default=False, nullable=False)

    # System fields
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    # Relationships
    orders = relationship("Order", back_populates="user", cascade="all, delete-orphan")
```

### Product Model

```python
from sqlalchemy import Column, Integer, String, DateTime, Numeric, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    price = Column(Numeric(10,2), nullable=False)
    stock = Column(Integer, default=0, nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    status = Column(String(20), default="active", nullable=False)

    # System fields
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    # Relationships
    category = relationship("Category", back_populates="products")
    order_items = relationship("OrderItem", back_populates="product")
```

### Order Model

```python
from sqlalchemy import Column, Integer, String, DateTime, Numeric, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_no = Column(String(50), unique=True, nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    total_amount = Column(Numeric(10,2), default=0.00, nullable=False)
    status = Column(String(20), default="pending", nullable=False)

    # System fields
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
```

### Order Item Model

```python
from sqlalchemy import Column, Integer, ForeignKey, Numeric
from sqlalchemy.orm import relationship
from app.database import Base

class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False, index=True)
    quantity = Column(Integer, default=1, nullable=False)
    price = Column(Numeric(10,2), nullable=False)
    total_price = Column(Numeric(10,2), nullable=False)

    # Relationships
    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")
```
