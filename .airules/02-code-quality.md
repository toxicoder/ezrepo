# Code Quality & Formatting

- **Indentation**: You MUST use **4 spaces** for all files. Do not use tabs.
- **Prettier Standard**: All code must be compatible with `esbenp.prettier-vscode`. Ensure that "format on save" would not result in large diffs.
- **Clean Code**: Prioritize readability over cleverness. Use descriptive names and follow the established project structure.

## Table of Contents

1. [Naming Conventions](#naming-conventions)
2. [Formatting Standards](#formatting-standards)
3. [Code Structure & Patterns](#code-structure--patterns)
4. [Documentation Standards](#documentation-standards)
5. [Error Handling](#error-handling)
6. [Type Safety](#type-safety)
7. [Testing Requirements](#testing-requirements)
8. [Performance Considerations](#performance-considerations)
9. [Accessibility (Web Projects)](#accessibility-web-projects)
10. [Security Practices](#security-practices)

---

## Naming Conventions

| Element                      | Style                        | Examples                                    | Rationale                        |
| :--------------------------- | :--------------------------- | :------------------------------------------ | :------------------------------- |
| **Files**                    | `kebab-case`                 | `user-service.ts`, `api-client.js`          | Consistent file system structure |
| **Directories**              | `kebab-case`                 | `src/services`, `test/integration`          | Clear project organization       |
| **Variables**                | `camelCase`                  | `userName`, `isLoading`, `maxRetries`       | JavaScript/TypeScript convention |
| **Functions**                | `camelCase`                  | `getUserData()`, `handleClick()`            | JavaScript/TypeScript convention |
| **Classes/Types/Interfaces** | `PascalCase`                 | `UserService`, `UserProfile`, `ITokenStore` | Language standard                |
| **Constants**                | `UPPER_SNAKE_CASE`           | `MAX_RETRIES`, `API_URL`, `DEFAULT_TIMEOUT` | Immediate visual identification  |
| **Private Members**          | `camelCase` with `_` prefix  | `_privateMethod()`, `_internalState`        | Clear visibility indication      |
| **Booleans**                 | `is`, `has`, `should` prefix | `isLoading`, `hasError`, `shouldUpdate`     | Intent clarity                   |

---

## Formatting Standards

### Line Length & Structure

- **Maximum line length**: 80 characters per line
- **Line endings**: Unix-style (`\n`) - no Windows (`\r\n`) or Mac (`\r`)
- **Trailing whitespace**: Remove all trailing whitespace on save
- **Blank lines**: Use sparingly; max 2 consecutive blank lines between sections

### Braces & Parentheses

```typescript
// ✓ Correct
if (condition) {
  doSomething();
}

function handleClick(event: MouseEvent) {
  // ...
}

// ✗ Incorrect (spaces, placement)
if (condition) {
  doSomething();
}
```

### Imports & Dependencies

**Order and grouping**:

```typescript
// 1. Built-in modules (Node.js) or languages
import { useState, useEffect } from "react";

// 2. External packages
import express from "express";
import mongoose from "mongoose";

// 3. Internal imports (absolute paths preferred)
import { UserService } from "@/services/user";
import { Logger } from "@/utils/logger";

// 4. Relative imports (last resort)
import { helper } from "../utils/helper";
```

### Quotes & Strings

- Prefer **single quotes** for string literals: `'hello'`
- Use **template literals** for string interpolation: `Hello, ${name}!`
- Use **double quotes** only when strings contain apostrophes: `"I'm here"`

### Semicolons

- **Always use semicolons** at the end of statements
- Avoid ASI (Automatic Semicolon Insertion) pitfalls

```typescript
// ✓ Correct
const value = 42;
return value;

// ✗ Incorrect
const value = 42;
return value;
```

---

## Code Structure & Patterns

### Function Design

- **Keep functions focused** on a single responsibility (ideally < 50 lines)
- **Single Responsibility Principle**: Each function should do one thing well
- **DRY Principle**: Avoid code duplication; extract common logic into reusable functions
- **Explicit over implicit**: Prefer clear, explicit code over clever one-liners

### Control Structures

```typescript
// ✓ Clear, explicit conditions
if (user && user.isActive && user.permissions.includes("admin")) {
  grantAccess();
}

// ✗ Complex chained conditions in single line
user?.isActive && user.permissions?.includes("admin") ? grantAccess() : null;
```

### Error Handling

- Use `try-catch` blocks for async operations (API calls, database operations)
- Handle errors gracefully with meaningful messages
- Validate external inputs before processing

### Return Statements

- Return early to reduce nesting
- Use nullish coalescing (`??`) for default values

```typescript
// ✓ Early return pattern
function processUser(user) {
  if (!user) return null;
  if (!user.isActive) return null;
  return transformUser(user);
}

// ✗ Deep nesting
function processUser(user) {
  if (user) {
    if (user.isActive) {
      return transformUser(user);
    }
  }
  return null;
}
```

---

## Documentation Standards

### Comment Guidelines

- Add comments for **complex logic**, not obvious code
- Prefer **self-documenting code** through good naming
- Comments should explain **why**, not **what**

### JSDoc/TSDoc Requirements

Document all public functions, classes, and interfaces with proper docblocks:

```typescript
/**
 * Fetches user data by ID from the API.
 * @param userId - The unique identifier of the user
 * @returns Promise<User> - The user object
 * @throws Error - If user is not found or API request fails
 */
async function getUserById(userId: string): Promise<User> {
  // Implementation
}
```

### README Files

- Include a `README.md` in each major directory
- Explain the directory's purpose and contents
- Document how to run tests and examples

### TODO Comments

Use consistent format:

```typescript
// TODO: Refactor this function to use async/await
// TODO(#42): Fix authentication token expiry issue
```

### Inline Comments

- Use sparingly
- Only for non-obvious implementation details
- Place on line above or same line (if comment is brief)

---

## Error Handling

### Error Messages

- Throw meaningful errors with **descriptive messages**
- Include relevant context in error messages

```typescript
// ✓ Good
throw new Error(`User not found: ID=${userId}, email=${email}`);

// ✗ Bad
throw new Error("User error");
```

### Logging Levels

Use consistent log levels with relevant context:
| Level | Use Case | Example |
| :---- | :------- | :------ |
| `debug` | Development details | `DEBUG: Cache miss for key=${key}` |
| `info` | Normal operations | `INFO: User logged in: ${userId}` |
| `warn` | Unexpected but handled | `WARN: Deprecated API version used` |
| `error` | Errors and failures | `ERROR: Database connection failed` |

### Validation

- Validate all external inputs before processing
- Provide clear error messages for invalid data
- Fail fast with informative errors

### Fallbacks

- Provide sensible fallbacks when data or services are unavailable
- Never let errors crash the application without recovery
- Implement retry logic for transient failures

---

## Type Safety

### TypeScript/JavaScript

- Enable **strict type checking** with `strict: true` in `tsconfig.json`
- **Avoid `any` types**; use `unknown` or proper types instead
- Define interfaces for complex data structures
- Use enums for fixed value sets

```typescript
// ✓ Type-safe
interface User {
  id: string;
  name: string;
  role: "admin" | "user" | "guest";
}

// ✗ Unsafe
interface User {
  id: any;
  name: any;
  role: any;
}
```

### Python

- Use **type hints** for all function signatures and variable assignments (PEP 484)
- Run type checkers like `mypy`, `pytype`, or `pyright` in CI
- Consider using `TypedDict` for dictionary structures
- Use `Protocol` for structural subtyping

### General Principles

- Prefer **immutability** where possible
- Use sealed classes/enums for closed sets of values
- Document type invariants in comments or assertions when necessary

---

## Testing Requirements

### Unit Tests

- Write unit tests for all **public functions** and **critical business logic**
- Test edge cases and error conditions

### Test Naming

Use descriptive test names following `function_case_what_it_should_do` pattern:

```typescript
// ✓ Descriptive
describe("getUserById", () => {
  it("should_return_user_when_user_exists", async () => {
    /*...*/
  });
  it("should_throw_error_when_user_not_found", async () => {
    /*...*/
  });
  it("should_handle_database_connection_failures", async () => {
    /*...*/
  });
});

// ✗ Ambiguous
describe("getUserById", () => {
  it("should work", async () => {
    /*...*/
  });
  it("should fail sometimes", async () => {
    /*...*/
  });
});
```

### Test Coverage

- Aim for **>80% coverage** for core logic
- Track coverage in CI/CD pipeline
- Focus on meaningful coverage, not just quantity

### Mocking

- Use mocks for external dependencies (APIs, databases)
- Keep mocks focused and specific to the test
- Validate mock behavior in tests

### Integration Tests

- Test component interactions
- Cover critical user flows
- Test error scenarios across system boundaries

---

## Performance Considerations

### Efficiency

- Consider **time/space complexity** before implementation
- Avoid unnecessary nested loops and iterations
- Use appropriate data structures for the use case

### Caching

- Cache expensive computations
- Cache frequently accessed data
- Implement cache invalidation strategies

```typescript
// ✓ Cached computation
const computedValue = expensiveCalculation();
cache.set("computedValue", computedValue);

// ✗ Recomputed on every access
function getValue() {
  return expensiveCalculation(); // Called every time
}
```

### Optimization Guidelines

- **Profile before optimizing**; focus on critical paths
- Use lazy loading for heavy components and routes
- Implement pagination for large datasets
- Optimize database queries with proper indexing

### Memory Management

- Clean up event listeners
- Cancel pending requests on unmount (React)
- Release resources when no longer needed

---

## Accessibility (Web Projects)

### ARIA Attributes

- Use proper ARIA attributes for interactive elements
- Ensure screen readers can navigate the interface
- Provide meaningful labels for all interactive elements

### Keyboard Navigation

- Ensure all functionality is accessible via keyboard
- Test tab order and focus management
- Provide visible focus indicators

### Visual Design

- Maintain minimum **4.5:1** text-to-background contrast ratio
- Provide descriptive alt text for all images
- Don't rely solely on color to convey information

### Semantic HTML

- Use proper HTML elements (`<button>`, `<nav>`, `<main>`)
- Use semantic heading hierarchy (`<h1>` through `<h6>`)
- Avoid `<div>` soup when semantic elements exist

---

## Security Practices

### Input Validation

- Sanitize all user inputs before processing
- Validate input types, formats, and ranges
- Use allowlists for expected values

### XSS Prevention

- Escape user-provided content before rendering in the browser
- Use `textContent` instead of `innerHTML` when possible
- Implement Content Security Policy (CSP)

### CORS Configuration

- Configure CORS headers appropriately for API endpoints
- Restrict allowed origins in production
- Avoid using `*` for credentials

### Rate Limiting

- Implement rate limiting for API endpoints where appropriate
- Protect against brute force attacks
- Log rate limit violations for monitoring

### Secrets & Credentials

- Never commit real secrets
- Use `.env` for API keys (already gitignored)
- Rotate credentials regularly
- Log redacted information only

---

## VS Code Specifics

### Formatter

- Use **Prettier** (`esbenp.prettier-vscode`) for all file types
- Configure Prettier to match project standards
- Run Prettier in CI/CD pipeline

### Auto-Save

- Project uses `afterDelay` (1000ms) auto-save
- Assume files are saved frequently
- Design code to handle frequent saves gracefully

### AI Integration

- Built-in VS Code AI features and GitHub Copilot are **fully disabled** by design
- You are the primary intelligence

---

## Quick Reference Checklist

Before committing code, verify:

- [ ] Code is formatted with Prettier
- [ ] No trailing whitespace
- [ ] Indentation is 4 spaces (no tabs)
- [ ] Line length is ≤80 characters
- [ ] Naming follows conventions
- [ ] All public functions are documented
- [ ] Error handling is in place
- [ ] Input validation is complete
- [ ] Tests pass with >80% coverage
- [ ] No `any` types used (TypeScript)
- [ ] Accessibility requirements met (web projects)
- [ ] No hardcoded secrets
- [ ] Security best practices applied

---

**End of Code Quality & Formatting Standards**
