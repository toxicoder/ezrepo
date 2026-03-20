# Workflow: Documentation Sync

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade, automated documentation synchronization process that ensures AGENTS.md, PROJECT_CONTEXT.md, and workflow rules remain accurate and aligned with the actual project state

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Discovery & Understanding Phase](#discovery--understanding-phase)
3. [Structure Audit Phase](#structure-audit-phase)
4. [External Refresh Phase](#external-refresh-phase)
5. [Content Update Phase](#content-update-phase)
6. [Skill/Rule Sync Phase](#skillrule-sync-phase)
7. [Verification & Validation Phase](#verification--validation-phase)
8. [Automation & CI/CD Integration](#automation--ci-cd-integration)
9. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
10. [Quick Reference](#quick-reference)

---

## Core Principles

| Principle                 | Description                                                                     | Anti-Pattern to Avoid                                                    |
| :------------------------ | :---------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| **Verification-First**    | Always compare documentation against actual codebase before making changes    | Assuming documentation is outdated without evidence                    |
| **Progressive Depth**     | Start with high-level audits; drill down only when inconsistencies found      | Spending hours on irrelevant files before grasping the architecture    |
| **Automated Detection**   | Use filesystem tools to programmatically detect mismatches                    | Manual file-by-file comparison without tooling assistance              |
| **Incremental Updates**   | Update documentation in small, focused changes with clear justifications      | Rewriting entire files without preserving existing context             |
| **Traceability**          | Document all changes with version tracking and update timestamps              | Making silent updates without recording what or why changed            |
| **Self-Healing**          | Enable documentation to catch up with code changes automatically              | Allowing documentation to drift until it becomes misleading            |
| **Security-Aware**        | Never update secrets, API keys, or sensitive configuration in documentation   | Including `.env` values, tokens, or credentials in documentation       |

---

## Discovery & Understanding Phase

**Objective**: Establish current project boundaries and understand what needs to be documented.

### 1. Project Scope Mapping

```zsh
# List top-level directories
ls -la

# Identify key directories and their purposes
find . -maxdepth 2 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/.next/*' | sort
```

### 2. Existing Documentation Audit

| File                      | Status Check                                          | Purpose for Sync |
| :------------------------ | :-------------------------------------------------- | :----------------- |
| `AGENTS.md`               | `[ -f AGENTS.md ] && echo "EXISTS" || echo "MISSING"` | Agent instructions |
| `PROJECT_CONTEXT.md`      | `[ -f PROJECT_CONTEXT.md ] && echo "EXISTS" || echo "MISSING"` | Current project state |
| `PROJECT_CONTEXT.md.example` | `[ -f PROJECT_CONTEXT.md.example ] && echo "TEMPLATE EXISTS"` | Template reference |
| `.airules/workflows/`     | `ls -la .airules/workflows/`                          | Workflow definitions |
| `README.md`               | `[ -f README.md ] && echo "EXISTS" || echo "MISSING"` | User-facing docs |

### 3. Directory Structure Analysis

```zsh
# Analyze structure depth
find . -maxdepth 3 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' | wc -l

# List structure in tree-like format
tree -L 3 -d 2>/dev/null || find . -maxdepth 3 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' -exec echo {} \;
```

**Expected Structure** (typical ezrepo layout):

```
ezrepo/
├── .airules/          # Workflow rules for AI agents (source of truth)
├── .clineignore       # Cline-specific ignore rules
├── .devcontainer/     # Dev container configuration
├── .vscode/           # VS Code settings
├── mcp/               # MCP server configurations
├── README.md          # Project documentation (user-facing)
├── AGENTS.md          # Agent instructions (sync target)
├── PROJECT_CONTEXT.md # Current project state (sync target)
├── .airules/
│   ├── workflows/     # Agent workflow definitions
│   └── skills/        # Skill definitions
└── mcp/
    ├── config.example.json
    └── README.md
```

### 4. Documentation Dependencies

Identify what files should be documented:

| Category           | Files to Analyze                        | Documentation Target |
| :----------------- | :------------------------------------- | :-------------------- |
| **Configuration**  | `mcp.json`, `.env.example`, `.gitignore` | AGENTS.md, PROJECT_CONTEXT.md |
| **Workflows**      | `.airules/workflows/*.md`                | AGENTS.md workflow section |
| **Rules**          | `.clinerules/*.md`                       | AGENTS.md best practices |
| **Templates**      | `*.example.md`                           | PROJECT_CONTEXT.md |

### 5. Discovery Sign-Off

Before proceeding to audit, verify:

- [ ] All top-level directories identified
- [ ] Documentation files located (AGENTS.md, PROJECT_CONTEXT.md)
- [ ] Directory structure mapped
- [ ] Documentation dependencies cataloged

---

## Structure Audit Phase

**Objective**: Programmatically compare documentation against actual file structure to identify discrepancies.

### 1. AGENTS.md Structure Audit

**Check for outdated sections**:

| Section                      | Verification Method                                    | Update Trigger |
| :-------------------------- | :------------------------------------------------- | :------------- |
| **MCP Section**              | Compare `mcp.json` servers vs documented servers     | Missing or new servers |
| **Directory Map**            | Compare `find . -maxdepth 2 -type d` vs documented dirs | New/removed directories |
| **Workflow Rules**           | Check `.airules/workflows/` vs documented workflows  | New/removed workflows |
| **Secret Management**        | Verify `.env.example` patterns vs documented secrets | Missing secrets |
| **Version Numbers**          | Check runtime versions in code vs documentation      | Version mismatches |

**Audit Script**:

```zsh
#!/bin/bash
# AGENTS.md Structure Audit Script

echo "=== AGENTS.md Structure Audit ==="
echo ""

# 1. Check MCP servers
echo "1. MCP Server Audit"
if [ -f mcp.json ]; then
    echo "   mcp.json exists - checking for server definitions"
    # Extract server names from mcp.json (simple grep)
    grep -o '"[a-z-]*":' mcp.json | grep -v command | sort -u
else
    echo "   ✗ mcp.json missing"
fi

# 2. Check documented directories
echo ""
echo "2. Directory Structure Audit"
if [ -f AGENTS.md ]; then
    # Look for directory mentions in AGENTS.md
    grep -E "^\s*-\s+/[a-z/]+" AGENTS.md || echo "   No directories documented"
else
    echo "   ✗ AGENTS.md missing"
fi

# 3. Check for TODOs that indicate stale documentation
echo ""
echo "3. Documentation Health Check"
if [ -f AGENTS.md ]; then
    grep -c "TODO\|FIXME\|INCOMPLETE" AGENTS.md || echo "   0 stale markers found"
else
    echo "   ✗ AGENTS.md missing"
fi
```

### 2. PROJECT_CONTEXT.md Structure Audit

**Check for outdated sections**:

| Section                | Verification Method                                      | Update Trigger |
| :-------------------- | :--------------------------------------------------- | :------------- |
| **Technical Environment** | Compare `.devcontainer/Dockerfile` vs documented env   | Env changes |
| **Architecture Map**   | Compare actual structure vs documented map            | Structure changes |
| **Current State**      | Check git status/commits vs documented state          | No recent commits |
| **Next Milestone**     | Check TODOs or issues vs documented milestones        | Missing activity |

**Audit Script**:

```zsh
#!/bin/bash
# PROJECT_CONTEXT.md Structure Audit Script

echo "=== PROJECT_CONTEXT.md Structure Audit ==="
echo ""

# 1. Check git status for out-of-date indicators
echo "1. Git Status Check"
if git status --porcelain 2>/dev/null | grep -q .; then
    echo "   ⚠ Uncommitted changes detected - context may be stale"
else
    echo "   ✓ Git working tree clean"
fi

# 2. Check recent commits
echo ""
echo "2. Recent Activity Check"
git log --oneline -5 2>/dev/null || echo "   No commits found"

# 3. Verify template placeholder is updated
echo ""
echo "3. Template Placeholder Check"
if [ -f PROJECT_CONTEXT.md ]; then
    grep -E "\[Insert|\[e\.g\.|\[Describe" PROJECT_CONTEXT.md || echo "   ✓ All placeholders updated"
else
    echo "   ✗ PROJECT_CONTEXT.md missing"
fi
```

### 3. Directory Structure Audit

**Automated structure comparison**:

```zsh
#!/bin/bash
# Directory Structure Audit

echo "=== Directory Structure Audit ==="
echo ""

# Get actual structure
echo "1. Actual Directory Structure (depth 3):"
find . -maxdepth 3 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/.next/*' ! -path '*/dist/*' ! -path '*/build/*' | sort | head -50

echo ""
echo "2. Documented Directories (from AGENTS.md):"
if [ -f AGENTS.md ]; then
    grep -E "^\s*-\s+/[a-z/]+" AGENTS.md | sed 's/^\s*-\s*//' || echo "   No directories documented"
else
    echo "   ✗ AGENTS.md missing"
fi
```

### 4. Structure Audit Sign-Off

Before proceeding to update, verify:

- [ ] AGENTS.md structure sections verified against actual codebase
- [ ] PROJECT_CONTEXT.md structure sections verified
- [ ] Directory discrepancies identified and documented
- [ ] Documentation health check completed (TODO markers counted)

---

## External Refresh Phase

**Objective**: Fetch and integrate updates for third-party libraries, frameworks, and external dependencies.

### 1. External Dependency Audit

**Identify external dependencies**:

```zsh
# Node.js dependencies
cat package.json | jq -r '.dependencies // {} | keys[]' 2>/dev/null || echo "No package.json or jq not available"

# Python dependencies
cat requirements.txt 2>/dev/null || cat pyproject.toml 2>/dev/null || echo "No Python deps found"

# Docker dependencies
cat Dockerfile | grep -E "^FROM|^RUN apt-get" 2>/dev/null || echo "No Dockerfile found"

# MCP servers
cat mcp.json | jq -r '.servers | keys[]' 2>/dev/null || echo "No MCP servers"
```

### 2. Version Checking with External Sources

**Using Context7 for library versions**:

```zsh
# Context7 query examples (via agent tool):
# context7/query with:
# - query: "latest version of express"
# - library: "express"
```

**Using Brave Search for general updates**:

```zsh
# Check npm package versions
npm view <package> version

# Check GitHub repo activity
curl -s "https://api.github.com/repos/<owner>/<repo>" | jq -r '.pushed_at'
```

### 3. External Refresh Workflow

| Action                    | Method                       | Frequency    | Approval Required |
| :------------------------ | :---------------------------- | :------------ | :---------------- |
| **Library version checks** | Context7 for version queries | Weekly       | No              |
| **Package updates**         | npm/yarn/pip                | As needed    | Yes (if breaking) |
| **Documentation updates**   | Crawl4AI for docs           | Monthly      | No              |
| **Security advisories**     | npm audit, pip-audit        | Weekly       | Yes             |

### 4. External Refresh Script

```zsh
#!/bin/bash
# External Refresh Workflow

echo "=== External Refresh Workflow ==="
echo ""

# 1. Check npm package updates
echo "1. npm Package Updates"
if [ -f package.json ]; then
    npm outdated 2>/dev/null || echo "   No npm packages or npm not available"
else
    echo "   No package.json found"
fi

# 2. Check Docker base image updates
echo ""
echo "2. Docker Base Image Updates"
if [ -f Dockerfile ]; then
    echo "   Dockerfile found - check FROM statements"
    grep "^FROM" Dockerfile
else
    echo "   No Dockerfile found"
fi

# 3. Check GitHub repo activity (MCP servers)
echo ""
echo "3. MCP Server Activity Check"
if [ -f mcp.json ]; then
    echo "   Checking for MCP server updates..."
    # This would require external API calls
    echo "   Review mcp.json and check GitHub for updates"
fi
```

### 5. External Refresh Sign-Off

Before proceeding to update, verify:

- [ ] External dependencies identified and cataloged
- [ ] Version checks completed for all major dependencies
- [   Security advisories reviewed
- [ ] Documentation sources updated

---

## Content Update Phase

**Objective**: Systematically update AGENTS.md and PROJECT_CONTEXT.md to reflect current project state.

### 1. Update Strategy

| Type of Change            | Update Method                    | Version Tracking |
| :------------------------- | :------------------------------- | :----------------- |
| **New directories**        | Add to directory map             | Date stamp       |
| **Removed directories**    | Mark as deprecated               | Date stamp       |
| **New MCP servers**        | Add to MCP section               | Date stamp       |
| **Updated versions**       | Update version numbers           | Date + version   |
| **New workflows**          | Link to workflow file            | Date stamp       |
| **Removed workflows**      | Archive or remove                | Date stamp       |

### 2. Automated Update Script (Foundation)

**Note**: This script provides the framework. Manual review is recommended for accuracy.

```zsh
#!/bin/bash
# Documentation Update Script

echo "=== Documentation Update Script ==="
echo ""
echo "WARNING: This script generates a suggested update. Manual review required."
echo ""

# Generate new AGENTS.md section
echo "1. Generating Updated MCP Section..."
cat << 'MCP_SECTION'
### Model Context Protocol (MCP) Usage

This repository provides access to MCP (Model Context Protocol) servers that extend an agent's capabilities.

#### Common MCP Server Categories

| Category                 | Purpose                                  | Usage Notes                                       |
| :----------------------- | :--------------------------------------- | :------------------------------------------------ |
| **Filesystem**           | Read/write files and list directories    | Use for project navigation and file manipulation. |
| **Search/Documentation** | Web search and documentation lookups     | Useful for finding latest APIs or library docs.   |
| **Database**             | Query databases and manage data          | Use for data persistence and retrieval.           |
| **Version Control**      | Git operations and repository management | Use for PRs, issues, and commit operations.       |
| **Browser Automation**   | Browser control and web scraping         | Use for testing, scraping, or UI interactions.    |
| **API Integration**      | Call external APIs and services          | Use for third-party service integration.          |

#### General Guidelines

- **Check your MCP configuration** (`mcp.json` or similar) to see available servers in your environment
- **Use the right tool for the job** - prefer native MCP tools over manual alternatives when available
- **Handle errors gracefully** - MCP servers may fail; implement appropriate fallbacks
- **Respect rate limits** - external services may have usage limits
- **Security considerations** - never expose sensitive credentials through MCP calls

#### Typical MCP Tools Available

| Tool Category     | Examples                           |
| :---------------- | :--------------------------------- |
| `list_directory`  | Browse file system structure       |
| `read_file`       | Read file contents                 |
| `write_file`      | Write file contents                |
| `search_files`    | Search files by content or pattern |
| `execute_command` | Run shell commands                 |
| `http_request`    | Make HTTP requests                 |
| `search`          | Perform web searches               |
| `database_query`  | Execute database queries           |
MCP_SECTION

echo ""
echo "2. Generating Updated Directory Map..."
echo ""
echo "3. Run structure audit first to identify discrepancies"
```

### 3. Manual Update Procedure

**Follow this procedure when making manual updates**:

1. **Backup current documentation**:
   ```zsh
   cp AGENTS.md AGENTS.md.backup.$(date +%Y%m%d)
   cp PROJECT_CONTEXT.md PROJECT_CONTEXT.md.backup.$(date +%Y%m%d)
   ```

2. **Update AGENTS.md**:
   - Read current AGENTS.md content
   - Compare with actual file structure
   - Make minimal, focused changes
   - Add version/date stamp

3. **Update PROJECT_CONTEXT.md**:
   - Copy template to PROJECT_CONTEXT.md (if missing)
   - Fill in current project state
   - Update technical environment section
   - Update architecture map

4. **Add version tracking**:
   ```markdown
   > **Version**: 2.0
   > **Last Updated**: 2026-03-19
   > **Changes**: [List of changes made]
   ```

### 4. Content Update Verification

**After updating, verify**:

```zsh
#!/bin/bash
# Content Update Verification

echo "=== Content Update Verification ==="
echo ""

# 1. Check file exists
echo "1. File Existence Check"
[ -f AGENTS.md ] && echo "   ✓ AGENTS.md exists" || echo "   ✗ AGENTS.md missing"
[ -f PROJECT_CONTEXT.md ] && echo "   ✓ PROJECT_CONTEXT.md exists" || echo "   ✗ PROJECT_CONTEXT.md missing"

# 2. Check for template placeholders
echo ""
echo "2. Template Placeholder Check"
if [ -f PROJECT_CONTEXT.md ]; then
    PLACEHOLDERS=$(grep -c "\[Insert\|\[Describe\|\[e\.g\." PROJECT_CONTEXT.md)
    if [ "$PLACEHOLDERS" -gt 0 ]; then
        echo "   ⚠ $PLACEHOLDERS template placeholders still present"
    else
        echo "   ✓ No template placeholders found"
    fi
else
    echo "   ✗ PROJECT_CONTEXT.md missing"
fi

# 3. Check for version/date stamps
echo ""
echo "3. Version Tracking Check"
grep -E "^\> \*\*Version\*\*|^\> \*\*Last Updated\*\*" AGENTS.md PROJECT_CONTEXT.md 2>/dev/null || echo "   No version stamps found"

# 4. Check for TODO markers
echo ""
echo "4. Documentation Health Check"
grep -c "TODO\|FIXME\|STALE\|OUTDATED" AGENTS.md PROJECT_CONTEXT.md 2>/dev/null || echo "   0 TODO/FIXME markers found"
```

### 5. Content Update Sign-Off

Before completing, verify:

- [ ] Current documentation backed up
- [ ] Discrepancies identified and documented
- [ ] Minimal, focused changes made
- [ ] Version/date stamps added
- [ ] Template placeholders removed
- [ ] No TODO/FIXME markers left in updated sections

---

## Skill/Rule Sync Phase

**Objective**: Synchronize workflow rules in `.airules/` with skill definitions and identify emerging patterns.

### 1. Skill Identification

**Identify skills from workflow files**:

```zsh
#!/bin/bash
# Skill Identification Script

echo "=== Skill Identification ==="
echo ""

# Find all workflow files
echo "1. Workflow Files Found:"
find .airules/workflows/ -name "*.md" -type f 2>/dev/null | sort

echo ""
echo "2. Skill Patterns Identified:"

# Look for skill indicators in workflows
for file in $(find .airules/workflows/ -name "*.md" -type f 2>/dev/null); do
    echo ""
    echo "   File: $file"
    
    # Check for common skill patterns
    if grep -q "MCP.*server\|filesystem\|search" "$file"; then
        echo "   - MCP/Tool Usage Skill"
    fi
    
    if grep -q "audit\|verify\|check" "$file"; then
        echo "   - Verification Skill"
    fi
    
    if grep -q "update\|modify\|write" "$file"; then
        echo "   - Content Modification Skill"
    fi
    
    if grep -q "troubleshoot\|debug\|fix" "$file"; then
        echo "   - Debugging Skill"
    fi
done
```

### 2. Pattern Analysis

**Identify emerging patterns across workflows**:

```zsh
#!/bin/bash
# Pattern Analysis Script

echo "=== Pattern Analysis ==="
echo ""

# Look for common patterns
echo "1. Common Pattern Analysis"

# Check for "Phase" usage (indicates structured workflows)
echo ""
echo "   Phase-based workflows:"
grep -r "Phase\]" .airules/workflows/ 2>/dev/null | wc -l || echo "   0 phase-based workflows"

# Check for checklists (indicates verification-focused workflows)
echo ""
echo "   Checklist-based workflows:"
grep -r "Checklist\|Verification\|Sign-Off" .airules/workflows/ 2>/dev/null | wc -l || echo "   0 checklist workflows"

# Check for version tracking (indicates mature workflows)
echo ""
echo "   Version-tracked workflows:"
grep -r "Version\|Revision History" .airules/workflows/ 2>/dev/null | wc -l || echo "   0 version-tracked workflows"
```

### 3. Rule/Workflow Enhancement Suggestions

**Based on pattern analysis, suggest enhancements**:

| Pattern Detected              | Enhancement Suggestion                         | Priority |
| :--------------------------- | :----------------------------------------- | :--------- |
| **No version tracking**       | Add version/date stamps to all workflows       | Medium   |
| **No checklists**             | Add verification checklists                    | Medium   |
| **No troubleshooting**        | Add common issues section                      | Low      |
| **Inconsistent structure**    | Standardize workflow template                  | High     |
| **No automation examples**    | Add automated scripts for common tasks         | Medium   |

### 4. New Pattern Detection

**Detect and document emerging patterns**:

```zsh
#!/bin/bash
# New Pattern Detection

echo "=== New Pattern Detection ==="
echo ""

# Look for consistent patterns that might be reusable
echo "1. Reusable Patterns Identified:"

# Check for common verification patterns
echo ""
echo "   Verification patterns:"
grep -h "Verify\|Check\|Validate" .airules/workflows/*.md 2>/dev/null | sort -u | head -10

# Check for common error patterns
echo ""
echo "   Error handling patterns:"
grep -h "Issue\|Troubleshoot\|Error" .airules/workflows/*.md 2>/dev/null | sort -u | head -10

# Check for common configuration patterns
echo ""
echo "   Configuration patterns:"
grep -h "Configuration\|Setup\|Initialize" .airules/workflows/*.md 2>/dev/null | sort -u | head -10
```

### 5. Skill/Rule Sync Sign-Off

Before completing, verify:

- [ ] All workflow files analyzed
- [ ] Skills identified and documented
- [ ] Patterns analyzed for reuse
- [ ] Enhancement suggestions documented
- [ ] New patterns detected and cataloged

---

## Verification & Validation Phase

**Objective**: Verify all documentation updates are accurate and complete.

### 1. Automated Verification Script

```zsh
#!/bin/bash
# Comprehensive Documentation Verification

echo "=== Comprehensive Documentation Verification ==="
echo ""

PASS=0
FAIL=0
WARN=0

# 1. File existence checks
echo "1. File Existence Checks"
if [ -f AGENTS.md ]; then
    echo "   ✓ AGENTS.md exists"
    ((PASS++))
else
    echo "   ✗ AGENTS.md missing"
    ((FAIL++))
fi

if [ -f PROJECT_CONTEXT.md ]; then
    echo "   ✓ PROJECT_CONTEXT.md exists"
    ((PASS++))
else
    echo "   ✗ PROJECT_CONTEXT.md missing"
    ((FAIL++))
fi

# 2. Content completeness checks
echo ""
echo "2. Content Completeness Checks"

if [ -f PROJECT_CONTEXT.md ]; then
    if grep -q "## 1\. Project Identity" PROJECT_CONTEXT.md; then
        echo "   ✓ Project Identity section exists"
        ((PASS++))
    else
        echo "   ⚠ Project Identity section missing"
        ((WARN++))
    fi
    
    if grep -q "## 2\. Technical Environment" PROJECT_CONTEXT.md; then
        echo "   ✓ Technical Environment section exists"
        ((PASS++))
    else
        echo "   ⚠ Technical Environment section missing"
        ((WARN++))
    fi
    
    if grep -q "## 3\. Toolchain" PROJECT_CONTEXT.md; then
        echo "   ✓ Toolchain section exists"
        ((PASS++))
    else
        echo "   ⚠ Toolchain section missing"
        ((WARN++))
    fi
    
    if grep -q "## 4\. Architecture" PROJECT_CONTEXT.md; then
        echo "   ✓ Architecture section exists"
        ((PASS++))
    else
        echo "   ⚠ Architecture section missing"
        ((WARN++))
    fi
fi

# 3. Version tracking checks
echo ""
echo "3. Version Tracking Checks"

if grep -q "^\> \*\*Version\*\*" AGENTS.md; then
    echo "   ✓ AGENTS.md has version tracking"
    ((PASS++))
else
    echo "   ⚠ AGENTS.md missing version tracking"
    ((WARN++))
fi

if grep -q "^\> \*\*Version\*\*" PROJECT_CONTEXT.md; then
    echo "   ✓ PROJECT_CONTEXT.md has version tracking"
    ((PASS++))
else
    echo "   ⚠ PROJECT_CONTEXT.md missing version tracking"
    ((WARN++))
fi

# 4. Template placeholder checks
echo ""
echo "4. Template Placeholder Checks"

PLACEHOLDERS=0
if [ -f PROJECT_CONTEXT.md ]; then
    PLACEHOLDERS=$(grep -c "\[Insert\|\[Describe\|\[e\.g\." PROJECT_CONTEXT.md)
fi

if [ "$PLACEHOLDERS" -eq 0 ]; then
    echo "   ✓ No template placeholders in PROJECT_CONTEXT.md"
    ((PASS++))
else
    echo "   ⚠ $PLACEHOLDERS template placeholders still present"
    ((WARN++))
fi

# 5. Documentation health checks
echo ""
echo "5. Documentation Health Checks"

TODO_COUNT=0
if [ -f AGENTS.md ]; then
    TODO_COUNT=$((TODO_COUNT + $(grep -c "TODO\|FIXME" AGENTS.md || echo 0)))
fi
if [ -f PROJECT_CONTEXT.md ]; then
    TODO_COUNT=$((TODO_COUNT + $(grep -c "TODO\|FIXME" PROJECT_CONTEXT.md || echo 0)))
fi

if [ "$TODO_COUNT" -eq 0 ]; then
    echo "   ✓ No TODO/FIXME markers in documentation"
    ((PASS++))
else
    echo "   ⚠ $TODO_COUNT TODO/FIXME markers found"
    ((WARN++))
fi

# 6. Directory consistency checks
echo ""
echo "6. Directory Consistency Checks"

if [ -f AGENTS.md ]; then
    DOCUMENTED_DIRS=$(grep -c "^\s*-\s+/[a-z/]" AGENTS.md || echo 0)
    ACTUAL_DIRS=$(find . -maxdepth 2 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' | wc -l)
    
    if [ "$DOCUMENTED_DIRS" -gt 0 ] && [ "$ACTUAL_DIRS" -gt 0 ]; then
        echo "   ✓ Directory documentation present"
        ((PASS++))
    else
        echo "   ⚠ Directory documentation incomplete"
        ((WARN++))
    fi
fi

# Summary
echo ""
echo "=== Verification Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Warnings: $WARN"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "✓ Documentation verification COMPLETE"
    exit 0
else
    echo "✗ Documentation verification FAILED"
    exit 1
fi
```

### 2. Manual Review Checklist

**For manual documentation updates, use this checklist**:

- [ ] **Content Accuracy**
  - [ ] All documented directories exist
  - [ ] All documented MCP servers are configured
  - [ ] All workflow links are valid
  - [ ] Version numbers are current

- [ ] **Structure Consistency**
  - [ ] All sections follow standard format
  - [ ] Version/date stamps present
  - [ ] No template placeholders remain

- [ ] **Quality Standards**
  - [ ] No TODO/FIXME markers
  - [ ] No broken links
  - [ ] No deprecated references

- [ ] **Version Control**
  - [ ] Changes documented in commit
  - [ ] Version number incremented
  - [ ] Update date recorded

### 3. Validation Sign-Off

Before completing the workflow, verify:

- [ ] Automated verification script executed
- [ ] All checks passed or warnings addressed
- [ ] Manual review checklist completed
- [ ] Changes committed with descriptive message
- [ ] Version/date stamps updated

---

## Automation & CI/CD Integration

**Objective**: Automate documentation sync as part of CI/CD pipeline for continuous alignment.

### 1. Automated Documentation Sync Pipeline

**Workflow**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Documentation Sync Pipeline                  │
├─────────────────────────────────────────────────────────────────┤
│ 1. Schedule/Trigger (Daily/Weekly/On-PR)                       │
│ 2. Discovery Phase - Scan project structure                    │
│ 3. Audit Phase - Compare vs documentation                      │
│ 4. External Refresh - Fetch updates                            │
│ 5. Update Phase - Apply changes                                │
│ 6. Verification Phase - Validate changes                       │
│ 7. Commit/Push (if changes)                                    │
│ 8. Report Generation (success/failure)                         │
└─────────────────────────────────────────────────────────────────┘
```

### 2. GitHub Actions Integration

**Example `.github/workflows/doc-sync.yml`**:

```yaml
name: Documentation Sync

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:      # Manual trigger

jobs:
  doc-sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'

      - name: Run Documentation Sync Script
        run: |
          # Install dependencies
          npm install jq -g
          
          # Run verification
          bash scripts/doc-sync-verify.sh
          
          # Run update if needed
          if [ $? -ne 0 ]; then
            bash scripts/doc-sync-update.sh
          fi

      - name: Commit Changes
        if: success()
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add AGENTS.md PROJECT_CONTEXT.md
          git commit -m "docs: sync documentation [skip ci]" || echo "No changes to commit"

      - name: Push Changes
        if: success()
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          branch: docs/doc-sync
          title: "docs: automated documentation sync"
          body: "Automated documentation sync completed. Review changes."
```

### 3. Pre-Commit Hook Integration

**Example `.git/hooks/pre-commit`**:

```bash
#!/bin/bash
# Documentation Sync Pre-Commit Hook

echo "Running documentation sync check..."

# Run verification script
if bash .airules/scripts/doc-sync-verify.sh; then
    echo "Documentation sync check passed"
    exit 0
else
    echo "⚠ Documentation sync check failed"
    echo "Run: bash .airules/scripts/doc-sync-update.sh"
    echo "Then retry commit"
    exit 1
fi
```

### 4. Automation Best Practices

| Practice                 | Recommendation                                               |
| :------------------------ | :-------------------------------------------------------- |
| **Run frequency**          | Daily for external refresh, Weekly for full sync           |
| **Error handling**         | Fail gracefully; notify on failure without blocking PRs    |
| **Rollback capability**    | Keep backup copies before updates                          |
| **Change logging**         | Log all changes to a `CHANGES.md` file                     |
| **Notification**           | Create GitHub issues on sync failures                      |

### 5. CI/CD Integration Sign-Off

Before completing automation, verify:

- [ ] Pipeline configuration created
- [ ] Pre-commit hook integrated
- [ ] Error handling implemented
- [ ] Backup mechanism in place
- [ ] Change logging configured

---

## Common Issues & Troubleshooting

### Issue 1: Documentation Out of Date

**Symptoms**: Documentation references files that no longer exist or missing new files.

**Diagnosis**:

```zsh
# Find references to non-existent files
grep -r "README.md" AGENTS.md | while read line; do
    FILE=$(echo "$line" | grep -oP '\[.*?\]' | tr -d '[]')
    if [ ! -f "$FILE" ]; then
        echo "MISSING: $FILE"
    fi
done

# Find unmentioned directories
find . -maxdepth 2 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' | while read dir; do
    if ! grep -r "$dir" AGENTS.md PROJECT_CONTEXT.md >/dev/null; then
        echo "UNMENTIONED: $dir"
    fi
done
```

**Resolution**:

1. Update documentation to match current file structure
2. Add new directories to directory map
3. Remove references to deleted files
4. Add version/date stamp

### Issue 2: Version Mismatches

**Symptoms**: Documentation references outdated versions of dependencies.

**Diagnosis**:

```zsh
# Check documented versions vs actual
echo "Documented Node version:"
grep -i "node\|nodejs" AGENTS.md | head -5

echo "Actual Node version:"
node --version

echo "Documented Python version:"
grep -i "python" AGENTS.md | head -5

echo "Actual Python version:"
python3 --version
```

**Resolution**:

1. Update documentation with current versions
2. Check dependency files (`package.json`, `requirements.txt`)
3. Add version check to verification pipeline

### Issue 3: Template Placeholders Not Removed

**Symptoms**: PROJECT_CONTEXT.md contains `[Insert Name]` or similar placeholders.

**Diagnosis**:

```zsh
# Find all template placeholders
grep -E "\[Insert|\[Describe|\[e\.g\." PROJECT_CONTEXT.md
```

**Resolution**:

1. Replace placeholders with actual values
2. Document placeholder format for future updates
3. Add placeholder check to verification pipeline

### Issue 4: Documentation Drift

**Symptoms**: Documentation and codebase become increasingly misaligned over time.

**Diagnosis**:

```zsh
# Track drift over time
echo "Checking documentation drift..."

# Count documentation changes per month
git log --since="1 month ago" --oneline -- AGENTS.md PROJECT_CONTEXT.md | wc -l

# Check for TODO markers (indicates stale documentation)
grep -c "TODO\|FIXME" AGENTS.md PROJECT_CONTEXT.md
```

**Resolution**:

1. Implement automated sync pipeline
2. Add pre-commit hooks for verification
3. Schedule regular documentation reviews
4. Use version tracking for all updates

### Issue 5: External Refresh Failures

**Symptoms**: External dependency information is outdated or unavailable.

**Diagnosis**:

```zsh
# Check external dependency sources
echo "Checking npm packages..."
npm view express version 2>&1 || echo "npm unavailable"

echo "Checking GitHub repositories..."
curl -s "https://api.github.com/repos/expressjs/express" | jq -r '.pushed_at' 2>&1 || echo "curl unavailable"
```

**Resolution**:

1. Configure API keys for external sources
2. Implement fallback mechanisms
3. Cache external data with expiration
4. Add retry logic with backoff

### Issue 6: Auto-Generated Documentation Errors

**Symptoms**: Script-generated documentation contains incorrect or malformed content.

**Diagnosis**:

```zsh
# Validate generated Markdown
echo "Checking Markdown validity..."
for file in AGENTS.md PROJECT_CONTEXT.md; do
    if [ -f "$file" ]; then
        # Check for common issues
        if grep -q "^#" "$file"; then
            echo "✓ $file has headings"
        else
            echo "✗ $file missing headings"
        fi
        
        if grep -q "^|" "$file"; then
            echo "✓ $file has tables"
        else
            echo "⚠ $file has no tables (may be OK)"
        fi
    fi
done
```

**Resolution**:

1. Add validation to auto-generation scripts
2. Implement manual review step
3. Add format checks to verification pipeline
4. Keep templates simple and reliable

---

## Quick Reference

### Documentation Sync Commands

| Action                        | Command                                                   |
| :---------------------------- | :-------------------------------------------------------- |
| Run full verification         | `bash .airules/scripts/doc-sync-verify.sh`               |
| Run structure audit           | `bash .airules/scripts/doc-sync-audit.sh`                |
| Update documentation          | `bash .airules/scripts/doc-sync-update.sh`               |
| Check template placeholders   | `grep -E "\[Insert\|\[Describe" PROJECT_CONTEXT.md`      |
| Find unmentioned directories  | `find . -maxdepth 2 -type d | grep -v -x -f AGENTS.md`   |
| Check external dependencies   | `bash .airules/scripts/doc-sync-external.sh`             |
| Generate change report        | `bash .airules/scripts/doc-sync-report.sh`               |

### Documentation Files Reference

| File                      | Purpose                                  | Sync Status    |
| :------------------------ | :----------------------------------------- | :-------- |
| `AGENTS.md`               | Agent instructions and best practices     | Manual/Auto    |
| `PROJECT_CONTEXT.md`      | Current project state for AI context      | Auto-generated |
| `PROJECT_CONTEXT.md.example` | Template for project context              | Template       |
| `.airules/workflows/`     | Workflow definitions                      | Manual         |
| `mcp/config.example.json` | MCP configuration template                | Template       |

### Documentation Health Metrics

| Metric                     | Target              | Current   | Status    |
| :-------------------------- | :------------------- | :-------- | :-------- |
| TODO/FIXME markers          | 0                   |           |           |
| Template placeholders       | 0                   |           |           |
| Version stamps present      | 100%                |           |           |
| Directory coverage          | 100%                |           |           |
| External refresh frequency  | Weekly              |           |           |
| Last documentation update   | Within last 30 days |           |           |

### Version Tracking Format

```markdown
> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Changes**:
>   - Added new MCP servers section
>   - Updated directory map for new structure
>   - Added automation section for CI/CD
>   - Removed deprecated legacy workflows
```

### Documentation Sync Workflow Decision Tree

```
Start Documentation Sync
    │
    ├─→ Discovery Phase - Understand Scope
    │   ├─ List top-level directories
    │   ├─ Identify documentation files
    │   └─ Map dependencies
    │
    ├─→ Structure Audit - Identify Discrepancies
    │   ├─ Compare files vs documentation
    │   ├─ Find unmentioned directories
    │   └─ Identify TODO markers
    │
    ├─→ External Refresh - Fetch Updates
    │   ├─ Check dependency versions
    │   ├─ Update MCP server info
    │   └─ Fetch latest docs
    │
    ├─→ Update Phase - Apply Changes
    │   ├─ Backup current documentation
    │   ├─ Apply minimal updates
    │   └─ Add version/date stamps
    │
    ├─→ Skill/Rule Sync - Analyze Patterns
    │   ├─ Identify emerging skills
    │   ├─ Document reusable patterns
    │   └─ Suggest enhancements
    │
    ├─→ Verification Phase - Validate Changes
    │   ├─ Run automated checks
    │   ├─ Manual review checklist
    │   └─ Sign-off if passes
    │
    └─→ Complete?
        ├─ Yes → Update PROJECT_CONTEXT.md
        └─ No → Repeat audit for remaining issues
```

### Agent Chat Commands Reference

After setup, use these commands in agent chat:

```
# Test documentation sync
execute_command with "bash .airules/scripts/doc-sync-verify.sh"

# Run structure audit
execute_command with "bash .airules/scripts/doc-sync-audit.sh"

# Update documentation
execute_command with "bash .airules/scripts/doc-sync-update.sh"

# Generate change report
execute_command with "bash .airules/scripts/doc-sync-report.sh"
```

---

## Revision History

| Version | Date       | Changes                                                                 |
| :------ | :--------- | :---------------------------------------------------------------------- |
| 1.0     | Initial    | Basic 4-step documentation sync workflow                              |
| 2.0     | 2026-03-19 | Complete rewrite: added core principles, discovery/verification phases, automation/CICD integration, troubleshooting guide, and revision history |

---

**End of Documentation Sync Workflow**