# Workflow: Debug & Repair

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade, systematic debugging workflow that enables AI agents to efficiently identify, diagnose, and resolve software issues while maintaining code quality, security, and project standards

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Issue Triage & Classification Phase](#issue-triage--classification-phase)
3. [Reproduction & Isolation Phase](#reproduction--isolation-phase)
4. [Root Cause Analysis Phase](#root-cause-analysis-phase)
5. [Research & Solution Discovery Phase](#research--solution-discovery-phase)
6. [Fix Implementation Phase](#fix-implementation-phase)
7. [Verification & Validation Phase](#verification--validation-phase)
8. [Regression Testing Phase](#regression-testing-phase)
9. [Documentation & Prevention Phase](#documentation--prevention-phase)
10. [Automation & CI/CD Integration](#automation--ci-cd-integration)
11. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
12. [Quick Reference](#quick-reference)

---

## Core Principles

| Principle                 | Description                                                                     | Anti-Pattern to Avoid                                                    |
| :------------------------ | :---------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| **Systematic Approach**   | Follow a structured, phase-based workflow rather than ad-hoc debugging         | Jumping straight to fixes without proper diagnosis                     |
| **Minimal Changes**       | Apply the smallest possible fix that resolves the issue                        | Large refactoring alongside bug fixes                                  |
| **Verification-First**    | Reproduce the issue before attempting any fix                                  | Assuming understanding of the problem without evidence                 |
| **Traceability**          | Document all debugging steps, hypotheses, and conclusions                      | Skipping documentation during debugging                                |
| **Security-Aware**        | Never introduce security vulnerabilities while fixing bugs                     | Adding quick fixes that expose secrets or weaken security              |
| **Regression-Prevention** | Always ensure existing functionality isn't broken by the fix                   | Fixing one bug while breaking other features                           |
| **Self-Healing**          | Implement safeguards to prevent recurrence of similar issues                   | Fixing symptoms rather than root causes                                |
| **License-Compliant**     | All fixes must adhere to the MIT license and project's legal requirements      | Introducing incompatible license code                                  |

---

## Issue Triage & Classification Phase

**Objective**: Categorize issues by severity, scope, and impact to prioritize debugging efforts effectively.

### 1. Issue Intake & Initial Assessment

**Gather essential information**:

```zsh
# Extract key details from issue report
echo "Issue Type: $1"
echo "Severity: $2"
echo "Environment: $3"
echo "Reproduction Steps: $4"
```

**Standard Classification Categories**:

| Category           | Definition                                    | Priority    | Response Time     |
| :------------------ | :------------------------------------------- | :----------- | :---------------- |
| **Security**       | Exploitable vulnerabilities, data exposure    | CRITICAL    | Immediate (0-1h)  |
| **Build/Deploy**   | Prevents compilation, testing, or deployment  | HIGH        | 1-4 hours         |
| **Core Functionality** | Main user-facing features broken            | HIGH        | 4-8 hours         |
| **Peripheral Features** | Non-essential features affected            | MEDIUM      | 1-2 days          |
| **Performance**    | Significant slowdowns or resource issues     | MEDIUM      | 1-2 days          |
| **Cosmetic**       | UI issues, minor UX problems                 | LOW         | 2-5 days          |
| **Documentation**  | Incorrect or missing docs                    | LOW         | 3-7 days          |

### 2. Severity Matrix

**Define severity criteria**:

| Severity | Criteria                                                                 | Required Actions                      |
| :--------- | :--------------------------------------------------------------------- | :--------------------- |
| **CRITICAL** | Security breach, production crash, data loss | Immediate investigation, team notification |
| **HIGH**     | Core features unavailable, tests fail        | High priority, quick resolution expected |
| **MEDIUM**   | Significant features degraded, workarounds exist | Schedule within sprint               |
| **LOW**      | Minor issues, cosmetic, edge cases           | Triage as capacity allows             |

### 3. Triage Checklist

Before proceeding to debugging, verify:

- [ ] Issue type clearly identified
- [ ] Severity level established
- [ ] Reproduction steps documented (even if incomplete)
- [ ] Environment details captured (OS, Node version, browser, etc.)
- [ ] Affected components identified
- [ ] Related issues/issues linked (duplicate check)

### 4. Triage Sign-Off

**Document triage results**:

```markdown
## Triage Summary
- **Issue ID**: #123
- **Type**: Bug / Feature / Performance
- **Severity**: HIGH
- **Status**: Ready for Reproduction
- **Assigned Agent**: Claude-4-Sonnet
- **Triage Date**: 2026-03-19
```

---

## Reproduction & Isolation Phase

**Objective**: Create a reliable reproduction case and isolate the problematic code area.

### 1. Environment Setup Verification

**Confirm dev container environment**:

```zsh
# Verify container setup
echo "=== Environment Verification ==="
echo "Container: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Working Dir: $(pwd)"
echo "Git Hash: $(git rev-parse HEAD)"

# Check required tools
which playwright || echo "Playwright: NOT INSTALLED"
which code || echo "VS Code: NOT INSTALLED"
```

### 2. Reproduction Test Case Creation

**Create minimal, reproducible test case**:

```typescript
// Example: Create a focused test file
// __tests__/bug-reproduction.test.ts
import { describe, it, expect } from 'vitest';

describe('Bug Reproduction: [Issue #XXX]', () => {
  it('should reproduce the reported issue', async () => {
    // Reproduce exact steps from issue report
    // Expected: [bug behavior]
    // Actual: [observed behavior]
    expect(false).toBe(true); // Placeholder
  });
});
```

### 3. Automated Reproduction Script

**Create a script to automate reproduction**:

```zsh
#!/bin/bash
# Reproduction Script Template

echo "=== Reproduction Attempt ==="
echo "Issue: $ISSUE_ID"
echo "Date: $(date)"
echo ""

# Step 1: Reset environment
echo "1. Resetting environment..."
npm run clean 2>/dev/null || echo "Clean skipped"

# Step 2: Install dependencies
echo "2. Installing dependencies..."
npm ci --ignore-scripts 2>&1 | tail -5

# Step 3: Build (if applicable)
echo "3. Building..."
npm run build 2>&1 | tail -10

# Step 4: Run test case
echo "4. Running reproduction test..."
npm test -- --grep="[Issue $ISSUE_ID]" 2>&1

# Capture exit code
EXIT_CODE=$?
echo ""
echo "Exit Code: $EXIT_CODE"

# Step 5: Analyze logs
echo "5. Log Analysis..."
if [ -f "logs/debug.log" ]; then
    tail -50 logs/debug.log
else
    echo "No debug log found"
fi

# Result
if [ $EXIT_CODE -ne 0 ]; then
    echo "✗ Reproduction SUCCESSFUL - Issue confirmed"
    exit 1
else
    echo "⚠ Reproduction FAILED - Issue may be intermittent or misreported"
    exit 0
fi
```

### 4. Playwright Browser Reproduction

**For UI-related issues, use Playwright**:

```typescript
// __tests__/ui-reproduction.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Bug Reproduction: [Issue #XXX]', () => {
  test('should reproduce the UI bug', async ({ page }) => {
    // Navigate to affected page
    await page.goto('/affected-route');
    
    // Perform reproduction steps
    await page.click('#trigger-element');
    await page.waitForSelector('.expected-element');
    
    // Capture screenshot for documentation
    await page.screenshot({ path: 'reproduction/screenshot-before-fix.png' });
    
    // Verify bug behavior
    const bugElement = page.locator('.buggy-element');
    expect(await bugElement.count()).toBeGreaterThan(0);
  });
});
```

### 5. Reproduction Sign-Off

Before proceeding to root cause analysis, verify:

- [ ] Reproduction case created and working
- [ ] Reproduction script executes reliably
- [ ] Error output consistently reproduced
- [ ] Screenshots/logs captured for documentation
- [ ] Environment matches issue reporter's setup

---

## Root Cause Analysis Phase

**Objective**: Systematically identify the underlying cause of the issue using code trace and analysis.

### 1. Error Message Analysis

**Extract and categorize error information**:

```zsh
# Parse error output
echo "=== Error Analysis ==="

# Extract error type
echo "Error Type: $(grep -oE '(Error|Exception|TypeError|ReferenceError)' error.log | head -1)"

# Extract error message
echo "Message: $(grep -A1 'Error:' error.log | tail -1)"

# Extract stack trace
echo "Stack Trace:"
grep -A20 'at ' error.log | head -30

# Identify source file
echo "Source File: $(grep -oE '(/[^:]+:\d+:\d+)' error.log | head -1)"
```

### 2. Code Trace with Error Lens

**Analyze error patterns from Error Lens or similar tools**:

```typescript
// Look for common error patterns
const errorPatterns = [
  { regex: /Cannot read property '.*' of null/, category: 'NullReference' },
  { regex: /Module not found/, category: 'Dependency' },
  { regex: /Timeout/, category: 'Performance' },
  { regex: /Unexpected token/, category: 'Syntax' },
  { regex: /Permission denied/, category: 'Security' },
];

// Search for error context in code
grep -r "Error\|Exception\|TODO\|FIXME" src/ --include="*.ts" | grep -i "error" | head -20
```

### 3. Call Stack Analysis

**Trace execution path to find failure point**:

```zsh
# Analyze function call stack
echo "=== Call Stack Analysis ==="

# 1. Find the error location
ERROR_FILE=$(grep -B5 'throw new Error' src/**/*.ts 2>/dev/null | head -1 | cut -d: -f1)
echo "Error Location: $ERROR_FILE"

# 2. Trace back through call chain
grep -r "from.*$ERROR_FILE\|require.*$ERROR_FILE\|import.*$ERROR_FILE" src/ --include="*.ts" | head -10

# 3. Identify callers
grep -r "$ERROR_FUNCTION" src/ --include="*.ts" | grep -v "export" | head -15
```

### 4. Dependency Chain Analysis

**Trace dependencies to identify propagation issues**:

```zsh
# Analyze dependency tree
echo "=== Dependency Chain Analysis ==="

# 1. Find direct dependencies
echo "Direct Dependencies:"
grep -h "import.*from\|require(" src/"$ERROR_FILE".ts 2>/dev/null | head -10

# 2. Check dependency versions
echo "Dependency Versions:"
npm ls 2>/dev/null | grep -E "$ISSUE_COMPONENT|$ISSUE_LIBRARY" | head -10

# 3. Check for version conflicts
echo "Version Conflicts:"
npm ls 2>/dev/null | grep -E "^└─?─?─? " | sort | uniq -d
```

### 5. Data Flow Analysis

**Trace data transformation to find corruption point**:

```typescript
// Add debug logging to trace data
function traceDataFlow(input: InputType): OutputType {
  console.log('[TRACE] Input:', JSON.stringify(input, null, 2));
  
  const stage1 = transform1(input);
  console.log('[TRACE] After transform1:', JSON.stringify(stage1, null, 2));
  
  const stage2 = transform2(stage1);
  console.log('[TRACE] After transform2:', JSON.stringify(stage2, null, 2));
  
  return stage2;
}
```

### 6. Root Cause Analysis Sign-Off

Before proceeding to research, verify:

- [ ] Error message fully analyzed
- [ ] Call stack traced to failure point
- [ ] Related code sections identified
- [ ] Dependency chain mapped
- [ ] Data flow analyzed (if applicable)
- [ ] Hypotheses for root cause formulated

---

## Research & Solution Discovery Phase

**Objective**: Research the issue using external resources and community knowledge to find proven solutions.

### 1. Search Strategy Framework

**Use multiple sources for comprehensive research**:

| Resource           | Best For                                      | Search Pattern                        |
| :------------------ | :------------------------------------------- | :--------------------------------- -- |
| **Brave Search**   | General query, recent discussions            | `"<error message>" site:stackoverflow.com` |
| **GitHub Issues**  | Known library/framework bugs                 | `"<library> <error>" repo:owner/repo` |
| **Documentation**  | API usage, configuration                     | `"<library> <feature> documentation"` |
| **Code Search**    | Implementation examples                      | `"functionName" language:typescript` |

### 2. Search Query Templates

**Craft effective search queries**:

```zsh
# Template 1: Error message search
echo "Searching for: \"$(grep -oE 'Error: .*' error.log | head -1)\""

# Template 2: Library-specific search
echo "Searching: \"$(npm view $ISSUE_LIBRARY name) $(grep -oE 'Error: .*' error.log)\""

# Template 3: Stack Overflow focused
brave-search "typescript ${ISSUE_COMPONENT} ${ISSUE_ERROR} stackoverflow"

# Template 4: GitHub issue search
curl -s "https://api.github.com/search/issues?q=${ISSUE_LIBRARY}+${ISSUE_ERROR}" | jq '.items[] | {html_url, title, state}'
```

### 3. Community-Vetted Solutions

**Evaluate solutions from community sources**:

| Solution Source     | Reliability | Verification Method                     |
| :------------------ | :---------- | :--------------------------------- --    |
| **Stack Overflow (top-rated)** | High | Check upvote count, accepted answer |
| **GitHub Issues (maintainer)** | High | Check issue status, official response |
| **Official Documentation** | High | Match current API version             |
| **Community Gist/Example** | Medium | Verify against official docs          |
| **Blog Post**       | Low-Medium  | Check author credentials, date        |

### 4. Security-Aware Research

**Always consider security implications**:

```zsh
# Check for security advisories
echo "=== Security Advisory Check ==="

# npm audit
npm audit 2>/dev/null | grep -E "(High|Critical)" || echo "No high/critical advisories"

# Check for known vulnerabilities
echo "Checking npm advisories for $ISSUE_LIBRARY..."
npm audit --json 2>/dev/null | jq -r '.advisories[] | select(.module_name == "$ISSUE_LIBRARY") | {title, severity, url}'

# Security-focused search
brave-search "security vulnerability $ISSUE_LIBRARY $ISSUE_ERROR"
```

### 5. Solution Scoring Matrix

**Evaluate potential solutions**:

| Criteria              | Weight | Scoring (1-5) | Notes                          |
| :--------------------- | :----- | :----------- | :----------------------------    |
| **Effectiveness**     | 30%    | [1-5]        | Does it fix the issue?         |
| **Maintainability**   | 25%    | [1-5]        | Is code clear and documented?  |
| **Security**          | 20%    | [1-5]        | No vulnerabilities introduced? |
| **Performance**       | 15%    | [1-5]        | No regression in speed?        |
| **Compatibility**     | 10%    | [1-5]        | Works with existing code?      |

### 6. Research Sign-Off

Before implementing a fix, verify:

- [ ] At least 2-3 research sources consulted
- [ ] Community-vetted solution identified
- [ ] Security implications evaluated
- [ ] Potential solution scored using matrix
- [ ] Alternative approaches considered
- [ ] Solution documented with source references

---

## Fix Implementation Phase

**Objective**: Implement the fix following project standards while maintaining code quality and security.

### 1. Pre-Implementation Checklist

**Verify environment and prepare**:

- [ ] Reproduction case confirmed working
- [ ] Root cause hypothesis validated
- [ ] Solution research completed
- [ ] Solution scored and approved
- [ ] Backup of affected files created
- [ ] New branch created for fix

### 2. Fix Strategy

**Choose appropriate fix approach**:

| Fix Type            | When to Use                                    | Example                              |
| :------------------- | :------------------------------------------- | :--------------------------------- -- |
| **Bug Fix**         | Incorrect behavior with known cause           | `if (user === null)` → `if (!user)` |
| **Refactor**        | Code quality improvement needed               | Extract function, rename variable   |
| **Enhancement**     | Feature improvement or new capability         | Add config option, support new type |
| **Dependency Update** | Fix caused by library version               | `npm update $LIBRARY`               |
| **Configuration**   | Issue resolved via config change              | Update `.env`, `tsconfig.json`      |

### 3. Implementation Guidelines

**Follow these rules**:

```typescript
// ✓ GOOD: Minimal, focused change
function getUserById(id: string): User {
  if (!id) {
    throw new Error('User ID is required');
  }
  return database.findUser(id);
}

// ✗ BAD: Unnecessary changes mixed with fix
function getUserById(id: string): User {
  // Changed function signature
  if (!id || typeof id !== 'string') {  // Added type check (not needed for bug)
    throw new Error('User ID is required');
  }
  // Changed error message format
  const user = database.findUser(id);
  if (!user) {
    throw new Error('USER_NOT_FOUND');  // Changed error format
  }
  return user;
}
```

### 4. License Compliance Check

**Verify license compatibility**:

```zsh
# Check license of any new/updated dependencies
echo "=== License Compliance Check ==="

# Check project license
echo "Project License: $(cat LICENSE | head -5)"

# Check updated dependencies
npm ls --json 2>/dev/null | jq -r '.dependencies | keys[]' | while read dep; do
  echo -n "$dep: "
  npm view "$dep" license 2>/dev/null || echo "UNKNOWN"
done | grep -E "(MIT|Apache|BSD|GPL)" | head -20
```

### 5. Code Quality Standards

**Apply project formatting**:

```bash
# Run formatting before commit
npx prettier --write "src/**/*.{ts,tsx,js,jsx,json,md}"

# Check TypeScript types
npx tsc --noEmit

# Run linter
npm run lint -- --fix
```

### 6. Implementation Sign-Off

Before verification, verify:

- [ ] Fix is minimal and focused
- [ ] Code follows project standards
- [ ] License compliance verified
- [ ] No unnecessary changes included
- [ ] Formatting applied
- [ ] Types and lints pass

---

## Verification & Validation Phase

**Objective**: Confirm the fix resolves the original issue and meets quality standards.

### 1. Automated Test Execution

**Run relevant test suite**:

```zsh
#!/bin/bash
# Verification Test Script

echo "=== Verification Tests ==="

# Unit tests for fixed component
echo "1. Running unit tests for fixed module..."
npm test -- --testPathPattern="fixed-component" --coverage=false

# Full test suite
echo "2. Running full test suite..."
npm test -- --passWithNoTests 2>&1 | tail -20

# Type checking
echo "3. Type checking..."
npx tsc --noEmit

# Linting
echo "4. Linting..."
npm run lint 2>&1

# Security check
echo "5. Security audit..."
npm audit --audit-level=moderate 2>&1 | tail -10
```

### 2. Reproduction Re-Execution

**Verify issue is resolved**:

```zsh
#!/bin/bash
# Reproduction Re-Execution Script

echo "=== Reproduction Re-Execution ==="
echo "Original Issue: $ISSUE_ID"
echo "Date: $(date)"
echo ""

# Run original reproduction steps
npm run test-reproduction 2>&1

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Issue RESOLVED - Reproduction now passes"
    exit 0
else
    echo ""
    echo "✗ Issue NOT RESOLVED - Reproduction still fails"
    exit 1
fi
```

### 3. Edge Case Testing

**Test boundary conditions**:

```typescript
// Edge cases to test
describe('Edge Cases', () => {
  it('should handle null input', () => {
    expect(processInput(null)).toBe(null);
  });

  it('should handle empty input', () => {
    expect(processInput('')).toBe('');
  });

  it('should handle max value', () => {
    expect(processInput(Number.MAX_VALUE)).toBe(someExpectedValue);
  });

  it('should handle invalid format', () => {
    expect(() => processInput('invalid')).toThrow();
  });
});
```

### 4. Manual Verification Checklist

**Review the changes**:

- [ ] Original issue behavior no longer occurs
- [ ] All test cases pass
- [ ] Code is readable and maintainable
- [ ] No new warnings introduced
- [ ] Error messages are clear and helpful
- [ ] Documentation updated if needed

### 5. Verification Sign-Off

Before regression testing, verify:

- [ ] Original issue reproduced and confirmed fixed
- [ ] Automated tests pass
- [ ] Type checking passes
- [ ] Linting passes
- [ ] Edge cases tested
- [ ] Security audit passes

---

## Regression Testing Phase

**Objective**: Ensure the fix doesn't break existing functionality across the codebase.

### 1. Regression Test Strategy

**Define test scope based on fix impact**:

| Fix Scope           | Test Coverage Required                         | Estimated Time |
| :------------------- | :------------------------------------------- | :-------------- |
| **Single Function**  | Function tests + related module tests          | 15-30 min      |
| **Module**           | Module tests + integration tests               | 30-60 min      |
| **Core Component**   | All related tests + E2E scenarios              | 1-2 hours      |
| **Framework/Library**| Full test suite + compatibility tests          | 4+ hours       |

### 2. Automated Regression Suite

**Run comprehensive tests**:

```zsh
#!/bin/bash
# Regression Test Suite

echo "=== Regression Testing ==="
echo "Date: $(date)"
echo ""

PASS=0
FAIL=0

# 1. Unit Tests
echo "1. Unit Tests"
if npm test -- --runInBand 2>&1 | grep -q "PASS"; then
    echo "   ✓ Unit tests passed"
    ((PASS++))
else
    echo "   ✗ Unit tests failed"
    ((FAIL++))
fi

# 2. Integration Tests
echo "2. Integration Tests"
npm run test:integration 2>&1 | tail -5

# 3. E2E Tests (if applicable)
echo "3. E2E Tests"
npm run test:e2e 2>&1 | tail -10

# 4. Performance Tests
echo "4. Performance Tests"
npm run test:performance 2>&1 | tail -5

# 5. Accessibility Tests (if applicable)
echo "5. Accessibility Tests"
npm run test:a11y 2>&1 | tail -5

# Summary
echo ""
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
```

### 3. Integration Points Check

**Verify integrations still work**:

```zsh
# Check API integrations
echo "=== Integration Check ==="

# 1. Database connections
npm run test:db-connection 2>&1 | tail -5

# 2. External API calls
npm run test:external-apis 2>&1 | tail -10

# 3. Authentication flows
npm run test:auth-flows 2>&1 | tail -10

# 4. Message queue processing
npm run test:queues 2>&1 | tail -10
```

### 4. Backward Compatibility Check

**Verify no breaking changes**:

```typescript
// Check public API signatures
describe('Backward Compatibility', () => {
  it('should maintain existing function signatures', () => {
    // Verify exports haven't changed
    expect(typeof exports.someFunction).toBe('function');
  });

  it('should not break existing config format', () => {
    // Verify config schema unchanged
    const config = loadConfig();
    expect(config).toEqual(expectedSchema);
  });
});
```

### 5. Regression Testing Sign-Off

Before completion, verify:

- [ ] All existing tests pass
- [ ] Integration points verified
- [ ] No breaking changes introduced
- [ ] Performance not degraded
- [ ] Security not compromised

---

## Documentation & Prevention Phase

**Objective**: Document the fix and implement measures to prevent similar issues.

### 1. Fix Documentation Template

**Document the fix comprehensively**:

```markdown
## Fix Documentation: [Issue #XXX]

### Problem Summary
[Brief description of the issue and its impact]

### Root Cause
[Detailed explanation of why the issue occurred]

### Solution
[Description of the implemented fix]

### Files Changed
- `src/module/file.ts` - [what changed]

### Testing
- [ ] Reproduction test passes
- [ ] All unit tests pass
- [ ] Integration tests pass

### Related
- Issue: #XXX
- PR: #[PR Number]
- Commit: [hash]

### Date
[YYYY-MM-DD]
```

### 2. Test Coverage Enhancement

**Add tests to prevent regression**:

```typescript
// Example: Add comprehensive test coverage
describe('Fixed Component', () => {
  describe('Original Bug', () => {
    it('should handle the reported edge case', () => {
      // Test that reproduces original bug
    });
  });

  describe('Normal Operation', () => {
    it('should work with valid inputs', () => {
      // Test normal use cases
    });
  });

  describe('Edge Cases', () => {
    it('should handle null/undefined', () => {
      // Test edge cases
    });
  });
});
```

### 3. Code Quality Improvements

**Address underlying issues**:

| Issue Type          | Prevention Strategy                            |
| :------------------- | :------------------------------------------- |
| **Null Reference**   | Add runtime checks, improve type definitions  |
| **Missing Tests**    | Add test templates, increase coverage target  |
| **Configuration**    | Add validation, better error messages         |
| **Documentation**    | Add JSDoc, update README, add examples        |

### 4. Alerting & Monitoring

**Add instrumentation for future issues**:

```typescript
// Add logging for debugging
function processUserData(data: UserData): ProcessedData {
  console.log('[DEBUG] Processing user data:', {
    userId: data.id,
    timestamp: new Date().toISOString(),
    inputSize: JSON.stringify(data).length
  });
  
  try {
    const result = processData(data);
    console.log('[DEBUG] Processing complete', { duration: result.duration });
    return result;
  } catch (error) {
    console.error('[ERROR] Data processing failed:', {
      userId: data.id,
      error: error.message,
      timestamp: new Date().toISOString()
    });
    throw error;
  }
}
```

### 5. Knowledge Sharing

**Document lessons learned**:

```markdown
## Lessons Learned: [Issue #XXX]

### What Went Well
- [ ] Fast reproduction
- [ ] Clear error messages
- [ ] Community solutions available

### What Could Be Better
- [ ] Better test coverage for edge cases
- [ ] More detailed error messages
- [ ] Earlier detection of the issue

### Prevention Actions
- [ ] Add regression test
- [ ] Update documentation
- [ ] Add monitoring alerts
```

### 6. Documentation Sign-Off

Before completion, verify:

- [ ] Fix documented
- [ ] Tests added for regression prevention
- [ ] Code quality improvements made
- [ ] Alerting/monitoring added if needed
- [ ] Knowledge shared

---

## Automation & CI/CD Integration

**Objective**: Automate debugging workflows as part of CI/CD for continuous quality.

### 1. Automated Debugging Pipeline

**Workflow**:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Automated Debugging Pipeline                     │
├─────────────────────────────────────────────────────────────────────┤
│ 1. Issue Detected (Test Failure / Bug Report)                    │
│ 2. Triage Phase - Classify severity and scope                    │
│ 3. Reproduction Phase - Create and verify test case              │
│ 4. Analysis Phase - Root cause identification                    │
│ 5. Research Phase - Find community solutions                     │
│ 6. Fix Phase - Apply minimal, safe fix                           │
│ 7. Verification Phase - Confirm fix works                        │
│ 8. Regression Phase - Ensure no side effects                     │
│ 9. Documentation Phase - Record fix and prevent recurrence       │
│ 10. Commit & Deploy (if all pass)                                 │
└─────────────────────────────────────────────────────────────────────┘
```

### 2. GitHub Actions Integration

**Example `.github/workflows/debug-pipeline.yml`**:

```yaml
name: Automated Debug Pipeline

on:
  pull_request:
    branches: [main, develop]
  workflow_dispatch:
    inputs:
      issue_number:
        description: 'Issue number to debug'
        required: true
        type: number

jobs:
  debug-pipeline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'

      - name: Triage
        run: |
          echo "Running triage..."
          bash .airules/scripts/04-triage.sh "${{ github.event.inputs.issue_number }}"

      - name: Reproduce
        run: |
          echo "Attempting reproduction..."
          bash .airules/scripts/04-reproduce.sh "${{ github.event.inputs.issue_number }}"

      - name: Analyze
        run: |
          echo "Running analysis..."
          bash .airules/scripts/04-analyze.sh "${{ github.event.inputs.issue_number }}"

      - name: Research
        run: |
          echo "Searching for solutions..."
          bash .airules/scripts/04-research.sh "${{ github.event.inputs.issue_number }}"

      - name: Verify
        run: |
          echo "Running verification..."
          bash .airules/scripts/04-verify.sh "${{ github.event.inputs.issue_number }}"

      - name: Regression Test
        run: |
          echo "Running regression tests..."
          bash .airules/scripts/04-regression.sh

      - name: Report
        run: |
          echo "Generating report..."
          bash .airules/scripts/04-report.sh
```

### 3. Pre-Commit Debugging Hook

**Example `.git/hooks/pre-commit`**:

```bash
#!/bin/bash
# Pre-Commit Debug Check

echo "Running pre-commit debug checks..."

# Check for debug statements
DEBUG_STMTS=$(grep -r "console\.(log|debug|info)" . --include="*.ts" --include="*.js" | grep -v "test" | grep -v "__tests__" || true)

if [ -n "$DEBUG_STMTS" ]; then
    echo "⚠ Warning: Debug statements found:"
    echo "$DEBUG_STMTS"
    echo ""
    echo "Consider removing or disabling before commit"
fi

# Check for TODO comments that should be addressed
TODO_ITEMS=$(grep -r "TODO" . --include="*.ts" --include="*.js" --include="*.md" | grep -v "__tests__" | grep -v "TODO.md" || true)

if [ -n "$TODO_ITEMS" ]; then
    echo "⚠ TODO items found (may indicate incomplete work):"
    echo "$TODO_ITEMS"
fi

echo "Debug checks completed"
exit 0
```

### 4. Automated Regression Prevention

**Implement safeguards**:

```yaml
# .github/workflows/coverage.yml
name: Coverage Check

on: [pull_request]

jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests with coverage
        run: npm test -- --coverage
      
      - name: Check coverage threshold
        run: |
          COVERAGE=$(cat coverage/lcov-report/index.html | grep "statement" | head -1 | grep -oE '[0-9]+\.[0-9]+')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage below 80%: $COVERAGE%"
            exit 1
          fi
```

### 5. Automation Best Practices

| Practice                 | Recommendation                                               |
| :------------------------ | :-------------------------------------------------------- |
| **Run frequency**          | On every PR, daily scheduled runs for regression testing  |
| **Timeout limits**         | 1 hour for full pipeline, 15 minutes for quick checks     |
| **Parallel execution**     | Run independent test suites in parallel                   |
| **Artifact retention**     | Keep test outputs, screenshots, and logs for 30 days      |
| **Notification**           | Notify on failure; post summary on success                |

### 6. Automation Sign-Off

Before completing automation, verify:

- [ ] Pipeline configuration created
- [ ] Pre-commit hooks integrated
- [ ] Error handling implemented
- [ ] Timeout limits set
- [ ] Artifact retention configured
- [ ] Notification channels configured

---

## Common Issues & Troubleshooting

### Issue 1: Unreproducible Bug

**Symptoms**: Issue reported but cannot be reproduced in development environment.

**Diagnosis**:

```zsh
#!/bin/bash
# Unreproducible Bug Diagnosis

echo "=== Unreproducible Bug Diagnosis ==="
echo ""

# Check environment differences
echo "1. Environment Comparison"
echo "Reporter's Environment: $REPORTER_ENV"
echo "Dev Environment:"
echo "  OS: $(uname -s)"
echo "  Node: $(node --version)"
echo "  npm: $(npm --version)"

# Check for environment-specific code
echo ""
echo "2. Environment-Specific Code Check"
grep -r "process.platform\|process.arch\|process.env" src/ --include="*.ts" | head -10

# Check for timing issues
echo ""
echo "3. Timing Issue Check"
grep -r "setTimeout\|setInterval\|Promise.delay" src/ --include="*.ts" | head -10
```

**Resolution**:

1. Create exact reproduction environment using Docker
2. Check environment-specific code paths
3. Add verbose logging to trace execution
4. Consider race conditions and timing issues
5. Ask reporter for more details (screenshots, logs, exact steps)

### Issue 2: Fix Introduces New Bug

**Symptoms**: Original issue fixed but new regression occurs.

**Diagnosis**:

```zsh
#!/bin/bash
# Regression Diagnosis

echo "=== Regression Diagnosis ==="
echo ""

# Check what changed
echo "1. Changes Made"
git diff HEAD~1 HEAD --stat

# Run affected tests
echo ""
echo "2. Running Affected Tests"
npm test -- --testNamePattern="affected.*feature" 2>&1

# Check for side effects
echo ""
echo "3. Side Effect Check"
grep -r "import.*$FIXED_MODULE" src/ --include="*.ts" | grep -v test | head -10
```

**Resolution**:

1. Identify which test/regression failed
2. Revert fix and implement more targeted solution
3. Increase test coverage for affected areas
4. Use feature flags to isolate changes

### Issue 3: Security Vulnerability

**Symptoms**: Bug potentially exposes security risk.

**Immediate Actions**:

```zsh
#!/bin/bash
# Security Vulnerability Response

echo "=== SECURITY: Immediate Response ==="
echo ""

# 1. Identify vulnerability type
echo "1. Vulnerability Classification"
grep -E "(password|secret|token|api_key)" error.log | head -5 || echo "No obvious secrets exposed"

# 2. Check affected components
echo ""
echo "2. Affected Components"
grep -oE "(auth|login|admin|config)" error.log | sort | uniq

# 3. Check for CVE
echo ""
echo "3. CVE Check"
curl -s "https://api.github.com/search/issues?q=$ISSUE_LIBRARY+security+CVE" | jq -r '.items[] | .title' | head -10
```

**Resolution**:

1. Assess severity using CVSS scale
2. If critical, follow emergency response protocol
3. Implement fix with security review
4. Add security tests
5. Update documentation

### Issue 4: Performance Degradation

**Symptoms**: Fix resolves issue but causes performance problems.

**Diagnosis**:

```zsh
#!/bin/bash
# Performance Regression Diagnosis

echo "=== Performance Regression Diagnosis ==="
echo ""

# Run benchmarks
echo "1. Performance Benchmarks"
npm run bench 2>&1 | tail -20

# Check memory usage
echo ""
echo "2. Memory Usage"
npm run test:memory 2>&1 | tail -10

# Profile code
echo ""
echo "3. Code Profiling"
npm run profile 2>&1 | head -30
```

**Resolution**:

1. Identify bottleneck using profiling tools
2. Optimize algorithm or data structures
3. Consider caching or memoization
4. Add performance tests to prevent regression

### Issue 5: Incomplete Fix

**Symptoms**: Fix appears to work but doesn't fully resolve issue.

**Diagnosis**:

```zsh
#!/bin/bash
# Incomplete Fix Diagnosis

echo "=== Incomplete Fix Diagnosis ==="
echo ""

# Verify all reproduction steps
echo "1. Reproduction Steps Verification"
cat reproduction-steps.md

# Check for related issues
echo ""
echo "2. Related Issues Check"
grep -r "$ISSUE_COMPONENT" src/ --include="*.ts" | wc -l
```

**Resolution**:

1. Re-analyze root cause
2. Check for related code paths
3. Add more comprehensive tests
4. Consider edge cases missed initially

---

## Quick Reference

### Debugging Commands Reference

| Action                        | Command                                                   |
| :---------------------------- | :-------------------------------------------------------- |
| Run full debug pipeline       | `bash .airules/scripts/04-debug.sh [issue-number]`       |
| Reproduce issue               | `bash .airules/scripts/04-reproduce.sh [issue-number]`   |
| Analyze error                 | `bash .airules/scripts/04-analyze.sh [issue-number]`     |
| Research solution             | `bash .airules/scripts/04-research.sh [issue-number]`    |
| Verify fix                    | `bash .airules/scripts/04-verify.sh [issue-number]`      |
| Run regression tests          | `bash .airules/scripts/04-regression.sh`                 |
| Generate report               | `bash .airules/scripts/04-report.sh`                     |
| Run quick checks              | `npm run debug:quick`                                    |
| Run full test suite           | `npm test -- --runInBand --coverage`                     |

### Triage Checklist

- [ ] Issue type identified
- [ ] Severity level established
- [ ] Reproduction steps documented
- [ ] Environment details captured
- [ ] Related issues checked
- [ ] Assignee identified

### Debug Pipeline Checklist

- [ ] Reproduction created
- [ ] Root cause identified
- [ ] Solution researched
- [ ] Fix implemented
- [ ] Verification passed
- [ ] Regression tests passed
- [ ] Documentation updated

### Quality Gate Checklist

- [ ] All tests pass
- [ ] Type checking passes
- [ ] Linting passes
- [ ] Security audit passes
- [ ] Coverage threshold met
- [ ] No new warnings introduced

---

## Revision History

| Version | Date       | Changes                                                                 |
| :------ | :--------- | :---------------------------------------------------------------------- |
| 1.0     | Initial    | Basic 5-step debug and repair workflow                                 |
| 2.0     | 2026-03-19 | Complete rewrite: added core principles, comprehensive phases, CI/CD integration, troubleshooting guide, and revision history |

---

**End of Debug & Repair Workflow**