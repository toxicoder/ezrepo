# syntax=docker/dockerfile:1
#
# ## .devcontainer/Dockerfile -- the pinned toolchain this project develops in
#
# This image is the supported development environment: `make`, `make doctor`,
# `make lint`, `make test` and `make docs` all run here, and CI runs the same
# targets. If it is green in here it is green in Actions.
#
# Exact commands (all run from the repository root, which is the build context):
#
#   docker build -f .devcontainer/Dockerfile -t __PROJECT_SLUG__-toolchain .
#   docker run --rm -it -v "$PWD":/work -w /work __PROJECT_SLUG__-toolchain zsh
#   docker run --rm -v "$PWD":/work -w /work __PROJECT_SLUG__-toolchain make doctor
#
# In VS Code you do not type those: Dev Containers: Reopen in Container builds
# this file through `.devcontainer/devcontainer.json`.
#
# Versions: ZERO numbers are hardcoded here. Every tool version is read from
# `tool-versions.env` at the top of the build, and the build FAILS if a key is
# missing or empty. This file is the named consumer of every key in that file;
# `make doctor` greps this file for each key and errors on one that appears in
# neither this Dockerfile nor `.github/workflows/ci.yml`. To retire a tool,
# delete the key and its install line here in the same commit.
#
# Deviations from the "Installed by" notes in tool-versions.env, with reasons:
#   - PRETTIER_VERSION is installed from npm, not pipx. The PyPI project named
#     `prettier` is an unrelated stub (its releases stop at 0.0.7); the 3.x line
#     is published only to npm, so pipx cannot deliver the pinned version.
#   - RUFF_VERSION / MYPY_VERSION / PYTEST_VERSION / PYTEST_COV_VERSION land in
#     one venv at /opt/venv-test rather than as isolated pipx apps, because
#     `tests/run.sh` probes them as `python3 -m pytest --version`. That only
#     works if the `python3` on PATH is the venv interpreter, so
#     /opt/venv-test/bin goes on PATH ahead of the system one.

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    PIPX_MAN_DIR=/opt/pipx/share/man \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    GOTOOLCHAIN=local \
    GOPATH=/opt/gopath \
    PATH=/opt/venv-test/bin:/opt/node/bin:/usr/local/go/bin:/opt/gopath/bin:/usr/local/bin:/usr/bin:/bin

# The pin file is the build's input. COPY (not a heredoc copy) so a pin change
# busts this layer and every install layer after it, and so nothing can read a
# stale cached copy.
COPY tool-versions.env /opt/__PROJECT_MODULE__-pins/env

# Fail before installing anything if the pin file lost a key or grew an empty
# value. A missing key must not become "installs the latest", which is exactly
# the kind of silent fallback this repo bans.
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    required="SHELLCHECK_VERSION SHFMT_VERSION BATS_VERSION YAMLLINT_VERSION PRE_COMMIT_VERSION GITLEAKS_VERSION PRETTIER_VERSION RUFF_VERSION MYPY_VERSION PYTEST_VERSION PYTEST_COV_VERSION NODE_VERSION TYPESCRIPT_VERSION ESLINT_VERSION VITEST_VERSION GO_VERSION GOLANGCI_LINT_VERSION"; \
    for key in $required; do \
      if [ -z "${!key:-}" ]; then \
        printf 'error: tool-versions.env is missing %s or has an empty value\n' "$key" >&2; exit 1; \
      fi; \
      printf 'pin: %s=%s\n' "$key" "${!key}"; \
    done

RUN apt-get update && apt-get install -y --no-install-recommends \
      apt-transport-https ca-certificates curl git gnupg jq less make \
      openssh-client procps tzdata unzip wget xz-utils zip \
      python3 python3-pip python3-venv python3-dev pipx \
      build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

# --- TypeScript lane runtimes: Node from nodejs.org (also the source of npm) ---
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    case "$(dpkg --print-architecture)" in \
      amd64) node_arch=linux-x64 ;; \
      arm64) node_arch=linux-arm64 ;; \
      *) printf 'error: no Node build mapped for architecture %s\n' "$(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
      -o /tmp/node.tar.xz \
      "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${node_arch}.tar.xz"; \
    mkdir -p /opt/node; \
    tar -xJf /tmp/node.tar.xz -C /opt/node --strip-components=1; \
    rm -f /tmp/node.tar.xz; \
    node --version | grep -F "v${NODE_VERSION}"

# --- Go lane runtime: the toolchain from go.dev --------------------------------
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    case "$(dpkg --print-architecture)" in \
      amd64) go_arch=linux-amd64 ;; \
      arm64) go_arch=linux-arm64 ;; \
      *) printf 'error: no Go build mapped for architecture %s\n' "$(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
      -o /tmp/go.tar.gz \
      "https://go.dev/dl/go${GO_VERSION}.${go_arch}.tar.gz"; \
    rm -rf /usr/local/go; \
    tar -xzf /tmp/go.tar.gz -C /usr/local; \
    rm -f /tmp/go.tar.gz; \
    mkdir -p "$GOPATH/bin"; \
    go version | grep -F "go${GO_VERSION}"

# --- Repository-wide and shell-lane binaries from upstream releases ------------
# Every download is HTTPS-only and must answer --version with the pinned number
# before the layer completes. There is no "download failed, carry on" path here:
# an image that quietly lacks gitleaks is an image whose secrets scan passes by
# absence, which is the failure this project exists to remove.
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    dpkg_arch="$(dpkg --print-architecture)"; \
    case "$dpkg_arch" in \
      amd64) sc_arch=x86_64; gl_arch=x64; gcl_arch=amd64 ;; \
      arm64) sc_arch=aarch64; gl_arch=arm64; gcl_arch=arm64 ;; \
      *) printf 'error: no release binaries mapped for architecture %s\n' "$dpkg_arch" >&2; exit 1 ;; \
    esac; \
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
      -o /tmp/shellcheck.tar.xz \
      "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.${sc_arch}.tar.xz"; \
    tar -xJf /tmp/shellcheck.tar.xz -C /tmp; \
    install -m 0755 "/tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck; \
    rm -rf "/tmp/shellcheck-v${SHELLCHECK_VERSION}" /tmp/shellcheck.tar.xz; \
    shellcheck --version | grep -F "${SHELLCHECK_VERSION}"; \
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
      -o /tmp/gitleaks.tar.gz \
      "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${gl_arch}.tar.gz"; \
    tar -xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks; \
    install -m 0755 /tmp/gitleaks /usr/local/bin/gitleaks; \
    rm -f /tmp/gitleaks /tmp/gitleaks.tar.gz; \
    gitleaks version | grep -F "${GITLEAKS_VERSION}"; \
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
      -o /tmp/golangci.tar.gz \
      "https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-${gcl_arch}.tar.gz"; \
    tar -xzf /tmp/golangci.tar.gz -C /tmp; \
    install -m 0755 "/tmp/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-${gcl_arch}/golangci-lint" /usr/local/bin/golangci-lint; \
    rm -rf "/tmp/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-${gcl_arch}" /tmp/golangci.tar.gz; \
    golangci-lint --version | grep -F "${GOLANGCI_LINT_VERSION}"

# --- Shell lane: bats-core from its tagged tarball, shfmt from `go install` ----
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
      -o /tmp/bats.tar.gz \
      "https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz"; \
    tar -xzf /tmp/bats.tar.gz -C /tmp; \
    "/tmp/bats-core-${BATS_VERSION}/install.sh" /usr/local; \
    rm -rf "/tmp/bats-core-${BATS_VERSION}" /tmp/bats.tar.gz; \
    bats --version | grep -F "${BATS_VERSION}"; \
    go install "mvdan.cc/sh/v3/cmd/shfmt@v${SHFMT_VERSION}"; \
    install -m 0755 "$GOPATH/bin/shfmt" /usr/local/bin/shfmt; \
    shfmt --version | grep -F "${SHFMT_VERSION}"

# --- Applications from PyPI, one isolated venv each (pipx) ---------------------
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    pipx install --pip-args="--no-cache-dir" "yamllint==${YAMLLINT_VERSION}"; \
    pipx install --pip-args="--no-cache-dir" "pre-commit==${PRE_COMMIT_VERSION}"; \
    yamllint --version | grep -F "${YAMLLINT_VERSION}"; \
    pre-commit --version | grep -F "${PRE_COMMIT_VERSION}"

# --- Python lane: pytest, ruff and mypy in the interpreter tests use -----------
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    python3 -m venv /opt/venv-test; \
    /opt/venv-test/bin/python -m pip install --no-cache-dir --upgrade pip; \
    /opt/venv-test/bin/python -m pip install --no-cache-dir \
      "pytest==${PYTEST_VERSION}" "pytest-cov==${PYTEST_COV_VERSION}" \
      "ruff==${RUFF_VERSION}" "mypy==${MYPY_VERSION}"; \
    python3 -m pytest --version | grep -F "${PYTEST_VERSION}"; \
    python3 -c 'import pytest_cov; print(pytest_cov.__version__)' | grep -F "${PYTEST_COV_VERSION}"; \
    ruff --version | grep -F "${RUFF_VERSION}"; \
    mypy --version | grep -F "${MYPY_VERSION}"

# --- TypeScript lane compilers and runners (npm global) ------------------------
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    npm install --global --no-audit --no-fund \
      "typescript@${TYPESCRIPT_VERSION}" \
      "eslint@${ESLINT_VERSION}" \
      "vitest@${VITEST_VERSION}" \
      "prettier@${PRETTIER_VERSION}"; \
    tsc --version | grep -F "${TYPESCRIPT_VERSION}"; \
    eslint --version | grep -F "${ESLINT_VERSION}"; \
    vitest --version | grep -F "${VITEST_VERSION}"; \
    prettier --version | grep -F "${PRETTIER_VERSION}"

# The same probe `make doctor` runs, baked into the image so a half-installed
# layer never reaches a shell. Kept last so it sees the finished PATH.
RUN set -euo pipefail; \
    . /opt/__PROJECT_MODULE__-pins/env; \
    for pair in \
      "shellcheck --version:$SHELLCHECK_VERSION" \
      "shfmt --version:$SHFMT_VERSION" \
      "bats --version:$BATS_VERSION" \
      "yamllint --version:$YAMLLINT_VERSION" \
      "pre-commit --version:$PRE_COMMIT_VERSION" \
      "gitleaks version:$GITLEAKS_VERSION" \
      "prettier --version:$PRETTIER_VERSION" \
      "ruff --version:$RUFF_VERSION" \
      "mypy --version:$MYPY_VERSION" \
      "python3 -m pytest --version:$PYTEST_VERSION" \
      "node --version:$NODE_VERSION" \
      "tsc --version:$TYPESCRIPT_VERSION" \
      "eslint --version:$ESLINT_VERSION" \
      "vitest --version:$VITEST_VERSION" \
      "go version:$GO_VERSION" \
      "golangci-lint --version:$GOLANGCI_LINT_VERSION"; do \
      cmd="${pair%%:*}"; want="${pair#*:}"; \
      if ! $cmd 2>&1 | grep -qF -- "$want"; then \
        printf 'error: %s does not report the pinned %s\n' "$cmd" "$want" >&2; exit 1; \
      fi; \
      printf 'ok: %s reports %s\n' "$cmd" "$want"; \
    done

WORKDIR /work

CMD ["zsh"]
