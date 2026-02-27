# Iteration Guide

## Iteration Flow

```
Test → Find issues → Analyze → Fix → Retest → All pass?
                                                   ↙        ↘
                                                  Yes        No
                                                  ↓          ↓
                                                Deliver   Iterate
```

## Issue Categories

### Functional Issues
- Feature not implemented
- Logic errors
- Incomplete feature

### UI Issues
- Layout errors
- Inconsistent styles
- Responsive issues

### Performance Issues
- Slow load
- Laggy interactions
- Memory leaks

### Compatibility Issues
- Browser incompatibility
- Device incompatibility
- Resolution display issues

## Fix Priority

### P0 - Fix Immediately
- Feature unusable
- Severe security vulnerabilities
- App crashes

### P1 - Fix Next
- UX-impacting issues
- Performance problems
- Compatibility issues

### P2 - Fix Later
- Cosmetic issues
- Non-core issues
- Optimization only

## Fix Methods

### 1. Update Component Code

#### Fix Logic Error

**Issue**: no redirect to home after login

**Before**:
```typescript
const handleLogin = async (values: LoginForm) => {
  try {
    await loginApi.login(values);
    message.success('Login successful');
  } catch (error) {
    message.error('Login failed');
  }
};
```

**After**:
```typescript
const handleLogin = async (values: LoginForm) => {
  try {
    const response = await loginApi.login(values);
    message.success('Login successful');
    // Save token
    localStorage.setItem('token', response.data.token);
    // Redirect to home
    navigate('/');
  } catch (error) {
    message.error('Login failed');
  }
};
```

#### Fix Form Validation

**Issue**: password strength validation incorrect

**Before**:
```typescript
<Form.Item
  label="Password"
  name="password"
  rules={[
    { required: true, message: 'Enter password' },
    { min: 8, message: 'Minimum 8 characters' },
  ]}
>
  <Input.Password placeholder="Enter password" />
</Form.Item>
```

**After**:
```typescript
<Form.Item
  label="Password"
  name="password"
  rules={[
    { required: true, message: 'Enter password' },
    { min: 8, message: 'Minimum 8 characters' },
    {
      pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      message: 'Must include upper/lowercase and numbers',
    },
  ]}
>
  <Input.Password placeholder="Enter password" />
</Form.Item>
```

### 2. Fix API Calls

#### Fix Request Params

**Issue**: incorrect request params

**Before**:
```typescript
const getUsers = async () => {
  const response = await userApi.getUsers({
    page,
    limit,
  });
  setUsers(response.data.users);
};
```

**After**:
```typescript
const getUsers = async () => {
  const response = await userApi.getUsers({
    page,
    limit,
    keyword: searchKeyword, // add keyword
  });
  setUsers(response.data.users);
};
```

#### Fix Response Parsing

**Issue**: response data parsing incorrect

**Before**:
```typescript
const getUsers = async () => {
  const response = await userApi.getUsers({ page, limit });
  setUsers(response.users); // wrong structure
};
```

**After**:
```typescript
const getUsers = async () => {
  const response = await userApi.getUsers({ page, limit });
  setUsers(response.data.users); // correct structure
};
```

### 3. Fix Styles

#### Fix Responsive Layout

**Issue**: mobile layout broken

**Before**:
```css
.container {
  display: flex;
  width: 1200px;
}
```

**After**:
```css
.container {
  display: flex;
  width: 100%;
  max-width: 1200px;
}

@media (max-width: 768px) {
  .container {
    flex-direction: column;
  }
}
```

#### Fix Alignment

**Issue**: form items misaligned

**Before**:
```typescript
<Form layout="horizontal">
  <Form.Item label="Username">
    <Input />
  </Form.Item>
</Form>
```

**After**:
```typescript
<Form layout="vertical" labelCol={{ span: 6 }}>
  <Form.Item label="Username">
    <Input />
  </Form.Item>
</Form>
```

### 4. Performance Optimization

#### Add Loading State

**Issue**: no loading indicator

**Before**:
```typescript
const loadUsers = async () => {
  const response = await userApi.getUsers({ page, limit });
  setUsers(response.data.users);
};
```

**After**:
```typescript
const [loading, setLoading] = useState(false);

const loadUsers = async () => {
  setLoading(true);
  try {
    const response = await userApi.getUsers({ page, limit });
    setUsers(response.data.users);
  } finally {
    setLoading(false);
  }
};
```

#### Add Debounce/Throttle

**Issue**: frequent API requests during search input

**Before**:
```typescript
const handleSearch = (value: string) => {
  loadUsers({ keyword: value });
};
```

**After**:
```typescript
import { debounce } from 'lodash';

const debouncedSearch = debounce((value: string) => {
  loadUsers({ keyword: value });
}, 300);

const handleSearch = (value: string) => {
  debouncedSearch(value);
};
```

## Change Log Template

### Iteration #1

**Date**: 2024-XX-XX
**Owner**: XXX

| Issue ID | Description | Priority | Location | Change | Status |
|----------|----------|--------|----------|----------|----------|
| BUG-001 | No redirect after login | P0 | UserLogin.tsx | Add navigate('/') | ✅ Fixed |
| BUG-002 | Password validation incorrect | P0 | UserForm.tsx | Add regex validation | ✅ Fixed |
| UI-001 | Mobile layout broken | P1 | UserList.css | Add responsive styles | ✅ Fixed |
| PERF-001 | Frequent API calls on search | P1 | UserList.tsx | Add debounce | ✅ Fixed |

**Test Results**:
- Functional tests: 4/4 passed
- UI tests: 3/3 passed
- Performance tests: 2/2 passed

**Continue iteration**: No / Yes

---

### Iteration #2

**Date**: 2024-XX-XX
**Owner**: XXX

| Issue ID | Description | Priority | Location | Change | Status |
|----------|----------|--------|----------|----------|----------|
| BUG-003 | Cart total not updated | P0 | Cart.tsx | Recalculate total | ✅ Fixed |
| UI-002 | No feedback on button click | P1 | Button.tsx | Add loading state | ✅ Fixed |
| COMPAT-001 | Safari incompatibility | P1 | request.ts | Fix Promise compatibility | ✅ Fixed |

**Test Results**:
- Functional tests: 3/3 passed
- UI tests: 2/2 passed
- Compatibility tests: 1/1 passed

**Continue iteration**: No / Yes

## Change Notes

### 1. Backup Before Changes
- Use version control (Git)
- Commit current code
- Create a new branch for changes

### 2. During Changes
- Do not modify unrelated code
- Keep code style consistent
- Add necessary comments
- Follow best practices

### 3. After Changes
- Test the modified features
- Test related features
- Ensure no regressions

### 4. Record Changes
- Record what was changed
- Record why
- Record test results

## Iteration Exit Criteria

**You can stop iterating when:**
1. All P0 acceptance criteria pass
2. All P1 acceptance criteria pass
3. No critical bugs
4. No major security issues
5. No performance issues
6. Good compatibility

**Otherwise, keep iterating.**

## Automated Testing Suggestions

### Unit Tests
```typescript
describe('UserList', () => {
  it('should render user list correctly', () => {
    // test list rendering
  });

  it('should handle search correctly', () => {
    // test search
  });
});
```

### E2E Tests
```typescript
describe('User Login', () => {
  it('should login successfully', () => {
    // test login flow
  });
});
```

### Integration Tests
```typescript
describe('API Integration', () => {
  it('should fetch user list', async () => {
    // test API call
  });
});
```
