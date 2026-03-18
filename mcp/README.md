# MCP Servers in This Repo

MCP (Model Context Protocol) servers give Kilo Code and Cline superpowers by connecting your AI agents to real tools and data sources inside the dev container.

## ✨ Featured Servers (all pre-configured)

**Context7 (Local Caching)**
Up-to-date, version-specific library docs + code examples (React, Supabase, Python, etc.). Built-in caching, optional API key.

**GitHub**
Full repo management, PRs, issues, file operations.

**Brave Search**
Web + local business search with AI summarization.

**Crawl4AI**
Powerful web scraping & crawling with markdown conversion.

**Filesystem** (safe auto-approvals for reads)
**Playwright** (browser automation)
**DevContainer** (control your own container)

## Quick Start (30 seconds)

1. `cp .env.example .env` (fill in any keys you want — optional!)
2. `cp mcp/config.example.json mcp.json`
3. Restart Kilo Code or Cline
4. In chat just say: “use github to create a PR”, “search brave for latest AI news”, “crawl4ai the React docs”, or “use context7 for Next.js 15”

## How to Add More

Kilo Code has a built-in **MCP Marketplace** — search and enable instantly.

## Security & Best Practices

- Only approve trusted servers
- Use `autoApprove` sparingly
- Never commit real secrets (`.env` is gitignored)
- Review permissions before approving tools

## Troubleshooting

- Restart agent after changing `mcp.json`
- Test a server in terminal: `npx @brave/brave-search-mcp-server --help` (etc.)
- Works on macOS Apple Silicon, Windows amd64, Linux arm64, NVIDIA DGX Spark

Happy agent-powered coding! 🚀
