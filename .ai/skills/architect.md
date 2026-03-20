# Skill: System Architect

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade framework for ensuring all code adheres to the project's strict formatting and architectural standards

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Workflow Pipeline](#workflow-pipeline)
3. [Tool Selection Matrix](#tool-selection-matrix)
4. [Code Quality Standards](#code-quality-standards)
5. [Architecture Enforcement](#architecture-enforcement)
6. [Documentation Requirements](#documentation-requirements)
7. [Error Handling & Fallbacks](#error-handling--fallbacks)
8. [Verification & Validation](#verification--validation)
9. [Best Practices Checklist](#best-practices-checklist)

---

## Core Principles

| Principle                 | Description                                                           | Anti-Pattern to Avoid                                            |
| :------------------------ | :------------------------------------------------------------------- | :-------------------------------------------------------------- |
| **Format Consistency**    | Every file must use 4-space indentation and Prettier formatting       | Mixed indentation, manual formatting, or no formatter applied  |
| **Tool Isolation**        | External AI features (Copilot, etc.) must remain disabled for purity  | Relying on external AI instead of agent's native capabilities  |
| **Traceability**          | All architectural decisions and changes must be documented            | Making changes without recording rationale or impact           |
| **Project Integrity**     | Maintain consistent architecture patterns across all modules          | Introducing inconsistent patterns that fragment the codebase   |
| **Self-Documentation**    | Code should be self-explanatory; comments explain why, not what       | Over-commenting obvious code or under-commenting complex logic |
| **Continuous Alignment**  | Architectural standards evolve; ensure new code aligns with current standards | Writing legacy-pattern code that contradicts current architecture |

---

## Workflow Pipeline

### Phase 1: Analysis & Inspection

**Objective**: Evaluate current codebase state before making changes

#### Actions

1. **Read existing files**
   - Examine file contents before any modifications
   - Identify current formatting style and patterns
   - Detect any pre-existing structural issues

2. **Architecture assessment**
   - Review module boundaries and dependencies
   - Identify potential coupling or tight dependencies
   - Verify alignment with documented architecture

3. **Format baseline**
   - Document current indentation style (2-space vs 4-space)
   - Check for Prettier configuration presence
   - Identify files that violate formatting standards

#### Output

- Current state assessment report
- List of format violations found
- Architecture improvement opportunities

### Phase 2: Code Modification

**Objective**: Apply changes while enforcing architectural standards

#### Actions

1. **Format enforcement**
   - Apply 4-space indentation universally
   - Ensure Prettier compatibility
   - Maintain consistent line endings (Unix `\n`)
   - Keep line length ≤80 characters where reasonable

2. **Structure optimization**
   - Break large functions into smaller, focused units
   - Improve naming clarity
   - Reduce nesting and complexity
   - Add proper error handling

3. **Tool verification**
   - Ensure `github.copilot` remains disabled in `.vscode/settings.json`
   - Verify other AI features (Copilot Chat, ChatCody, etc.) are disabled
   - Confirm settings are committed to version control

#### Output

- Modified files meeting format standards
- Architecture-compliant code structure
- Verified tool isolation configuration

### Phase 3: Documentation Update

**Objective**: Record architectural changes and decisions

#### Actions

1. **Update PROJECT_CONTEXT.md**
   - Document architectural modifications
   - Record new milestones or significant changes
   - Add rationale for major design decisions

2. **Add version tracking**
   - Include update timestamp
   - Document version number for context
   - Track breaking changes

3. **Archive decisions**
   - Document rejected alternatives with rationale
   - Note temporary workarounds with TODOs
   - Record technical debt with prioritization

#### Output

- Updated PROJECT_CONTEXT.md
- Clear audit trail of decisions
- Archived design alternatives

---

## Tool Selection Matrix

| Task                              | Primary Tool       | Fallback                   | When to Use                                      | Notes                                       |
| :-------------------------------- | :----------------- | :------------------        | :---------------------------------------------- | :--------------------------------------       |
| Read existing code                | `read_file`        | `execute_command` (cat)    | Before making any changes                        | Get exact current state                     |
| Write modified code               | `write_file`       | `execute_command` (echo)   | Initial file creation or full rewrite          | Use for complete file replacements          |
| Targeted edits                    | `replace_in_file`  | Manual diff editing        | Small, localized changes                        | Use for surgical modifications              |
| List directory contents           | `list_directory`   | `execute_command` (ls)     | Explore project structure                        | Identify relevant files and directories     |
| Search code patterns              | `search_files`     | `execute_command` (grep)   | Find specific implementations or patterns      | Use regex for complex pattern matching      |
| List code definitions             | `list_code_definition_names` | Manual inspection      | Understand architecture at a glance              | Get classes, functions, methods overview   |
| Edit VS Code settings             | `read_file` + `write_file` | `execute_command`       | Verify/disable AI features                      | Update `.vscode/settings.json`              |
| Update project context            | `read_file` + `write_file` | `replace_in_file`       | Document architectural changes                  | Update `PROJECT_CONTEXT.md`                 |
| Check git status                  | `execute_command`  | Built-in VCS integration   | Verify changes before commit                    | `git status`, `git diff`                    |

---

## Code Quality Standards

### Indentation & Syntax

| Standard              | Requirement                                        | Example                                  |
| :-------------------- | :-------------------------------                    | :---------------                         |
| **Indentation**       | 4 spaces per level; no tabs                       | `    // 4 spaces`                        |
| **Line length**       | Max 80 characters per line                        | Split long lines appropriately          |
| **Line endings**      | Unix-style (`\n`) only                            | No `\r\n` or `\r`                        |
| **Trailing whitespace** | Remove all trailing spaces                       | Clean lines end with content only       |
| **Semicolons**        | Always use in JavaScript/TypeScript               | `const value = 42;`                      |

### Naming Conventions

| Element                      | Style                        | Examples                                    |
| :--------------------------- | :--------------------------- | :------------------------------------------ |
| **Files**                    | `kebab-case`                 | `user-service.ts`, `api-client.js`          |
| **Directories**              | `kebab-case`                 | `src/services`, `test/integration`          |
| **Variables**                | `camelCase`                  | `userName`, `isLoading`, `maxRetries`       |
| **Functions**                | `camelCase`                  | `getUserData()`, `handleClick()`            |
| **Classes/Types/Interfaces** | `PascalCase`                 | `UserService`, `UserProfile`, `ITokenStore` |
| **Constants**                | `UPPER_SNAKE_CASE`           | `MAX_RETRIES`, `API_URL`, `DEFAULT_TIMEOUT` |
| **Private Members**          | `camelCase` with `_` prefix  | `_privateMethod()`, `_internalState`        |
| **Booleans**                 | `is`, `has`, `should` prefix | `isLoading`, `hasError`, `shouldUpdate`     |

### Code Structure

#### Function Design
- Keep functions focused (<50 lines ideal)
- Single Responsibility Principle
- Avoid deep nesting
- Use early returns to reduce complexity

#### Error Handling
- Use `try-catch` for async operations
- Validate external inputs
- Provide meaningful error messages with context
- Implement fallbacks where appropriate

#### Documentation
- Comments explain **why**, not **what**
- JSDoc/TSDoc for all public functions
- README files in major directories
- TODO format: `// TODO(#issue): description`

---

## Architecture Enforcement

### VS Code Settings Verification

Ensure `.vscode/settings.json` maintains these settings:

```json
{
  "github.copilot": {
    "enable": {
      "*": false,
      "interactiveChat": false,
      "codeSnippets": false,
      "chat": false,
      "autoComplete": false
    }
  },
  "cody.automaticFileContext": false,
  "copilot.chat": {
    "enable": false
  },
  "telemetry.telemetryLevel": "off"
}
```

### Architectural Patterns

| Pattern           | When to Use                                    | Key Characteristics                          |
| :--------------- | :---------------                               | :---------------                             |
| **Layered**       | Most applications; clear separation of concerns | Presentation, Business Logic, Data layers   |
| **Service-based** | Microservices; independent deployable units    | Single responsibility, clear interfaces      |
| **Event-driven**  | Async processing; decoupled components         | Pub/sub patterns, message queues             |
| **Repository**    | Data access abstraction                        | Interface + implementation separation        |

### Dependency Management

- **Circular dependencies**: Prohibited; use inversion of control
- **Import depth**: Max 3 levels (avoid deep relative imports)
- **Module boundaries**: Clear ownership; no cross-team module access without agreement
- **Version pinning**: Use exact versions for dependencies in `package.json`

---

## Documentation Requirements

### PROJECT_CONTEXT.md Updates

#### Required Sections

1. **Version Header**
   ```markdown
   # Project Context v2.0
   > Updated: 2026-03-19
   ```

2. **Architecture Changes**
   - Description of changes
   - Rationale
   - Impact assessment
   - Migration steps (if applicable)

3. **New Milestones**
   - Feature completion
   - Performance benchmarks
   - Security certifications
   - Deployment milestones

4. **Technical Debt**
   - Documented issues
   - Priority ratings
   - Suggested resolution approach

### File Documentation

Every file should include:

```typescript
/**
 * [Brief purpose description]
 * 
 * @author [Author]
 * @version [Version]
 * @since [Date introduced or modified]
 */

// For functions:
/**
 * [Function purpose]
 * @param [paramName] - [Description]
 * @returns [Description]
 * @throws [Description]
 */
```

---

## Error Handling & Fallbacks

### Common Error Scenarios

| Error Scenario            | Immediate Action                                   | Escalation Path                                                  |
| :------------------------ | :------------------------------------------------- | :--------------------------------------------------------------- |
| **Format conflict**       | Use `replace_in_file` with exact match; re-read if match fails | Report to user; may need manual resolution                     |
| **Architecture mismatch** | Halt; report conflict with documented standards   | User decision: adapt standards or adjust approach              |
| **File not found**        | Verify path via `list_directory`                  | Search for alternative naming or structure                     |
| **Tool misconfiguration** | Check `.vscode/settings.json` validity            | Restore default settings or user-specific config              |
| **Permission denied**     | Check file permissions, use `sudo` if necessary   | Report; may require user intervention                          |

### Retry Strategy

```zsh
# Pattern: Verify before modify
[ -f /path/to/file ] && read_file || echo "File not found: /path/to/file"

# Pattern: Format verification
# Always verify formatting after changes before proceeding
```

### Logging Requirements

Every architecture enforcement should log:

```markdown
## Architecture Enforcement Log

- **Timestamp**: YYYY-MM-DD HH:MM:SS
- **File Modified**: [path]
- **Changes Made**: [description]
- **Standards Enforced**: [list]
- **Warnings**: [any issues encountered]
- **PROJECT_CONTEXT Updated**: [yes/no]
```

---

## Verification & Validation

### Automated Checks

Run these after each architecture enforcement:

#### Format Verification Checklist

- [ ] **Indentation**: 4 spaces used consistently
- [ ] **Line length**: All lines ≤80 characters
- [ ] **Line endings**: Unix-style (`\n`) only
- [ ] **Trailing whitespace**: None present
- [ ] **Semicolons**: Present in all JavaScript/TypeScript statements
- [ ] **Prettier compatibility**: No formatting issues reported

#### Architecture Verification Checklist

- [ ] **No copilot**: `github.copilot.enable.*` set to `false`
- [ ] **Module boundaries**: No circular dependencies
- [ ] **Import depth**: ≤3 levels
- [ ] **Naming conventions**: Files/directories use `kebab-case`
- [ ] **Function length**: Critical functions <50 lines
- [ ] **Error handling**: Try-catch blocks for async operations

#### Documentation Verification Checklist

- [ ] **PROJECT_CONTEXT**: Updated with changes
- [ ] **Version tracking**: Timestamp and version number included
- [ ] **Rationale documented**: Key decisions explained
- [ ] **TODOs added**: Temporary workarounds documented
- [ ] **Architecture diagram**: Updated if applicable

### Manual Verification

When uncertainty exists:

1. **Code review**: Does the code follow established patterns?
2. **Architecture review**: Does it align with documented structure?
3. **Test execution**: Do related tests still pass?
4. **Format verification**: Run Prettier and verify no changes

### Success Criteria

Architecture enforcement is successful when:

- All files meet formatting standards
- No external AI tools enabled
- PROJECT_CONTEXT accurately reflects changes
- No architecture violations introduced
- All tests continue to pass

---

## Best Practices Checklist

### Pre-Modification Checklist

- [ ] Read existing file contents
- [ ] Assess current architecture alignment
- [ ] Check for format violations
- [ ] Verify VS Code settings
- [ ] Identify related files that may need updates

### During Modification Checklist

- [ ] Apply 4-space indentation
- [ ] Enforce Prettier compatibility
- [ ] Maintain architecture patterns
- [ ] Add/updated relevant comments
- [ ] Verify tool isolation settings

### Post-Modification Checklist

- [ ] Format verified (Prettier run)
- [ ] Architecture review completed
- [ ] PROJECT_CONTEXT updated
- [ ] Related tests executed
- [ ] Documentation reviewed

### Emergency Stop Checklist

If encountering unexpected issues:

- [ ] **Check logs**: What was the last successful operation?
- [ ] **Verify settings**: Is copilot or external AI somehow enabled?
- [ ] **Review standards**: Are current standards clear and documented?
- [ ] **Report**: Document exactly what failed and when

---

## Quick Reference

### Common Formatting Patterns

```typescript
// ✓ Correct: 4-space indentation
function example() {
    const value = 42;
    if (value > 0) {
        console.log("Positive");
    }
}

// ✗ Incorrect: Mixed indentation
function example() {
  const value = 42;
        if (value > 0) {
    console.log("Positive");
        }
}
```

### Common Architecture Patterns

```typescript
// ✓ Service-based with clear boundaries
class UserService {
    constructor(private userRepository: UserRepository) {}
    
    async getUser(id: string): Promise<User> {
        return await this.userRepository.findById(id);
    }
}

// ✗ Tight coupling (avoid)
class UserService {
    async getUser(id: string): Promise<User> {
        const db = connectToDatabase(); // Bad: creates coupling
        return db.findUserById(id);
    }
}
```

### VS Code Settings Template

```json
{
  "editor.tabSize": 4,
  "editor.insertSpaces": true,
  "files.eol": "\n",
  "editor.formatOnSave": true,
  "prettier.singleQuote": true,
  "prettier.semi": true,
  "github.copilot": {
    "enable": {
      "*": false,
      "interactiveChat": false,
      "codeSnippets": false,
      "chat": false,
      "autoComplete": false
    }
  }
}
```

---

## Revision History

| Version | Date       | Changes                                                                 |
| :------ | :--------- | :---------------------------------------------------------------------- |
| 1.0     | Initial    | Minimal 3-point workflow outline                                       |
| 2.0     | 2026-03-19 | Complete rewrite: added principles, workflow pipeline, tool matrix, code quality standards, architecture enforcement, documentation requirements, error handling, verification, and best practices |

---

**End of System Architect Skill**