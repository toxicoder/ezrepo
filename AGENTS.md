# AGENTS.md — Instructions for AI Assistants

This file provides the necessary context and rules for any AI agent (Kilo Code, Cline, etc.) operating within this repository.

## 🛠 Model Context Protocol (MCP) Usage

This repository provides access to MCP (Model Context Protocol) servers that extend an agent's capabilities. The available servers depend on your environment configuration.

### Common MCP Server Categories

| Category                 | Purpose                                  | Usage Notes                                       |
| :----------------------- | :--------------------------------------- | :------------------------------------------------ |
| **Filesystem**           | Read/write files and list directories    | Use for project navigation and file manipulation. |
| **Search/Documentation** | Web search and documentation lookups     | Useful for finding latest APIs or library docs.   |
| **Database**             | Query databases and manage data          | Use for data persistence and retrieval.           |
| **Version Control**      | Git operations and repository management | Use for PRs, issues, and commit operations.       |
| **Browser Automation**   | Browser control and web scraping         | Use for testing, scraping, or UI interactions.    |
| **API Integration**      | Call external APIs and services          | Use for third-party service integration.          |

### General Guidelines

- **Check your MCP configuration** (`mcp.json` or similar) to see available servers in your environment
- **Use the right tool for the job** - prefer native MCP tools over manual alternatives when available
- **Handle errors gracefully** - MCP servers may fail; implement appropriate fallbacks
- **Respect rate limits** - external services may have usage limits
- **Security considerations** - never expose sensitive credentials through MCP calls

### Typical MCP Tools Available

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

## 📏 Coding & Formatting Standards

### Indentation & Syntax

- **Indentation**: Always use **4 spaces**; never use tabs.
- **Line Length**: Maximum 80 characters per line.
- **Line Endings**: Use Unix-style (`\n`) line endings.
- **Trailing Spaces**: Remove all trailing whitespace on save.
- **Semicolons**: Use semicolons consistently in JavaScript/TypeScript.

### Naming Conventions

- **Files**: Use `kebab-case` for file names (e.g., `user-service.ts`, `api-client.js`).
- **Directories**: Use `kebab-case` for directory names.
- **Variables/Functions**: Use `camelCase` (e.g., `userName`, `getUserData()`).
- **Classes/Types/Interfaces**: Use `PascalCase` (e.g., `UserService`, `UserProfile`).
- **Constants**: Use `UPPER_SNAKE_CASE` (e.g., `MAX_RETRIES`, `API_URL`).
- **Private Members**: Prefix private class properties/methods with `_` (e.g., `_privateMethod()`).
- **Boolean Variables**: Prefix with `is`, `has`, or `should` (e.g., `isLoading`, `hasError`, `shouldUpdate`).

### Code Structure & Patterns

- **Function Length**: Keep functions focused and concise (ideally <50 lines).
- **Single Responsibility**: Each function should do one thing well.
- **DRY Principle**: Avoid code duplication; extract common logic into reusable functions.
- **Explicit Over Implicit**: Prefer clear, explicit code over clever one-liners.
- **Error Handling**: Use try-catch blocks for async operations and handle errors gracefully.

### Imports & Dependencies

- **Order**: Group imports as: Built-in modules → External packages → Internal imports → Relative imports.
- **Aliases**: Use path aliases for internal imports (e.g., `@/services/api` instead of `../../services/api`).
- **Wildcard Imports**: Avoid wildcard imports (`import * as ...`); use named imports instead.

### Documentation Standards

- **Comments**: Add comments for complex logic, not obvious code. Prefer self-documenting code.
- **JSDoc/TSDoc**: Document all public functions, classes, and interfaces with proper docblocks.
- **README Files**: Include a README.md in each major directory explaining its purpose and contents.
- **TODO Comments**: Use `// TODO: [description]` or `// TODO(#issue): [description]` format.
- **Inline Comments**: Use sparingly; only for non-obvious implementation details.

### Error Handling & Logging

- **Errors**: Throw meaningful errors with descriptive messages.
- **Logging**: Use consistent log levels (debug, info, warn, error). Include relevant context in log messages.
- **Validation**: Validate all external inputs and provide clear error messages for invalid data.
- **Fallbacks**: Provide sensible fallbacks when data or services are unavailable.

### Testing Requirements

- **Unit Tests**: Write unit tests for all public functions and critical business logic.
- **Test Naming**: Use descriptive test names following `function_case_what_it_should_do` pattern.
- **Test Coverage**: Aim for >80% coverage for core logic.
- **Mocking**: Use mocks for external dependencies (APIs, databases).

### Performance Considerations

- **Efficiency**: Consider time/space complexity; avoid unnecessary nested loops.
- **Lazy Loading**: Implement lazy loading for heavy components and routes.
- **Caching**: Cache expensive computations and frequently accessed data.
- **Optimization**: Profile before optimizing; focus on critical paths.

### Type Safety

Type safety helps catch errors early and improves code maintainability. Use appropriate type checking mechanisms for each language:

- **TypeScript/JavaScript**: Enable strict type checking with `strict: true` in `tsconfig.json`. Avoid `any` types; use `unknown` or proper types instead. Define interfaces for complex data structures and use enums for fixed value sets.

- **Python**: Use type hints for all function signatures and variable assignments (PEP 484). Run type checkers like `mypy`, `pytype`, or `pyright` in CI. Consider using `TypedDict` for dictionary structures and `Protocol` for structural subtyping.

- **General**: Prefer immutability where possible. Use sealed classes/enums for closed sets of values. Document type invariants in comments or assertions when necessary.

> **Note**: Even dynamically typed languages benefit from explicit type annotations. Type hints serve as executable documentation and enable static analysis tools to catch bugs before runtime.

### Accessibility (Web Projects)

- **ARIA**: Use proper ARIA attributes for interactive elements.
- **Keyboard Nav**: Ensure all functionality is accessible via keyboard.
- **Contrast**: Maintain minimum 4.5:1 text-to-background contrast ratio.
- **Alt Text**: Provide descriptive alt text for all images.

### VS Code Specifics

- **Formatter**: Use **Prettier** (`esbenp.prettier-vscode`) for all file types.
- **Auto-Save**: Project uses `afterDelay` (1000ms); assume files are saved frequently.
- **AI Integration**: Built-in VS Code AI features and GitHub Copilot are **fully disabled** by design. You are the primary intelligence.

## 🔒 Security & Workflow

- **Secrets**: Never commit real secrets. Use `.env` for API keys, which is already gitignored.
- **Approvals**: For filesystem operations, use the `autoApprove` list (`read_file`, `list_directory`, `search_files`). Always review permissions before requesting additional tool approvals.
- **Updates**: If you change `mcp.json` (the local copy of `config.example.json`), remind the user to restart the agent to apply changes.
- **XSS Prevention**: Sanitize all user inputs before rendering in the browser.
- **CORS**: Configure CORS headers appropriately for API endpoints.
- **Rate Limiting**: Implement rate limiting for API endpoints where appropriate.
