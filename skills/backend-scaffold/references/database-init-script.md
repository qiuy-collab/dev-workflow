# Database Initialization Script

## PostgreSQL DDL

### Users Table

```sql
-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- Seed data
INSERT INTO users (username, email, password_hash, avatar, status) VALUES
('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyWw9xS.2H7m', 'https://example.com/admin.png', 'active'),
('testuser', 'test@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyWw9xS.2H7m', NULL, 'active');
```

### Products Table

```sql
-- Create products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER DEFAULT 0,
    image VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_price ON products(price);

-- Seed data
INSERT INTO products (name, description, price, stock, status) VALUES
('Laptop Pro', 'High performance laptop', 1299.99, 50, 'active'),
('Smartphone', 'Latest smartphone', 699.99, 100, 'active'),
('Headphones', 'Noise cancelling headphones', 199.99, 200, 'active'),
('Mouse', 'Wireless mouse', 29.99, 500, 'active'),
('Keyboard', 'Mechanical keyboard', 79.99, 150, 'active');
```

### Orders Table

```sql
-- Create orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_no VARCHAR(50) UNIQUE NOT NULL,
    user_id INTEGER NOT NULL,
    receiver_name VARCHAR(100) NOT NULL,
    receiver_mobile VARCHAR(20) NOT NULL,
    receiver_address VARCHAR(255) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_orders_order_no ON orders(order_no);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);

-- Seed data
INSERT INTO orders (order_no, user_id, receiver_name, receiver_mobile, receiver_address, total_amount, status) VALUES
('ORD20240101001', 1, 'Zhang San', '13800138000', 'Chaoyang District, Beijing', 1299.99, 'completed'),
('ORD20240101002', 2, 'Li Si', '13900139000', 'Pudong, Shanghai', 699.99, 'pending');
```

### Order Items Table

```sql
-- Create order_items table
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Seed data
INSERT INTO order_items (order_id, product_id, quantity, price, subtotal) VALUES
(1, 1, 1, 1299.99, 1299.99),
(2, 2, 1, 699.99, 699.99);
```

### Roles Table (Optional)

```sql
-- Create roles table
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user_roles join table
CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    UNIQUE(user_id, role_id)
);

-- Seed roles
INSERT INTO roles (name, description) VALUES
('admin', 'Administrator'),
('user', 'Regular User');

-- Assign roles
INSERT INTO user_roles (user_id, role_id) VALUES
(1, 1),  -- admin user has admin role
(2, 2);  -- testuser has user role
```

## MySQL DDL

### Users Table

```sql
-- Create users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed data
INSERT INTO users (username, email, password_hash, avatar, status) VALUES
('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyWw9xS.2H7m', 'https://example.com/admin.png', 'active'),
('testuser', 'test@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyWw9xS.2H7m', NULL, 'active');
```

### Products Table

```sql
-- Create products table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INT DEFAULT 0,
    image VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_status (status),
    INDEX idx_price (price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed data
INSERT INTO products (name, description, price, stock, status) VALUES
('Laptop Pro', 'High performance laptop', 1299.99, 50, 'active'),
('Smartphone', 'Latest smartphone', 699.99, 100, 'active'),
('Headphones', 'Noise cancelling headphones', 199.99, 200, 'active');
```

### Orders Table

```sql
-- Create orders table
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(50) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    receiver_name VARCHAR(100) NOT NULL,
    receiver_mobile VARCHAR(20) NOT NULL,
    receiver_address VARCHAR(255) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_no (order_no),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed data
INSERT INTO orders (order_no, user_id, receiver_name, receiver_mobile, receiver_address, total_amount, status) VALUES
('ORD20240101001', 1, 'Zhang San', '13800138000', 'Chaoyang District, Beijing', 1299.99, 'completed');
```

## MongoDB Initialization

### Users Collection

```javascript
// Create users
db.users.insertMany([
    {
        username: "admin",
        email: "admin@example.com",
        password_hash: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyWw9xS.2H7m",
        avatar: "https://example.com/admin.png",
        status: "active",
        created_at: new Date(),
        updated_at: new Date()
    },
    {
        username: "testuser",
        email: "test@example.com",
        password_hash: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyWw9xS.2H7m",
        avatar: null,
        status: "active",
        created_at: new Date(),
        updated_at: new Date()
    }
]);

// Indexes
db.users.createIndex({ username: 1 }, { unique: true });
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ status: 1 });
```

### Products Collection

```javascript
// Create products
db.products.insertMany([
    {
        name: "Laptop Pro",
        description: "High performance laptop",
        price: 1299.99,
        stock: 50,
        image: null,
        status: "active",
        created_at: new Date(),
        updated_at: new Date()
    },
    {
        name: "Smartphone",
        description: "Latest smartphone",
        price: 699.99,
        stock: 100,
        image: null,
        status: "active",
        created_at: new Date(),
        updated_at: new Date()
    }
]);

// Indexes
db.products.createIndex({ name: 1 });
db.products.createIndex({ status: 1 });
db.products.createIndex({ price: 1 });
```

### Orders Collection

```javascript
// Create orders
db.orders.insertMany([
    {
        order_no: "ORD20240101001",
        user_id: 1,
        receiver_name: "Zhang San",
        receiver_mobile: "13800138000",
        receiver_address: "Chaoyang District, Beijing",
        total_amount: 1299.99,
        status: "completed",
        items: [
            {
                product_id: 1,
                quantity: 1,
                price: 1299.99,
                subtotal: 1299.99
            }
        ],
        created_at: new Date(),
        updated_at: new Date()
    }
]);

// Indexes
db.orders.createIndex({ order_no: 1 }, { unique: true });
db.orders.createIndex({ user_id: 1 });
db.orders.createIndex({ status: 1 });
```

## Python SQLAlchemy Init Script

```python
# database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

SQLALCHEMY_DATABASE_URL = "postgresql://postgres:password@localhost:5432/myapp"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# models.py
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    email = Column(String(100), unique=True, index=True)
    password_hash = Column(String(255))
    avatar = Column(String(255))
    status = Column(String(20), default="active")

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    description = Column(String(500))
    price = Column(Float)
    stock = Column(Integer, default=0)

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    order_no = Column(String(50), unique=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    total_amount = Column(Float)
    status = Column(String(20), default="pending")

    items = relationship("OrderItem", back_populates="order")

# init_db.py
from database import engine, Base
from models import User, Product, Order

def init_db():
    """Create all tables"""
    Base.metadata.create_all(bind=engine)
    print("Database tables created")

if __name__ == "__main__":
    init_db()
```

## Run Initialization

### PostgreSQL

```bash
# Method 1: psql
psql -U postgres -d myapp -f schema.sql

# Method 2: Python
python init_db.py
```

### MySQL

```bash
# Use mysql command
mysql -u root -p myapp < schema.sql
```

### MongoDB

```bash
# Use mongo command
mongo myapp < schema.js

# Or mongosh
mongosh myapp --eval "load('schema.js')"
```

## Verify Initialization

### PostgreSQL

```bash
# List tables
psql -U postgres -d myapp -c "\\dt"

# Describe table
psql -U postgres -d myapp -c "\\d users"

# Query data
psql -U postgres -d myapp -c "SELECT * FROM users;"
```

### MySQL

```bash
# List tables
mysql -u root -p myapp -e "SHOW TABLES;"

# Describe table
mysql -u root -p myapp -e "DESCRIBE users;"

# Query data
mysql -u root -p myapp -e "SELECT * FROM users;"
```

### MongoDB

```bash
# List collections
mongo myapp --eval "db.getCollectionNames()"

# Query data
mongo myapp --eval "db.users.find().pretty()"
```

## Common Issues

### Permission Denied

```sql
-- PostgreSQL: grant privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO postgres;

-- MySQL: grant privileges
GRANT ALL PRIVILEGES ON myapp.* TO 'user'@'localhost';
FLUSH PRIVILEGES;
```

### Table Already Exists

```sql
-- Drop tables and recreate
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;
```

### Foreign Key Constraint Error

```sql
-- Drop referencing tables first
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
-- Then recreate
```
