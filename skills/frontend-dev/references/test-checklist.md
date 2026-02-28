# Test Acceptance Checklist

## Test Process

### Phase 1: Functional Testing
Verify each requirement against the acceptance criteria in the requirements list.

### Phase 2: UI Testing
Check page layout, responsiveness, and interaction feedback.
UI quality full-gate is executed in `final-delivery`; frontend phase keeps basic UI sanity checks only.

### Phase 3: Integration Testing
Test front-end/back-end integration and end-to-end user flows.

### Phase 4: Performance Testing
Check load speed and response time.

### Phase 5: Compatibility Testing
Check compatibility across browsers and devices.

## Acceptance Criteria Extraction Process

### Read Acceptance Criteria From Requirements

**Input**: Requirements document (`requirements-template.md`)

**Extraction Steps**:
1. Read all requirements (REQ-001, REQ-002, ...)
2. Extract the "Acceptance Criteria" section for each requirement
3. Generate the test checklist

**Example**:

Requirement in the requirements document:
```
REQ-001 User Registration
Acceptance Criteria:
- Users can register with an email address
- Users can register with a phone number
- Send a verification email/SMS during registration
- Password strength check (at least 8 characters, includes letters and numbers)
- Validate email/phone number format
- Prevent duplicate registration
```

Convert to test checklist:
```
REQ-001 User Registration
├── Users can register with an email address [ ]
├── Users can register with a phone number [ ]
├── Send a verification email/SMS during registration [ ]
├── Password strength check (at least 8 characters, includes letters and numbers) [ ]
├── Validate email/phone number format [ ]
└── Prevent duplicate registration [ ]
```

## Acceptance Criteria Checklist Templates

### General Checklist Format

| Requirement ID | Requirement Name | Acceptance Criteria | Test Method | Expected Result | Actual Result | Status |
|----------|----------|----------|----------|----------|----------|------|
| REQ-XXX | XXX | Extracted from requirements | Specific test steps | Expected behavior | Actual behavior | ⬜/✅ |

### Blank Checklist (Fill From Requirements)

#### REQ-___[Requirement Name]

**Requirement Description**: [Read from requirements document]

| Acceptance Criteria | Test Method | Expected Result | Actual Result | Status |
|----------|----------|----------|----------|------|
| [Acceptance Criteria 1] | [Specific test steps] | [Expected behavior] | | ⬜ |
| [Acceptance Criteria 2] | [Specific test steps] | [Expected behavior] | | ⬜ |
| [Acceptance Criteria 3] | [Specific test steps] | [Expected behavior] | | ⬜ |
| ... | ... | ... | | ... |

---

#### REQ-___[Requirement Name]

**Requirement Description**: [Read from requirements document]

| Acceptance Criteria | Test Method | Expected Result | Actual Result | Status |
|----------|----------|----------|----------|------|
| [Acceptance Criteria 1] | [Specific test steps] | [Expected behavior] | | ⬜ |
| [Acceptance Criteria 2] | [Specific test steps] | [Expected behavior] | | ⬜ |
| [Acceptance Criteria 3] | [Specific test steps] | [Expected behavior] | | ⬜ |
| ... | ... | ... | | ... |

## UI Testing Checklist

### Layout Checks
- [ ] Page layout meets design requirements
- [ ] Elements are aligned correctly
- [ ] Spacing is consistent
- [ ] Font sizes are consistent

### UI Quality (Frontend Sanity, Non-Gate)
- [ ] Spacing consistency verified on all pages
- [ ] Style consistency verified for 4 component types (Button/Input/Card/List)
- [ ] Interaction states verified (hover/active/focus/disabled)
- [ ] If checked in frontend phase, evidence is optional; final gate evidence is required in `final-delivery`

### Responsive Testing
- [ ] Desktop displays correctly (1920x1080)
- [ ] Tablet displays correctly (768x1024)
- [ ] Mobile displays correctly (375x667)
- [ ] Both landscape and portrait orientations display correctly
- [ ] Different zoom levels display correctly

### Interaction Feedback
- [ ] Buttons provide visual feedback on click
- [ ] Form submission has a loading state
- [ ] Error messages are clear and explicit
- [ ] Successful actions show success feedback
- [ ] Loading state shows a loading animation

### Data Display
- [ ] List data displays correctly
- [ ] Images load correctly
- [ ] Currency format is correct (2 decimal places)
- [ ] Date/time format is correct
- [ ] Empty states have placeholders
- [ ] Long text is truncated with ellipsis

## Performance Testing Checklist

### Load Speed
- [ ] Initial page load time < 2 seconds
- [ ] Page transitions are smooth without jank
- [ ] Image lazy loading works correctly
- [ ] API response time < 1 second (95% of requests)
- [ ] List scrolling is smooth

### Resource Optimization
- [ ] CSS is minified
- [ ] JS is minified
- [ ] Images are compressed
- [ ] Gzip compression enabled
- [ ] Use CDN acceleration
- [ ] Code splitting and on-demand loading

### Memory Usage
- [ ] No memory leaks during long-term use
- [ ] Memory released after page switches
- [ ] Reasonable number of images
- [ ] Reasonable caching strategy

## Security Testing Checklist

### XSS Protection
- [ ] Special characters in input are not executed as code
- [ ] User input is escaped when rendered
- [ ] URL parameters are not executed

### CSRF Protection
- [ ] Sensitive operations require token validation
- [ ] Cross-origin requests have security validation

### Access Control
- [ ] Unauthenticated users cannot access login-required pages
- [ ] Regular users cannot access admin pages
- [ ] Users can only operate on their own data
- [ ] Sensitive actions require second confirmation

### Data Validation
- [ ] Front-end form validation works correctly
- [ ] Back-end validation also exists
- [ ] No bypass of front-end validation
- [ ] Sensitive data is not shown in URLs

### Sensitive Data Protection
- [ ] Passwords are not displayed in plain text
- [ ] Tokens are not stored in localStorage (or use HttpOnly Cookie)
- [ ] HTTPS is used to transmit sensitive data
- [ ] Sensitive data is not logged

## Compatibility Testing Checklist

### Browser Compatibility
- [ ] Chrome (latest) displays correctly
- [ ] Firefox (latest) displays correctly
- [ ] Safari (latest) displays correctly
- [ ] Edge (latest) displays correctly
- [ ] IE 11 (if required) displays correctly

### Mobile Browser Compatibility
- [ ] iOS Safari displays correctly
- [ ] Android Chrome displays correctly
- [ ] WeChat in-app browser displays correctly
- [ ] Alipay in-app browser displays correctly

### Device Compatibility
- [ ] Desktop (Windows) displays correctly
- [ ] Desktop (Mac) displays correctly
- [ ] Tablet (iPad) displays correctly
- [ ] Tablet (Android) displays correctly
- [ ] Phone (iPhone) displays correctly
- [ ] Phone (Android) displays correctly

### Network Environment Compatibility
- [ ] Works normally on WiFi
- [ ] Works normally on 4G
- [ ] Show loading indicator on weak networks
- [ ] Friendly message in offline mode

## Test Report Template

```
Test Report
==================================================
Project Name: XXX System
Test Date: 2024-XX-XX
Tester: XXX
Tech Stack: React + Ant Design + TypeScript

I. Functional Testing
----------------------------------------
Total Requirements: XX
Passed: XX
Failed: XX

Pass Rate: XX%

Failed Requirements List:
1. REQ-XXX: [Requirement Name]
   - Acceptance Criteria: [Specific criteria]
   - Issue Description: [Specific issue]
   - Priority: P0/P1/P2

2. REQ-XXX: [Requirement Name]
   - Acceptance Criteria: [Specific criteria]
   - Issue Description: [Specific issue]
   - Priority: P0/P1/P2

II. UI Testing
----------------------------------------
Layout Checks: ✅ Pass / ⬜ Fail
Responsive Testing: ✅ Pass / ⬜ Fail
Interaction Feedback: ✅ Pass / ⬜ Fail
Data Display: ✅ Pass / ⬜ Fail

Failed Items:
1. [Specific issue]
2. [Specific issue]

III. Performance Testing
----------------------------------------
Initial Load: X.X seconds (target < 2 seconds) ✅ / ⬜
API Response: X.X seconds (target < 1 second) ✅ / ⬜
Memory Usage: Normal / ⬜ Leak detected

Failed Items:
1. [Specific issue]
2. [Specific issue]

IV. Security Testing
----------------------------------------
XSS Protection: ✅ Pass / ⬜ Fail
CSRF Protection: ✅ Pass / ⬜ Fail
Access Control: ✅ Pass / ⬜ Fail
Data Validation: ✅ Pass / ⬜ Fail

Failed Items:
1. [Specific issue]
2. [Specific issue]

V. Compatibility Testing
----------------------------------------
Browser Compatibility: ✅ Pass / ⬜ Fail
Device Compatibility: ✅ Pass / ⬜ Fail

Failed Items:
1. [Specific issue]
2. [Specific issue]

VI. Summary
----------------------------------------
Overall Rating: [Excellent/Good/Fair/Poor]

Ready for Delivery: [Yes/No]

If not ready, continue fixing the following issues:
P0 Issues (must fix):
1. REQ-XXX: [Issue description]
2. REQ-XXX: [Issue description]

P1 Issues (should fix):
1. [Issue description]
2. [Issue description]

P2 Issues (can be deferred):
1. [Issue description]
2. [Issue description]
```

## Delivery Standards

### Must Meet (P0)
- [ ] All P0 requirements pass acceptance criteria
- [ ] No critical bugs (features unusable)
- [ ] No major security issues
- [ ] No front-end console errors

### Should Meet (P1)
- [ ] All P1 requirements pass acceptance criteria
- [ ] No performance issues (slow loads, jank)
- [ ] Good user experience

### Can Meet (P2)
- [ ] P2 requirements pass acceptance criteria as much as possible
- [ ] Good visual aesthetics
- [ ] Good animation effects
