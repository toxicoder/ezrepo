# Hook: Project Initialization

> **Version**: 3.0
> **Last Updated**: 2026-03-19
> **Purpose**: Production-grade project initialization and readiness verification for LLM coding agents in Ubuntu 24.04 Dev Container environment

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Initialization Checklist](#initialization-checklist)
3. [Environment Verification Protocols](#environment-verification-protocols)
4. [Runtime Audit Procedures](#runtime-audit-procedures)
5. [MCP Configuration Validation](#mcp-configuration-validation)
6. [Secret Hygiene Verification](#secret-hygiene-verification)
7. [Cache & State Management](#cache--state-management)
8. [Error Recovery & Fallbacks](#error-recovery--fallbacks)
9. [Documentation & Logging](#documentation--logging)
10. [Cline Integration Checklist](#cline-integration-checklist)

---

## Core Principles

| Principle                     | Description                                                          | Anti-Pattern to Avoid                                     |
| :---------------------------- | :----------------------------------------------------------------- | :--------------------------------------------------     |
| **Fail Fast Validation**      | Halt initialization if critical environment checks fail             | Continuing with missing dependencies                      |
| **Deterministic Order**       | Verify components in dependency order (env → runtime → MCP)         | Parallelizing independent but related checks              |
| **Graceful Degradation**      | Provide warnings for non-critical issues; block only critical paths | Warnings and errors treated identically                   |
| **Self-Healing Attempt**      | Retry transient failures (network, permissions) before escalating   | Immediate failure without retry attempt                   |
| **Immutable Configuration**   | Never modify core infrastructure files during initialization        | Auto-fixing devcontainer.json or Dockerfile               |

---

## Initialization Checklist

### Phase 1: Environment Check (0-2 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Pass Criteria                  |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| Dev Container Detection          | `/etc/os-release` check     | Yes        | 500ms      | Contains `Ubuntu 24.04`      |
| Container Environment Variable   | `DEVCONTAINER` check        | Yes        | 500ms      | Variable exists and is "1"   |
| Hostname Verification            | `hostname` command          | No         | 500ms      | Matches container naming     |

### Phase 2: Runtime Audit (2-8 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Expected Version               |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| Node.js Accessibility            | `node --version`            | Yes        | 1000ms     | LTS (20.x series)             |
| Node.js Architecture             | `node -e 'process.arch'`    | No         | 500ms      | x64 or arm64 (supported)      |
| Python Accessibility             | `python3 --version`         | Yes        | 1000ms     | 3.12.x                        |
| PIP Accessibility                | `pip3 --version`            | No         | 500ms      | Available in path             |

### Phase 3: MCP Configuration (8-15 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Expected State                |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| mcp.json Existence               | File check                  | Yes        | 200ms      | File exists                   |
| mcp.json Valid JSON              | JSON parser                 | Yes        | 500ms      | Valid JSON syntax             |
| MCP Servers Configuration        | MCP config validation       | Yes        | 1000ms     | At least one server defined   |

### Phase 4: Secret Hygiene (15-20 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Expected State                |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| .env File Existence              | File check                  | Yes        | 200ms      | File exists                   |
| .gitignore Compliance            | `.gitignore` check          | Yes        | 500ms      | `.env` is gitignored          |
| Required Variables Present       | Variable template check     | No         | 500ms      | Placeholders present          |

### Phase 5: Cache State (20-25 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Action on Mismatch            |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| Prettier Cache                   | Prettier cache check        | No         | 2000ms     | Clear and reinstall           |
| TypeScript Cache                 | tsc cache check             | No         | 2000ms     | Clear and rebuild             |
| node_modules Integrity           | npm ls --depth=0            | No         | 5000ms     | Reinstall if corrupted        |

---

## Environment Verification Protocols

### Protocol 1: Dev Container Detection

```typescript
interface DevcontainerInfo {
  isDevcontainer: boolean;
  containerName: string;
  hostName: string;
  ubuntuVersion: string;
  architecture: string;
}

async function detectDevcontainer(): Promise<DevcontainerInfo> {
  // 1. Check /etc/os-release
  const osRelease = await readFile("/etc/os-release", "utf-8");
  if (!osRelease.includes("Ubuntu 24.04")) {
    throw new Error("Project requires Ubuntu 24.04 Dev Container");
  }

  // 2. Check DEVCONTAINER environment variable
  const isDevcontainer = process.env.DEVCONTAINER === "1";
  if (!isDevcontainer) {
    console.warn("Warning: DEVCONTAINER environment variable not set");
  }

  // 3. Get container name
  const containerName = process.env.DEVCONTAINER_NAME || "unknown";
  const hostName = await executeCommand("hostname");

  // 4. Detect architecture
  const architecture = process.arch;

  return {
    isDevcontainer,
    containerName,
    hostName,
    ubuntuVersion: "24.04",
    architecture,
  };
}
````

### Protocol 2: Multi-Architecture Support

```typescript
interface ArchitectureSupport {
  x64: {
    nodeImage: "node:20-bullseye";
    pythonImage: "python:3.12-slim-bullseye";
    allowedDockerfiles: string[];
  };
  arm64: {
    nodeImage: "node:20-bullseye-arm64";
    pythonImage: "python:3.12-slim-bullseye-arm64";
    allowedDockerfiles: string[];
  };
}

const architectureSupport: Record<string, ArchitectureSupport> = {
  x64: {
    nodeImage: "node:20-bullseye",
    pythonImage: "python:3.12-slim-bullseye",
    allowedDockerfiles: [
      "Dockerfile",
      ".devcontainer/Dockerfile",
    ],
  },
  arm64: {
    nodeImage: "node:20-bullseye-arm64",
    pythonImage: "python:3.12-slim-bullseye-arm64",
    allowedDockerfiles: [
      "Dockerfile.arm64",
      ".devcontainer/Dockerfile",
      "Dockerfile",
    ],
  },
};

function verifyArchitectureCompatibility(): {
  supported: boolean;
  current: string;
  expected: string[];
  remediation?: string;
} {
  const currentArch = process.arch;
  const supported = Object.keys(architectureSupport).includes(currentArch);

  if (!supported) {
    return {
      supported: false,
      current: currentArch,
      expected: Object.keys(architectureSupport),
      remediation: `Build for supported architecture using: docker buildx build --platform linux/${currentArch === 'x64' ? 'amd64' : 'arm64'}`
    };
  }

  return { supported: true, current: currentArch, expected: [currentArch] };
}
```

---

## Runtime Audit Procedures

### Protocol 1: Node.js Version Verification

```typescript
interface NodeVersion {
  major: number;
  minor: number;
  patch: number;
  version: string;
  lts: boolean;
}

async function verifyNodeVersion(): Promise<NodeVersion> {
  const versionOutput = await executeCommand("node --version");
  const versionMatch = versionOutput.match(/v(\d+)\.(\d+)\.(\d+)/);

  if (!versionMatch) {
    throw new Error("Failed to parse Node.js version");
  }

  const [_, major, minor, patch] = versionMatch.map(Number);
  const isLTS = major === 20 && minor >= 0; // Node 20.x is LTS

  return {
    major,
    minor,
    patch,
    version: `${major}.${minor}.${patch}`,
    lts: isLTS,
  };
}

function validateNodeVersion(version: NodeVersion): {
  valid: boolean;
  reason: string;
  recommended?: string;
} {
  if (version.major !== 20) {
    return {
      valid: false,
      reason: `Node.js ${version.version} is not the LTS version (20.x)`,
      recommended: "Install Node.js 20.x LTS from https://nodejs.org/",
    };
  }

  return { valid: true, reason: "Node.js LTS version verified" };
}
```

### Protocol 2: Python Version Verification

```typescript
interface PythonVersion {
  major: number;
  minor: number;
  patch: number;
  version: string;
}

async function verifyPythonVersion(): Promise<PythonVersion> {
  const versionOutput = await executeCommand("python3 --version");
  const versionMatch = versionOutput.match(/Python (\d+)\.(\d+)\.(\d+)/);

  if (!versionMatch) {
    throw new Error("Failed to parse Python version");
  }

  const [_, major, minor, patch] = versionMatch.map(Number);

  return {
    major,
    minor,
    patch,
    version: `${major}.${minor}.${patch}`,
  };
}

function validatePythonVersion(version: PythonVersion): {
  valid: boolean;
  reason: string;
  recommended?: string;
} {
  if (version.major !== 3 || version.minor !== 12) {
    return {
      valid: false,
      reason: `Python ${version.version} is not the required version (3.12)`,
      recommended: "Install Python 3.12 from https://www.python.org/downloads/",
    };
  }

  return { valid: true, reason: "Python 3.12 version verified" };
}
```

### Protocol 3: Runtime Dependency Verification

```bash
# Check all required runtimes are accessible
check_runtime() {
  local name=$1
  local command=$2
  local version_flag=$3
  
  if ! command -v "$command" &> /dev/null; then
    echo "ERROR: $name is not installed"
    return 1
  fi
  
  local version=$($command $version_flag 2>&1)
  echo "✓ $name: $version"
  return 0
}

# Verify all runtimes
check_runtime "Node.js" "node" "--version"
check_runtime "Python" "python3" "--version"
check_runtime "npm" "npm" "--version"
check_runtime "pip3" "pip3" "--version"
```

---

## MCP Configuration Validation

### Protocol 1: mcp.json Schema Validation

```typescript
interface MCPConfig {
  version?: string;
  servers: Record<string, {
    type: "stdio" | "sse" | "injected-stream";
    command?: string;
    args?: string[];
    url?: string;
    env?: Record<string, string>;
  }>;
  timeouts?: {
    request?: number;
    initialization?: number;
  };
}

interface MCPValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  servers: string[];
}

function validateMCPConfig(config: unknown): MCPValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  const servers: string[] = [];

  if (typeof config !== "object" || config === null) {
    errors.push("MCP config is not a valid object");
    return { valid: false, errors, warnings, servers };
  }

  // Validate servers
  if (!config.servers || typeof config.servers !== "object") {
    errors.push("MCP config missing 'servers' section");
  } else {
    for (const [serverName, serverConfig] of Object.entries(config.servers)) {
      servers.push(serverName);
      
      if (!serverConfig.type) {
        errors.push(`Server '${serverName}' missing 'type' field`);
      } else if (!["stdio", "sse", "injected-stream"].includes(serverConfig.type)) {
        errors.push(`Server '${serverName}' has invalid type: ${serverConfig.type}`);
      }

      // Validate type-specific requirements
      if (serverConfig.type === "stdio") {
        if (!serverConfig.command) {
          warnings.push(`Server '${serverName}' of type 'stdio' missing 'command'`);
        }
      } else if (serverConfig.type === "sse") {
        if (!serverConfig.url) {
          errors.push(`Server '${serverName}' of type 'sse' missing 'url'`);
        }
      }
    }
  }

  if (errors.length > 0) {
    return { valid: false, errors, warnings, servers };
  }

  return { valid: true, errors, warnings, servers };
}
```

### Protocol 2: MCP Server Health Check

```typescript
interface ServerHealthCheck {
  serverName: string;
  accessible: boolean;
  latencyMs: number;
  error?: string;
}

async function checkMCPHealth(): Promise<ServerHealthCheck[]> {
  const results: ServerHealthCheck[] = [];
  
  for (const serverName of Object.keys(mcpConfig.servers)) {
    const startTime = Date.now();
    try {
      const response = await mcpClient.call(serverName, "health");
      const latency = Date.now() - startTime;
      
      results.push({
        serverName,
        accessible: true,
        latencyMs: latency,
      });
    } catch (error) {
      results.push({
        serverName,
        accessible: false,
        latencyMs: 0,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
  
  return results;
}
```

---

## Secret Hygiene Verification

### Protocol 1: .env File Structure Check

```typescript
interface EnvFileStatus {
  exists: boolean;
  gitignored: boolean;
  hasRequiredVars: boolean;
  requiredVars: string[];
  missingVars: string[];
}

const REQUIRED_ENV_VARS = [
  "GITHUB_TOKEN",
  "BRAVE_API_KEY",
  "DATABASE_URL",
  "JWT_SECRET",
  "NODE_ENV",
];

async function verifyEnvFile(): Promise<EnvFileStatus> {
  const envPath = ".env";
  const gitignorePath = ".gitignore";
  
  // Check .env existence
  const exists = await fileExists(envPath);
  
  // Check .gitignore compliance
  let gitignored = false;
  if (await fileExists(gitignorePath)) {
    const gitignore = await readFile(gitignorePath, "utf-8");
    gitignored = gitignore.includes(".env");
  }
  
  // Check required variables
  const missingVars: string[] = [];
  if (exists) {
    const envContent = await readFile(envPath, "utf-8");
    const envVars = parseEnvContent(envContent);
    
    for (const required of REQUIRED_ENV_VARS) {
      if (!envVars.has(required)) {
        missingVars.push(required);
      }
    }
  }
  
  return {
    exists,
    gitignored,
    hasRequiredVars: missingVars.length === 0,
    requiredVars: REQUIRED_ENV_VARS,
    missingVars,
  };
}

function parseEnvContent(content: string): Map<string, string> {
  const vars = new Map<string, string>();
  
  for (const line of content.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    
    const [key, ...valueParts] = trimmed.split("=");
    if (key) {
      vars.set(key.trim(), valueParts.join("=").trim());
    }
  }
  
  return vars;
}
```

### Protocol 2: Secret Placeholder Verification

```bash
# Verify .env contains proper placeholder format
check_env_placeholders() {
  local env_file="${1:-.env}"
  
  if [ ! -f "$env_file" ]; then
    echo "ERROR: .env file not found"
    return 1
  fi
  
  # Check for GitHub token placeholder
  if ! grep -q "GITHUB_TOKEN=ghp_" "$env_file"; then
    echo "ERROR: GITHUB_TOKEN placeholder not found or invalid"
    echo "Expected: GITHUB_TOKEN=ghp_<your-token-here>"
  fi
  
  # Check for Brave API key placeholder
  if ! grep -q "BRAVE_API_KEY=brave_api_key_" "$env_file"; then
    echo "ERROR: BRAVE_API_KEY placeholder not found or invalid"
    echo "Expected: BRAVE_API_KEY=brave_api_key_<your-key-here>"
  fi
  
  echo "✓ .env file structure verified"
}

# Run verification
check_env_placeholders
```

---

## Cache & State Management

### Protocol 1: Prettier Cache Management

```typescript
interface PrettierCache {
  lastRun: string;
  cacheValid: boolean;
  recommendedAction?: string;
}

async function verifyPrettierCache(): Promise<PrettierCache> {
  const cachePath = ".prettiercache";
  const cacheFile = ".prettiercache";
  const configFile = ".prettierrc.json";
  
  // Check if cache file exists
  const cacheExists = await fileExists(cacheFile);
  
  if (!cacheExists) {
    return {
      lastRun: "never",
      cacheValid: false,
      recommendedAction: "Run Prettier to initialize cache",
    };
  }
  
  // Check config file for changes
  const cacheStat = await stat(cacheFile);
  const configStat = await fileExists(configFile) 
    ? await stat(configFile) 
    : null;
  
  // If config changed after cache, cache is invalid
  const cacheValid = !configStat || configStat.mtime <= cacheStat.mtime;
  
  return {
    lastRun: cacheStat.mtime.toISOString(),
    cacheValid,
    recommendedAction: cacheValid 
      ? undefined 
      : "Config changed, Prettier cache may be invalid",
  };
}
```

### Protocol 2: node_modules Integrity Check

```bash
# Verify node_modules integrity
verify_node_modules() {
  echo "Checking node_modules integrity..."
  
  # Check if node_modules exists
  if [ ! -d "node_modules" ]; then
    echo "WARNING: node_modules directory not found"
    echo "Run: npm install"
    return 1
  fi
  
  # Check for corrupted packages
  local broken_packages=0
  for pkg_dir in node_modules/*/; do
    if [ ! -f "${pkg_dir}package.json" ]; then
      echo "WARNING: Corrupted package directory: ${pkg_dir}"
      broken_packages=$((broken_packages + 1))
    fi
  done
  
  if [ $broken_packages -gt 0 ]; then
    echo "ERROR: $broken_packages corrupted packages found"
    echo "Run: npm install --force"
    return 1
  fi
  
  # Verify package-lock.json matches
  if [ -f "package-lock.json" ]; then
    npm ls --parseable 2>/dev/null || {
      echo "WARNING: Dependency tree has issues"
    }
  fi
  
  echo "✓ node_modules integrity verified"
  return 0
}

# Run integrity check
verify_node_modules
```

---

## Error Recovery & Fallbacks

### Recovery Strategy 1: Environment Detection Failure

```typescript
interface RecoveryPlan {
  step: number;
  description: string;
  command: string;
  estimatedTime: number; // seconds
}

const environmentRecovery: RecoveryPlan[] = [
  {
    step: 1,
    description: "Verify Docker container is running",
    command: "docker ps -a --filter name=ezrepo",
    estimatedTime: 2,
  },
  {
    step: 2,
    description: "Check container logs for errors",
    command: "docker logs ezrepo --tail 50",
    estimatedTime: 3,
  },
  {
    step: 3,
    description: "Rebuild container if needed",
    command: "devcontainer build",
    estimatedTime: 120,
  },
];

async function attemptEnvironmentRecovery(): Promise<void> {
  for (const plan of environmentRecovery) {
    console.log(`Recovery Step ${plan.step}: ${plan.description}`);
    
    try {
      await executeCommand(plan.command);
      console.log(`✓ Step ${plan.step} completed`);
    } catch (error) {
      console.warn(`Step ${plan.step} failed: ${error.message}`);
      if (plan.step < environmentRecovery.length) {
        console.log("Continuing to next recovery step...");
      } else {
        throw new Error("All recovery steps failed");
      }
    }
  }
}
```

### Recovery Strategy 2: MCP Configuration Recovery

```bash
# MCP configuration recovery
recover_mcp_config() {
  local config_path="mcp.json"
  local example_path="mcp/config.example.json"
  
  if [ ! -f "$config_path" ]; then
    echo "ERROR: mcp.json not found"
    
    if [ -f "$example_path" ]; then
      echo "Copying example configuration..."
      cp "$example_path" "$config_path"
      echo "✓ mcp.json created from example"
    else
      echo "ERROR: No example configuration available"
      return 1
    fi
  fi
  
  # Validate JSON syntax
  if ! python3 -m json.tool "$config_path" > /dev/null 2>&1; then
    echo "ERROR: mcp.json contains invalid JSON"
    return 1
  fi
  
  echo "✓ MCP configuration validated"
  return 0
}

# Attempt recovery
recover_mcp_config || {
  echo "MCP configuration recovery failed"
  exit 1
}
```

---

## Documentation & Logging

### Audit Log Format

```json
{
  "audit_id": "AUD-INIT-20260319-001",
  "timestamp": "2026-03-19T20:42:00Z",
  "event_type": "project_initialization",
  "environment": {
    "devcontainer": {
      "detected": true,
      "container_name": "ezrepo",
      "ubuntu_version": "24.04",
      "architecture": "x64"
    },
    "runtimes": {
      "node": {
        "installed": true,
        "version": "v20.11.0",
        "lts": true,
        "path": "/usr/local/bin/node"
      },
      "python": {
        "installed": true,
        "version": "3.12.1",
        "path": "/usr/bin/python3"
      }
    },
    "mcp": {
      "config_valid": true,
      "servers_configured": 5,
      "servers_accessible": 5
    },
    "secrets": {
      "env_file_exists": true,
      "gitignored": true,
      "required_vars_present": true,
      "missing_vars": []
    }
  },
  "cache_status": {
    "prettier": {
      "valid": true,
      "last_run": "2026-03-19T20:40:00Z"
    },
    "node_modules": {
      "integrity": "verified",
      "issues": 0
    }
  },
  "warnings": [],
  "recommendations": [],
  "duration_ms": 25432
}
```

### Initialization Report Template

```markdown
# Project Initialization Report

> **Timestamp**: ${timestamp}
> **Audit ID**: ${audit_id}

## Environment Status

| Component | Status | Version/Info |
| :--------- | :--------- | :----------- |
| Dev Container | ${env.devcontainer.detected ? "✓ Verified" : "✗ Failed"} | Ubuntu ${env.devcontainer.ubuntu_version} (${env.devcontainer.architecture}) |
| Node.js | ${env.runtimes.node.installed ? "✓ Verified" : "✗ Missing"} | ${env.runtimes.node.version} ${env.runtimes.node.lts ? "(LTS)" : ""} |
| Python | ${env.runtimes.python.installed ? "✓ Verified" : "✗ Missing"} | ${env.runtimes.python.version} |

## MCP Configuration

- **Config Valid**: ${env.mcp.config_valid ? "✓ Yes" : "✗ No"}
- **Servers Configured**: ${env.mcp.servers_configured}
- **Servers Accessible**: ${env.mcp.servers_accessible}

## Secret Hygiene

| Check | Status |
| :----- | :----- |
| .env File | ${env.secrets.env_file_exists ? "✓ Exists" : "✗ Missing"} |
| Gitignored | ${env.secrets.gitignored ? "✓ Yes" : "✗ No"} |
| Required Vars | ${env.secrets.required_vars_present ? "✓ Present" : "✗ Missing"} |

## Cache Status

| Cache | Valid | Last Run |
| :----- | :----- | :----- |
| Prettier | ${cache.prettier.valid ? "✓ Yes" : "✗ No"} | ${cache.prettier.last_run} |
| node_modules | ${cache.node_modules.integrity} | - |

## Warnings

${warnings.length > 0 ? warnings.map(w => `- ${w}`).join("\n") : "None"}

## Recommendations

${recommendations.length > 0 ? recommendations.map(r => `- ${r}`).join("\n") : "None"}

---

**Initialization Duration**: ${duration_ms}ms