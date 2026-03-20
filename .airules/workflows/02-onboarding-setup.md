# Workflow: Project Onboarding

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade, comprehensive onboarding process for setting up the development environment, configuring MCP servers, and establishing context baseline for AI agents

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Pre-Workflow Prerequisites](#pre-workflow-prerequisites)
3. [System Readiness Phase](#system-readiness-phase)
4. [Secret Initialization Phase](#secret-initialization-phase)
5. [MCP Configuration Phase](#mcp-configuration-phase)
6. [Context Baseline Phase](#context-baseline-phase)
7. [Validation & Verification Phase](#validation--verification-phase)
8. [Post-Onboarding](#post-onboarding)
9. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
10. [Quick Reference](#quick-reference)

---

## Core Principles

| Principle                | Description                                                            | Anti-Pattern to Avoid                              |
| :----------------------- | :--------------------------------------------------------------------- | :------------------------------------------------- |
| **Verification-First**   | All dependencies and configurations must be verified before proceeding | Assuming environment is ready without verification |
| **Incremental Progress** | Each phase must complete successfully before moving to the next        | Skipping phases or skipping verification steps     |
| **Document Everything**  | All configuration changes and decisions must be documented             | Making changes without updating PROJECT_CONTEXT.md |
| **Security-First**       | Secrets must be handled securely; never expose real credentials        | Committing `.env` files or hardcoding API keys     |
| **Agent-Ready**          | MCP configuration must be complete before AI agent uses tools          | Attempting to use MCP servers before configuration |
| **Context-Aware**        | PROJECT_CONTEXT.md must reflect current project state                  | Using stale or incomplete project context          |

---

## Pre-Workflow Prerequisites

Before starting onboarding, ensure:

| Requirement              | Status Check                                     |
| :----------------------- | :----------------------------------------------- |
| VS Code installed        | `code --version`                                 |
| Dev Containers extension | VS Code extension manager (install if missing)   |
| Git configured           | `git --version`                                  |
| Repository cloned        | Repository directory exists in expected location |
| User has write access    | Can create files in workspace directory          |

**User Action Required**:

```zsh
# Verify git is configured
git config --global user.name
git config --global user.email
```

---

## System Readiness Phase

**Objective**: Verify all system dependencies and environment readiness.

### 1. Runtime Version Verification

```zsh
# Verify Node.js LTS
node --version && npm --version

# Verify Python 3.12
python3 --version && pip3 --version

# Verify Docker-in-Docker
docker --version
docker info 2>/dev/null | grep -E "(Server Version|Operating System)"
```

**Expected Versions**:

| Tool    | Required Version     | Verification Command |
| :------ | :------------------- | :------------------- |
| Node.js | LTS (v20.x or v22.x) | `node --version`     |
| npm     | v10.x or higher      | `npm --version`      |
| Python  | 3.12.x               | `python3 --version`  |
| Docker  | 24.x or higher       | `docker --version`   |
| Zsh     | 5.8 or higher        | `zsh --version`      |

### 2. CLI Tools Verification

```zsh
# Verify essential CLI tools
which git
which curl
which jq
which make
which sed
which awk
```

### 3. Shell Environment

```zsh
# Verify Zsh is default shell
echo $SHELL

# Verify Oh My Zsh is installed
[ -f "$ZSH/oh-my-zsh.sh" ] && echo "OMZ installed" || echo "OMZ not found"
```

### 4. Container Environment

```zsh
# Verify container identity
cat /etc/os-release | grep -E "(PRETTY_NAME|VERSION)"

# Verify container architecture
uname -m
```

**System Readiness Checklist**:

- [ ] Node.js LTS version verified
- [ ] npm version verified
- [ ] Python 3.12 version verified
- [ ] Docker version verified (24.x+)
- [ ] Zsh shell confirmed
- [ ] Oh My Zsh installed
- [ ] Ubuntu 24.04 container confirmed
- [ ] All CLI tools available
- [ ] Git configured with user.name and user.email

### 5. System Readiness Sign-Off

Before proceeding, verify:

- [ ] All runtime versions match requirements
- [ ] No version conflicts detected
- [ ] Container environment confirmed as Ubuntu 24.04
- [ ] All required CLI tools are accessible

---

## Secret Initialization Phase

**Objective**: Initialize environment secrets and configure optional API keys.

### 1. Environment File Setup

```zsh
# Create .env from template
cp .env.example .env

# Verify .env exists and is not gitignored
ls -la .env
```

**Note**: `.env` is already gitignored via `.gitignore`.

### 2. Required Secret Configuration

**Optional API Keys** (configure if available):

| Secret             | Purpose                         | Configuration Guide                              |
| :----------------- | :------------------------------ | :----------------------------------------------- |
| `GITHUB_TOKEN`     | GitHub API access, PR creation  | Generate at github.com/settings/tokens (classic) |
| `BRAVE_API_KEY`    | Web search via Brave Search API | Get at search.brave.com/api-key                  |
| `CONTEXT7_API_KEY` | Upstash Context7 documentation  | Get at upstash.com (free tier available)         |

### 3. Secret Configuration Template

```zsh
# Example .env content
cat > .env << 'EOF'
# GitHub API (optional but recommended)
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Brave Search API (optional)
BRAVE_API_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Upstash Context7 API (optional)
CONTEXT7_API_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
EOF
```

### 4. Secret Verification

```zsh
# Check for configured secrets (values should exist but may be empty)
grep -E "^(GITHUB_TOKEN|BRAVE_API_KEY|CONTEXT7_API_KEY)=" .env || echo "No secrets configured"

# Verify .env is gitignored
grep "\.env$" .gitignore && echo ".env is gitignored" || echo "WARNING: .env not gitignored"
```

### 5. Secret Best Practices

| Practice               | Recommendation                                                |
| :--------------------- | :------------------------------------------------------------ |
| Token Scope            | Use minimal required scopes (repo, read:org for GITHUB_TOKEN) |
| Token Rotation         | Rotate tokens every 90 days                                   |
| Environment Separation | Use different tokens per environment (dev/staging/prod)       |
| Commit Policy          | Never commit `.env` to any repository                         |
| Backup Policy          | Store tokens in password manager with backup                  |

### 6. Secret Initialization Sign-Off

Before proceeding, verify:

- [ ] `.env` file created from `.env.example`
- [ ] `.env` is gitignored
- [ ] Optional API keys configured (if available)
- [ ] No hardcoded secrets in source code

---

## MCP Configuration Phase

**Objective**: Configure Model Context Protocol servers for AI agent tool access.

### 1. MCP Configuration Setup

```zsh
# Create MCP configuration from template
cp mcp/config.example.json mcp.json

# Verify configuration exists
cat mcp.json
```

**Configuration Files**:

| File                      | Purpose                                    | Status    |
| :------------------------ | :----------------------------------------- | :-------- |
| `mcp/config.example.json` | Template with all pre-configured servers   | Committed |
| `mcp.json`                | Local configuration (user-customizable)    | Generated |
| `.gitignore`              | Excludes `.env` and `mcp.json` (if needed) | Committed |

### 2. Pre-Configured MCP Servers

| Server         | Purpose                            | Environment Variable Required  |
| :------------- | :--------------------------------- | :----------------------------- |
| `filesystem`   | Read/write files, list directories | None (auto-approved for reads) |
| `github`       | PR creation, issue management      | `GITHUB_TOKEN`                 |
| `brave-search` | Web search with AI summarization   | `BRAVE_API_KEY`                |
| `crawl4ai`     | Web scraping to Markdown           | None                           |
| `playwright`   | Browser automation                 | None                           |
| `devcontainer` | Container environment info         | None                           |
| `context7`     | Documentation queries with caching | `CONTEXT7_API_KEY`             |

### 3. Server-Specific Configuration

#### GitHub Server

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_TOKEN": "${env:GITHUB_TOKEN}" }
}
```

**Requirements**: Valid `GITHUB_TOKEN` in `.env`

#### Brave Search Server

```json
"brave-search": {
  "command": "npx",
  "args": ["-y", "@brave/brave-search-mcp-server"],
  "env": { "BRAVE_API_KEY": "${env:BRAVE_API_KEY}" }
}
```

**Requirements**: Valid `BRAVE_API_KEY` in `.env`

#### Context7 Server

```json
"context7": {
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp@latest"],
  "env": { "CONTEXT7_API_KEY": "${env:CONTEXT7_API_KEY}" }
}
```

**Requirements**: Valid `CONTEXT7_API_KEY` in `.env`

### 4. Customizing MCP Configuration

**Adding new servers**:

```json
// Add to servers object in mcp.json
"your-server": {
  "command": "npx",
  "args": ["-y", "your-mcp-server-package"],
  "env": {
    "YOUR_API_KEY": "${env:YOUR_API_KEY}"
  }
}
```

**Auto-approving tools** (use sparingly):

```json
"filesystem": {
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-filesystem",
    "${workspaceFolder}"
  ],
  "env": {},
  "autoApprove": ["read_file", "list_directory", "search_files"]
}
```

### 5. Agent Restart Requirement

**Critical**: After modifying `mcp.json`, restart the AI agent:

| Agent     | Restart Method                                    |
| :-------- | :------------------------------------------------ |
| Cline     | Click "Restart Agent" in sidebar or reload window |
| Kilo Code | Restart the extension or reload VS Code window    |

**Command to verify restart**:

```zsh
# After restart, check MCP servers are loaded
# Look for "MCP servers loaded" message in agent output
```

### 6. MCP Configuration Sign-Off

Before proceeding, verify:

- [ ] `mcp.json` created from `mcp/config.example.json`
- [ ] All server configurations are valid JSON
- [ ] Required environment variables are set
- [ ] Agent has been restarted after configuration

---

## Context Baseline Phase

**Objective**: Index current project state and initialize PROJECT_CONTEXT.md.

### 1. Project Structure Indexing

```zsh
# List top-level directories
ls -la

# Identify key directories
find . -maxdepth 2 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' | sort
```

**Expected Project Structure**:

```
ezrepo/
├── .airules/          # Workflow rules for AI agents
├── .clineignore       # Cline-specific ignore rules
├── .devcontainer/     # Dev container configuration
├── .vscode/           # VS Code settings
├── mcp/               # MCP server configurations
├── README.md          # Project documentation
├── AGENTS.md          # Agent instructions
├── PROJECT_CONTEXT.md.example  # Context template
└── mcp.json           # MCP configuration (generated)
```

### 2. File Content Analysis

**Key Files to Index**:

| File                         | Purpose for AI Context                |
| :--------------------------- | :------------------------------------ |
| `README.md`                  | Project overview and quick start      |
| `AGENTS.md`                  | Agent instructions and best practices |
| `PROJECT_CONTEXT.md.example` | Template for current project state    |
| `.airules/`                  | Workflow rules and processes          |
| `mcp/README.md`              | MCP server documentation              |

### 3. PROJECT_CONTEXT.md Initialization

**Copy template and populate**:

```zsh
# Copy template (if not already created)
cp PROJECT_CONTEXT.md.example PROJECT_CONTEXT.md

# Or create new file with template
cat > PROJECT_CONTEXT.md << 'EOF'
# PROJECT_CONTEXT.md

## 1. Project Identity & Purpose

> **Instruction for User**: Briefly describe what this specific project is building.

- **Project Name**: [Insert Name]
- **Goal**: [Describe the primary objective of the repository]
- **Base Template**: Ultimate Dev Environment Template (2026 standards).

## 2. Technical Environment (Immortal Context)

This project runs in a pre-configured Dev Container:

- **OS**: Ubuntu 24.04 (Multi-Arch).
- **Runtimes**: Node LTS and Python 3.12.
- **Shell**: Zsh + Oh My Zsh.
- **Editor Settings**: 4-space indentation and Prettier formatting are mandatory.
- **AI Constraints**: Built-in Copilot and VS Code AI features are fully disabled; you are the primary intelligence.

## 3. Toolchain & AI Capabilities (MCP)

You have active superpowers via Model Context Protocol (MCP) servers. Use them as follows:

- **Filesystem**: Auto-approved for `read_file`, `list_directory`, and `search_files`.
- **Context7**: Use this for version-specific library docs and code examples.
- **Brave Search**: Use for real-time web data and AI news.
- **Crawl4AI**: Use for high-fidelity web scraping into Markdown.
- **GitHub**: Full management of PRs, issues, and repo operations.

## 4. Architecture & Directory Map

> **Instruction for User**: Map out the key directories of your current project here.

- `/.devcontainer`: Environment configuration.
- `/mcp`: MCP server configurations and documentation.
- `/[src/app/lib]`: [Explain the project's specific folder structure].

## 5. Workflow Rules

- **Secret Management**: Never hardcode keys; use `.env` based on `.env.example`.
- **Coding Style**: Follow Prettier standards; focus on high-performance, cross-platform code (Windows, macOS, Linux).
- **Task Protocol**: Before starting a task, search the filesystem to understand current implementations.

## 6. Current Project State

> **Instruction for User**: Update this section regularly to keep the AI aligned.

- **Status**: [e.g., Initial Setup / Feature Development / Bug Fixing]
- **Next Milestone**: [What should the AI help with next?]
EOF
```

### 4. Git Baseline

```zsh
# Verify git status
git status

# View recent commits
git log --oneline -5

# Verify git remote
git remote -v
```

### 5. Context Baseline Sign-Off

Before proceeding, verify:

- [ ] Project structure documented in PROJECT_CONTEXT.md
- [ ] All key files indexed and understood
- [ ] Git status clean or changes documented
- [ ] Recent commits reviewed

---

## Validation & Verification Phase

**Objective**: Verify all onboarding steps completed successfully.

### 1. Environment Validation Checklist

```zsh
# Run comprehensive validation
echo "=== Environment Validation ==="

# Node.js
node --version && echo "✓ Node.js available"

# Python
python3 --version && echo "✓ Python available"

# Docker
docker --version && echo "✓ Docker available"

# Git
git --version && echo "✓ Git available"

# MCP config
[ -f mcp.json ] && echo "✓ mcp.json exists" || echo "✗ mcp.json missing"

# Environment file
[ -f .env ] && echo "✓ .env exists" || echo "✗ .env missing"

# Project context
[ -f PROJECT_CONTEXT.md ] && echo "✓ PROJECT_CONTEXT.md exists" || echo "✗ PROJECT_CONTEXT.md missing"

# Git
git log -1 >/dev/null 2>&1 && echo "✓ Git repository initialized" || echo "✗ Git not initialized"
```

### 2. MCP Server Test

```zsh
# Test filesystem server (auto-approved)
cat mcp.json

# Test git operations
git status

# Test Docker connection
docker info >/dev/null 2>&1 && echo "✓ Docker connection OK" || echo "⚠ Docker not running (may be expected in container)"
```

### 3. AI Agent Readiness

**For Cline/Kilo Code**:

- [ ] Agent restarted after `mcp.json` creation
- [ ] Agent shows MCP servers loaded
- [ ] Agent can access `filesystem` tools
- [ ] Agent can access configured API-based servers

**Agent Test Commands**:

```
# In agent chat, test each server:
filesystem/list_directory
filesystem/read_file (with path)
filesystem/search_files (with pattern)
github/list_issues (if GITHUB_TOKEN set)
brave-search/query (if BRAVE_API_KEY set)
context7/query (if CONTEXT7_API_KEY set)
```

### 4. Validation Sign-Off

Complete only when all checks pass:

- [ ] All environment versions verified
- [ ] `.env` file created with optional secrets
- [ ] `mcp.json` created and valid JSON
- [ ] Agent restarted after MCP configuration
- [ ] `PROJECT_CONTEXT.md` initialized
- [ ] Git repository initialized
- [ ] MCP servers accessible via agent

---

## Post-Onboarding

### 1. Next Steps

After successful onboarding:

1. **Review PROJECT_CONTEXT.md**: Update with specific project details
2. **Start Feature Lifecycle**: Follow `01-feature-lifecycle.md` for new features
3. **Configure Additional Tools**: Add project-specific configurations

### 2. Ongoing Maintenance

| Task                      | Frequency | Command/Action                            |
| :------------------------ | :-------- | :---------------------------------------- |
| Update dependencies       | Weekly    | `npm update`, `pip list --outdated`       |
| Rotate secrets            | Quarterly | Generate new tokens, update `.env`        |
| Review PROJECT_CONTEXT.md | Monthly   | Update with current project state         |
| MCP server updates        | As needed | Check for new versions, update `mcp.json` |

### 3. Documentation Updates

Update these files when onboarding changes:

- `PROJECT_CONTEXT.md` - Current project state
- `AGENTS.md` - If workflow rules change
- `.airules/workflows/` - If onboarding process changes

---

## Common Issues & Troubleshooting

### Issue 1: MCP Server Not Loading

**Symptoms**: Agent cannot access MCP tools after `mcp.json` creation.

**Diagnosis**:

```zsh
# Check mcp.json syntax
cat mcp.json | python3 -m json.tool

# Check for missing environment variables
grep -E "^\s+\"[A-Z_]+\"" mcp.json

# Verify environment file exists
ls -la .env
```

**Resolution**:

1. Verify `mcp.json` is valid JSON
2. Ensure required environment variables are in `.env`
3. Restart AI agent completely
4. Check agent logs for specific error messages

### Issue 2: Docker Connection Failed

**Symptoms**: `docker info` or `docker ps` fails in container.

**Diagnosis**:

```zsh
# Check if Docker daemon is running
docker info 2>&1 | head -20

# Check Docker socket
ls -la /var/run/docker.sock 2>/dev/null || echo "Docker socket not found"
```

**Resolution**:

- This is expected in some container configurations
- Docker-in-Docker requires special setup
- Verify `.devcontainer/devcontainer.json` has Docker access

### Issue 3: Node.js Version Mismatch

**Symptoms**: `node --version` shows unexpected version.

**Diagnosis**:

```zsh
# Check which Node is being used
which node
node --version

# Check nvm (if installed)
which nvm 2>/dev/null || echo "nvm not found"
```

**Resolution**:

- Node LTS is pre-configured in devcontainer
- Avoid using `nvm` inside container
- If version needs update, modify `.devcontainer/Dockerfile`

### Issue 4: Git Authentication Issues

**Symptoms**: Git operations fail with authentication errors.

**Diagnosis**:

```zsh
# Check git configuration
git config user.name
git config user.email

# Check remote configuration
git remote -v
```

**Resolution**:

```zsh
# Configure git if missing
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# For GitHub operations, ensure GITHUB_TOKEN is set
```

### Issue 5: PROJECT_CONTEXT.md Outdated

**Symptoms**: AI agent provides incorrect context about project state.

**Resolution**:

1. Update PROJECT_CONTEXT.md with current status
2. Index any new directories or files
3. Document any breaking changes

---

## Quick Reference

### Onboarding Commands

| Action                        | Command                                                   |
| :---------------------------- | :-------------------------------------------------------- |
| Verify all dependencies       | `node --version && python3 --version && docker --version` |
| Create MCP configuration      | `cp mcp/config.example.json mcp.json`                     |
| Create environment file       | `cp .env.example .env`                                    |
| Copy project context template | `cp PROJECT_CONTEXT.md.example PROJECT_CONTEXT.md`        |
| Validate environment          | `cat .env && cat mcp.json && ls -la PROJECT_CONTEXT.md`   |
| Test Docker connection        | `docker info`                                             |
| Check git status              | `git status`                                              |

### Critical Files

| File                         | Purpose                                  | Status    |
| :--------------------------- | :--------------------------------------- | :-------- |
| `.env`                       | Environment variables (API keys, tokens) | Generated |
| `mcp.json`                   | MCP server configuration                 | Generated |
| `PROJECT_CONTEXT.md`         | Current project state for AI context     | Generated |
| `mcp/config.example.json`    | MCP configuration template               | Committed |
| `PROJECT_CONTEXT.md.example` | Project context template                 | Committed |
| `.env.example`               | Environment template (no secrets)        | Committed |

### Environment Variables Reference

| Variable           | Required For                      | Security Level |
| :----------------- | :-------------------------------- | :------------- |
| `GITHUB_TOKEN`     | GitHub API, PR creation, repo ops | High           |
| `BRAVE_API_KEY`    | Brave Search MCP server           | Medium         |
| `CONTEXT7_API_KEY` | Upstash Context7 documentation    | Medium         |

### MCP Servers Quick Reference

| Server       | Command in Agent Chat       |
| :----------- | :-------------------------- |
| Filesystem   | `filesystem/list_directory` |
| GitHub       | `github/list_issues`        |
| Brave Search | `brave-search/query`        |
| Crawl4AI     | `crawl4ai/fetch`            |
| Playwright   | `playwright/new_page`       |
| DevContainer | `devcontainer/info`         |
| Context7     | `context7/query`            |

### Validation Commands

```zsh
# Comprehensive validation script
#!/bin/zsh
echo "=== Onboarding Validation ==="

# 1. Runtime versions
echo -n "Node.js: "; node --version
echo -n "npm: "; npm --version
echo -n "Python: "; python3 --version
echo -n "Docker: "; docker --version

# 2. File checks
[ -f .env ] && echo "✓ .env exists" || echo "✗ .env missing"
[ -f mcp.json ] && echo "✓ mcp.json exists" || echo "✗ mcp.json missing"
[ -f PROJECT_CONTEXT.md ] && echo "✓ PROJECT_CONTEXT.md exists" || echo "✗ PROJECT_CONTEXT.md missing"

# 3. Git
git log -1 >/dev/null 2>&1 && echo "✓ Git repository initialized" || echo "✗ Git not initialized"

# 4. Docker (optional)
docker info >/dev/null 2>&1 && echo "✓ Docker accessible" || echo "⚠ Docker check skipped"
```

### Workflow Decision Tree

```
Start Onboarding
    │
    ├─→ System Dependencies Verified?
    │   ├─ No → Install missing dependencies
    │   └─ Yes → Secret Initialization Phase
    │
    ├─→ .env Created?
    │   ├─ No → cp .env.example .env
    │   └─ Yes → MCP Configuration Phase
    │
    ├─→ mcp.json Created?
    │   ├─ No → cp mcp/config.example.json mcp.json
    │   └─ Yes → Agent Restart Required
    │
    ├─→ Agent Restarted?
    │   ├─ No → Restart AI agent
    │   └─ Yes → Context Baseline Phase
    │
    ├─→ PROJECT_CONTEXT.md Updated?
    │   ├─ No → Copy template and populate
    │   └─ Yes → Validation Phase
    │
    └─→ All Checks Pass?
        ├─ Yes → Onboarding Complete
        └─ No → Review troubleshooting guide
```

### Agent Chat Commands Reference

After onboarding, use these commands in agent chat:

```
# Test filesystem (always available)
filesystem/list_directory

# Test GitHub (requires GITHUB_TOKEN)
github/list_issues

# Test Brave Search (requires BRAVE_API_KEY)
brave-search/query

# Test Context7 (requires CONTEXT7_API_KEY)
context7/query

# Test Docker
execute_command with "docker ps"

# Test browser automation (requires agent restart)
playwright/new_page
```

---

## Revision History

| Version | Date       | Changes                                                                                                                                  |
| :------ | :--------- | :--------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | Initial    | Basic 4-step onboarding workflow                                                                                                         |
| 2.0     | 2026-03-19 | Complete rewrite: added core principles, prerequisites, phases, checklists, troubleshooting guide, quick reference, and revision history |

---

**End of Onboarding Workflow**
