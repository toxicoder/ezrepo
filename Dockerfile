# syntax=docker/dockerfile:1
#
# ## Runtime image for __PROJECT_NAME__ (default lane: shell)
#
# Build:
#   docker build -t __PROJECT_SLUG__:dev .
#   docker build -t __PROJECT_SLUG__:dev --build-arg TARGETARCH=arm64 .   # cross-arch probe
# Run:
#   docker run --rm __PROJECT_SLUG__:dev                       # runs the entry point
#   docker run --rm __PROJECT_SLUG__:dev --help                # args are passed through
#   docker run --rm -it --entrypoint bash __PROJECT_SLUG__:dev # poke around
#   docker run --rm --entrypoint id __PROJECT_SLUG__:dev       # proves it is not root
# Verify the build stages without running the app:
#   docker build --target deps -t __PROJECT_SLUG__:deps .         # pinned toolchain only
#   docker build --target builder -t __PROJECT_SLUG__:builder .   # lint + test gate
#
# Stages:
#   base     ubuntu:24.04, pins copied in, locale/TZ-neutral environment
#   deps     the pinned shell-lane toolchain (shellcheck, shfmt, bats) in /opt/tools
#   builder  lint + test the tree; produces the installable payload under /out
#   runner   non-root, no compilers, no test runners, only what the app executes
#
# Pin rule: this file declares NO version defaults. tool-versions.env is copied in
# and sourced, so a mirrored ARG default (the usual pattern) cannot drift from the
# single source of truth -- there is only one copy. `make doctor` is the host-side
# twin of the guard below, and it fails the same way: loudly.
#
# Release asset names are quoted from the GitHub release API, not guessed:
# shellcheck ships shellcheck-v<ver>.linux.<x86_64|aarch64>.tar.xz and shfmt ships
# shfmt_v<ver>_linux_<amd64|arm64>. A wrong asset name is a 404 with --fail, which
# is the outcome this file wants; a silent fallback to another artifact is not.
#
# Pinned base images (tag AND digest; bump both together, never the tag alone):
#   ubuntu:24.04   @sha256:REPLACE_WITH_DIGEST_FROM_YOUR_FIRST_VERIFIED_BUILD

ARG TARGETARCH

# -- base -----------------------------------------------------------------------
FROM ubuntu:24.04 AS base
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive \
    PINS_FILE=/opt/__PROJECT_SLUG__/tool-versions.env \
    PATH=/opt/tools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY tool-versions.env ${PINS_FILE}
RUN set -eu; \
    for key in SHELLCHECK_VERSION SHFMT_VERSION BATS_VERSION; do \
      if ! grep -qE "^${key}=[^[:space:]]+$" "${PINS_FILE}"; then \
        printf 'error: %s is missing or empty in tool-versions.env\n' "${key}" >&2; exit 1; \
      fi; \
    done; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl xz-utils git; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    printf 'ok: base prepared for lane=shell arch=%s\n' "${TARGETARCH:-amd64}"

# -- deps: pinned tools, isolated so the runner never inherits them -------------
FROM base AS deps
ARG TARGETARCH
RUN set -eu; \
    . "${PINS_FILE}"; \
    case "${TARGETARCH:-amd64}" in \
      amd64) dl_arch=amd64; gnu_arch=x86_64 ;; \
      arm64) dl_arch=arm64; gnu_arch=aarch64 ;; \
      *) printf 'error: unsupported TARGETARCH %s\n' "${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /opt/tools/bin; \
    curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.${gnu_arch}.tar.xz" -o /tmp/sc.tar.xz; \
    tar -xJf /tmp/sc.tar.xz -C /tmp; \
    install -m 0755 "/tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" /opt/tools/bin/shellcheck; \
    rm -rf "/tmp/shellcheck-v${SHELLCHECK_VERSION}" /tmp/sc.tar.xz; \
    curl -fsSL "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${dl_arch}" -o /opt/tools/bin/shfmt; \
    chmod 0755 /opt/tools/bin/shfmt; \
    git clone --depth 1 --branch "v${BATS_VERSION}" https://github.com/bats-core/bats-core.git /tmp/bats; \
    /tmp/bats/install.sh /opt/tools >/dev/null; \
    rm -rf /tmp/bats; \
    shellcheck --version | sed -n '2p'; \
    shfmt --version; \
    bats --version; \
    printf 'ok: shellcheck %s, shfmt %s, bats %s\n' "${SHELLCHECK_VERSION}" "${SHFMT_VERSION}" "${BATS_VERSION}"

# -- builder: the gate. A build that cannot lint and test is not a build --------
FROM base AS builder
COPY --from=deps /opt/tools /opt/tools
WORKDIR /src
COPY . /src
RUN set -eu; \
    printf '== builder: lint ==\n'; \
    find . -type f -name '*.sh' -not -path './.git/*' -not -path './node_modules/*' -exec shellcheck -x --severity=warning {} +; \
    find . -type f -name '*.sh' -not -path './.git/*' -not -path './node_modules/*' -exec shfmt -d -i 2 -ci {} +; \
    printf 'ok: shellcheck and shfmt clean\n'; \
    printf '== builder: test ==\n'; \
    bash tests/run.sh; \
    mkdir -p /out/bin; \
    entry=""; \
    for candidate in "src/main.sh" "src/bin/__PROJECT_SLUG__.sh" "src/bin/__PROJECT_SLUG__" "src/__PROJECT_SLUG__.sh"; do \
      if [ -f "$candidate" ]; then entry="$candidate"; break; fi; \
    done; \
    if [ -z "$entry" ]; then \
      printf 'error: no entry point found. The shell lane must ship src/main.sh; src/ holds: %s\n' "$(ls -1 src 2>/dev/null | tr '\n' ' ' || echo 'nothing')" >&2; \
      exit 1; \
    fi; \
    install -m 0755 "$entry" /out/bin/__PROJECT_SLUG__; \
    printf 'ok: payload staged in /out/bin from %s\n' "$entry"

# -- runner: fixed UID, non-root, nothing a compiler can hide in ----------------
FROM ubuntu:24.04 AS runner
ARG APP_UID=10001
ARG APP_GID=10001
ENV APP_HOME=/app \
    PROJECT_ENTRY=/app/bin/__PROJECT_SLUG__
RUN set -eu; \
    groupadd --gid "${APP_GID}" app; \
    useradd --uid "${APP_UID}" --gid app --create-home --home-dir /app --shell /usr/sbin/nologin app; \
    printf '%s\n' \
      '#!/bin/sh' \
      'set -eu' \
      'entry="${PROJECT_ENTRY:-/app/bin/__PROJECT_SLUG__}"' \
      'if [ ! -f "$entry" ]; then printf "error: %s does not exist; build produced no payload\n" "$entry" >&2; exit 1; fi;' \
      'if [ ! -x "$entry" ]; then printf "error: %s is not executable\n" "$entry" >&2; exit 1; fi;' \
      'exec "$entry" "$@"' \
      > /usr/local/bin/docker-entrypoint.sh; \
    chmod 0755 /usr/local/bin/docker-entrypoint.sh
WORKDIR /app
COPY --from=builder --chown=app:app /out/bin/ /app/bin/
USER app:${APP_GID}
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--help"]
