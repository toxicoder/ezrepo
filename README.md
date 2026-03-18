# Ultimate Dev Environment Template

**One repo. Zero "works on my machine."**
Cross-platform (Windows, macOS Apple Silicon, Linux arm64 + NVIDIA DGX Spark), pre-configured with the best extensions, and **all Microsoft AI/Copilot completely disabled**.

## 🚀 Quick Start (30 seconds)

1. Clone this repo
2. Open the folder in VS Code
3. When prompted, click **"Reopen in Container"** (Dev Containers extension will auto-install if missing)
4. Wait for the container to build (~30–60s first time)

You now have:

- Ubuntu 24.04 (multi-arch)
- Node LTS, Python 3.12, Docker-in-Docker, GitHub CLI, Zsh + Oh My Zsh
- Kilo Code + Cline (your preferred AI agents)
- GitLens, Prettier, Error Lens, Docker tools, etc.
- **All built-in GitHub Copilot & VS Code AI features disabled**

## Supported Platforms

- ✅ Windows amd64
- ✅ macOS Apple Silicon (arm64)
- ✅ Linux arm64 (including NVIDIA DGX Spark — CUDA 12.6 ready)

## Customization

- Add language runtimes via Features in `.devcontainer/devcontainer.json`
- Tweak settings in `.vscode/settings.json`
- Add more extensions in `.vscode/extensions.json`

## Why This Template?

- Follows official Microsoft + devcontainers.org best practices (2026)
- Everything version-controlled except personal `.code-workspace` files
- GPU-ready for DGX Spark and any NVIDIA host
- Clean, minimal, and battle-tested

Happy coding!
