# Agent Collaboration

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a robust, production-grade framework for multi-agent systems, AI-assisted development, and seamless human-AI collaboration

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Agent Communication Protocol](#agent-communication-protocol)
3. [Documentation Standards](#documentation-standards)
4. [Version Control & PR Management](#version-control--pr-management)
5. [Handoff Procedures](#handoff-procedures)
6. [Error Handling & Recovery](#error-handling--recovery)
7. [Security & Trust Boundaries](#security--trust-boundaries)
8. [Best Practices Checklist](#best-practices-checklist)

---

## Core Principles

| Principle                 | Description                                        | Anti-Pattern to Avoid                            |
| :------------------------ | :------------------------------------------------- | :----------------------------------------------- |
| **Autonomous Execution**  | Agents operate independently with clear boundaries | Constant handoffs for simple tasks               |
| **Context Preservation**  | State is explicitly transferred between agents     | Assuming agents "know" previous context          |
| **Explicit Boundaries**   | Clear handoff points and responsibilities          | Overlapping responsibilities causing duplication |
| **Verification-first**    | Each agent validates inputs before proceeding      | Blindly trusting previous agent's outputs        |
| **Progress Transparency** | Task progress is tracked and documented            | "Black box" work without status tracking         |

---

## Agent Communication Protocol

### 1. Context Handoff Format

When transferring work between agents or sessions, use this structure:

```markdown
# Agent Handoff

## Current Status

[Brief overview of current state]

## Pending Tasks

- [ ] Task 1 - [Description]
- [ ] Task 2 - [Description]

## Key Technical Details

- **Technology**: [Stack/component]
- **Configuration**: [Relevant settings]
- **Last Known State**: [What was working/not working]

## Blockers & Questions

1. [Blocker] - [Details]
2. [Question] - [Context needed]

## Next Action

[What the next agent should do]
```

### 2. Session State Management

**Always** include this information when starting a new session:

- Previous agent or session identifier
- Last completed task or milestone
- Files modified in last session
- Any failing tests or errors observed
- Pending approvals or decisions

### 3. Communication Channels

| Channel                  | Purpose                               | When to Use              |
| :----------------------- | :------------------------------------ | :----------------------- |
| `PROJECT_CONTEXT.md`     | Architecture and status documentation | Major feature completion |
| Task progress checklists | Tracking work-in-progress             | All multi-step tasks     |
| Commit messages          | Version-controlled state              | Production code changes  |
| PR descriptions          | Review context                        | Code review preparation  |

---

## Documentation Standards

### PROJECT_CONTEXT.md Protocol

The `PROJECT_CONTEXT.md` file serves as the single source of truth for project state.

#### When to Update

Update `PROJECT_CONTEXT.md` when:

- ✅ Major feature implementation complete
- ✅ Architecture decisions are made
- ✅ Tech stack changes or extends
- ✅ Breaking changes are introduced
- ✅ Project structure is refactored
- ❌ Minor bug fixes (no need)
- ❌ Documentation-only changes (no need)

#### Update Template

```markdown
## Current Status

[Overview of where the project stands]

### Last Updated

[Date]

### Recent Major Changes

- [Feature] - [Brief description]
- [Architecture] - [Brief description]

### Open Questions

- [Question] - [Context]
- [Question] - [Context]

### Known Limitations

- [Limitation] - [Impact]
```

### Self-Documenting Code Requirements

Documentation should be code-first where possible:

- **Inline comments** explain _why_ for non-obvious logic
- **JSDoc/TSDoc** for all public APIs
- **README.md** in each major directory
- **TODO comments** with issue references: `// TODO(#123): ...`

---

## Version Control & PR Management

### PR Preparation Checklist

Before drafting a pull request:

- [ ] All tests pass
- [ ] Code is formatted (Prettier)
- [ ] Type checking passes (if applicable)
- [ ] Documentation updated
- [ ] Breaking changes documented
- [ ] Changelog entry added (if applicable)

### PR Description Template

```markdown
## Summary

[One-paragraph overview of changes]

## Changes

- [Change 1] - [Description]
- [Change 2] - [Description]

## Testing

[How changes were tested]

## Related Issues

- Closes #123
- Related to #456

## Risk Assessment

[Low/Medium/High] - [Explanation]
```

### Commit Message Standards

Follow the Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `style`, `ci`, `build`

**Example**:

```
feat(auth): add JWT token refresh logic

Implements automatic token refresh when approaching expiry.
Handles both successful refresh and failure cases.

Closes #789
```

---

## Handoff Procedures

### Scheduled Handoffs

Use when an agent session will end before task completion:

```markdown
# Handoff Request

## Task: [Task Name]

## Current Progress

[Percentage complete]

## What Was Done

[Summary of completed work]

## Remaining Work

- [Step 1] - [Estimated time/complexity]
- [Step 2] - [Estimated time/complexity]

## Critical Information

[Any information the next agent needs to know]

## Requested Action

[Continue, review, document, or other instruction]
```

### Unplanned Interruptions

If a task is interrupted:

1. **Commit or stash** any in-progress work
2. **Document** current state and next steps
3. **Note** any blocking issues
4. **Create** a brief handoff note

---

## Error Handling & Recovery

### Agent Errors

When an agent encounters an error:

1. **Diagnose**: Identify root cause from logs/output
2. **Document**: Record error details and context
3. **Recover**: Attempt fix or report blockers
4. **Prevent**: Add safeguards if applicable

### Recovery Procedures

| Scenario                  | Action                              |
| :------------------------ | :---------------------------------- |
| Build fails after changes | Rollback or fix? Document decision  |
| Test failures             | Identify flaky vs. real failures    |
| Missing dependencies      | Document and install or work around |
| Permission issues         | Escalate or adjust approach         |

### Failure Post-Mortem

For significant errors:

```markdown
## Incident Summary

- **Time**: [Timestamp]
- **Agent**: [Identifier]
- **Impact**: [Scope of impact]

## Root Cause Analysis

[What went wrong and why]

## Resolution Steps

[What was done to fix]

## Prevention Measures

[How to avoid recurrence]
```

---

## Security & Trust Boundaries

### Credential Handling

**Strict Rules**:

- Never commit secrets to version control
- Never log sensitive data (passwords, tokens, keys)
- Never share credentials in agent communications
- Always use `.env` files (gitignored)

### Input Validation

Each agent must validate:

- File paths (no directory traversal)
- User inputs (sanitize and validate)
- External data (parse and verify types)
- Configuration values (type-check and sanity-check)

### Trust Verification

Before accepting work from another agent:

1. Verify task progress is documented
2. Confirm state is consistent
3. Check for any obvious errors
4. Validate assumptions are stated

---

## Best Practices Checklist

### Before Starting Work

- [ ] Read `PROJECT_CONTEXT.md` for current state
- [ ] Review `AGENTS.md` for project conventions
- [ ] Check `mcp.json` for available tools
- [ ] Understand task requirements fully
- [ ] Identify any missing information to clarify

### During Task Execution

- [ ] Update task progress regularly
- [ ] Commit meaningful changes
- [ ] Document non-obvious decisions
- [ ] Test changes before proceeding
- [ ] Note any blockers or questions

### Before Ending Session

- [ ] Update `PROJECT_CONTEXT.md` if major change
- [ ] Document pending work clearly
- [ ] Ensure tests pass
- [ ] Run formatter (Prettier)
- [ ] Commit or stash in-progress work

### Agent Handoff Checklist

- [ ] Context is explicit and complete
- [ ] Pending tasks are listed
- [ ] Key decisions are documented
- [ ] Blockers are highlighted
- [ ] Next steps are clear

---

## Quick Reference

### Common Commands

| Action               | Command                       |
| :------------------- | :---------------------------- |
| View project context | `cat PROJECT_CONTEXT.md`      |
| Check MCP servers    | `cat mcp/config.example.json` |
| Review agent rules   | `cat .airules/*.md`           |
| Check git status     | `git status`                  |
| View recent commits  | `git log --oneline -10`       |

### Critical Files

| File                      | Purpose                         |
| :------------------------ | :------------------------------ |
| `PROJECT_CONTEXT.md`      | Current project status          |
| `AGENTS.md`               | Project-wide agent instructions |
| `mcp/config.example.json` | Available MCP tools             |
| `.airules/*.md`           | Agent collaboration rules       |

---

## Revision History

| Version | Date       | Changes                                                                                                          |
| :------ | :--------- | :--------------------------------------------------------------------------------------------------------------- |
| 1.0     | Initial    | Basic 3-point protocol                                                                                           |
| 2.0     | 2026-03-19 | Complete rewrite: added communication protocol, handoff procedures, error handling, security, and best practices |

---

**End of Agent Collaboration Protocol**
