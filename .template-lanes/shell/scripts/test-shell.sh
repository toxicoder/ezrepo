#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## test-shell.sh - the shell lane's full local gate (entry point)
#
# One command that answers "is the shell lane green": lint first, then bats.
# Lint runs before tests on purpose - a file that will not parse is faster to
# find from shellcheck than from ten failing bats assertions.
#
# The dispatcher (tests/run.sh --lane shell) runs bats directly over tests/;
# this script is the superset CI uses, because CI must also prove the formatters
# are clean. Both paths run the same .bats files, so neither can drift into a
# private green.
#
# A missing bats is a failure with the pinned install command, never a skip.
#
# Usage:
#   scripts/test-shell.sh              # lint + bats, what CI's shell job runs
#   scripts/test-shell.sh --lint-only  # lint only
#
# Returns: 0 when every stage passed, 1 otherwise.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="$ROOT_DIR/tool-versions.env"

LINT_ONLY=0

# @function pin_value
# Read one version pin out of tool-versions.env with grep, never with source.
# Globals:
#   PINS_FILE
# Arguments:
#   $1 - KEY, for example BATS_VERSION
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

# @function parse_args
# Validate argv and set the run mode.
# Globals:
#   LINT_ONLY, SCRIPT_NAME
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   None
# Returns:
#   0, or exits 2 on an unknown flag
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --lint-only) LINT_ONLY=1 ;;
      --help | -h)
        printf 'Usage: %s [--lint-only]\n' "$SCRIPT_NAME"
        exit 0
        ;;
      *)
        printf 'error: unknown argument: %s (try --help)\n' "$1" >&2
        exit 2
        ;;
    esac
    shift
  done
}

# @function require_bats
# Abort with the pinned install command when bats is missing.
# Globals:
#   SCRIPT_NAME, ROOT_DIR, PINS_FILE
# Arguments:
#   None
# Outputs:
#   Three error lines on stderr
# Returns:
#   never returns (exits 1) when bats is absent
require_bats() {
  if command -v bats >/dev/null 2>&1; then
    return 0
  fi
  local version
  version="$(pin_value BATS_VERSION)"
  [ -n "$version" ] || version='<VERSION>'
  printf 'error: %s needs bats, which is not on PATH\n' "$SCRIPT_NAME" >&2
  printf 'error:   this repo pins BATS_VERSION in %s\n' "${PINS_FILE#"$ROOT_DIR"/}" >&2
  printf 'error:   install it: git clone --depth 1 --branch v%s https://github.com/bats-core/bats-core.git /tmp/bats && /tmp/bats/install.sh /usr/local\n' "$version" >&2
  exit 1
}

# @function run_bats
# Run every .bats file under tests/.
# Globals:
#   ROOT_DIR
# Arguments:
#   None
# Outputs:
#   bats' own output
# Returns:
#   bats' exit code, or 1 when no .bats file was found
run_bats() {
  local -a files=()
  mapfile -d '' -t files < <(find "$ROOT_DIR/tests" -type f -name '*.bats' -print0 | sort -z)
  if [ ${#files[@]} -eq 0 ]; then
    printf 'error: the shell lane is selected but tests/ holds no .bats file\n' >&2
    return 1
  fi
  printf -- '-> bats %s file(s)\n' "${#files[@]}"
  bats --timing "${files[@]}"
}

# @function main
# Lint, then test, then print the summary.
# Globals:
#   ROOT_DIR, LINT_ONLY
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   Full run transcript
# Returns:
#   0 when every stage passed, 1 otherwise
main() {
  parse_args "$@"
  printf '== test: shell ==\n'

  if ! bash "$ROOT_DIR/scripts/lint-shell.sh"; then
    printf 'summary: 0 ok, 0 warnings, 1 failed (lint)\n'
    return 1
  fi

  if [ "$LINT_ONLY" -eq 1 ]; then
    printf 'summary: 1 ok, 0 warnings, 0 failed (lint only)\n'
    return 0
  fi

  require_bats
  local rc=0
  run_bats || rc=$?
  if [ "$rc" -eq 0 ]; then
    printf 'summary: 2 ok, 0 warnings, 0 failed\n'
  else
    printf 'summary: 1 ok, 0 warnings, 1 failed (bats)\n'
  fi
  return "$rc"
}

main "$@"
