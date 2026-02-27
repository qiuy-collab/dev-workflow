# Database DDL Template

## Table of Contents
- [PostgreSQL DDL](#postgresql-ddl)
- [MySQL DDL](#mysql-ddl)
- [Index Creation](#index-creation)
- [Constraint Definitions](#constraint-definitions)

## PostgreSQL DDL

### Users Table (users)

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    mobile VARCHAR(20) UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    avatar VARCHAR(255),
    gender VARCHAR(10) CHECK (gender IS NULL OR gender IN ('male', 'female', 'secret')),
    bio VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'deleted')),
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Comments
COMMENT ON TABLE users IS 'Users table';
COMMENT ON COLUMN users.id IS 'Primary key ID';
COMMENT ON COLUMN users.username IS 'Username';
COMMENT ON COLUMN users.email IS 'Email';
COMMENT ON COLUMN users.mobile IS 'Mobile';
COMMENT ON COLUMN users.hashed_password IS 'Password hash';
COMMENT ON COLUMN users.avatar IS 'Avatar URL';
COMMENT ON COLUMN users.gender IS 'Gender: male/female/secret';
COMMENT ON COLUMN users.bio IS 'Bio';
COMMENT ON COLUMN users.status IS 'Status: active/inactive/deleted';
COMMENT ON COLUMN users.is_admin IS 'Is admin';
COMMENT ON COLUMN users.created_at IS 'Created time';
COMMENT ON COLUMN users.updated_at IS 'Updated time';
COMMENT ON COLUMN users.deleted_at IS 'Deleted time (soft delete)';
```

### Products Table (products)

```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price > 0),
    original_price NUMERIC(10,2),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'out_of_stock')),
    images VARCHAR(1000),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Comments
COMMENT ON TABLE products IS 'Products table';
COMMENT ON COLUMN products.name IS 'Product name';
COMMENT ON COLUMN products.description IS 'Product description';
COMMENT ON COLUMN products.price IS 'Product price';
COMMENT ON COLUMN products.original_price IS 'Original price';
COMMENT ON COLUMN products.stock IS 'Stock quantity';
COMMENT ON COLUMN products.category_id IS 'Category ID';
COMMENT ON COLUMN products.status IS 'Status: active/inactive/out_of_stock';
COMMENT ON COLUMN products.images IS 'Product image URLs, comma-separated';
```

### Categories Table (categories)

```sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    parent_id INTEGER,
    level INTEGER NOT NULL DEFAULT 1,
    sort_order INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    icon VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Self-referencing FK
ALTER TABLE categories ADD CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_id) REFERENCES categories(id);

-- Comments
COMMENT ON TABLE categories IS 'Product categories table';
COMMENT ON COLUMN categories.name IS 'Category name';
COMMENT ON COLUMN categories.description IS 'Category description';
COMMENT ON COLUMN categories.parent_id IS 'Parent category ID';
COMMENT ON COLUMN categories.level IS 'Level: 1=top-level, 2=subcategory';
COMMENT ON COLUMN categories.sort_order IS 'Sort order';
COMMENT ON COLUMN categories.status IS 'Status: active/inactive';
COMMENT ON COLUMN categories.icon IS 'Category icon URL';
```

### Orders Table (orders)

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_no VARCHAR(50) NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    discount_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    actual_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    receiver_name VARCHAR(50) NOT NULL,
    receiver_mobile VARCHAR(20) NOT NULL,
    receiver_address VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'shipped', 'completed', 'cancelled')),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    payment_method VARCHAR(20),
    payment_time TIMESTAMP,
    remark VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Foreign key
ALTER TABLE orders ADD CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Comments
COMMENT ON TABLE orders IS 'Orders table';
COMMENT ON COLUMN orders.order_no IS 'Order number';
COMMENT ON COLUMN orders.user_id IS 'User ID';
COMMENT ON COLUMN orders.total_amount IS 'Order total amount';
COMMENT ON COLUMN orders.discount_amount IS 'Discount amount';
COMMENT ON COLUMN orders.actual_amount IS 'Paid amount';
COMMENT ON COLUMN orders.receiver_name IS 'Receiver name';
COMMENT ON COLUMN orders.receiver_mobile IS 'Receiver mobile';
COMMENT ON COLUMN orders.receiver_address IS 'Receiver address';
COMMENT ON COLUMN orders.status IS 'Status: pending/paid/shipped/completed/cancelled';
COMMENT ON COLUMN orders.payment_status IS 'Payment status: unpaid/paid/refunded';
COMMENT ON COLUMN orders.payment_method IS 'Payment method: wechat/alipay/bank_card';
COMMENT ON COLUMN orders.payment_time IS 'Payment time';
COMMENT ON COLUMN orders.remark IS 'Order remark';
```

### Order Items Table (order_items)

```sql
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    product_image VARCHAR(255),
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    total_price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Foreign keys
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;

ALTER TABLE order_items ADD CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT;

-- Comments
COMMENT ON TABLE order_items IS 'Order items table';
COMMENT ON COLUMN order_items.order_id IS 'Order ID';
COMMENT ON COLUMN order_items.product_id IS 'Product ID';
COMMENT ON COLUMN order_items.product_name IS 'Product name';
COMMENT ON COLUMN order_items.product_image IS 'Product image';
COMMENT ON COLUMN order_items.quantity IS 'Quantity';
COMMENT ON COLUMN order_items.unit_price IS 'Unit price';
COMMENT ON COLUMN order_items.total_price IS 'Line total';
```

## MySQL DDL

### Users Table (users)

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    mobile VARCHAR(20) UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    avatar VARCHAR(255),
    gender VARCHAR(10) CHECK (gender IS NULL OR gender IN ('male', 'female', 'secret')),
    bio VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_mobile ON users(mobile);
```

### Products Table (products)

```sql
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    stock INT NOT NULL DEFAULT 0,
    category_id INT,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    images VARCHAR(1000),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
```

### Orders Table (orders)

```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(50) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    actual_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    receiver_name VARCHAR(50) NOT NULL,
    receiver_mobile VARCHAR(20) NOT NULL,
    receiver_address VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    payment_status VARCHAR(20) NOT NULL DEFAULT 'unpaid',
    payment_method VARCHAR(20),
    payment_time TIMESTAMP NULL,
    remark VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX idx_orders_order_no ON orders(order_no);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
```

### Order Items Table (order_items)

```sql
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    product_image VARCHAR(255),
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
```

## Index Creation

### PostgreSQL Indexes

```sql
-- Users table indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_mobile ON users(mobile);
CREATE INDEX idx_users_status ON users(status);

-- Products table indexes
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_price ON products(price);

-- Composite index
CREATE INDEX idx_products_category_status ON products(category_id, status);

-- Orders table indexes
CREATE INDEX idx_orders_order_no ON orders(order_no);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Order items table indexes
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
```

### MySQL Indexes

```sql
-- Users table indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_mobile ON users(mobile);
CREATE INDEX idx_users_status ON users(status);

-- Products table indexes
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_price ON products(price);

-- Composite index
CREATE INDEX idx_products_category_status ON products(category_id, status);

-- Orders table indexes
CREATE INDEX idx_orders_order_no ON orders(order_no);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Order items table indexes
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
```

## Constraint Definitions

### Add Foreign Key Constraints

```sql
-- PostgreSQL
ALTER TABLE products ADD CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;

ALTER TABLE orders ADD CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE order_items ADD CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;

ALTER TABLE order_items ADD CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT;
```

### Add Check Constraints

```sql
-- PostgreSQL
ALTER TABLE products ADD CONSTRAINT check_product_price CHECK (price > 0);
ALTER TABLE products ADD CONSTRAINT check_product_stock CHECK (stock >= 0);

ALTER TABLE orders ADD CONSTRAINT check_order_total CHECK (total_amount >= 0);
```

## Data Initialization

### Insert Test Data

```sql
-- Insert admin user
INSERT INTO users (username, email, hashed_password, is_admin, status) VALUES
('admin', 'admin@example.com', '$2b$12$hashed_password_here', TRUE, 'active');

-- Insert test users
INSERT INTO users (username, email, hashed_password, mobile, status) VALUES
('john_doe', 'john@example.com', '$2b$12$hashed_password_here', '13800138000', 'active'),
('jane_smith', 'jane@example.com', '$2b$12$hashed_password_here', '13900139000', 'active');

-- Insert categories
INSERT INTO categories (name, description, level, sort_order, status) VALUES
('Electronics', 'Electronic devices', 1, 1, 'active'),
('Apparel', 'Clothing and shoes', 1, 2, 'active'),
('Food', 'Food and beverages', 1, 3, 'active');

-- Insert products
INSERT INTO products (name, description, price, stock, category_id, status) VALUES
('iPhone 15 Pro', 'Apple latest phone', 8999.00, 100, 1, 'active'),
('MacBook Pro', 'Apple laptop', 14999.00, 50, 1, 'active'),
('T-shirt', 'Cotton T-shirt', 99.00, 500, 2, 'active'),
('Jeans', 'Jeans', 199.00, 300, 2, 'active'),
('Chocolate', 'Imported chocolate', 29.90, 1000, 3, 'active');
```

## Database Cleanup

### Truncate Tables (Keep Schema)

```sql
-- Truncate all tables
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE products CASCADE;
TRUNCATE TABLE categories CASCADE;
TRUNCATE TABLE users CASCADE;
```

### Reset Auto Increment (MySQL)

```sql
-- Reset auto increment
ALTER TABLE users AUTO_INCREMENT = 1;
ALTER TABLE categories AUTO_INCREMENT = 1;
ALTER TABLE products AUTO_INCREMENT = 1;
ALTER TABLE orders AUTO_INCREMENT = 1;
ALTER TABLE order_items AUTO_INCREMENT = 1;
```

### Reset Auto Increment (PostgreSQL)

```sql
-- Reset sequences
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
TRUNCATE TABLE categories RESTART IDENTITY CASCADE;
TRUNCATE TABLE products RESTART IDENTITY CASCADE;
TRUNCATE TABLE orders RESTART IDENTITY CASCADE;
TRUNCATE TABLE order_items RESTART IDENTITY CASCADE;
```
