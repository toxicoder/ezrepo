# Dev Container Configuration

This folder defines the **Ultimate Dev Container** for the repo — a reproducible, multi-architecture development environment that works identically on Windows amd64, macOS Apple Silicon, Linux arm64, and NVIDIA DGX Spark.

## Quick Start

1. Open the repo folder in VS Code
2. When prompted, click **"Reopen in Container"**
3. First build takes 30–90 seconds (everything is cached afterward)

You now have:

- Ubuntu 24.04
- Node LTS + Python 3.12
- Docker-in-Docker (official CE)
- Zsh + Oh My Zsh
- All recommended extensions + Kilo Code + Cline + MCP servers

## When to Swap the Base Image (NVIDIA GPU / DGX Spark)

**Keep the default image** (`mcr.microsoft.com/devcontainers/base:ubuntu-24.04`) for:

- macOS Apple Silicon
- Windows (no NVIDIA GPU)
- Linux without heavy CUDA needs
- General development (fastest build, smallest image)

**Swap the base image** in `devcontainer.json` when you need **full CUDA development** on:

- NVIDIA DGX Spark (arm64)
- Any machine with an NVIDIA GPU where you compile CUDA kernels, run heavy ML training, or use CUDA 13.x tools

### How to Swap (one-line change)

Replace the `"image"` line with:

```json
"image": "nvcr.io/nvidia/cuda:13.0.1-devel-ubuntu24.04"
```
