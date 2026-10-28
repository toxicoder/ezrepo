#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## test-python.sh - the python lane's full local gate (entry point)
#
# ruff, mypy, pytest, in that order, each behind a presence guard. The order is
# cheap-to-expensive and each stage answers a different question: does it
# parse and read well (ruff), does it typecheck (mypy), does it work (pytest).
#
# Coverage is not arithmetic in this file. The threshold is
# [tool.coverage.report] fail_under in pyproject.toml; the --cov-fail-under flag
# below only re-states it so a hand-run `pytest --cov` outside this script gets
# the same gate. If the two ever disagree, pyproject.toml wins, and this script
# should stop passing the flag rather than the config changing to match it.
#
# The anti-silent-skip rule: a missing ruff / mypy / pytest fails the run and
# prints the pinned `pip install` line naming the key in tool-versions.env. A
# python lane that "passed" because pytest was absent is a false green.
#
# Usage:
#   scripts/test-python.sh                  # ruff + mypy + pytest with coverage
#   scripts/test-python.sh --no-cov         # pytest without the coverage gate
#
# Returns: 0 when every stage passed, 1 otherwise.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="$ROOT_DIR/tool-versions.env"
PYTHON_BIN="${PYTHON_BIN:-python3}"

SUMMARY_OK=0
SUMMARY_FAIL=0
WITH_COV=1

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
# Read one version pin out of tool-versions.env with grep, never with source.
# Globals:
#   PINS_FILE
# Arguments:
#   $1 - KEY, for example RUFF_VERSION
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

# @function require_module
# Abort with the pinned pip command when a python tool is not available.
# Three probes, because the four tools are not installed the same way: ruff and
# mypy ship a console script, pytest is run with -m, and pytest-cov is a plugin
# with no entry point of its own, so only `import` proves it is there.
# Globals:
#   SCRIPT_NAME, PYTHON_BIN, ROOT_DIR, PINS_FILE
# Arguments:
#   $1 - probe name (command / module), e.g. pytest_cov
#   $2 - distribution name for the install hint, e.g. pytest-cov
#   $3 - the tool-versions.env KEY that pins it
#   $4 - extra pip arguments, or an empty string
# Outputs:
#   Three error lines on stderr
# Returns:
#   never returns (exits 1) when the tool is absent
require_module() {
  local probe="$1"
  local dist="$2"
  local key="$3"
  local extra="${4-}"
  if command -v "$probe" >/dev/null 2>&1 ||
    "$PYTHON_BIN" -c "import ${probe}" >/dev/null 2>&1 ||
    "$PYTHON_BIN" -m "$probe" --version >/dev/null 2>&1; then
    return 0
  fi
  local version
  version="$(pin_value "$key")"
  [ -n "$version" ] || version='<VERSION>'
  printf 'error: %s needs %s, which %s cannot find\n' "$SCRIPT_NAME" "$dist" "$PYTHON_BIN" >&2
  printf 'error:   this repo pins %s in %s\n' "$key" "${PINS_FILE#"$ROOT_DIR"/}" >&2
  printf 'error:   install it: %s -m pip install%s "%s==%s"\n' "$PYTHON_BIN" " $extra" "$dist" "$version" >&2
  exit 1
}

# @function parse_args
# Validate argv and set the run mode.
# Globals:
#   WITH_COV, SCRIPT_NAME
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   None
# Returns:
#   0, or exits 2 on an unknown flag
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-cov) WITH_COV=0 ;;
      --help | -h)
        printf 'Usage: %s [--no-cov]\n' "$SCRIPT_NAME"
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

# @function run_stage
# Run one tool stage from the repo root and record its outcome.
# Globals:
#   ROOT_DIR, SUMMARY_OK, SUMMARY_FAIL
# Arguments:
#   $1 - label; rest - the command
# Outputs:
#   The stage's own output
# Returns:
#   0
run_stage() {
  local label="$1"
  shift
  phase "$label: $*"
  if (cd "$ROOT_DIR" && "$@"); then
    ok "$label"
  else
    err "$label failed"
    return 1
  fi
  return 0
}

# @function main
# Guard the toolchain, then lint, typecheck, test.
# Globals:
#   ROOT_DIR, PYTHON_BIN, SUMMARY_OK, SUMMARY_FAIL, WITH_COV
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   Full run transcript
# Returns:
#   0 when every stage passed, 1 otherwise
main() {
  parse_args "$@"
  printf '== test: python ==\n'

  if [ ! -f "$ROOT_DIR/pyproject.toml" ]; then
    err "pyproject.toml is missing, so the python lane has no configuration to honour"
    printf 'summary: 0 ok, 0 warnings, %d failed\n' $((SUMMARY_FAIL + 1))
    return 1
  fi

  if ! "$PYTHON_BIN" --version >/dev/null 2>&1; then
    err "$PYTHON_BIN is not on PATH - install the interpreter CI uses, or set PYTHON_BIN"
    printf 'summary: 0 ok, 0 warnings, 1 failed\n'
    return 1
  fi

  require_module ruff ruff RUFF_VERSION "--upgrade"
  require_module mypy mypy MYPY_VERSION "--upgrade"
  require_module pytest pytest PYTEST_VERSION "--upgrade"
  ok "toolchain present for $("$PYTHON_BIN" --version 2>&1)"

  run_stage "ruff" "$PYTHON_BIN" -m ruff check . || true
  run_stage "mypy" "$PYTHON_BIN" -m mypy src tests || true

  local -a cov_args=()
  if [ "$WITH_COV" -eq 1 ]; then
    # PYTEST_COV_VERSION is the one pin this lane adds to the shared key set:
    # --cov comes from pytest-cov, and an unpinned plugin is an unpinned gate.
    require_module pytest_cov pytest-cov PYTEST_COV_VERSION "--upgrade"
    cov_args=(--cov=src --cov-report=term-missing --cov-fail-under=100)
  fi
  run_stage "pytest" "$PYTHON_BIN" -m pytest -q ${cov_args[@]+"${cov_args[@]}"} || true

  printf 'summary: %d ok, 0 warnings, %d failed\n' "$SUMMARY_OK" "$SUMMARY_FAIL"
  [ "$SUMMARY_FAIL" -eq 0 ]
}

main "$@"
