# Quickstart Script

## Python + FastAPI Quickstart

### 1. Create Project Structure

```bash
# Create project directory
mkdir backend-app
cd backend-app

# Create directories
mkdir -p app/models app/schemas app/routers app/utils
mkdir -p tests
```

### 2. Create Config Files

**.env**
```bash
DATABASE_URL=postgresql://postgres:password@localhost:5432/myapp
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

**requirements.txt**
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
pydantic==2.5.0
pydantic-settings==2.1.0
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Initialize Database

```bash
# Create database
createdb myapp

# Run DDL (if any)
python -c "from app.database import Base, engine; Base.metadata.create_all(bind=engine)"
```

### 5. Start Service

```bash
# Dev mode (hot reload)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Production mode
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 6. Verify Service

```bash
# Access root path
curl http://localhost:8000/

# Open API docs
open http://localhost:8000/docs
```

## Java + Spring Boot Quickstart

### 1. Create Project Structure

```bash
# Use Spring Initializr
# Or create directories manually
mkdir backend-app
cd backend-app

mkdir -p src/main/java/com/example/app
mkdir -p src/main/resources
mkdir -p src/test/java/com/example/app
```

### 2. Create Config Files

**application.yml**
```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/myapp
    username: postgres
    password: password
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true

  sql:
    init:
      mode: always
```

**pom.xml**
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
    </dependency>
</dependencies>
```

### 3. Install Dependencies

```bash
mvn clean install
```

### 4. Initialize Database

```bash
# Create database
createdb myapp

# Spring Boot auto-creates tables (ddl-auto: update)
```

### 5. Start Service

```bash
# Dev mode
mvn spring-boot:run

# Production mode
mvn clean package
java -jar target/backend-app.jar
```

### 6. Verify Service

```bash
# Access root path
curl http://localhost:8080/

# Access Actuator endpoint (if configured)
curl http://localhost:8080/actuator/health
```

## Node.js + Express Quickstart

### 1. Create Project Structure

```bash
# Create project directory
mkdir backend-app
cd backend-app

# Init project
npm init -y

# Create directories
mkdir -p src/models src/routes src/controllers src/middleware src/utils
mkdir -p tests
```

### 2. Create Config Files

**.env**
```bash
PORT=3000
DATABASE_URL=postgresql://postgres:password@localhost:5432/myapp
JWT_SECRET=your-secret-key-change-in-production
```

**package.json**
```json
{
  "name": "backend-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon src/index.js",
    "start": "node src/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

### 3. Install Dependencies

```bash
npm install
```

### 4. Initialize Database

```bash
# Create database
createdb myapp

# Run DDL (if any)
psql -U postgres -d myapp -f schema.sql
```

### 5. Start Service

```bash
# Dev mode (hot reload)
npm run dev

# Production mode
npm start
```

### 6. Verify Service

```bash
# Access root path
curl http://localhost:3000/
```

## General Startup Checklist

### Preflight
- [ ] Runtime installed (Python / Java / Node.js)
- [ ] Database service running
- [ ] Port not in use
- [ ] Environment variables configured

### Startup
- [ ] Dependencies installed
- [ ] Database created
- [ ] Schema created
- [ ] Service started

### Verification
- [ ] Service port accessible
- [ ] Health check works
- [ ] API docs accessible
- [ ] Logs contain no errors

## Common Commands

### View Service Processes

```bash
# Find process by port
lsof -i :8000  # Python FastAPI
lsof -i :8080  # Java Spring Boot
lsof -i :3000  # Node.js Express

# Kill process
kill -9 <PID>
```

### View Logs

```bash
# Tail logs (if running in background)
tail -f logs/app.log

# Error logs
tail -f logs/error.log
```

### Stop Service

```bash
# Foreground: Ctrl + C

# Background: find and kill process
ps aux | grep uvicorn
kill -9 <PID>
```

## Environment Variable Templates

### Python Project
```bash
# .env.example
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
DEBUG=True
```

### Java Project
```bash
# application.example.yml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/dbname
    username: user
    password: password

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
```

### Node.js Project
```bash
# .env.example
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
JWT_SECRET=your-secret-key
NODE_ENV=development
```
