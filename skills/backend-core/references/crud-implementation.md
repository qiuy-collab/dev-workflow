# CRUD Implementation Guide

## Python + FastAPI CRUD Implementation

### 1. Define Pydantic Schemas

**app/schemas/user.py**
```python
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)

class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    avatar: Optional[str] = None
    status: Optional[str] = None

class UserResponse(UserBase):
    id: int
    avatar: Optional[str] = None
    status: str = "active"
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
```

**app/schemas/product.py**
```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from decimal import Decimal

class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    price: Decimal = Field(..., gt=0)
    stock: int = Field(..., ge=0)

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    price: Optional[Decimal] = Field(None, gt=0)
    stock: Optional[int] = Field(None, ge=0)
    status: Optional[str] = None

class ProductResponse(ProductBase):
    id: int
    image: Optional[str] = None
    status: str = "active"
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
```

### 2. Implement CRUD Routes

**app/routers/users.py**
```python
from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.models.user import User
from app.utils.security import get_password_hash

router = APIRouter(prefix="/api/v1/users", tags=["users"])

# Create
@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """Create new user"""
    # Check username exists
    existing_user = db.query(User).filter(User.username == user.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already exists"
        )

    # Check email exists
    existing_email = db.query(User).filter(User.email == user.email).first()
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already exists"
        )

    # Create new user
    db_user = User(
        username=user.username,
        email=user.email,
        password_hash=get_password_hash(user.password)
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user

# Read list (with pagination)
@router.get("/", response_model=dict)
def get_users(
    page: int = 1,
    limit: int = 10,
    status: str = None,
    keyword: str = None,
    db: Session = Depends(get_db)
):
    """Get user list"""
    query = db.query(User)

    # Filters
    if status:
        query = query.filter(User.status == status)
    if keyword:
        query = query.filter(
            (User.username.ilike(f"%{keyword}%")) |
            (User.email.ilike(f"%{keyword}%"))
        )

    total = query.count()

    # Pagination
    offset = (page - 1) * limit
    users = query.offset(offset).limit(limit).all()

    return {
        "code": 200,
        "message": "success",
        "data": {
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit,
            "users": users
        }
    }

# Read single
@router.get("/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get user detail"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user

# Update
@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    user_update: UserUpdate,
    db: Session = Depends(get_db)
):
    """Update user info"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    update_data = user_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)

    db.commit()
    db.refresh(user)

    return user

# Delete
@router.delete("/{user_id}", status_code=status.HTTP_200_OK)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    """Delete user"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    db.delete(user)
    db.commit()

    return {
        "code": 200,
        "message": "deleted",
        "data": None
    }
```

**app/routers/products.py**
```python
from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.product import ProductCreate, ProductUpdate, ProductResponse
from app.models.product import Product

router = APIRouter(prefix="/api/v1/products", tags=["products"])

# Create
@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    product: ProductCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_admin)  # Admin required
):
    """Create new product (admin)"""
    db_product = Product(**product.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)

    return db_product

# Read list (pagination/filter/sort)
@router.get("/", response_model=dict)
def get_products(
    page: int = 1,
    limit: int = 10,
    status: str = None,
    keyword: str = None,
    min_price: float = None,
    max_price: float = None,
    sort_by: str = "created_at",
    order: str = "desc",
    db: Session = Depends(get_db)
):
    """Get product list"""
    query = db.query(Product)

    # Filters
    if status:
        query = query.filter(Product.status == status)
    if keyword:
        query = query.filter(Product.name.ilike(f"%{keyword}%"))
    if min_price:
        query = query.filter(Product.price >= min_price)
    if max_price:
        query = query.filter(Product.price <= max_price)

    total = query.count()

    # Sorting
    sort_column = getattr(Product, sort_by, Product.created_at)
    if order.lower() == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())

    # Pagination
    offset = (page - 1) * limit
    products = query.offset(offset).limit(limit).all()

    return {
        "code": 200,
        "message": "success",
        "data": {
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit,
            "products": products
        }
    }

# Read single
@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """Get product detail"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    return product

# Update
@router.put("/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: int,
    product_update: ProductUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_admin)  # Admin required
):
    """Update product info (admin)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    update_data = product_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)

    db.commit()
    db.refresh(product)

    return product

# Delete
@router.delete("/{product_id}", status_code=status.HTTP_200_OK)
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_admin)  # Admin required
):
    """Delete product (admin)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    db.delete(product)
    db.commit()

    return {
        "code": 200,
        "message": "deleted",
        "data": None
    }
```

### 3. Register Routes

**app/main.py**
```python
from fastapi import FastAPI
from app.routers import users, products

app = FastAPI()

# Register routes
app.include_router(users.router)
app.include_router(products.router)
```

## Java + Spring Boot CRUD Implementation

### 1. Define Entity

**User.java**
```java
import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 50)
    private String username;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    private String avatar;

    @Column(nullable = false, length = 20)
    private String status = "active";

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt;

    // Getters and Setters
    // ...
}
```

**Product.java**
```java
import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "products")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    private String description;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(nullable = false)
    private Integer stock = 0;

    private String image;

    @Column(nullable = false, length = 20)
    private String status = "active";

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt;

    // Getters and Setters
    // ...
}
```

### 2. Define DTOs

**UserCreate.java**
```java
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

public class UserCreate {
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username length must be 3-50")
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password length must be at least 6")
    private String password;

    // Getters and Setters
    // ...
}
```

**UserUpdate.java**
```java
import javax.validation.constraints.Email;
import javax.validation.constraints.Size;

public class UserUpdate {
    @Size(min = 3, max = 50, message = "Username length must be 3-50")
    private String username;

    @Email(message = "Invalid email format")
    private String email;

    private String avatar;

    private String status;

    // Getters and Setters
    // ...
}
```

**UserResponse.java**
```java
import java.time.LocalDateTime;

public class UserResponse {
    private Long id;
    private String username;
    private String email;
    private String avatar;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Getters and Setters
    // ...
}
```

### 3. Define Repository

**UserRepository.java**
```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
}
```

**ProductRepository.java**
```java
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    Page<Product> findByStatus(String status, Pageable pageable);
}
```

### 4. Define Service

**UserService.java**
```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public UserResponse createUser(UserCreate userCreate) {
        // Check username exists
        if (userRepository.existsByUsername(userCreate.getUsername())) {
            throw new BusinessException("Username already exists");
        }

        // Check email exists
        if (userRepository.existsByEmail(userCreate.getEmail())) {
            throw new BusinessException("Email already exists");
        }

        // Create user
        User user = new User();
        user.setUsername(userCreate.getUsername());
        user.setEmail(userCreate.getEmail());
        user.setPasswordHash(passwordEncoder.encode(userCreate.getPassword()));
        user.setStatus("active");

        user = userRepository.save(user);

        return convertToResponse(user);
    }

    public Page<UserResponse> getUsers(int page, int limit) {
        Pageable pageable = PageRequest.of(page - 1, limit);
        Page<User> users = userRepository.findAll(pageable);
        return users.map(this::convertToResponse);
    }

    public UserResponse getUser(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new BusinessException("User not found"));
        return convertToResponse(user);
    }

    @Transactional
    public UserResponse updateUser(Long id, UserUpdate userUpdate) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new BusinessException("User not found"));

        // Update fields
        if (userUpdate.getUsername() != null) {
            user.setUsername(userUpdate.getUsername());
        }
        if (userUpdate.getEmail() != null) {
            user.setEmail(userUpdate.getEmail());
        }
        if (userUpdate.getAvatar() != null) {
            user.setAvatar(userUpdate.getAvatar());
        }
        if (userUpdate.getStatus() != null) {
            user.setStatus(userUpdate.getStatus());
        }

        user.setUpdatedAt(LocalDateTime.now());
        user = userRepository.save(user);

        return convertToResponse(user);
    }

    @Transactional
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new BusinessException("User not found"));
        userRepository.delete(user);
    }

    private UserResponse convertToResponse(User user) {
        UserResponse response = new UserResponse();
        response.setId(user.getId());
        response.setUsername(user.getUsername());
        response.setEmail(user.getEmail());
        response.setAvatar(user.getAvatar());
        response.setStatus(user.getStatus());
        response.setCreatedAt(user.getCreatedAt());
        response.setUpdatedAt(user.getUpdatedAt());
        return response;
    }
}
```

### 5. Define Controller

**UserController.java**
```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import javax.validation.Valid;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    @Autowired
    private UserService userService;

    // Create
    @PostMapping
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody UserCreate userCreate) {
        UserResponse userResponse = userService.createUser(userCreate);
        return ResponseEntity.status(HttpStatus.CREATED).body(userResponse);
    }

    // Read List
    @GetMapping
    public ResponseEntity<Page<UserResponse>> getUsers(
        @RequestParam(defaultValue = "1") int page,
        @RequestParam(defaultValue = "10") int limit
    ) {
        Page<UserResponse> users = userService.getUsers(page, limit);
        return ResponseEntity.ok(users);
    }

    // Read Single
    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(@PathVariable Long id) {
        UserResponse userResponse = userService.getUser(id);
        return ResponseEntity.ok(userResponse);
    }

    // Update
    @PutMapping("/{id}")
    public ResponseEntity<UserResponse> updateUser(
        @PathVariable Long id,
        @Valid @RequestBody UserUpdate userUpdate
    ) {
        UserResponse userResponse = userService.updateUser(id, userUpdate);
        return ResponseEntity.ok(userResponse);
    }

    // Delete
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.ok().build();
    }
}
```

## Node.js + Express CRUD Implementation

### 1. Define Mongoose Schemas

**models/User.js**
```javascript
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    minlength: 3,
    maxlength: 50
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  passwordHash: {
    type: String,
    required: true
  },
  avatar: {
    type: String,
    default: null
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'banned'],
    default: 'active'
  }
}, {
  timestamps: true
});

userSchema.pre('save', async function(next) {
  if (!this.isModified('passwordHash')) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 10);
  next();
});

module.exports = mongoose.model('User', userSchema);
```

**models/Product.js**
```javascript
const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  description: {
    type: String,
    default: null
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  stock: {
    type: Number,
    default: 0,
    min: 0
  },
  image: {
    type: String,
    default: null
  },
  status: {
    type: String,
    enum: ['active', 'inactive'],
    default: 'active'
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Product', productSchema);
```

### 2. Define Service

**services/userService.js**
```javascript
const User = require('../models/User');

class UserService {
  async createUser(userData) {
    // Check username exists
    const existingUsername = await User.findOne({ username: userData.username });
    if (existingUsername) {
      throw new Error('Username already exists');
    }

    // Check email exists
    const existingEmail = await User.findOne({ email: userData.email });
    if (existingEmail) {
      throw new Error('Email already exists');
    }

    // Create user
    const user = new User({
      username: userData.username,
      email: userData.email,
      passwordHash: userData.password
    });

    await user.save();
    return this.toResponse(user);
  }

  async getUsers(page = 1, limit = 10, filters = {}) {
    const query = User.find(filters);

    // Filters
    if (filters.status) {
      query.where('status').equals(filters.status);
    }
    if (filters.keyword) {
      query.or([
        { username: new RegExp(filters.keyword, 'i') },
        { email: new RegExp(filters.keyword, 'i') }
      ]);
    }

    const total = await User.countDocuments(filters);

    // Pagination
    const skip = (page - 1) * limit;
    const users = await query.skip(skip).limit(limit).sort({ createdAt: -1 });

    return {
      total,
      page,
      limit,
      pages: Math.ceil(total / limit),
      users: users.map(user => this.toResponse(user))
    };
  }

  async getUser(id) {
    const user = await User.findById(id);
    if (!user) {
      throw new Error('User not found');
    }
    return this.toResponse(user);
  }

  async updateUser(id, updateData) {
    const user = await User.findById(id);
    if (!user) {
      throw new Error('User not found');
    }

    // Update fields
    if (updateData.username !== undefined) user.username = updateData.username;
    if (updateData.email !== undefined) user.email = updateData.email;
    if (updateData.avatar !== undefined) user.avatar = updateData.avatar;
    if (updateData.status !== undefined) user.status = updateData.status;

    await user.save();
    return this.toResponse(user);
  }

  async deleteUser(id) {
    const user = await User.findById(id);
    if (!user) {
      throw new Error('User not found');
    }

    await User.deleteOne({ _id: id });
  }

  toResponse(user) {
    return {
      id: user._id,
      username: user.username,
      email: user.email,
      avatar: user.avatar,
      status: user.status,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };
  }
}

module.exports = new UserService();
```

### 3. Define Router

**routes/users.js**
```javascript
const express = require('express');
const router = express.Router();
const userService = require('../services/userService');
const { authenticate } = require('../middleware/auth');

// Create
router.post('/', async (req, res) => {
  try {
    const user = await userService.createUser(req.body);
    res.status(201).json({
      code: 201,
      message: 'created',
      data: user
    });
  } catch (error) {
    res.status(400).json({
      code: 400,
      message: error.message
    });
  }
});

// Read List
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 10, status, keyword } = req.query;
    const filters = { status, keyword };
    const result = await userService.getUsers(
      parseInt(page),
      parseInt(limit),
      filters
    );
    res.json({
      code: 200,
      message: 'success',
      data: result
    });
  } catch (error) {
    res.status(500).json({
      code: 500,
      message: error.message
    });
  }
});

// Read Single
router.get('/:id', async (req, res) => {
  try {
    const user = await userService.getUser(req.params.id);
    res.json({
      code: 200,
      message: 'success',
      data: user
    });
  } catch (error) {
    res.status(404).json({
      code: 404,
      message: error.message
    });
  }
});

// Update
router.put('/:id', authenticate, async (req, res) => {
  try {
    const user = await userService.updateUser(req.params.id, req.body);
    res.json({
      code: 200,
      message: 'updated',
      data: user
    });
  } catch (error) {
    res.status(404).json({
      code: 404,
      message: error.message
    });
  }
});

// Delete
router.delete('/:id', authenticate, async (req, res) => {
  try {
    await userService.deleteUser(req.params.id);
    res.json({
      code: 200,
      message: 'deleted',
      data: null
    });
  } catch (error) {
    res.status(404).json({
      code: 404,
      message: error.message
    });
  }
});

module.exports = router;
```

### 4. Register Routes

**app.js**
```javascript
const express = require('express');
const userRoutes = require('./routes/users');
const productRoutes = require('./routes/products');

const app = express();

// Middleware
app.use(express.json());

// Routes
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/products', productRoutes);

module.exports = app;
```

## CRUD Test Checklist

### Create Tests
- [ ] Successful create (all required fields)
- [ ] Duplicate username returns 400
- [ ] Duplicate email returns 400
- [ ] Missing params return 400
- [ ] Invalid param format returns 400

### Read Tests
- [ ] Get existing resource
- [ ] Get non-existent resource returns 404
- [ ] List query (pagination works)
- [ ] List query (total pages correct)

### Update Tests
- [ ] Successful update
- [ ] Update non-existent resource returns 404
- [ ] Validation returns 400

### Delete Tests
- [ ] Successful delete
- [ ] Delete non-existent resource returns 404
- [ ] Cascade delete related data
