# Common Issues and Fixes

## Service Startup Issues

### Issue 1: Port In Use

**Error**:
```
Error: Address already in use: 8000
```

**Cause**:
- Port 8000 is already in use by another process

**Solutions**:

**Find the process**:
```bash
# Linux/Mac
lsof -i :8000
netstat -tuln | grep 8000

# Windows
netstat -ano | findstr :8000
```

**Kill the process**:
```bash
# Linux/Mac
kill -9 <PID>

# Windows
taskkill /F /PID <PID>
```

**Change the port**:
```bash
# Python FastAPI
uvicorn app.main:app --port 8001

# Java Spring Boot
# Edit application.yml
server:
  port: 8081

# Node.js Express
# Edit .env
PORT=3001
```

---

### Issue 2: Database Connection Failed

**Error**:
```
OperationalError: could not connect to server: Connection refused
```

**Cause**:
- DB service not started
- DB host/port incorrect
- DB auth failed

**Solutions**:

**Check DB service status**:
```bash
# PostgreSQL
sudo systemctl status postgresql
sudo systemctl start postgresql

# MySQL
sudo systemctl status mysql
sudo systemctl start mysql

# MongoDB
sudo systemctl status mongod
sudo systemctl start mongod
```

**Test DB connection**:
```bash
# PostgreSQL
psql -U postgres -h localhost -p 5432

# MySQL
mysql -u root -p -h localhost -P 3306

# MongoDB
mongo --host localhost --port 27017
```

**Check config**:
```python
# Check DATABASE_URL
DATABASE_URL=postgresql://postgres:password@localhost:5432/myapp

# Ensure database exists
createdb myapp
```

---

### Issue 3: Dependency Installation Failed

**Error**:
```
ModuleNotFoundError: No module named 'fastapi'
```

**Cause**:
- Python dependencies not installed
- Virtual environment not activated
- pip version too old

**Solutions**:

**Install dependencies**:
```bash
# Python
pip install -r requirements.txt

# Ensure correct Python environment
python -m pip install -r requirements.txt
```

**Create virtual environment**:
```bash
# Create venv
python -m venv venv

# Activate venv
source venv/bin/activate  # Linux/Mac
venv\\Scripts\\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

**Upgrade pip**:
```bash
python -m pip install --upgrade pip
```

---

### Issue 4: Environment Variables Not Loaded

**Error**:
```
KeyError: 'DATABASE_URL'
```

**Cause**:
- .env file missing
- Environment variables not loaded

**Solutions**:

**Create .env file**:
```bash
# .env
DATABASE_URL=postgresql://postgres:password@localhost:5432/myapp
SECRET_KEY=your-secret-key
```

**Load env vars**:

**Python**:
```python
# Install python-dotenv
pip install python-dotenv

# Load in code
from dotenv import load_dotenv
load_dotenv()
```

**Node.js**:
```javascript
// Install dotenv
npm install dotenv

// Load in code
require('dotenv').config();
```

**Java**:
```yaml
# application.yml
spring:
  config:
    import: optional:file:.env[.properties]
```

---

## API Issues

### Issue 1: 404 Not Found

**Error**:
```json
{
  "detail": "Not Found"
}
```

**Cause**:
- Route path incorrect
- Resource not found

**Solutions**:

**Check route definition**:
```python
# FastAPI
@app.get("/api/v1/products/{product_id}")
def get_product(product_id: int):
    ...
```

**Check request path**:
```bash
# Correct path
curl http://localhost:8000/api/v1/products/1

# Not
curl http://localhost:8000/products/1
```

**Check route registration**:
```python
# Ensure route is registered
from app.routers import products
app.include_router(products.router, prefix="/api/v1/products", tags=["products"])
```

---

### Issue 2: 401 Unauthorized

**Error**:
```json
{
  "detail": "Not authenticated"
}
```

**Cause**:
- Token missing
- Token invalid
- Token expired

**Solutions**:

**Check token existence**:
```bash
# Ensure Authorization header included
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/users
```

**Check token format**:
```python
# Token should be in Bearer format
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Re-acquire token**:
```bash
# Log in to get a new token
curl -X POST http://localhost:8000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Password123"}'
```

---

### Issue 3: 403 Forbidden

**Error**:
```json
{
  "detail": "Permission denied"
}
```

**Cause**:
- Insufficient permissions
- Accessing another user's data

**Solutions**:

**Check permission logic**:
```python
# Ensure user has permission to access resource
if current_user.id != resource.user_id and not current_user.is_admin:
    raise HTTPException(status_code=403, detail="Permission denied")
```

**Login with correct user**:
```bash
# Login with privileged user
curl -X POST http://localhost:8000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin123"}'
```

---

### Issue 4: 422 Unprocessable Entity

**Error**:
```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

**Cause**:
- Missing required params
- Wrong param type
- Invalid param format

**Solutions**:

**Check request params**:
```bash
# Ensure all required params exist
curl -X POST http://localhost:8000/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Password123"
  }'
```

**Check param types**:
```python
# Pydantic model definition
class UserCreate(BaseModel):
    username: str  # Must be string
    email: EmailStr  # Must be valid email
    password: str  # Must be string
```

---

### Issue 5: 500 Internal Server Error

**Error**:
```json
{
  "detail": "Internal Server Error"
}
```

**Cause**:
- Server-side code error
- DB operation failed
- Unhandled exception

**Solutions**:

**Check logs**:
```bash
# View server logs
tail -f logs/app.log

# View error logs
tail -f logs/error.log
```

**Enable debug mode**:
```python
# FastAPI
app = FastAPI(debug=True)

# Java Spring Boot
# application.yml
debug: true
logging.level.org.springframework.web: DEBUG
```

**Check code logic**:
```python
# Add exception handling
try:
    result = some_operation()
except Exception as e:
    logger.error(f"Error: {str(e)}")
    raise HTTPException(status_code=500, detail=str(e))
```

---

## Database Issues

### Issue 1: Table Does Not Exist

**Error**:
```
Relation "users" does not exist
```

**Cause**:
- DB not initialized
- Tables not created

**Solutions**:

**Run schema script**:
```bash
# PostgreSQL
psql -U postgres -d myapp -f schema.sql

# MySQL
mysql -u root -p myapp < schema.sql
```

**Auto-create via ORM**:
```python
# SQLAlchemy
Base.metadata.create_all(bind=engine)
```

---

### Issue 2: Foreign Key Constraint Error

**Error**:
```
IntegrityError: foreign key constraint fails
```

**Cause**:
- Referenced record does not exist
- FK config incorrect

**Solutions**:

**Check referenced row**:
```sql
-- Check if user_id=1 exists
SELECT * FROM users WHERE id = 1;
```

**Insert referenced data first**:
```sql
-- Insert user first
INSERT INTO users (username, email, password_hash) VALUES ('test', 'test@example.com', 'hash');

-- Then insert order (user_id=1)
INSERT INTO orders (user_id, ...) VALUES (1, ...);
```

---

### Issue 3: Unique Constraint Conflict

**Error**:
```
IntegrityError: duplicate key value violates unique constraint
```

**Cause**:
- Duplicate username/email

**Solutions**:

**Use different values**:
```bash
# Username and email must be unique
{
  "username": "testuser2",
  "email": "test2@example.com"
}
```

**Handle conflicts**:
```python
# Catch unique constraint error
try:
    user = create_user(username="testuser", email="test@example.com")
except IntegrityError:
    raise HTTPException(status_code=400, detail="Username or email already exists")
```

---

## Auth Issues

### Issue 1: Password Hashing Failed

**Error**:
```
ValueError: Invalid salt
```

**Cause**:
- Hash algorithm inconsistent
- bcrypt version mismatch

**Solutions**:

**Use correct hashing**:
```python
# Use bcrypt for password hashing
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
```

---

### Issue 2: Token Generation Failed

**Error**:
```
JWTError: Invalid signature
```

**Cause**:
- SECRET_KEY misconfigured
- Token format invalid

**Solutions**:

**Check SECRET_KEY**:
```python
# SECRET_KEY must be a sufficiently complex string
SECRET_KEY = "your-secret-key-change-in-production"

# Generate random secret
import secrets
SECRET_KEY = secrets.token_urlsafe(32)
```

**Generate token correctly**:
```python
from jose import JWTError, jwt

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
```

---

## Performance Issues

### Issue 1: Slow Queries

**Cause**:
- Missing indexes
- N+1 query problem

**Solutions**:

**Add indexes**:
```sql
-- Add indexes for common fields
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

**Use eager loading**:
```python
# Avoid N+1 queries
from sqlalchemy.orm import joinedload

# Bad: N+1 queries
orders = session.query(Order).all()
for order in orders:
    print(order.user.username)  # Query user each time

# Good: eager loading
orders = session.query(Order).options(joinedload(Order.user)).all()
```

---

### Issue 2: High Memory Usage

**Cause**:
- Loading too much data at once
- DB connections not released

**Solutions**:

**Pagination**:
```python
# Use pagination
def get_products(page: int = 1, limit: int = 10):
    offset = (page - 1) * limit
    return session.query(Product).offset(offset).limit(limit).all()
```

**Generators**:
```python
# Yield data in batches
def stream_products():
    for product in session.query(Product).yield_per(100):
        yield product
```

---

## Debugging Tips

### 1. Enable Detailed Logs

```python
# Python FastAPI
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

@app.get("/products/{product_id}")
def get_product(product_id: int):
    logger.debug(f"Getting product with id: {product_id}")
    ...
```

### 2. Use Breakpoints

```python
# Use pdb
import pdb

@app.get("/products/{product_id}")
def get_product(product_id: int):
    pdb.set_trace()  # Breakpoint
    product = get_product_by_id(product_id)
    return product
```

### 3. Log Requests

```python
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Incoming request: {request.method} {request.url}")
    response = await call_next(request)
    logger.info(f"Response status: {response.status_code}")
    return response
```

### 4. Use API Docs

FastAPI auto-generates API docs:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

---

## Test Checklist

After fixes, ensure the following:

- [ ] Service starts successfully
- [ ] Database connection works
- [ ] All tables created
- [ ] Test data inserted
- [ ] Health check works
- [ ] User registration/login works
- [ ] API auth works
- [ ] CRUD operations work
- [ ] Error handling correct
- [ ] Logging correct

## Getting Help

If the above does not solve the issue:

1. Check full error logs
2. Verify dependency versions
3. Check config files
4. Search for similar issues
5. Read official docs
