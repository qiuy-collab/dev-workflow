# Authentication and Authorization Guide

## Core Concepts

### Authentication
- Identity verification (who you are)
- Common methods: username/password, token, OAuth

### Authorization
- Permission verification (what you can do)
- Common method: role-based access control (RBAC)

## Python + FastAPI Auth Implementation

### 1. User Registration

**app/routers/auth.py**
```python
from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user import UserCreate, UserResponse
from app.models.user import User
from app.utils.security import get_password_hash, verify_password
from app.utils.jwt import create_access_token

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: UserCreate, db: Session = Depends(get_db)):
    """User registration"""
    # Check if username exists
    existing_user = db.query(User).filter(User.username == user.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already exists"
        )

    # Check if email exists
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
```

### 2. User Login

**app/routers/auth.py**
```python
from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

@router.post("/login", response_model=LoginResponse)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """User login"""
    # Find user
    user = db.query(User).filter(User.username == login_data.username).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )

    # Verify password
    if not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )

    # Generate token
    access_token = create_access_token(data={"sub": user.username})

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }
```

### 3. JWT Token Utilities

**app/utils/jwt.py**
```python
from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

SECRET_KEY = "your-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

security = HTTPBearer()

def create_access_token(data: dict, expires_delta: timedelta = None):
    """Create access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_token(token: str):
    """Decode token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        return username
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
```

### 4. Dependency Injection

**app/dependencies/auth.py**
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.utils.jwt import decode_token

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Get current user"""
    token = credentials.credentials
    username = decode_token(token)

    user = db.query(User).filter(User.username == username).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )

    return user

async def get_current_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current admin user"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions, admin required"
        )

    return current_user
```

### 5. Protect Routes

**app/routers/users.py**
```python
from app.dependencies.auth import get_current_user, get_current_admin

# Requires login
@router.get("/me")
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user info"""
    return current_user

# Requires admin
@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    """Delete user (admin)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(user)
    db.commit()

    return {"message": "Deleted"}
```

## Java + Spring Boot Auth Implementation

### 1. User Registration

**AuthController.java**
```java
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<UserResponse> register(@Valid @RequestBody UserCreate userCreate) {
        UserResponse userResponse = authService.register(userCreate);
        return ResponseEntity.status(HttpStatus.CREATED).body(userResponse);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest loginRequest) {
        LoginResponse loginResponse = authService.login(loginRequest);
        return ResponseEntity.ok(loginResponse);
    }
}
```

### 2. AuthService Implementation

**AuthService.java**
```java
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.security.Key;
import java.util.Date;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private Key key = Keys.secretKeyFor(SignatureAlgorithm.HS256);
    private long jwtExpirationMs = 1800000; // 30 minutes

    public UserResponse register(UserCreate userCreate) {
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
        user.setRole("user");

        user = userRepository.save(user);

        return convertToResponse(user);
    }

    public LoginResponse login(LoginRequest loginRequest) {
        // Find user
        User user = userRepository.findByUsername(loginRequest.getUsername())
            .orElseThrow(() -> new BusinessException("Invalid username or password"));

        // Verify password
        if (!passwordEncoder.matches(loginRequest.getPassword(), user.getPasswordHash())) {
            throw new BusinessException("Invalid username or password");
        }

        // Generate token
        String token = generateToken(user.getUsername());

        LoginResponse response = new LoginResponse();
        response.setAccessToken(token);
        response.setTokenType("Bearer");
        response.setUser(convertToResponse(user));

        return response;
    }

    private String generateToken(String username) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationMs);

        return Jwts.builder()
            .setSubject(username)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(key, SignatureAlgorithm.HS256)
            .compact();
    }

    private UserResponse convertToResponse(User user) {
        UserResponse response = new UserResponse();
        response.setId(user.getId());
        response.setUsername(user.getUsername());
        response.setEmail(user.getEmail());
        response.setRole(user.getRole());
        return response;
    }
}
```

### 3. JWT Validation Filter

**JwtAuthenticationFilter.java**
```java
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Collections;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        try {
            String jwt = getJwtFromRequest(request);

            if (jwt != null && tokenProvider.validateToken(jwt)) {
                String username = tokenProvider.getUsernameFromToken(jwt);

                UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                        username,
                        null,
                        Collections.emptyList()
                    );

                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication in security context", ex);
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
```

### 4. Authorization

**ProductController.java**
```java
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    // Requires login
    @GetMapping("/my-products")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<Product>> getMyProducts() {
        // ...
    }

    // Requires admin
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Product> createProduct(@RequestBody ProductCreate productCreate) {
        // ...
    }
}
```

## Node.js + Express Auth Implementation

### 1. User Registration

**routes/auth.js**
```javascript
const express = require('express');
const router = express.Router();
const authService = require('../services/authService');

router.post('/register', async (req, res) => {
  try {
    const user = await authService.register(req.body);
    res.status(201).json({
      code: 201,
      message: 'registered',
      data: user
    });
  } catch (error) {
    res.status(400).json({
      code: 400,
      message: error.message
    });
  }
});

router.post('/login', async (req, res) => {
  try {
    const result = await authService.login(req.body);
    res.json({
      code: 200,
      message: 'success',
      data: result
    });
  } catch (error) {
    res.status(401).json({
      code: 401,
      message: error.message
    });
  }
});

module.exports = router;
```

### 2. AuthService Implementation

**services/authService.js**
```javascript
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const jwtSecret = process.env.JWT_SECRET || 'your-secret-key';

class AuthService {
  async register(userData) {
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
      password: userData.password
    });

    await user.save();
    return this.toResponse(user);
  }

  async login(loginData) {
    // Find user
    const user = await User.findOne({ username: loginData.username });
    if (!user) {
      throw new Error('Invalid username or password');
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(loginData.password, user.passwordHash);
    if (!isValidPassword) {
      throw new Error('Invalid username or password');
    }

    // Generate token
    const token = jwt.sign(
      { userId: user._id, username: user.username },
      jwtSecret,
      { expiresIn: '30d' }
    );

    return {
      accessToken: token,
      tokenType: 'Bearer',
      user: this.toResponse(user)
    };
  }

  verifyToken(token) {
    try {
      const decoded = jwt.verify(token, jwtSecret);
      return decoded;
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  toResponse(user) {
    return {
      id: user._id,
      username: user.username,
      email: user.email,
      role: user.role
    };
  }
}

module.exports = new AuthService();
```

### 3. Auth Middleware

**middleware/auth.js**
```javascript
const authService = require('../services/authService');

const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        code: 401,
        message: 'Token not provided'
      });
    }

    const decoded = authService.verifyToken(token);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({
      code: 401,
      message: 'Invalid token'
    });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        code: 403,
        message: 'Insufficient permissions'
      });
    }
    next();
  };
};

module.exports = { authenticate, authorize };
```

### 4. Protect Routes

**routes/products.js**
```javascript
const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');

// Requires login
router.get('/my-products', authenticate, async (req, res) => {
  // ...
});

// Requires admin
router.post(
  '/',
  authenticate,
  authorize('admin'),
  async (req, res) => {
    // ...
  }
);

module.exports = router;
```

## Password Security

### bcrypt Hashing

**Python**
```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
```

**Java**
```java
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
String hashedPassword = encoder.encode("plain_password");
boolean matches = encoder.matches("plain_password", hashedPassword);
```

**Node.js**
```javascript
const bcrypt = require('bcryptjs');
const hashedPassword = await bcrypt.hash('plain_password', 10);
const matches = await bcrypt.compare('plain_password', hashedPassword);
```

## JWT Configuration

### Environment Variables
```bash
# Python
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Java
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION_MS=1800000

# Node.js
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION_DAYS=30
```

### Token Generation and Validation
```python
# Python
access_token = create_access_token(data={"sub": username})
decoded = decode_token(token)
```

```java
// Java
String token = Jwts.builder()
    .setSubject(username)
    .signWith(key, SignatureAlgorithm.HS256)
    .compact();
```

```javascript
// Node.js
const token = jwt.sign({ userId, username }, secret, { expiresIn: '30d' });
const decoded = jwt.verify(token, secret);
```

## Test Checklist
- [ ] User registration works
- [ ] Duplicate username returns 400
- [ ] Duplicate email returns 400
- [ ] Password hashed in storage
- [ ] User login works
- [ ] Wrong username returns 401
- [ ] Wrong password returns 401
- [ ] Token generation works
- [ ] Token validation works
- [ ] Token expired returns 401
- [ ] Invalid token returns 401
- [ ] Authorization works (403)
- [ ] Unauthenticated requests return 401
