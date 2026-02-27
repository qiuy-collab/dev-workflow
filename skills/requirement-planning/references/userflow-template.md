# User Flow Template

## Table of Contents
- [Flow Diagram Symbols](#flow-diagram-symbols)
- [Flow Document Format](#flow-document-format)
- [Flow Examples](#flow-examples)

## Flow Diagram Symbols

### Common Symbols
| Symbol | Meaning | Example |
|------|------|------|
| Start/End | Start or end of a flow | User visits homepage |
| Action | Action by user or system | Click register button |
| Decision | A decision node | Verification passed? |
| Data/Input | Data input or output | Enter email address |
| Sub-flow | Reference to a detailed flow | See "Registration Verification Flow" |

### Text Representation
Since this template uses text format, use these conventions:
- → indicates flow direction
- ? indicates a decision node
- [Yes/No] indicates branches
- ⚠️ indicates exception handling

## Flow Document Format

### Basic Structure
```markdown
## [Flow Name]

### Flow Overview
- **Goal**: purpose of the flow
- **Roles**: user roles involved
- **Preconditions**: conditions that trigger the flow

### Normal Flow
1. User action → system response
2. User action → system response
3. ...

### Exception Handling
- Exception scenario A → handling
- Exception scenario B → handling

### Branch Logic
- Condition A → Branch A
- Condition B → Branch B
```

## Flow Examples

## User Registration Flow

### Flow Overview
- **Goal**: new user completes account registration and activation
- **Roles**: new user, system
- **Preconditions**: user visits registration page

### Normal Flow
1. User visits registration page → system shows registration form (email/phone, password, confirm password)
2. User enters registration info → system performs frontend validation
3. User clicks "Register" → system sends verification email/SMS
4. User receives code → user enters verification code
5. User submits code → system verifies successfully
6. System creates user account → auto login
7. System redirects to homepage → show welcome message

### Exception Handling
- Invalid email/phone format → show error message
- Weak password → show password requirement prompt
- Email/phone already registered → prompt login or password recovery
- Code timeout (10 minutes) → allow resend
- Code incorrect (over 3 times) → require new code
- Send failure → prompt retry later

### Branch Logic
- Register with email → send email verification
- Register with phone → send SMS verification

---

## User Login Flow

### Flow Overview
- **Goal**: registered user successfully logs into the system
- **Roles**: registered user, system
- **Preconditions**: user has a registered account

### Normal Flow
1. User visits login page → system shows login form
2. User enters email/phone and password → user clicks "Login"
3. System validates credentials → success
4. System creates login session → redirect to homepage
5. System shows user info → login success

### Exception Handling
- Email/phone not found → prompt registration
- Wrong password → show password error
- 5 consecutive password failures → lock account for 30 minutes, show unlock prompt
- Account not activated → prompt account activation
- Account disabled → prompt contact admin

### Branch Logic
- "Remember me" checked → keep session for 7 days
- "Remember me" unchecked → require re-login after browser closes

---

## Password Recovery Flow

### Flow Overview
- **Goal**: user resets a forgotten password
- **Roles**: registered user, system
- **Preconditions**: user forgot password but remembers email/phone

### Normal Flow
1. User clicks "Forgot password" on login page → go to recovery page
2. User enters registered email/phone → click "Send verification code"
3. System sends reset link/code → user receives it
4. User enters code → system verifies successfully
5. User sets new password → system checks strength
6. User clicks "Confirm change" → password update succeeds
7. System requires re-login → redirect to login page

### Exception Handling
- Email/phone not registered → prompt registration
- Code timeout → allow resend
- Code incorrect → prompt re-entry
- New password same as old → prompt a different password
- New password too weak → show password requirements

### Branch Logic
- Email recovery → send reset link (valid 24 hours)
- Phone recovery → send code (valid 10 minutes)

## Flow Design Best Practices

### Principles
1. **Simplicity**: minimize steps, avoid redundant actions
2. **Clarity**: each step has clear action and feedback
3. **Fault tolerance**: consider exceptions and provide friendly prompts
4. **Consistency**: keep similar flows consistent

### Notes
- Each flow has a clear start and end
- Mark all exception scenarios
- Describe branch logic clearly
- Consider user cognitive load
- Provide sufficient guidance and feedback
