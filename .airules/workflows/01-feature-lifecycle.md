# Workflow: Feature Lifecycle

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade, end-to-end process for developing, testing, and deploying new features with proper validation, collaboration, and version control practices

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Pre-Workflow Prerequisites](#pre-workflow-prerequisites)
3. [Discovery Phase](#discovery-phase)
4. [Environment Preparation](#environment-preparation)
5. [Scaffolding Phase](#scaffolding-phase)
6. [Validation Phase](#validation-phase)
7. [Submission Phase](#submission-phase)
8. [Post-Submission](#post-submission)
9. [Common Feature Types & Patterns](#common-feature-types--patterns)
10. [Quick Reference](#quick-reference)

---

## Core Principles

| Principle                 | Description                                                                  | Anti-Pattern to Avoid                                    |
| :------------------------ | :-----------------------------------------------                             | :-----------------------------------------------         |
| **Requirement-First**     | All features must have documented requirements before coding begins          | Implementing without clear requirements or acceptance criteria |
| **Discovery-Driven**      | Research latest patterns and best practices before implementation            | Solving problems with outdated or suboptimal approaches |
| **Environment-Verified**  | MCP servers and environment must be validated before development             | Assuming environment is ready without checking          |
| **Test-First**            | Tests are written or reviewed before implementation (TDD倡导)                | Implementing then attempting to add tests later         |
| **Collaboration-First**   | Handoffs between agents are documented with clear context transfer           | Silent work without status updates or context loss      |
| **Traceability**          | Every feature links to requirements, tests, and deployment artifacts         | Features implemented without traceable documentation    |

---

## Pre-Workflow Prerequisites

Before starting any feature lifecycle, ensure:

### 1. Agent Readiness Checklist

- [ ] **MCP Configuration**: `mcp.json` exists and is configured (see `mcp/config.example.json`)
- [ ] **Environment Variables**: `.env` file exists with required secrets
- [ ] **Git Status**: Clean working directory or documented in-progress changes
- [ ] **Terminal Available**: Docker container or development environment accessible
- [ ] **Task Context**: `PROJECT_CONTEXT.md` is up-to-date

### 2. Requirement Documentation

Every feature requires:

- **Feature Description**: Clear problem statement and business value
- **Acceptance Criteria**: Measurable conditions for success
- **Dependencies**: Any prerequisites or related work
- **Risk Assessment**: Potential impact and mitigation strategies

### 3. Context Handoff Format

When resuming work from a previous session:

```markdown
# Feature: [Feature Name]

## Current Status

- **Phase**: [Discovery/Environment/Scaffolding/Validation/Submission]
- **Progress**: [Percentage complete]
- **Last Session**: [Agent or date]

## Completed Work

- [Completed item 1]
- [Completed item 2]

## Pending Tasks

- [ ] Pending task 1
- [ ] Pending task 2

## Key Decisions

[Any important decisions made]

## Blockers

[Any issues preventing progress]
```

---

## Discovery Phase

**Objective**: Research and document the optimal approach for implementing the feature.

### 1. Requirements Analysis

- [ ] **Feature Scope**: Define clear boundaries and scope
- [ ] **Acceptance Criteria**: Write measurable success conditions
- [ ] **Dependencies**: Identify required libraries, APIs, or data
- [ ] **Constraints**: Note any technical, security, or compliance constraints

### 2. Research Protocol

Use `brave-search` and `context7` to research implementation patterns:

| Research Target       | Search Strategy                                                | Example Queries                                                                 |
| :------------------ | :--------------------------------                                          | :--------------------------------                                               |
| **Latest Framework Patterns** | `site:docs.example.com "best practices" feature name`                       | `site:react.dev "feature flagging" best practices`                             |
| **Library Documentation**    | `site:example.com library API reference`                                    | `site:axios-http.com axios request interceptor best practices`                |
| **Community Solutions**      | `site:stackoverflow.com "how to implement" feature`                         | `site:stackoverflow.com "how to implement rate limiting in express"`          |
| **Security Considerations**  | `site:owasp.org "feature name" security`                                    | `site:owasp.org authentication token security best practices`                 |

### 3. Technical Design Documentation

After research, document:

```markdown
## Technical Design: [Feature Name]

### Approach

[Primary implementation strategy]

### Architecture

- [Component/Module 1] - [Purpose]
- [Component/Module 2] - [Purpose]
- [Integration Point] - [How components interact]

### Dependencies

| Package/Service | Version | Purpose |
| :--------------- | :--------- | :----- |
| example-lib     | ^2.0.0   | [Purpose] |

### Security Considerations

[Any security implications or requirements]

### Performance Considerations

[Any performance implications or requirements]
```

### 4. Discovery Sign-Off

Before proceeding, verify:

- [ ] Requirements are clear and complete
- [ ] Research has identified optimal patterns
- [ ] Technical design is documented
- [ ] Dependencies are identified
- [ ] Risks are assessed and documented

---

## Environment Preparation Phase

**Objective**: Verify and prepare the development environment.

### 1. MCP Server Verification

Check all required MCP servers are available:

```zsh
# Verify Docker is running
docker ps

# Check MCP configuration
cat mcp.json 2>/dev/null || echo "MCP config missing"
```

**Required MCP Servers** (verify against `mcp/config.example.json`):

| Server             | Purpose                              | Verification Command        |
| :----------------- | :--------------------------------- | :------------------------   |
| `filesystem`       | Read/write files, list directories   | `filesystem/list_directory` |
| `search`           | Web searches, documentation lookup   | `search/query`              |
| `context7`         | Documentation queries                | `context7/query`            |
| `github`           | PR creation, issue management        | `github/list_issues`        |
| `devcontainer`     | Container environment verification   | `devcontainer/info`         |

### 2. Secret Verification

Verify required secrets are in `.env` by comparing with `.env.example`:

| Secret              | Required For                          | Verification Check                     |
| :------------------- | :---------------------------------    | :-----------------------------------  |
| `GITHUB_TOKEN`      | PR creation, git operations           | `gh auth status` shows authenticated  |
| `BRAVE_API_KEY`     | Web search via brave-search MCP       | Search query succeeds                 |
| `CONTEXT7_API_KEY`  | Documentation queries                 | Context7 queries succeed              |

**Secrets Checklist**:

```zsh
# Check for missing secrets
! grep -q "^GITHUB_TOKEN=" .env && echo "Missing GITHUB_TOKEN"
! grep -q "^BRAVE_API_KEY=" .env && echo "Missing BRAVE_API_KEY"
! grep -q "^CONTEXT7_API_KEY=" .env && echo "Missing CONTEXT7_API_KEY"
```

### 3. Environment Setup

If MCP configuration is missing:

```zsh
# Create MCP configuration
cp mcp/config.example.json mcp.json

# Restart agent to apply changes
# (Note: Agent restart required - inform user)
```

### 4. Environment Sign-Off

Before proceeding, verify:

- [ ] MCP servers are accessible and responding
- [ ] Required secrets are present in `.env`
- [ ] Docker/container environment is running
- [ ] Git is configured and accessible
- [ ] Development dependencies are available

---

## Scaffolding Phase

**Objective**: Create the feature's file structure and initial implementation.

### 1. File Structure Guidelines

Follow the 4-space indentation and Prettier standards:

| File Type           | Naming Convention    | Indentation | Location Pattern                     |
| :------------------- | :------------------- | :----------- | :----------------------------------- |
| TypeScript/JavaScript | `kebab-case.ts/js` | 4 spaces     | `src/features/{feature-name}/`       |
| Tests               | `*.test.ts/*.spec.ts` | 4 spaces   | `src/features/{feature-name}/tests/` |
| Documentation       | `README.md`         | 4 spaces     | `src/features/{feature-name}/`       |
| Configuration       | `config.json/yaml`  | 4 spaces     | `src/features/{feature-name}/`       |

### 2. Feature Directory Structure

```
src/features/{feature-name}/
├── README.md           # Feature documentation
├── config.json         # Feature configuration (if needed)
├── index.ts            # Main entry point
├── types.ts            # Type definitions
├── utils.ts            # Utility functions (if needed)
└── tests/
    ├── unit/
    │   ├── index.test.ts
    │   └── utils.test.ts (if applicable)
    └── integration/
        └── feature.test.ts
```

### 3. File Creation Checklist

For each file in the structure:

- [ ] File created with correct naming
- [ ] 4-space indentation applied
- [ ] Prettier formatting applied
- [ ] Type definitions included (TypeScript)
- [ ] Error handling implemented
- [ ] Logging levels correct (debug/info/warn/error)
- [ ] TODO comments for incomplete work

### 4. Implementation Standards

#### Code Style Requirements

- **Functions**: <50 lines, single responsibility
- **Imports**: Built-in → External → Internal → Relative
- **Comments**: Explain _why_, not _what_
- **Error Messages**: Descriptive with context
- **Validation**: Input validation on all public functions

#### Type Safety

```typescript
// ✓ Good: Explicit types
interface FeatureConfig {
  enabled: boolean;
  maxRetries: number;
  timeoutMs: number;
}

// ✗ Bad: Using any
interface FeatureConfig {
  enabled: any;
  maxRetries: any;
  timeoutMs: any;
}
```

### 5. Scaffolding Sign-Off

Before proceeding, verify:

- [ ] Directory structure matches pattern
- [ ] All required files created
- [ ] 4-space indentation applied
- [ ] Prettier formatting applied
- [ ] Type definitions complete
- [ ] Initial implementation complete

---

## Validation Phase

**Objective**: Verify the feature works correctly and doesn't break existing functionality.

### 1. Test Strategy

#### Unit Tests

- Test individual functions and components
- Mock external dependencies
- Target >80% coverage

#### Integration Tests

- Test component interactions
- Test API endpoints
- Test data flow

#### Regression Tests

- Verify existing functionality still works
- Test edge cases

### 2. Test Execution

```zsh
# Run unit tests
npm test -- --runTests src/features/{feature-name}/tests/unit

# Run integration tests
npm test -- --runTests src/features/{feature-name}/tests/integration

# Check coverage
npm run coverage
```

### 3. Code Quality Checks

```zsh
# Type checking
npm run type-check

# Linting
npm run lint

# Format verification
npm run format:check
```

### 4. Environment Verification

```zsh
# Docker container status
docker ps

# Container logs (if applicable)
docker logs {container-name} --tail 50

# Health check (if applicable)
curl -f http://localhost:{port}/health || echo "Health check failed"
```

### 5. Validation Sign-Off

Before proceeding, verify:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Type checking passes
- [ ] Linting passes with no errors
- [ ] Code coverage >80%
- [ ] No breaking changes introduced
- [ ] Environment verification passes

---

## Submission Phase

**Objective**: Create a pull request with proper documentation and review.

### 1. Pre-Submission Checklist

- [ ] All validation checks pass
- [ ] Code is formatted (Prettier)
- [ ] Type checking passes
- [ ] Documentation is complete
- [ ] TODO comments are documented with issue references
- [ ] Sensitive data removed
- [ ] Error messages are clear
- [ ] Logging levels are appropriate

### 2. Git Workflow

```zsh
# Create feature branch
git checkout -b feature/{feature-name}-{timestamp}

# Stage changes
git add src/features/{feature-name}/

# Commit with conventional message
git commit -m "feat({feature-name}): implement feature description"
```

### 3. PR Description Template

```markdown
## Summary

[One-paragraph overview of the feature]

## Problem Statement

[What problem does this solve?]

## Solution

[How was the problem solved?]

## Changes

### New Files
- `src/features/{feature-name}/` - Feature implementation

### Modified Files
- [List any modified files]

### Deleted Files
- [List any deleted files]

## Testing

### Unit Tests
- [Test 1]
- [Test 2]

### Integration Tests
- [Test 1]
- [Test 2]

### Manual Testing
- [Manual test steps]

## Configuration

[Any configuration changes or environment variables]

## Security Considerations

[Any security implications]

## Performance Considerations

[Any performance implications]

## Related Issues

- Closes #{issue-number}
- Related to #{related-issue}

## Risk Assessment

[Low/Medium/High] - [Explanation]
```

### 4. GitHub PR Creation

Using the `github` MCP:

```typescript
// Create PR via MCP
github.create_issue({
  owner: "toxicoder",
  repo: "ezrepo",
  title: "feat: implement {feature-name}",
  body: "[PR description]",
  labels: ["feature", "ready-for-review"],
  assignees: ["toxicoder"],
  milestone: null,
  draft: false
});
```

### 5. Submission Sign-Off

Before finalizing:

- [ ] All checks pass
- [ ] PR description complete
- [ ] Labels applied correctly
- [ ] Assignees set appropriately
- [ ] Milestone set (if applicable)

---

## Post-Submission

**Objective**: Handle PR review and merge preparation.

### 1. Review Response Protocol

When feedback is received:

1. **Acknowledge**: Respond to all comments
2. **Clarify**: Ask for clarification on ambiguous feedback
3. **Implement**: Make requested changes
4. **Test**: Re-run validation checks
5. **Commit**: Push updates to feature branch

### 2. Merge Readiness

Before merging:

- [ ] All review comments addressed
- [ ] All CI checks passing
- [ ] No merge conflicts
- [ ] Branch is up-to-date with base
- [ ] Documentation updated if needed

### 3. Post-Merge Actions

- [ ] Delete feature branch (optional cleanup)
- [ ] Update `PROJECT_CONTEXT.md` with feature status
- [ ] Document lessons learned
- [ ] Update related documentation

### 4. Rollback Procedure

If issues are discovered post-merge:

```zsh
# Revert commit
git revert HEAD

# Or restore previous commit
git reset --hard HEAD~1
```

---

## Common Feature Types & Patterns

### Feature Type Matrix

| Feature Type        | Discovery Focus                        | Scaffolding Pattern                   | Validation Priority        |
| :------------------- | :----------------------------------- | :----------------------------------- | :------------------------- |
| **New API Endpoint** | REST/GraphQL best practices            | `src/api/endpoints/{endpoint}/`      | Integration tests, auth    |
| **New UI Component** | Component library patterns             | `src/components/{component}/`        | Visual regression, unit    |
| **Database Feature** | ORM best practices, migrations         | `src/models/{model}/`                | Data integrity, queries    |
| **Background Job**   | Queue/job processor patterns           | `src/jobs/{job}/`                    | Retry logic, error handling|
| **Configuration**    | Config management patterns             | `src/config/{feature}.json`          | Validation, defaults       |

### Template Files

#### New Feature Template

```typescript
// src/features/{feature-name}/index.ts
/**
 * Feature: {Feature Name}
 * Description: {Brief description}
 * Version: 1.0.0
 */

// Dependencies
import { logger } from '@/utils/logger';

// Types
export interface FeatureConfig {
  enabled: boolean;
}

// Configuration
export const defaultConfig: FeatureConfig = {
  enabled: true,
};

/**
 * Initialize the feature
 */
export function initialize(config: FeatureConfig = defaultConfig): void {
  if (!config.enabled) {
    logger.info('Feature disabled');
    return;
  }
  logger.info('Feature initialized');
}

/**
 * Cleanup feature resources
 */
export function cleanup(): void {
  logger.info('Feature cleanup');
}
```

---

## Quick Reference

### Common Commands

| Action                              | Command                                                                 |
| :---------------------------------- | :--------------------------------------------------------------------              |
| Check MCP configuration              | `cat mcp.json 2>/dev/null || echo "MCP config missing"`                |
| Verify environment variables         | `grep -E "^(GITHUB_TOKEN|BRAVE_API_KEY|CONTEXT7_API_KEY)=" .env`       |
| Run all tests                        | `npm test -- --runTests src/features/{feature-name}`                   |
| Check code quality                   | `npm run lint && npm run type-check`                                   |
| Format code                          | `npm run format`                                                       |
| Create feature branch                | `git checkout -b feature/{feature-name}-{timestamp}`                   |
| Commit changes                       | `git add . && git commit -m "feat({feature-name}): {description}"`     |
| View git status                      | `git status`                                                           |
| View recent commits                  | `git log --oneline -10`                                                |

### Critical Files

| File                      | Purpose                                         |
| :------------------------- | :----------------------------------------------- |
| `PROJECT_CONTEXT.md`      | Current project status and milestones           |
| `AGENTS.md`               | Project-wide agent instructions                 |
| `mcp/config.example.json` | MCP server configuration template              |
| `.env.example`            | Environment variable template                  |
| `.gitignore`              | Git ignore rules                               |
| `src/features/{feature}/` | New feature implementation directory           |

### Workflow Decision Tree

```
Start Feature
    │
    ├─→ Requirements Clear?
    │   ├─ No → Document requirements first
    │   └─ Yes → Discovery Phase
    │
    ├─→ MCP Servers Running?
    │   ├─ No → Verify/Configure MCP
    │   └─ Yes → Environment Preparation
    │
    ├─→ Secrets Present?
    │   ├─ No → Add to .env
    │   └─ Yes → Scaffolding Phase
    │
    ├─→ Tests Passing?
    │   ├─ No → Fix issues
    │   └─ Yes → Submission Phase
    │
    └─→ PR Merged?
        ├─ No → Address review feedback
        └─ Yes → Post-Merge Actions
```

### Error Handling Flow

```
Error Encountered
    │
    ├─→ Environment Error?
    │   ├─ Yes → Check MCP config, .env, Docker status
    │   └─ No → Continue
    │
    ├─→ Code Error?
    │   ├─ Yes → Debug, fix, re-test
    │   └─ No → Continue
    │
    ├─→ Test Error?
    │   ├─ Yes → Fix code or update tests
    │   └─ No → Continue
    │
    └─→ Documentation Error?
        ├─ Yes → Update docs
        └─ No → Continue
```

---

## Revision History

| Version | Date       | Changes                                                                 |
| :------ | :--------- | :---------------------------------------------------------------------- |
| 1.0     | Initial    | Basic 5-step workflow                                                  |
| 2.0     | 2026-03-19 | Complete rewrite: added core principles, prerequisites, phases, checklists, templates, quick reference, and revision history |

---

**End of Feature Lifecycle Workflow**