# Hook: Task Preparation

> **Version**: 3.0
> **Last Updated**: 2026-03-19
> **Purpose**: Production-grade task preparation with context synchronization, dependency validation, and safety protocol enforcement

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Preparation Checklist](#preparation-checklist)
3. [Context Synchronization Protocols](#context-synchronization-protocols)
4. [Dependency Validation Procedures](#dependency-validation-procedures)
5. [Safety Protocol Enforcement](#safety-protocol-enforcement)
6. [Resource Availability Checks](#resource-availability-checks)
7. [Task Validation & Approval](#task-validation--approval)
8. [Configuration Verification](#configuration-verification)
9. [Error Recovery & Fallbacks](#error-recovery--fallbacks)
10. [Cline Integration Checklist](#cline-integration-checklist)

---

## Core Principles

| Principle                     | Description                                                          | Anti-Pattern to Avoid                                     |
| :---------------------------- | :----------------------------------------------------------------- | :--------------------------------------------------     |
| **Context-Driven Execution**  | All tasks must be aligned with current project state                | Proceeding with stale or outdated context                 |
| **Dependency-First Approach** | Validate all dependencies before task execution                     | Starting tasks with missing or outdated dependencies      |
| **Safety-First Design**       | Prevent destructive operations without proper verification          | Executing destructive commands without prior checks       |
| **Resource-Aware Planning**   | Verify resource availability before task start                      | Starting resource-intensive tasks without verification    |
| **Validation-Driven Workflow**| Block task execution if any validation fails                        | Proceeding with tasks that have known issues              |

---

## Preparation Checklist

### Phase 1: Context Synchronization (0-5 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Action on Failure             |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| PROJECT_CONTEXT.md Read          | File read                   | Yes        | 500ms      | Block task                    |
| Current Status Extract           | Section parsing             | Yes        | 500ms      | Block task                    |
| Task Alignment Check             | Context comparison          | Yes        | 1000ms     | Block task                    |

### Phase 2: Dependency Validation (5-15 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Pass Criteria                 |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| Library Documentation Check      | context7 cache              | Yes        | 5000ms     | Cached or fetched             |
| Package.json Sync                | npm ls                      | Yes        | 2000ms     | No orphaned packages          |
| Dependency Tree Integrity        | npm ls --all                | No         | 3000ms     | No duplicate/resolution errors|

### Phase 3: Safety Protocol (15-20 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Action                        |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| Destructive Command Check        | Command parsing             | Yes        | 500ms      | Block + require approval      |
| Target Path Verification         | list_directory              | Yes        | 500ms      | Confirm path exists           |
| Environment Variable Check       | process.env validation      | Yes        | 200ms      | All required vars present     |

### Phase 4: Resource Availability (20-30 seconds)

| Check                            | Tool/Command                | Critical | Timeout | Pass Criteria                 |
| :--------------------------      | :-------------------------  | :--------- | :--------- | :-----------------------      |
| Disk Space Check                 | df -h                       | No         | 500ms      | >10% free space               |
| Memory Check                     | free -m                     | No         | 500ms      | >20% available memory         |
| Node.js Memory Limit             | node --v8-options           | No         | 500ms      | Sufficient heap size          |

---

## Context Synchronization Protocols

### Protocol 1: PROJECT_CONTEXT.md Reading

```typescript
interface ProjectContext {
  version: string;
  projectTitle: string;
  projectDescription: string;
  currentStatus: {
    activeMilestones: string[];
    recentAccomplishments: string[];
    pendingTasks: string[];
    knownIssues: string[];
  };
  architecture: {
    overview: string;
    keyComponents: Record<string, string>;
    technologyStack: string[];
  };
  features: {
    [featureName: string]: {
      status: "planned" | "in-progress" | "completed";
      description: string;
      completedAt?: string;
    };
  };
  bugfixes: {
    [bugId: string]: {
      description: string;
      status: "open" | "in-progress" | "resolved";
      fixedIn?: string;
    };
  };
  lastUpdated: string;
  lastUpdatedBy: string;
}

async function readProjectContext(): Promise<ProjectContext> {
  const contextPath = "PROJECT_CONTEXT.md";
  
  if (!(await fileExists(contextPath))) {
    throw new Error("PROJECT_CONTEXT.md not found");
  }
  
  const content = await readFile(contextPath, "utf-8");
  const parsed = parseProjectContextMarkdown(content);
  
  return parsed;
}

function parseProjectContextMarkdown(content: string): ProjectContext {
  // Parse YAML frontmatter if present
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
  const frontmatter = frontmatterMatch ? parseYAML(frontmatterMatch[1]) : {};
  
  // Extract sections
  const sections = extractMarkdownSections(content);
  
  return {
    version: frontmatter.version || "1.0.0",
    projectTitle: sections["Project Title"]?.content || "Unknown Project",
    projectDescription: sections["Description"]?.content || "",
    currentStatus: {
      activeMilestones: parseList(sections["Active Milestones"]?.content || ""),
      recentAccomplishments: parseList(sections["Recent Accomplishments"]?.content || ""),
      pendingTasks: parseList(sections["Pending Tasks"]?.content || ""),
      knownIssues: parseList(sections["Known Issues"]?.content || ""),
    },
    architecture: {
      overview: sections["Architecture"]?.content || "",
      keyComponents: parseKeyValueList(sections["Key Components"]?.content || ""),
      technologyStack: parseList(sections["Technology Stack"]?.content || ""),
    },
    features: parseFeatures(sections["Features"]?.content || ""),
    bugfixes: parseBugfixes(sections["Bugfixes"]?.content || ""),
    lastUpdated: frontmatter.lastUpdated || new Date().toISOString(),
    lastUpdatedBy: frontmatter.lastUpdatedBy || "system",
  };
}
````

### Protocol 2: Task Alignment Validation

```typescript
interface TaskAlignmentResult {
  aligned: boolean;
  alignmentScore: number; // 0-100
  conflicts: TaskConflict[];
  recommendations: string[];
}

interface TaskConflict {
  type: "milestone" | "feature" | "architecture" | "priority";
  current: string;
  proposed: string;
  resolution?: string;
}

async function validateTaskAlignment(
  task: string,
  context: ProjectContext
): Promise<TaskAlignmentResult> {
  const conflicts: TaskConflict[] = [];
  const recommendations: string[] = [];
  
  // Check if task is listed in pending tasks
  const pendingTasks = context.currentStatus.pendingTasks;
  const taskIsPending = pendingTasks.some(t => 
    t.toLowerCase().includes(task.toLowerCase())
  );
  
  if (!taskIsPending && pendingTasks.length > 0) {
    recommendations.push(
      "Task not in pending tasks list. Consider adding to PROJECT_CONTEXT.md"
    );
  }
  
  // Check against active milestones
  const activeMilestones = context.currentStatus.activeMilestones;
  for (const milestone of activeMilestones) {
    if (task.toLowerCase().includes(milestone.toLowerCase())) {
      conflicts.push({
        type: "milestone",
        current: milestone,
        proposed: task,
        resolution: "Task aligns with milestone - proceed",
      });
    }
  }
  
  // Calculate alignment score
  let alignmentScore = 100;
  
  if (taskIsPending) alignmentScore -= 10; // Task is pending - good
  if (conflicts.length > 0) alignmentScore -= conflicts.length * 15;
  if (pendingTasks.length === 0) alignmentScore -= 20; // No pending tasks defined
  
  alignmentScore = Math.max(0, Math.min(100, alignmentScore));
  
  return {
    aligned: alignmentScore >= 70,
    alignmentScore,
    conflicts,
    recommendations,
  };
}
````

---

## Dependency Validation Procedures

### Protocol 1: context7 Documentation Check

```typescript
interface DependencyCheckResult {
  library: string;
  version: string;
  cached: boolean;
  documentationUrl?: string;
  notes?: string[];
}

async function validateLibraryDocumentation(
  libraries: string[]
): Promise<DependencyCheckResult[]> {
  const results: DependencyCheckResult[] = [];
  
  for (const library of libraries) {
    const version = await getLibraryVersion(library);
    
    // Check if documentation is cached in context7
    const cacheInfo = await checkContext7Cache(library, version);
    
    results.push({
      library,
      version,
      cached: cacheInfo.isCached,
      documentationUrl: cacheInfo.documentationUrl,
      notes: cacheInfo.notes || [],
    });
  }
  
  return results;
}

interface Context7CacheInfo {
  isCached: boolean;
  documentationUrl?: string;
  notes?: string[];
}

async function checkContext7Cache(
  library: string,
  version: string
): Promise<Context7CacheInfo> {
  // Attempt to query context7
  try {
    const result = await context7.search(library, version, "documentation");
    
    return {
      isCached: result.cached,
      documentationUrl: result.documentUrl,
      notes: result.notes || [],
    };
  } catch (error) {
    return {
      isCached: false,
      documentationUrl: undefined,
      notes: [`context7 query failed: ${error.message}`],
    };
  }
}
````

### Protocol 2: Package.json Synchronization

```bash
# Validate package.json dependencies
validate_dependencies() {
  echo "Validating dependencies..."
  
  # Check for orphaned packages (installed but not in package.json)
  echo "Checking for orphaned packages..."
  npm ls --depth=0 --parseable 2>/dev/null | while read -r pkg; do
    if [ -n "$pkg" ]; then
      # Check if package is in package.json
      local pkg_name=$(basename "$pkg")
      if ! grep -q "\"$pkg_name\":" package.json; then
        echo "WARNING: Orphaned package: $pkg_name"
      fi
    fi
  done
  
  # Check for missing packages (in package.json but not installed)
  echo "Checking for missing packages..."
  npm ls --depth=0 --parseable 2>/dev/null || {
    echo "ERROR: Dependency tree has issues"
    echo "Run: npm install"
    return 1
  }
  
  # Check for duplicate versions
  echo "Checking for duplicate versions..."
  npm ls 2>/dev/null | grep -E "deduped|invalid" && {
    echo "WARNING: Duplicate versions or invalid dependencies found"
  }
  
  echo "✓ Dependency validation completed"
  return 0
}

# Run dependency validation
validate_dependencies
```

### Protocol 3: Package Lock Verification

```typescript
interface LockFileCheck {
  packageJsonValid: boolean;
  packageLockValid: boolean;
  packagesMatch: boolean;
  missingPackages: string[];
  extraPackages: string[];
}

async function verifyLockFile(): Promise<LockFileCheck> {
  const packageJson = await readPackageJson();
  const packageLock = await readPackageLock();
  
  const packageJsonDeps = Object.keys(packageJson.dependencies || {});
  const packageLockDeps = Object.keys(packageLock.packages || {});
  
  // Remove node_modules prefix from lock file keys
  const normalizedLockDeps = packageLockDeps
    .filter(k => !k.startsWith("node_modules/"))
    .map(k => k.replace(/^node_modules\//, ""));
  
  const missing = packageJsonDeps.filter(d => !normalizedLockDeps.includes(d));
  const extra = normalizedLockDeps.filter(d => !packageJsonDeps.includes(d));
  
  return {
    packageJsonValid: true, // Basic validation
    packageLockValid: true, // Basic validation
    packagesMatch: missing.length === 0 && extra.length === 0,
    missingPackages: missing,
    extraPackages: extra,
  };
}
````

---

## Safety Protocol Enforcement

### Protocol 1: Destructive Command Detection

```typescript
interface DestructiveCommand {
  command: string;
  type: "deletion" | "overwrite" | "format" | "system";
  riskLevel: "low" | "medium" | "high" | "critical";
  approvalRequired: boolean;
}

interface CommandAnalysis {
  command: string;
  isDestructive: boolean;
  destructiveDetails?: DestructiveCommand;
  safeAlternatives?: string[];
  warnings: string[];
}

const destructivePatterns: DestructiveCommand[] = [
  {
    command: "rm -rf",
    type: "deletion",
    riskLevel: "critical",
    approvalRequired: true,
  },
  {
    command: "rm -r",
    type: "deletion",
    riskLevel: "high",
    approvalRequired: true,
  },
  {
    command: "rm",
    type: "deletion",
    riskLevel: "medium",
    approvalRequired: false,
  },
  {
    command: "mkfs",
    type: "format",
    riskLevel: "critical",
    approvalRequired: true,
  },
  {
    command: "dd if=",
    type: "overwrite",
    riskLevel: "critical",
    approvalRequired: true,
  },
  {
    command: "apt remove",
    type: "system",
    riskLevel: "high",
    approvalRequired: true,
  },
  {
    command: "pip uninstall",
    type: "system",
    riskLevel: "medium",
    approvalRequired: false,
  },
];

async function analyzeCommandSafety(command: string): Promise<CommandAnalysis> {
  const warnings: string[] = [];
  const safeAlternatives: string[] = [];
  
  // Check against destructive patterns
  for (const pattern of destructivePatterns) {
    if (command.includes(pattern.command)) {
      const isDestructive = true;
      
      warnings.push(
        `Command contains destructive pattern: ${pattern.command}`,
        `Risk level: ${pattern.riskLevel}`,
        `Approval required: ${pattern.approvalRequired ? "YES" : "No"}`
      );
      
      if (pattern.approvalRequired) {
        safeAlternatives.push(
          `Use dry-run first: ${command} --dry-run`,
          `Add -i flag for interactive mode: ${command} -i`
        );
      }
      
      return {
        command,
        isDestructive,
        destructiveDetails: pattern,
        safeAlternatives,
        warnings,
      };
    }
  }
  
  // Check for dangerous shell constructs
  if (command.includes("$(cat") || command.includes("`cat")) {
    warnings.push("Potential command injection via command substitution");
    safeAlternatives.push("Use safer input methods");
  }
  
  return {
    command,
    isDestructive: false,
    warnings,
  };
}
````

### Protocol 2: Target Path Verification

```typescript
interface PathVerification {
  path: string;
  exists: boolean;
  isDirectory: boolean;
  permissions: string;
  requiredAction?: "create" | "access" | "none";
}

async function verifyTargetPath(target: string): Promise<PathVerification> {
  // Check if path exists
  let exists = false;
  let isDirectory = false;
  let permissions = "unknown";
  
  try {
    const stat = await stat(target);
    exists = true;
    isDirectory = stat.isDirectory();
    permissions = stat.mode.toString(8);
  } catch (error) {
    if (error.code === "ENOENT") {
      exists = false;
    } else {
      permissions = "permission_error";
    }
  }
  
  // Determine required action
  let requiredAction: PathVerification["requiredAction"] = "none";
  
  if (!exists) {
    // Path doesn't exist - may need to create
    requiredAction = "create";
  } else if (!isDirectory && target.endsWith("/")) {
    // Target is directory path but file exists
    requiredAction = "none"; // Likely an error condition
  }
  
  return {
    path: target,
    exists,
    isDirectory,
    permissions,
    requiredAction,
  };
}

async function confirmPathAccess(
  target: string
): Promise<{
  allowed: boolean;
  reason?: string;
}> {
  const verification = await verifyTargetPath(target);
  
  if (!verification.exists) {
    return {
      allowed: false,
      reason: `Path does not exist: ${target}`,
    };
  }
  
  if (verification.permissions.startsWith("000")) {
    return {
      allowed: false,
      reason: `No permissions to access: ${target}`,
    };
  }
  
  return { allowed: true };
}
````

---

## Resource Availability Checks

### Protocol 1: Disk Space Check

```typescript
interface DiskSpaceInfo {
  total: number; // bytes
  used: number; // bytes
  available: number; // bytes
  usagePercent: number;
}

async function checkDiskSpace(): Promise<DiskSpaceInfo> {
  const result = await executeCommand("df -B1 . 2>&1");
  const lines = result.trim().split("\n");
  
  // Parse df output
  // Example: Filesystem     1B-blocks     Used Available Use% Mounted on
  const dataLine = lines[1];
  const parts = dataLine.split(/\s+/);
  
  if (parts.length < 5) {
    throw new Error("Failed to parse df output");
  }
  
  const total = parseInt(parts[1]);
  const used = parseInt(parts[2]);
  const available = parseInt(parts[3]);
  
  return {
    total,
    used,
    available,
    usagePercent: (used / total) * 100,
  };
}

function validateDiskSpace(info: DiskSpaceInfo): {
  sufficient: boolean;
  recommendation?: string;
} {
  const MIN_AVAILABLE_PERCENT = 10;
  
  if (info.usagePercent > 90) {
    return {
      sufficient: false,
      recommendation: "Disk usage is above 90%. Consider cleaning up.",
    };
  }
  
  if (info.usagePercent > 80) {
    return {
      sufficient: true,
      recommendation: "Disk usage is above 80%. Monitor for cleanup opportunities.",
    };
  }
  
  return { sufficient: true };
}
````

### Protocol 2: Memory Check

```bash
# Check system memory availability
check_memory() {
  echo "Checking system memory..."
  
  # Get memory info from /proc/meminfo
  local total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local available_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
  
  if [ -z "$available_mem" ]; then
    # Fallback for older kernels
    local free_mem=$(grep MemFree /proc/meminfo | awk '{print $2}')
    local buffers=$(grep Buffers /proc/meminfo | awk '{print $2}')
    local cached=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
    local available_mem=$((free_mem + buffers + cached))
  fi
  
  # Calculate percentage
  local usage_percent=$((100 - (available_mem * 100 / total_mem)))
  
  echo "Total Memory: $((total_mem / 1024)) MB"
  echo "Available Memory: $((available_mem / 1024)) MB"
  echo "Memory Usage: ${usage_percent}%"
  
  if [ $usage_percent -gt 90 ]; then
    echo "WARNING: Memory usage is above 90%"
    return 1
  elif [ $usage_percent -gt 80 ]; then
    echo "WARNING: Memory usage is above 80%"
    return 0
  fi
  
  echo "✓ Memory check passed"
  return 0
}

# Run memory check
check_memory
```

---

## Task Validation & Approval

### Protocol 1: Task Description Quality

```typescript
interface TaskValidation {
  valid: boolean;
  score: number;
  issues: TaskIssue[];
  recommendations: string[];
}

interface TaskIssue {
  type: "length" | "clarity" | "scope" | "specificity";
  severity: "low" | "medium" | "high";
  description: string;
}

async function validateTaskDescription(
  task: string
): Promise<TaskValidation> {
  const issues: TaskIssue[] = [];
  const recommendations: string[] = [];
  
  // Check task length
  if (task.length < 10) {
    issues.push({
      type: "length",
      severity: "medium",
      description: "Task description is very brief (less than 10 characters)",
    });
    recommendations.push("Provide more specific details about the task");
  }
  
  if (task.length > 1000) {
    issues.push({
      type: "length",
      severity: "low",
      description: "Task description is very long (more than 1000 characters)",
    });
    recommendations.push("Consider breaking into smaller tasks");
  }
  
  // Check for specificity
  const vagueWords = ["something", "thing", " stuff", "fix", "update"];
  for (const word of vagueWords) {
    if (new RegExp(`\\b${word}\\b`, "i").test(task)) {
      issues.push({
        type: "specificity",
        severity: "medium",
        description: `Task contains vague word: "${word}"`,
      });
      recommendations.push("Replace with specific technical requirements");
      break;
    }
  }
  
  // Check for actionable language
  const actionVerbs = ["add", "create", "update", "modify", "refactor", "fix"];
  const hasActionVerb = actionVerbs.some(verb => 
    new RegExp(`\\b${verb}\\b`, "i").test(task)
  );
  
  if (!hasActionVerb) {
    issues.push({
      type: "scope",
      severity: "low",
      description: "Task description may lack clear action verb",
    });
    recommendations.push("Ensure task has clear action item");
  }
  
  // Calculate validation score
  let score = 100;
  for (const issue of issues) {
    switch (issue.severity) {
      case "high":
        score -= 30;
        break;
      case "medium":
        score -= 15;
        break;
      case "low":
        score -= 5;
        break;
    }
  }
  score = Math.max(0, score);
  
  return {
    valid: score >= 70,
    score,
    issues,
    recommendations,
  };
}
````

### Protocol 2: Approval Workflow

```typescript
interface ApprovalRequest {
  task: string;
  riskLevel: "low" | "medium" | "high" | "critical";
  approvalType: "standard" | "urgent" | "emergency";
  requiredFor: string[];
  timestamp: string;
}

interface ApprovalResponse {
  approved: boolean;
  approvedBy?: string;
  timestamp: string;
  conditions?: string[];
}

async function requestTaskApproval(
  task: string,
  riskLevel: ApprovalRequest["riskLevel"]
): Promise<ApprovalResponse> {
  const approvalRequest: ApprovalRequest = {
    task,
    riskLevel,
    approvalType: determineApprovalType(riskLevel),
    requiredFor: getRequiredStakeholders(riskLevel),
    timestamp: new Date().toISOString(),
  };
  
  // Log approval request
  await logApprovalRequest(approvalRequest);
  
  // For critical/high risk, require explicit approval
  if (riskLevel === "critical" || riskLevel === "high") {
    const response = await getUserApproval(approvalRequest);
    return response;
  }
  
  // For medium/low risk, auto-approve with notification
  return {
    approved: true,
    timestamp: new Date().toISOString(),
  };
}

function determineApprovalType(riskLevel: string): ApprovalRequest["approvalType"] {
  switch (riskLevel) {
    case "critical":
      return "emergency";
    case "high":
      return "urgent";
    default:
      return "standard";
  }
}

function getRequiredStakeholders(riskLevel: string): string[] {
  // In production, this would look up team members
  return ["project-lead"];
}
````

---

## Configuration Verification

### Protocol 1: Tool Configuration Check

```typescript
interface ToolConfig {
  name: string;
  path: string;
  version: string;
  configPath?: string;
  valid: boolean;
  issues?: string[];
}

async function verifyToolConfigurations(): Promise<ToolConfig[]> {
  const tools: ToolConfig[] = [
    { name: "node", path: "node", version: "20.x", configPath: undefined },
    { name: "npm", path: "npm", version: "9.x", configPath: undefined },
    { name: "tsc", path: "npx tsc", version: "5.x", configPath: "tsconfig.json" },
    { name: "eslint", path: "npx eslint", version: "8.x", configPath: ".eslintrc.json" },
    { name: "prettier", path: "npx prettier", version: "3.x", configPath: ".prettierrc.json" },
  ];
  
  const results: ToolConfig[] = [];
  
  for (const tool of tools) {
    const issues: string[] = [];
    
    // Check if tool is accessible
    try {
      const versionOutput = await executeCommand(`${tool.path} --version 2>&1`);
      const versionMatch = versionOutput.match(/(\d+)\.(\d+)\.(\d+)/);
      
      if (!versionMatch) {
        issues.push(`Failed to parse version: ${versionOutput}`);
      }
    } catch (error) {
      issues.push(`Tool not accessible: ${error.message}`);
    }
    
    // Check config file if specified
    if (tool.configPath && (await fileExists(tool.configPath))) {
      // Config exists and is readable
    } else if (tool.configPath) {
      issues.push(`Config file not found: ${tool.configPath}`);
    }
    
    results.push({
      ...tool,
      valid: issues.length === 0,
      issues,
    });
  }
  
  return results;
}
````

---

## Error Recovery & Fallbacks

### Recovery Strategy 1: Context Recovery

```typescript
interface ContextRecoveryPlan {
  fallbackContext: ProjectContext;
  recoveryMethod: "previous_commit" | "template" | "user_input";
  estimatedAccuracy: number; // 0-100
}

async function recoverProjectContext(): Promise<ContextRecoveryPlan> {
  // Try to load from previous commit
  try {
    const commitContent = await executeCommand(
      "git show HEAD:PROJECT_CONTEXT.md 2>/dev/null"
    );
    
    if (commitContent) {
      const fallbackContext = parseProjectContextMarkdown(commitContent);
      
      return {
        fallbackContext,
        recoveryMethod: "previous_commit",
        estimatedAccuracy: 95,
      };
    }
  } catch (error) {
    // Fall through to next option
  }
  
  // Use template if available
  if (await fileExists("PROJECT_CONTEXT.md.example")) {
    const templateContent = await readFile("PROJECT_CONTEXT.md.example", "utf-8");
    
    return {
      fallbackContext: parseProjectContextMarkdown(templateContent),
      recoveryMethod: "template",
      estimatedAccuracy: 70,
    };
  }
  
  // Create minimal context from git
  const gitInfo = await getGitInfo();
  
  return {
    fallbackContext: createMinimalContext(gitInfo),
    recoveryMethod: "git_analysis",
    estimatedAccuracy: 50,
  };
}

function createMinimalContext(gitInfo: {
  branch: string;
  commit: string;
  lastCommitMessage: string;
}): ProjectContext {
  return {
    version: "0.0.1",
    projectTitle: "Unknown Project",
    projectDescription: "Context recovery from git",
    currentStatus: {
      activeMilestones: [],
      recentAccomplishments: [gitInfo.lastCommitMessage],
      pendingTasks: [],
      knownIssues: [],
    },
    architecture: {
      overview: "Unknown",
      keyComponents: {},
      technologyStack: [],
    },
    features: {},
    bugfixes: {},
    lastUpdated: new Date().toISOString(),
    lastUpdatedBy: "system",
  };
}
````

### Recovery Strategy 2: Dependency Recovery

```bash
# Dependency recovery workflow
recover_dependencies() {
  echo "Starting dependency recovery..."
  
  # Step 1: Clean npm cache
  echo "1. Cleaning npm cache..."
  npm cache clean --force || echo "  Cache clean warning (non-fatal)"
  
  # Step 2: Remove node_modules
  echo "2. Removing node_modules..."
  rm -rf node_modules || echo "  node_modules removal skipped (may not exist)"
  
  # Step 3: Remove package-lock.json
  echo "3. Removing package-lock.json..."
  rm -f package-lock.json || echo "  package-lock.json removal skipped (may not exist)"
  
  # Step 4: Reinstall dependencies
  echo "4. Installing dependencies..."
  npm install || {
    echo "ERROR: npm install failed"
    return 1
  }
  
  # Step 5: Verify installation
  echo "5. Verifying installation..."
  npm ls --depth=0 || {
    echo "ERROR: Dependency verification failed"
    return 1
  }
  
  echo "✓ Dependency recovery completed"
  return 0
}

# Attempt dependency recovery
recover_dependencies || {
  echo "Dependency recovery failed"
  exit 1
}
```

---

## Cline Integration Checklist

### Pre-Task Verification

- [ ] PROJECT_CONTEXT.md read successfully
- [ ] Current status extracted and validated
- [ ] Task alignment verified with project milestones
- [ ] Pending tasks reviewed

### Dependency Validation Phase

- [ ] Library documentation checked in context7
- [ ] Package.json synchronized
- [ ] Dependency tree validated
- [ ] Package lock verified

### Safety Protocol Phase

- [ ] Destructive commands identified
- [ ] Target paths verified
- [ ] Environment variables checked
- [ ] Risk level assessed

### Resource Verification Phase

- [ ] Disk space sufficient
- [ ] Memory availability confirmed
- [ ] Node.js memory limit adequate

### Configuration Phase

- [ ] Tool configurations validated
- [ ] Config file syntax checked
- [ ] MCP configuration verified

### Task Approval Phase

- [ ] Task description quality assessed
- [ ] Approval requested (if required)
- [ ] User notified of findings

---

## Configuration Reference

### `.airules/config/pre-task.json`

```json
{
  "version": "3.0",
  "contextSync": {
    "timeout": 5000,
    "validateProjectContext": true,
    "requireActiveMilestones": true,
    "taskAlignmentScoreThreshold": 70
  },
  "dependencyValidation": {
    "timeout": 15000,
    "checkDocumentation": true,
    "useContext7Cache": true,
    "validateLockFile": true,
    "allowMissingDependencies": false
  },
  "safetyProtocol": {
    "timeout": 20000,
    "detectDestructiveCommands": true,
    "requirePathVerification": true,
    "checkEnvironmentVariables": true,
    "approvalThreshold": "medium"
  },
  "resourceChecks": {
    "timeout": 10000,
    "checkDiskSpace": true,
    "minFreeSpacePercent": 10,
    "checkMemory": true,
    "minAvailableMemoryPercent": 20,
    "checkNodeHeap": true,
    "minNodeHeapMB": 512
  },
  "approval": {
    "autoApproveLowRisk": true,
    "requireApprovalFor": ["critical", "high"],
    "approvalTimeoutSeconds": 300,
    "escalateAfterTimeout": true
  },
  "notifications": {
    "slackWebhook": "${SLACK_WEBHOOK_URL}",
    "emailRecipients": ["team@company.com"],
    "notifyOnApprovalRequest": true
  }
}
```

---

## Revision History

| Version | Date       | Changes    |
| :------ | :--------- | :--------- |
| 1.0     | Initial    | Basic 3-point preparation protocol |
| 2.0     | 2026-03-19 | Enhanced with dependency checks, safety protocols |
| 3.0     | 2026-03-19 | Complete rewrite: comprehensive validation, MCP integration, approval workflows, configuration |

---

**End of Task Preparation Hook**