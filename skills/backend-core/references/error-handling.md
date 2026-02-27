# Error Handling Implementation Guide

## Error Handling Principles

### 1. Validation
- Use framework validation features
- Provide clear error messages
- Avoid leaking sensitive information

### 2. Exception Handling
- Global exception handlers
- Record error logs
- Return unified error format

### 3. Status Code Conventions
- 400: invalid parameters
- 401: unauthorized
- 403: forbidden
- 404: not found
- 500: server error

## Python + FastAPI Error Handling

### 1. Validation

**Use Pydantic validation**
```python
from pydantic import BaseModel, Field, EmailStr, validator

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, description="Username")
    email: EmailStr
    password: str = Field(..., min_length=6, description="Password")
    age: int = Field(..., ge=18, le=100, description="Age")

    @validator('username')
    def username_alphanumeric(cls, v):
        if not v.isalnum():
            raise ValueError('Username can only contain letters and numbers')
        return v

    @validator('password')
    def password_complexity(cls, v):
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must include a number')
        if not any(c.isupper() for c in v):
            raise ValueError('Password must include an uppercase letter')
        return v
```

**Automatic validation error response**
```json
{
  "detail": [
    {
      "loc": ["body", "password"],
      "msg": "ensure this value has at least 6 characters",
      "type": "value_error.any_str.min_length",
      "ctx": {"limit_value": 6}
    }
  ]
}
```

### 2. Custom Exceptions

**app/exceptions.py**
```python
from typing import Optional

class AppException(Exception):
    """Base app exception"""

    def __init__(
        self,
        message: str,
        code: int = 400,
        detail: Optional[str] = None
    ):
        self.message = message
        self.code = code
        self.detail = detail
        super().__init__(message)

class BadRequestException(AppException):
    """400 Bad Request"""
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(message, 400, detail)

class UnauthorizedException(AppException):
    """401 Unauthorized"""
    def __init__(self, message: str = "unauthorized", detail: Optional[str] = None):
        super().__init__(message, 401, detail)

class ForbiddenException(AppException):
    """403 Forbidden"""
    def __init__(self, message: str = "forbidden", detail: Optional[str] = None):
        super().__init__(message, 403, detail)

class NotFoundException(AppException):
    """404 Not Found"""
    def __init__(self, message: str = "not found", detail: Optional[str] = None):
        super().__init__(message, 404, detail)

class ConflictException(AppException):
    """409 Conflict"""
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(message, 409, detail)

class InternalServerException(AppException):
    """500 Internal Server Error"""
    def __init__(self, message: str = "server error", detail: Optional[str] = None):
        super().__init__(message, 500, detail)
```

### 3. Global Exception Handlers

**app/exception_handlers.py**
```python
from fastapi import Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError
from app.exceptions import (
    AppException,
    BadRequestException,
    UnauthorizedException,
    ForbiddenException,
    NotFoundException,
    ConflictException,
    InternalServerException
)

async def app_exception_handler(request: Request, exc: AppException):
    """App exception handler"""

    return JSONResponse(
        status_code=exc.code,
        content={
            "code": exc.code,
            "message": exc.message,
            "detail": exc.detail
        }
    )

async def http_exception_handler(request: Request, exc):
    """HTTP exception handler"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": exc.status_code,
            "message": exc.detail,
            "detail": None
        }
    )

async def validation_exception_handler(request: Request, exc):
    """Validation exception handler"""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "code": 422,
            "message": "validation failed",
            "detail": exc.errors()
        }
    )

async def integrity_exception_handler(request: Request, exc: IntegrityError):
    """DB integrity exception handler"""
    error_message = str(exc.orig)

    if "duplicate key" in error_message:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={
                "code": 409,
                "message": "duplicate data",
                "detail": error_message
            }
        )

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "code": 500,
            "message": "database error",
            "detail": error_message
        }
    )

async def general_exception_handler(request: Request, exc):
    """General exception handler"""
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "code": 500,
            "message": "server error",
            "detail": str(exc)
        }
    )
```

### 4. Register Exception Handlers

**app/main.py**
```python
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import IntegrityError
from app.exception_handlers import (
    app_exception_handler,
    http_exception_handler,
    validation_exception_handler,
    integrity_exception_handler,
    general_exception_handler
)

app = FastAPI()

# Register handlers
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(Exception, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(IntegrityError, integrity_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)
```

### 5. Usage Example

**app/routers/users.py**
```python
from app.exceptions import NotFoundException, BadRequestException, ConflictException

@router.post("/")
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Check username exists
    if db.query(User).filter(User.username == user.username).first():
        raise ConflictException("Username already exists")

    # Check email exists
    if db.query(User).filter(User.email == user.email).first():
        raise ConflictException("Email already exists")

    # Create user
    try:
        db_user = User(**user.dict())
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        raise InternalServerException("Failed to create user", detail=str(e))

@router.get("/{user_id}")
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("User not found")
    return user
```

## Java + Spring Boot Error Handling

### 1. Validation

**DTO class**
```java
import javax.validation.constraints.*;

public class UserCreate {
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username length must be 3-50")
    @Pattern(regexp = "^[a-zA-Z0-9]+$", message = "Username must be alphanumeric")
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password length must be at least 6")
    @Pattern(regexp = "^(?=.*[0-9])(?=.*[A-Z]).*$", message = "Password must include a number and an uppercase letter")
    private String password;

    @NotNull(message = "Age is required")
    @Min(value = 18, message = "Age must be >= 18")
    @Max(value = 100, message = "Age must be <= 100")
    private Integer age;

    // Getters and Setters
    // ...
}
```

### 2. Custom Exceptions

**BusinessException.java**
```java
public class BusinessException extends RuntimeException {
    private int code;
    private String message;
    private String detail;

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
        this.message = message;
    }

    public BusinessException(String message) {
        this(400, message);
    }

    public BusinessException(int code, String message, String detail) {
        super(message);
        this.code = code;
        this.message = message;
        this.detail = detail;
    }

    // Getters
    public int getCode() { return code; }
    public String getMessage() { return message; }
    public String getDetail() { return detail; }
}
```

**Error constants**
```java
public class ErrorCodes {
    public static final int BAD_REQUEST = 400;
    public static final int UNAUTHORIZED = 401;
    public static final int FORBIDDEN = 403;
    public static final int NOT_FOUND = 404;
    public static final int CONFLICT = 409;
    public static final int INTERNAL_SERVER_ERROR = 500;
}
```

### 3. Unified Error Response

**ErrorResponse.java**
```java
public class ErrorResponse {
    private int code;
    private String message;
    private String detail;

    public ErrorResponse(int code, String message, String detail) {
        this.code = code;
        this.message = message;
        this.detail = detail;
    }

    // Getters and Setters
    // ...
}
```

### 4. Global Exception Handler

**GlobalExceptionHandler.java**
```java
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import javax.validation.ConstraintViolation;
import javax.validation.ConstraintViolationException;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // Business exception
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException ex) {
        ErrorResponse error = new ErrorResponse(
            ex.getCode(),
            ex.getMessage(),
            ex.getDetail()
        );
        return ResponseEntity.status(ex.getCode()).body(error);
    }

    // Validation exception
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(MethodArgumentNotValidException ex) {
        String detail = ex.getBindingResult().getFieldErrors().stream()
            .map(error -> error.getField() + ": " + error.getDefaultMessage())
            .collect(Collectors.joining(", "));

        ErrorResponse error = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            "validation failed",
            detail
        );
        return ResponseEntity.badRequest().body(error);
    }

    // Constraint violation exception
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolationException(ConstraintViolationException ex) {
        String detail = ex.getConstraintViolations().stream()
            .map(ConstraintViolation::getMessage)
            .collect(Collectors.joining(", "));

        ErrorResponse error = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            "validation failed",
            detail
        );
        return ResponseEntity.badRequest().body(error);
    }

    // Not found exception
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErrorResponse> handleNoResourceFoundException(NoResourceFoundException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(),
            "not found",
            ex.getMessage()
        );
        return ResponseEntity.notFound().build();
    }

    // General exception
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneralException(Exception ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            "server error",
            "Internal error, contact admin"
        );
        return ResponseEntity.internalServerError().body(error);
    }
}
```

### 5. Usage Example

**UserService.java**
```java
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public UserResponse createUser(UserCreate userCreate) {
        // Check username exists
        if (userRepository.existsByUsername(userCreate.getUsername())) {
            throw new BusinessException(
                ErrorCodes.CONFLICT,
                "Username already exists"
            );
        }

        // Check email exists
        if (userRepository.existsByEmail(userCreate.getEmail())) {
            throw new BusinessException(
                ErrorCodes.CONFLICT,
                "Email already exists"
            );
        }

        try {
            // Create user
            User user = new User();
            user.setUsername(userCreate.getUsername());
            user.setEmail(userCreate.getEmail());
            user.setPassword(passwordEncoder.encode(userCreate.getPassword()));

            user = userRepository.save(user);

            return convertToResponse(user);
        } catch (Exception e) {
            throw new BusinessException(
                ErrorCodes.INTERNAL_SERVER_ERROR,
                "Failed to create user",
                e.getMessage()
            );
        }
    }

    public UserResponse getUser(Long id) {
        return userRepository.findById(id)
            .map(this::convertToResponse)
            .orElseThrow(() -> new BusinessException(
                ErrorCodes.NOT_FOUND,
                "User not found"
            ));
    }
}
```

## Node.js + Express Error Handling

### 1. Validation

**Use Joi**
```javascript
const Joi = require('joi');

const userCreateSchema = Joi.object({
  username: Joi.string()
    .alphanum()
    .min(3)
    .max(50)
    .required()
    .messages({
      'string.base': 'Username must be a string',
      'string.alphanum': 'Username must be alphanumeric',
      'string.min': 'Username must be at least 3 characters',
      'string.max': 'Username must be at most 50 characters',
      'any.required': 'Username is required'
    }),

  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Invalid email format',
      'any.required': 'Email is required'
    }),

  password: Joi.string()
    .min(6)
    .pattern(/^(?=.*[0-9])(?=.*[A-Z]).*$/)
    .required()
    .messages({
      'string.min': 'Password must be at least 6 characters',
      'string.pattern.base': 'Password must include a number and an uppercase letter',
      'any.required': 'Password is required'
    }),

  age: Joi.number()
    .integer()
    .min(18)
    .max(100)
    .required()
    .messages({
      'number.min': 'Age must be >= 18',
      'number.max': 'Age must be <= 100',
      'any.required': 'Age is required'
    })
});
```

### 2. Validation Middleware

**middleware/validation.js**
```javascript
const Joi = require('joi');

const validate = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false });

    if (error) {
      const details = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      return res.status(400).json({
        code: 400,
        message: 'validation failed',
        detail: details
      });
    }

    req.body = value;
    next();
  };
};

module.exports = { validate, userCreateSchema };
```

### 3. Custom Error Classes

**utils/AppError.js**
```javascript
class AppError extends Error {
  constructor(message, statusCode = 400, detail = null) {
    super(message);
    this.statusCode = statusCode;
    this.detail = detail;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

class BadRequestError extends AppError {
  constructor(message = 'invalid parameters', detail = null) {
    super(message, 400, detail);
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'unauthorized', detail = null) {
    super(message, 401, detail);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'forbidden', detail = null) {
    super(message, 403, detail);
  }
}

class NotFoundError extends AppError {
  constructor(message = 'not found', detail = null) {
    super(message, 404, detail);
  }
}

class ConflictError extends AppError {
  constructor(message = 'conflict', detail = null) {
    super(message, 409, detail);
  }
}

class InternalServerError extends AppError {
  constructor(message = 'server error', detail = null) {
    super(message, 500, detail);
  }
}

module.exports = {
  AppError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  InternalServerError
};
```

### 4. Global Error Middleware

**middleware/errorHandler.js**
```javascript
const { AppError } = require('../utils/AppError');

const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;
  error.detail = err.detail;

  // Mongoose errors
  if (err.name === 'CastError') {
    const message = 'not found';
    error = new AppError(message, 404);
  }

  // Duplicate key
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    const message = `${field} already exists`;
    error = new AppError(message, 409, err.keyValue);
  }

  // Validation error
  if (err.name === 'ValidationError') {
    const message = 'validation failed';
    error = new AppError(message, 400, err.errors);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'invalid token';
    error = new AppError(message, 401);
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'token expired';
    error = new AppError(message, 401);
  }

  // Default error
  if (!err.statusCode) {
    const message = 'server error';
    error = new AppError(message, 500);
  }

  res.status(error.statusCode || 500).json({
    code: error.statusCode || 500,
    message: error.message,
    detail: error.detail || null
  });
};

module.exports = errorHandler;
```

### 5. Usage Example

**routes/users.js**
```javascript
const express = require('express');
const router = express.Router();
const userService = require('../services/userService');
const { validate, userCreateSchema } = require('../middleware/validation');
const { NotFoundError, ConflictError, InternalServerError } = require('../utils/AppError');

// Create user (with validation)
router.post('/', validate(userCreateSchema), async (req, res, next) => {
  try {
    const user = await userService.createUser(req.body);
    res.status(201).json({
      code: 201,
      message: 'created',
      data: user
    });
  } catch (error) {
    next(error);
  }
});

// Get user
router.get('/:id', async (req, res, next) => {
  try {
    const user = await userService.getUser(req.params.id);
    res.json({
      code: 200,
      message: 'success',
      data: user
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
```

**services/userService.js**
```javascript
const User = require('../models/User');
const { NotFoundError, ConflictError, InternalServerError } = require('../utils/AppError');

class UserService {
  async createUser(userData) {
    // Check username exists
    const existingUsername = await User.findOne({ username: userData.username });
    if (existingUsername) {
      throw new ConflictError('Username already exists');
    }

    // Check email exists
    const existingEmail = await User.findOne({ email: userData.email });
    if (existingEmail) {
      throw new ConflictError('Email already exists');
    }

    try {
      const user = new User(userData);
      await user.save();
      return this.toResponse(user);
    } catch (error) {
      throw new InternalServerError('Failed to create user', error.message);
    }
  }

  async getUser(id) {
    const user = await User.findById(id);
    if (!user) {
      throw new NotFoundError('User not found');
    }
    return this.toResponse(user);
  }

  toResponse(user) {
    return {
      id: user._id,
      username: user.username,
      email: user.email
    };
  }
}

module.exports = new UserService();
```

## Error Logging

### Python
```python
import logging

logger = logging.getLogger(__name__)

try:
    # Business logic
    pass
except Exception as e:
    logger.error(f"Operation failed: {str(e)}", exc_info=True)
    raise InternalServerException("Operation failed")
```

### Java
```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class UserService {
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    public UserResponse createUser(UserCreate userCreate) {
        try {
            // Business logic
            return user;
        } catch (Exception e) {
            logger.error("Create user failed", e);
            throw new BusinessException("Create user failed", e.getMessage());
        }
    }
}
```

### Node.js
```javascript
const logger = require('../utils/logger');

try {
  // Business logic
} catch (error) {
  logger.error('Operation failed', error);
  throw new InternalServerError('Operation failed', error.message);
}
```

## Test Checklist
- [ ] Missing params return 400
- [ ] Invalid params return 400
- [ ] Validation errors return clear messages
- [ ] Not found returns 404
- [ ] Duplicates return 409
- [ ] Unauthorized returns 401
- [ ] Forbidden returns 403
- [ ] Server error returns 500
- [ ] Unified error format (code, message, detail)
- [ ] No sensitive data leaks
- [ ] Error logs recorded
