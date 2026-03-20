# Secret Hygiene

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade approach to managing secrets, API keys, and sensitive credentials

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Types of Secrets to Protect](#types-of-secrets-to-protect)
3. [Environment File Best Practices](#environment-file-best-practices)
4. [Gitignore Compliance](#gitignore-compliance)
5. [Detection and Prevention](#detection-and-prevention)
6. [Secret Rotation Procedures](#secret-rotation-procedures)
7. [Common Anti-Patterns](#common-anti-patterns)
8. [Verification & Validation](#verification--validation)
9. [Security Checklist](#security-checklist)

---

## Core Principles

| Principle                 | Description                                                               | Anti-Pattern to Avoid                             |
| :------------------------ | :------------------------------------------------------------------------ | :------------------------------------------------ |
| **Zero Exposure**         | Never commit secrets to any repository, even "private" ones               | Adding `.env` files to git history                |
| **Environment Isolation** | Separate credentials per environment (dev, staging, production)           | Using production secrets in development           |
| **Least Privilege**       | Use tokens with minimal required permissions                              | Using admin-level tokens for read-only operations |
| **Rotation Regular**      | Rotate secrets on a schedule and immediately after any potential exposure | Keeping the same credentials for months           |
| **Audit Trail**           | Log and monitor secret access for security breaches                       | No monitoring of credential usage                 |

---

## Types of Secrets to Protect

### Category 1: API Credentials

| Secret Type           | Examples                                          | Risk Level |
| :-------------------- | :------------------------------------------------ | :--------- |
| Cloud Provider Tokens | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`      | Critical   |
| API Keys              | `GITHUB_TOKEN`, `BRAVE_API_KEY`, `OPENAI_API_KEY` | High       |
| Service Keys          | `STRIPE_SECRET_KEY`, `SENDGRID_API_KEY`           | High       |

### Category 2: Database Credentials

| Secret Type        | Examples                             | Risk Level |
| :----------------- | :----------------------------------- | :--------- |
| Connection Strings | `DATABASE_URL`, `MONGODB_URI`        | Critical   |
| Database Passwords | `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD` | High       |

### Category 3: Authentication Secrets

| Secret Type       | Examples                                      | Risk Level |
| :---------------- | :-------------------------------------------- | :--------- |
| JWT Secrets       | `JWT_SECRET`, `SESSION_SECRET`                | Critical   |
| OAuth Credentials | `GOOGLE_CLIENT_SECRET`, `FACEBOOK_APP_SECRET` | High       |

### Category 4: Infrastructure Secrets

| Secret Type     | Examples                        | Risk Level |
| :-------------- | :------------------------------ | :--------- |
| SSH Keys        | `SSH_PRIVATE_KEY`, `DEPLOY_KEY` | Critical   |
| Encryption Keys | `ENCRYPTION_KEY`, `MASTER_KEY`  | High       |

---

## Environment File Best Practices

### `.env` File Structure

```zsh
# ✓ Correct: Organized by category
# API Keys
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxx
BRAVE_API_KEY=brave_api_key_xxxxxxxxxxxxxx

# Database
DATABASE_URL=postgres://user:password@localhost:5432/dbname

# Authentication
JWT_SECRET=your_super_secret_jwt_key_here

# Environment
NODE_ENV=development
API_URL=http://localhost:3000
```

### File Naming Conventions

| File Name          | Purpose                                 | Gitignore   |
| :----------------- | :-------------------------------------- | :---------- |
| `.env`             | Local development secrets               | ✓ Ignored   |
| `.env.example`     | Template showing required variables     | ✓ Committed |
| `.env.development` | Development environment-specific values | ✓ Ignored   |
| `.env.staging`     | Staging environment-specific values     | ✓ Ignored   |
| `.env.production`  | Production environment-specific values  | ✓ Ignored   |

### Environment Variable Validation

Always validate required environment variables at application startup:

```typescript
// ✓ Good: Validate required variables
const requiredEnvVars = ["DATABASE_URL", "JWT_SECRET", "API_KEY"];

const missingVars = requiredEnvVars.filter((varName) => !process.env[varName]);

if (missingVars.length > 0) {
  throw new Error(
    `Missing required environment variables: ${missingVars.join(", ")}`,
  );
}

// Safe to use now
const dbUrl = process.env.DATABASE_URL;
```

---

## Gitignore Compliance

### Required `.gitignore` Entries

```gitignore
# Environment files - NEVER commit these
.env
.env.*
!.env.example

# AWS credentials
.aws/credentials
~/.aws/credentials

# SSH keys
*.pem
*.key
id_rsa
id_ed25519

# Node modules (standard)
node_modules/

# IDE specific
.idea/
.vscode/

# Generated secrets
credentials.json
service-account.json
```

### What NOT to Gitignore

| File                         | Reason to Commit                               |
| :--------------------------- | :--------------------------------------------- |
| `.env.example`               | ✓ Template helps team know required variables  |
| `mcp/config.example.json`    | ✓ Shows structure for MCP server configuration |
| `PROJECT_CONTEXT.md.example` | ✓ Template for project documentation           |

---

## Detection and Prevention

### Pre-Commit Secret Scanning

Always run secret scanning before committing:

```zsh
# Install git-secrets (if not already installed)
brew install git-secrets  # macOS
apt-get install git-secrets  # Ubuntu

# Scan repository for secrets
git secrets --register-aws
git secrets --scan

# Scan specific file
git secrets --scan path/to/file
```

### Manual Detection Patterns

Search for common secret patterns before committing:

```zsh
# Look for hardcoded secrets
grep -r "TOKEN=" .
grep -r "API_KEY=" .
grep -r "PASSWORD=" .
grep -r "SECRET=" .

# Look for common secret name patterns
grep -r "(token|secret|key|password|credential)" --include="*.ts" --include="*.js" .
```

### Automated Scanning Tools

| Tool               | Purpose                                   | Integration      |
| :----------------- | :---------------------------------------- | :--------------- |
| **git-secrets**    | Scan for AWS, GitHub, and common patterns | Local pre-commit |
| **truffleHog**     | Deep secrets scanning in git history      | CI/CD pipeline   |
| **gitleaks**       | Detect hardcoded secrets in codebase      | GitHub Actions   |
| **detect-secrets** | Yelp's secret scanning tool               | CI/CD pipeline   |

### CI/CD Secret Scanning Integration

```yaml
# .github/workflows/secret-scan.yml
name: Secret Scanning

on: [pull_request, push]

jobs:
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Secret Rotation Procedures

### Scheduled Rotation Checklist

| Frequency     | Actions                          | Verification      |
| :------------ | :------------------------------- | :---------------- |
| **Daily**     | Review access logs for anomalies | Alerting system   |
| **Weekly**    | Rotate non-critical API keys     | Test integrations |
| **Monthly**   | Rotate database passwords        | Connection test   |
| **Quarterly** | Rotate all credentials           | Full audit        |
| **Annually**  | Comprehensive security review    | External audit    |

### Rotation Process

```mermaid
graph TD
    A[Identify Secret to Rotate] --> B[Generate New Secret]
    B --> C[Update in Environment]
    C --> D[Update in All Services]
    D --> E[Test All Integrations]
    E --> F[Revoke Old Secret]
    F --> G[Document Rotation]
```

### Emergency Rotation (When Compromised)

1. **Immediately revoke** the exposed secret
2. **Generate new secret** with different parameters
3. **Update all systems** using the old secret
4. **Review access logs** for unauthorized use
5. **Investigate** how the secret was exposed
6. **Implement prevention** measures
7. **Document incident** and response actions

---

## Common Anti-Patterns

### Anti-Pattern 1: Hardcoded Secrets

```typescript
// ✗ BAD: Hardcoded credentials
const config = {
  apiKey: "sk-proj-1234567890abcdef",
  databaseUrl: "postgres://admin:secretpass@db.example.com",
};
```

**Correct Approach:**

```typescript
// ✓ GOOD: Environment-based
const config = {
  apiKey: process.env.API_KEY,
  databaseUrl: process.env.DATABASE_URL,
};
```

### Anti-Pattern 2: Secret in Comments

```typescript
// ✗ BAD: Secret in code comment
// API_KEY=sk-proj-1234567890abcdef
function fetchData() {
  // ...
}
```

### Anti-Pattern 3: Secret in Error Messages

```typescript
// ✗ BAD: Exposes secret in error
if (!apiKey) {
  throw new Error(`API key is missing. Expected: ${process.env.API_KEY}`);
}
```

**Correct Approach:**

```typescript
// ✓ GOOD: Generic error message
if (!apiKey) {
  throw new Error(
    "API key configuration is invalid. Please check your .env file.",
  );
}
```

### Anti-Pattern 4: Secret in Logs

```typescript
// ✗ BAD: Logging secrets
app.use((req, res, next) => {
  logger.info(`Request with API key: ${req.headers["x-api-key"]}`);
  next();
});
```

**Correct Approach:**

```typescript
// ✓ GOOD: Masked logging
app.use((req, res, next) => {
  const apiKey = req.headers["x-api-key"];
  logger.info(
    `Request with API key: ${apiKey ? "***" + apiKey.slice(-4) : "none"}`,
  );
  next();
});
```

### Anti-Pattern 5: Committing `.env` to Git

```zsh
# ✗ BAD: Adding .env to git
echo "API_KEY=sk-proj-1234567890abcdef" >> .env
git add .env
git commit -m "Add API key"
```

**Recovery Steps if Accidentally Committed:**

1. **Revoke the exposed secret immediately**
2. **Remove from git history:**
   ```zsh
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch .env' \
   --prune-empty --tag-name-filter cat -- --all
   ```
3. **Force push to remote:**
   ```zsh
   git push origin --force --all
   git push origin --force --tags
   ```
4. **Generate new secret**
5. **Update all services**

---

## Verification & Validation

### Environment Variable Validation Checklist

- [ ] All required variables are defined in `.env`
- [ ] `.env.example` contains all required variables (without values)
- [ ] No secrets in `.env` files that are committed
- [ ] Environment variables use appropriate naming conventions
- [ ] No hardcoded secrets in source code

### Pre-Commit Checklist

Before committing code, verify:

- [ ] No API keys in source files
- [ ] No database passwords in code
- [ ] No secret tokens in comments
- [ ] No hardcoded credentials in configuration
- [ ] `.gitignore` includes all `.env` patterns
- [ ] Secrets are masked in any debug output

### Code Review Checklist

When reviewing PRs, check for:

- [ ] No `.env` file changes (unless .env.example)
- [ ] No secret patterns in new code
- [ ] Error messages don't expose secrets
- [ ] Logging doesn't include sensitive data
- [ ] Configuration uses environment variables

---

## Security Checklist

### Daily

- [ ] Monitor access logs for anomalies
- [ ] Check for unexpected secret usage

### Weekly

- [ ] Rotate non-critical API keys
- [ ] Review which services have which credentials

### Monthly

- [ ] Rotate database credentials
- [ ] Audit who has access to which secrets

### Quarterly

- [ ] Full credential rotation
- [ ] Security audit and penetration testing

### Annually

- [ ] External security review
- [ ] Update secret hygiene policies
- [ ] Security training for team

---

## Quick Reference: Secret Patterns to Detect

Use these grep patterns to search for hardcoded secrets:

```zsh
# API Keys (generic patterns)
grep -r "[A-Za-z0-9_\-]{20,}" .

# GitHub tokens
grep -r "ghp_[A-Za-z0-9]{36}" .
grep -r "github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59}" .

# AWS credentials
grep -r "AKIA[A-Z0-9]{16}" .
grep -r "aws_secret_access_key" .

# OpenAI tokens
grep -r "sk-proj-[A-Za-z0-9]{48}" .
grep -r "sk-[A-Za-z0-9]{20,}" .

# Generic secrets
grep -r "api_key\s*=" .
grep -r "password\s*=" .
grep -r "secret\s*=" .
grep -r "token\s*=" .
```

---

## Emergency Contact & Response

### If a Secret is Exposed

1. **Immediate Action:**
   - Revoke the exposed secret
   - Generate a new secret
   - Update all affected services

2. **Documentation:**
   - Record when exposure was discovered
   - Document steps taken to contain
   - Note which systems may have been affected

3. **Post-Incident:**
   - Review how exposure occurred
   - Implement preventive measures
   - Update training if needed

---

## Revision History

| Version | Date       | Changes                                                                                                                                  |
| :------ | :--------- | :--------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | Initial    | Basic 2-point protocol                                                                                                                   |
| 2.0     | 2026-03-19 | Complete rewrite: added categories, rotation procedures, anti-patterns, verification checklists, detection tools, and emergency response |

---

**End of Secret Hygiene Protocol**
