# ORM Model Code Template

## Base Model Template

All models should inherit from Base and include system fields:

```python
from sqlalchemy import Column, Integer, DateTime
from sqlalchemy.sql import func
from app.database import Base

class BaseModel(Base):
    """
    Base model class with common fields
    """
    __abstract__ = True

    id = Column(Integer, primary_key=True, autoincrement=True, comment="Primary key ID")
    created_at = Column(DateTime, server_default=func.now(), comment="Created time")
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), comment="Updated time")
    deleted_at = Column(DateTime, nullable=True, comment="Deleted time (soft delete)")
```

## User Model

```python
from sqlalchemy import Column, String, Boolean, CheckConstraint
from app.database import Base

class User(Base):
    """
    User model
    """
    __tablename__ = "users"

    # Basic info
    username = Column(String(50), unique=True, nullable=False, index=True, comment="Username")
    email = Column(String(255), unique=True, nullable=False, index=True, comment="Email")
    mobile = Column(String(20), unique=True, nullable=True, index=True, comment="Mobile")
    hashed_password = Column(String(255), nullable=False, comment="Password hash")

    # Profile
    avatar = Column(String(255), nullable=True, comment="Avatar URL")
    gender = Column(String(10), nullable=True, comment="Gender: male/female/secret")
    bio = Column(String(255), nullable=True, comment="Bio")

    # Account status
    status = Column(String(20), default="active", nullable=False, comment="Status: active/inactive/deleted")
    is_admin = Column(Boolean, default=False, nullable=False, comment="Is admin")

    # Constraints
    __table_args__ = (
        CheckConstraint("status IN ('active', 'inactive', 'deleted')", name="check_user_status"),
        CheckConstraint("gender IS NULL OR gender IN ('male', 'female', 'secret')", name="check_user_gender"),
        {"comment": "Users table"}
    )

    def __repr__(self):
        return f"<User(id={self.id}, username={self.username})>"
```

## Product Model

```python
from sqlalchemy import Column, String, Integer, Numeric, Text, ForeignKey, CheckConstraint, Index
from sqlalchemy.orm import relationship
from app.database import Base

class Product(Base):
    """
    Product model
    """
    __tablename__ = "products"

    # Basic info
    name = Column(String(100), nullable=False, index=True, comment="Product name")
    description = Column(Text, nullable=True, comment="Product description")

    # Price and stock
    price = Column(Numeric(10, 2), nullable=False, comment="Product price")
    original_price = Column(Numeric(10, 2), nullable=True, comment="Original price")
    stock = Column(Integer, default=0, nullable=False, comment="Stock quantity")

    # Category
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True, index=True, comment="Category ID")

    # Product status
    status = Column(String(20), default="active", nullable=False, comment="Status: active/inactive/out_of_stock")

    # Images
    images = Column(String(1000), nullable=True, comment="Product image URLs, comma-separated")

    # Constraints and indexes
    __table_args__ = (
        CheckConstraint("price > 0", name="check_product_price"),
        CheckConstraint("stock >= 0", name="check_product_stock"),
        CheckConstraint("status IN ('active', 'inactive', 'out_of_stock')", name="check_product_status"),
        Index("idx_product_category", "category_id", "status"),
        {"comment": "Products table"}
    )

    # Relationships
    category = relationship("Category", back_populates="products")
    order_items = relationship("OrderItem", back_populates="product")

    def __repr__(self):
        return f"<Product(id={self.id}, name={self.name})>"
```

## Order Model

```python
from sqlalchemy import Column, String, Integer, Numeric, ForeignKey, CheckConstraint, Index
from sqlalchemy.orm import relationship
from app.database import Base

class Order(Base):
    """
    Order model
    """
    __tablename__ = "orders"

    # Order number
    order_no = Column(String(50), unique=True, nullable=False, index=True, comment="Order number")

    # User association
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True, comment="User ID")

    # Amounts
    total_amount = Column(Numeric(10, 2), default=0.00, nullable=False, comment="Total amount")
    discount_amount = Column(Numeric(10, 2), default=0.00, nullable=False, comment="Discount amount")
    actual_amount = Column(Numeric(10, 2), default=0.00, nullable=False, comment="Paid amount")

    # Shipping address
    receiver_name = Column(String(50), nullable=False, comment="Receiver name")
    receiver_mobile = Column(String(20), nullable=False, comment="Receiver mobile")
    receiver_address = Column(String(500), nullable=False, comment="Receiver address")

    # Order status
    status = Column(String(20), default="pending", nullable=False, comment="Status: pending/paid/shipped/completed/cancelled")
    payment_status = Column(String(20), default="unpaid", nullable=False, comment="Payment status: unpaid/paid/refunded")

    # Payment
    payment_method = Column(String(20), nullable=True, comment="Payment method: wechat/alipay/bank_card")
    payment_time = Column(DateTime, nullable=True, comment="Payment time")

    # Remark
    remark = Column(String(500), nullable=True, comment="Order remark")

    # Constraints and indexes
    __table_args__ = (
        CheckConstraint("total_amount >= 0", name="check_order_total"),
        CheckConstraint("status IN ('pending', 'paid', 'shipped', 'completed', 'cancelled')", name="check_order_status"),
        Index("idx_order_user_status", "user_id", "status"),
        {"comment": "Orders table"}
    )

    # Relationships
    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Order(id={self.id}, order_no={self.order_no})>"
```

## Order Item Model

```python
from sqlalchemy import Column, Integer, ForeignKey, Numeric, CheckConstraint, Index
from sqlalchemy.orm import relationship
from app.database import Base

class OrderItem(Base):
    """
    Order item model (order-product join table)
    """
    __tablename__ = "order_items"

    # Associations
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False, index=True, comment="Order ID")
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False, index=True, comment="Product ID")

    # Product snapshot (at order time)
    product_name = Column(String(100), nullable=False, comment="Product name")
    product_image = Column(String(255), nullable=True, comment="Product image")

    # Quantity and price
    quantity = Column(Integer, default=1, nullable=False, comment="Quantity")
    unit_price = Column(Numeric(10, 2), nullable=False, comment="Unit price")
    total_price = Column(Numeric(10, 2), nullable=False, comment="Line total")

    # Constraints
    __table_args__ = (
        CheckConstraint("quantity > 0", name="check_order_item_quantity"),
        CheckConstraint("unit_price > 0", name="check_order_item_price"),
        Index("idx_order_item_order", "order_id"),
        Index("idx_order_item_product", "product_id"),
        {"comment": "Order items table"}
    )

    # Relationships
    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")

    def __repr__(self):
        return f"<OrderItem(id={self.id}, order_id={self.order_id}, product_id={self.product_id})>"
```

## Category Model

```python
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Category(Base):
    """
    Product category model
    """
    __tablename__ = "categories"

    # Basic info
    name = Column(String(50), nullable=False, index=True, comment="Category name")
    description = Column(String(255), nullable=True, comment="Category description")

    # Hierarchy
    parent_id = Column(Integer, ForeignKey("categories.id"), nullable=True, comment="Parent category ID")
    level = Column(Integer, default=1, nullable=False, comment="Level: 1=top-level, 2=subcategory")
    sort_order = Column(Integer, default=0, nullable=False, comment="Sort order")

    # Status
    status = Column(String(20), default="active", nullable=False, comment="Status: active/inactive")

    # Icon
    icon = Column(String(255), nullable=True, comment="Category icon URL")

    # Relationships
    parent = relationship("Category", remote_side=["Category.id"], backref="children")
    products = relationship("Product", back_populates="category")

    def __repr__(self):
        return f"<Category(id={self.id}, name={self.name})>"
```

## Soft Delete Support

Add soft delete query methods:

```python
from sqlalchemy.orm import Query
from sqlalchemy import or_

class SoftDeleteMixin:
    """
    Soft delete mixin
    """
    def delete(self):
        """
        Soft delete current object
        """
        self.deleted_at = func.now()

    @classmethod
    def query_active(cls, session):
        """
        Query non-deleted records
        """
        return session.query(cls).filter(cls.deleted_at.is_(None))
```

## Model Usage Examples

### Create User

```python
from app.database import SessionLocal
from app.models.user import User
from app.utils.password import hash_password

db = SessionLocal()

# Create user
user = User(
    username="john_doe",
    email="john@example.com",
    hashed_password=hash_password("Password123")
)

db.add(user)
db.commit()
db.refresh(user)

print(f"User created, ID: {user.id}")
db.close()
```

### Query User

```python
from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()

# Query single user
user = db.query(User).filter(User.username == "john_doe").first()

# Paginated query
users = db.query(User).filter(User.status == "active").offset(0).limit(10).all()

# Soft delete query (only non-deleted)
users = User.query_active(db).all()

db.close()
```

### Update User

```python
from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()

user = db.query(User).filter(User.id == 1).first()
if user:
    user.avatar = "https://example.com/new-avatar.png"
    user.mobile = "13900139000"
    db.commit()

db.close()
```

### Delete User (Soft Delete)

```python
from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()

user = db.query(User).filter(User.id == 1).first()
if user:
    user.deleted_at = func.now()  # Soft delete
    # db.delete(user)  # Hard delete
    db.commit()

db.close()
```

## Model Registration

Register all models in `app/models/__init__.py`:

```python
from app.models.user import User
from app.models.product import Product
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.category import Category

__all__ = [
    "User",
    "Product",
    "Order",
    "OrderItem",
    "Category",
]
```
