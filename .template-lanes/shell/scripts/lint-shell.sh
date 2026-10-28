#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## lint-shell.sh - shellcheck + shfmt over every first-party shell file (entry point)
#
# The shell lane's lint gate, and the reason `make lint` cannot go green with a
# syntax error in it: shellcheck with -x (follow `source`) at severity warning,
# and shfmt in diff mode with the repo's own shape (2 spaces, indent-switch-cases).
# Both tools run over src/, scripts/ and tests/, .bats files included, so a test
# file cannot smuggle in unquoted expansion.
#
# The anti-silent-skip rule lives here: a missing shellcheck or shfmt is a
# FAILURE that prints the pinned install command naming the key in
# tool-versions.env, never a warning and never a skip. A lint job that "passed"
# because the binary was absent is worse than no lint job at all, because the
# green tick is a lie about coverage.
#
# Usage:
#   scripts/lint-shell.sh            # what CI and `make lint` run
#   bash scripts/lint-shell.sh       # same thing from any cwd
#
# Returns: 0 when every tool ran and every file was clean, 1 otherwise.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="$ROOT_DIR/tool-versions.env"

readonly -a SCAN_DIRS=("src" "scripts" "tests")

SUMMARY_OK=0
SUMMARY_WARN=0
SUMMARY_FAIL=0
FILES=()

# @function phase
# Print an in-progress step line.
# Globals:
#   None
# Arguments:
#   $1 - step text
# Outputs:
#   "-> step" on stdout
# Returns:
#   0
phase() {
  printf -- '-> %s\n' "$1"
}

# @function ok
# Record and print a passed check.
# Globals:
#   SUMMARY_OK
# Arguments:
#   $1 - text without the "ok: " prefix
# Outputs:
#   "ok: text" on stdout
# Returns:
#   0
ok() {
  SUMMARY_OK=$((SUMMARY_OK + 1))
  printf 'ok: %s\n' "$1"
}

# @function err
# Record and print a failure.
# Globals:
#   SUMMARY_FAIL
# Arguments:
#   $1 - text without the "error: " prefix
# Outputs:
#   "error: text" on stderr
# Returns:
#   0
err() {
  SUMMARY_FAIL=$((SUMMARY_FAIL + 1))
  printf 'error: %s\n' "$1" >&2
}

# @function pin_value
# Read one version pin out of tool-versions.env.
# Read with grep, never sourced: a malformed pin file must not be able to run
# code from inside a lint script, and must not stop the lint from running.
# Globals:
#   PINS_FILE
# Arguments:
#   $1 - KEY, for example SHELLCHECK_VERSION
# Outputs:
#   The value on stdout, or the empty string when the key is absent
# Returns:
#   0
pin_value() {
  local key="$1"
  local line=""
  if [ -r "$PINS_FILE" ]; then
    line="$(grep -m1 -E "^${key}=" "$PINS_FILE" 2>/dev/null || true)"
  fi
  printf '%s\n' "${line#*=}"
}

# @function require_tool
# Abort with the pinned install command when a lint binary is missing.
# This is the whole reason the script exists twice in CI: without it, a runner
# image that lost shellcheck turns the lint job green.
# Globals:
#   SCRIPT_NAME, PINS_FILE, ROOT_DIR
# Arguments:
#   $1 - binary name on PATH
#   $2 - the tool-versions.env KEY that pins it
#   $3 - install command template, with every %s standing for the version
# Outputs:
#   Three error lines on stderr
# Returns:
#   never returns (exits 1) when the binary is absent
require_tool() {
  local binary="$1"
  local key="$2"
  local hint="$3"
  local version
  if command -v "$binary" >/dev/null 2>&1; then
    return 0
  fi
  version="$(pin_value "$key")"
  if [ -z "$version" ]; then
    version='<VERSION>'
  fi
  printf 'error: %s needs %s, which is not on PATH\n' "$SCRIPT_NAME" "$binary" >&2
  printf 'error:   this repo pins %s in %s\n' "$key" "${PINS_FILE#"$ROOT_DIR"/}" >&2
  printf 'error:   install it: %s\n' "${hint//\%s/$version}" >&2
  exit 1
}

# @function collect_files
# Fill FILES with every shell file this lane owns, or fail loudly.
# A scan directory that does not exist is an error, not a skip: it means a lane
# was half-installed, and linting "whatever is there" would report success over
# an empty set.
# Globals:
#   ROOT_DIR, SCAN_DIRS, FILES
# Arguments:
#   None
# Outputs:
#   One error line on stderr when the tree does not match the lane
# Returns:
#   0 when FILES is populated, 1 otherwise
collect_files() {
  local dir=""
  for dir in "${SCAN_DIRS[@]}"; do
    if [ ! -d "$ROOT_DIR/$dir" ]; then
      printf 'error: scan directory %s/ is missing, so the shell lint would check nothing\n' "$dir" >&2
      return 1
    fi
  done
  mapfile -d '' -t FILES < <(find "${SCAN_DIRS[@]}" -type f \( -name '*.sh' -o -name '*.bats' \) -print0 | sort -z)
  if [ ${#FILES[@]} -eq 0 ]; then
    printf 'error: no .sh or .bats file under %s, so the shell lint would check nothing\n' "${SCAN_DIRS[*]}" >&2
    return 1
  fi
  return 0
}

# @function run_shellcheck
# Run shellcheck over FILES at the pinned severity.
# Globals:
#   FILES
# Arguments:
#   None
# Outputs:
#   Shellcheck's own diagnostics
# Returns:
#   Shellcheck's exit code
run_shellcheck() {
  phase "shellcheck -x --severity=warning (${#FILES[@]} file(s))"
  # .shellcheckrc at the repo root carries the shared options (source-path,
  # external-sources); -x is repeated here so the script also works when the
  # rc file is deleted by someone pruning "stray dotfiles".
  shellcheck -x --severity=warning -- "${FILES[@]}"
}

# @function run_shfmt
# Run shfmt in diff mode over the same file set.
# Globals:
#   FILES, SCAN_DIRS
# Arguments:
#   None
# Outputs:
#   The diff shfmt would apply, or nothing when the tree is formatted
# Returns:
#   shfmt's exit code
run_shfmt() {
  phase "shfmt -d -i 2 -ci (${#FILES[@]} file(s))"
  if ! shfmt -d -i 2 -ci -- "${FILES[@]}"; then
    printf 'error: the files above are not shfmt-formatted; run: shfmt -w -i 2 -ci %s\n' "${SCAN_DIRS[*]}" >&2
    return 1
  fi
}

# @function main
# Check the toolchain, then run both linters and print the summary.
# Globals:
#   SUMMARY_OK, SUMMARY_WARN, SUMMARY_FAIL, FILES
# Arguments:
#   "$@" - unused
# Outputs:
#   Full run transcript
# Returns:
#   0 when both linters were clean, 1 otherwise
main() {
  printf '== lint: shell ==\n'
  require_tool shellcheck SHELLCHECK_VERSION \
    'curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v%s/shellcheck-v%s.linux.x86_64.tar.xz" | tar -xJf - -C /tmp && sudo install -m 0755 /tmp/shellcheck-v%s/shellcheck /usr/local/bin/shellcheck'
  require_tool shfmt SHFMT_VERSION \
    'curl -fsSL -o /tmp/shfmt "https://github.com/mvdan/sh/releases/download/v%s/shfmt_v%s_linux_amd64" && sudo install -m 0755 /tmp/shfmt /usr/local/bin/shfmt'
  ok "toolchain present: shellcheck $(shellcheck --version | awk '/^version:/ {print $2}'), shfmt $(shfmt --version)"

  if ! collect_files; then
    err "no shell files to lint"
    printf 'summary: %d ok, %d warnings, %d failed\n' "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
    return 1
  fi
  ok "found ${#FILES[@]} shell file(s) to lint"

  local sc_rc=0
  run_shellcheck || sc_rc=$?
  if [ "$sc_rc" -eq 0 ]; then
    ok "shellcheck clean"
  else
    err "shellcheck reported findings"
  fi

  local fmt_rc=0
  run_shfmt || fmt_rc=$?
  if [ "$fmt_rc" -eq 0 ]; then
    ok "shfmt clean"
  else
    err "shfmt reported findings"
  fi

  printf 'summary: %d ok, %d warnings, %d failed\n' "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
  [ "$sc_rc" -eq 0 ] && [ "$fmt_rc" -eq 0 ]
}

main "$@"
