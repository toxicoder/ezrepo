#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## test-typescript.sh - the typescript lane's full local gate (entry point)
#
# One command that answers "is the typescript lane green": pins first, then the
# install, then lint, typecheck and tests. That order is deliberate and it is not
# cheap-to-expensive - `scripts/check-pins.sh` goes first because a checkout whose
# package.json and tool-versions.env disagree is testing a different build than CI
# is, and every minute spent reading eslint output from that checkout is wasted.
#
# The dispatcher (tests/run.sh --lane typescript) runs `npm test` only. This script
# is the superset CI uses, because CI must also prove the pins agree, the types
# check, and the coverage thresholds hold. Both paths run the same vitest files, so
# neither can drift into a private green.
#
# Note on where a tool comes from: `make lint` runs the globally installed eslint
# and tsc that tool-versions.env pins, while `npm run ...` here resolves them from
# node_modules/.bin. The install step below is what makes the second set exist, and
# the guards are what make it impossible for its absence to look like a pass.
#
# The anti-silent-skip rule: a missing npm, python3, eslint, tsc or vitest fails the
# run and prints the exact pinned install line, with the version read from
# tool-versions.env. There is no path through this file that prints "skipping" and
# returns 0.
#
# Usage:
#   scripts/test-typescript.sh            # pins + install + lint + typecheck + coverage
#   scripts/test-typescript.sh --no-cov   # same, without the coverage thresholds
#
# Returns: 0 when every stage passed, 1 otherwise.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="$ROOT_DIR/tool-versions.env"
PACKAGE_JSON="$ROOT_DIR/package.json"
LOCKFILE="$ROOT_DIR/package-lock.json"
CHECK_PINS="$ROOT_DIR/scripts/check-pins.sh"

SUMMARY_OK=0
SUMMARY_WARN=0
SUMMARY_FAIL=0
WITH_COV=1

# @function section
# Print a top-level group heading.
# Globals:
#   None
# Arguments:
#   $1 - heading text, without the "== ==" wrapper
# Outputs:
#   "== heading ==" on stdout
# Returns:
#   0
section() {
  printf '== %s ==\n' "$1"
}

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

# @function warn
# Record and print a soft warning. A warning never fails the run; a missing tool
# is an error, never a warning.
# Globals:
#   SUMMARY_WARN
# Arguments:
#   $1 - text without the "warning: " prefix
# Outputs:
#   "warning: text" on stdout
# Returns:
#   0
warn() {
  SUMMARY_WARN=$((SUMMARY_WARN + 1))
  printf 'warning: %s\n' "$1"
}

# @function note
# Print a fact worth reading that never changes the verdict.
# Globals:
#   None
# Arguments:
#   $1 - text without the "note: " prefix
# Outputs:
#   "note: text" on stdout
# Returns:
#   0
note() {
  printf 'note: %s\n' "$1"
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

# @function summary
# Print the closing tally.
# Globals:
#   SUMMARY_OK, SUMMARY_WARN, SUMMARY_FAIL
# Arguments:
#   None
# Outputs:
#   "summary: N ok, W warnings, F failed" on stdout
# Returns:
#   0
summary() {
  printf 'summary: %d ok, %d warnings, %d failed\n' \
    "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
}

# @function have
# Report whether a command resolves on PATH.
# Globals:
#   None
# Arguments:
#   $1 - command name
# Outputs:
#   None
# Returns:
#   0 when found, 1 when not
have() {
  command -v "$1" >/dev/null 2>&1
}

# @function pin_value
# Read one version pin out of tool-versions.env with grep, never with source, so a
# malformed pin cannot take the test run down with it.
# Globals:
#   PINS_FILE
# Arguments:
#   $1 - KEY, for example VITEST_VERSION
# Outputs:
#   The value on stdout, or the empty string when the key is absent
# Returns:
#   0
pin_value() {
  local key="$1"
  local line=""
  if [ -r "$PINS_FILE" ]; then
    line="$(grep -m1 -E "^${key}=" "$PINS_FILE")" || line=""
  fi
  printf '%s\n' "${line#*=}"
}

# @function usage
# Print the CLI contract and exit.
# Globals:
#   SCRIPT_NAME
# Arguments:
#   None
# Outputs:
#   Usage text on stdout
# Returns:
#   0 (exits)
usage() {
  cat <<EOF
${SCRIPT_NAME} -- run the typescript lane's full local gate

Usage:
  ${SCRIPT_NAME} [--no-cov] [--help]

Stages, in order:
  scripts/check-pins.sh   package.json must agree with tool-versions.env
  npm ci                  (or npm install when no lockfile is committed)
  npm run lint            eslint . --max-warnings 0
  npm run typecheck       tsc --noEmit
  npm run test:coverage   vitest run --coverage, 100 thresholds in vitest.config.ts

Options:
  --no-cov  run npm test instead of npm run test:coverage; the coverage thresholds
            live in vitest.config.ts, so this drops the gate, not a flag
  --help    show this text

Exit codes:
  0  every stage passed
  1  a stage failed, the install failed, or a pinned tool is not installed
EOF
  exit 0
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
      --help | -h) usage ;;
      *)
        printf 'error: unknown argument: %s (try --help)\n' "$1" >&2
        exit 2
        ;;
    esac
    shift
  done
}

# @function require_tool
# Abort with the exact pinned install line when a node tool is not reachable.
# Two probes, because the tools arrive two ways: the install step puts them in
# node_modules/.bin, and a dev container also installs them globally from
# tool-versions.env. Either one satisfies the stage; neither being present means
# the stage would test nothing.
# Globals:
#   ROOT_DIR, SCRIPT_NAME, PINS_FILE
# Arguments:
#   $1 - binary name, for example tsc
#   $2 - npm package name, for example typescript
#   $3 - the tool-versions.env KEY that pins it
# Outputs:
#   Three error lines on stderr
# Returns:
#   never returns (exits 1) when the tool is absent
require_tool() {
  local binary="$1" pkg="$2" key="$3"
  if [ -x "$ROOT_DIR/node_modules/.bin/$binary" ] || have "$binary"; then
    return 0
  fi
  local version
  version="$(pin_value "$key")"
  [ -n "$version" ] || version='<VERSION>'
  printf 'error: %s needs %s (%s), which neither node_modules/.bin nor PATH provides\n' \
    "$SCRIPT_NAME" "$binary" "$pkg" >&2
  printf 'error:   this repo pins %s in %s\n' "$key" "${PINS_FILE#"$ROOT_DIR"/}" >&2
  printf 'error:   install it: npm install --save-dev "%s@%s"\n' "$pkg" "$version" >&2
  exit 1
}

# @function npm_script_present
# Report whether package.json declares an npm script. Read with json.load, not
# grep, so a script name that only appears inside a description string cannot
# satisfy the probe.
# Globals:
#   PACKAGE_JSON
# Arguments:
#   $1 - script name, for example test:coverage
# Outputs:
#   None
# Returns:
#   0 when the script exists, 1 when it does not
npm_script_present() {
  local name="$1"
  python3 -c 'import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
sys.exit(0 if sys.argv[2] in data.get("scripts", {}) else 1)' "$PACKAGE_JSON" "$name"
}

# @function run_stage
# Run one stage from the repo root and record its outcome. It always returns 0 so
# one failing stage does not hide the ones after it; main reads the tally.
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
  fi
  return 0
}

# @function install_dependencies
# Populate node_modules so the guarded tools exist. npm ci is the default because
# it refuses to install anything the lockfile does not name; npm install is the
# fallback only when no lockfile is committed, and it warns, because that is the
# case where CI and your terminal can disagree.
# Globals:
#   ROOT_DIR, LOCKFILE, SUMMARY_WARN
# Arguments:
#   None
# Outputs:
#   npm output, plus a warning or note line
# Returns:
#   0 when the install succeeded, 1 otherwise
install_dependencies() {
  section "install"
  if [ -f "$LOCKFILE" ]; then
    phase "npm ci (lockfile present, so nothing outside it is installed)"
    if (cd "$ROOT_DIR" && npm ci --no-audit --no-fund); then
      ok "npm ci installed the locked tree"
      return 0
    fi
    err "npm ci failed; fix the lockfile with npm install and commit the result"
    return 1
  fi
  warn "no package-lock.json, so npm install resolves versions itself; commit one so CI and your terminal agree"
  phase "npm install (no lockfile to honour)"
  if (cd "$ROOT_DIR" && npm install --no-audit --no-fund); then
    ok "npm install resolved and installed the tree"
    return 0
  fi
  err "npm install failed; see the npm output above"
  return 1
}

# @function run_lint_stages
# Lint, typecheck, and test with coverage, each script guarded by name so a renamed
# or deleted script is an error rather than a no-op.
# Globals:
#   ROOT_DIR, WITH_COV, SUMMARY_FAIL
# Arguments:
#   None
# Outputs:
#   Each tool's own output
# Returns:
#   0
run_lint_stages() {
  section "static checks"
  if npm_script_present "lint"; then
    run_stage "lint" npm run lint
  else
    err 'package.json declares no "lint" script, so eslint never ran'
  fi
  if npm_script_present "typecheck"; then
    run_stage "typecheck" npm run typecheck
  else
    err 'package.json declares no "typecheck" script, so tsc --noEmit never ran'
  fi

  section "tests"
  if [ "$WITH_COV" -eq 1 ]; then
    if npm_script_present "test:coverage"; then
      run_stage "test:coverage" npm run test:coverage
    else
      err 'package.json declares no "test:coverage" script, so the thresholds in vitest.config.ts are not enforced'
    fi
  elif npm_script_present "test"; then
    run_stage "test" npm test
  else
    err 'package.json declares no "test" script, so there is nothing to run'
  fi
  return 0
}

# @function main
# Guard the toolchain, then pins, install, lint, typecheck, test.
# Globals:
#   ROOT_DIR, PACKAGE_JSON, CHECK_PINS, SUMMARY_OK, SUMMARY_WARN, SUMMARY_FAIL
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   Full run transcript
# Returns:
#   0 when every stage passed, 1 otherwise
main() {
  parse_args "$@"
  section "test: typescript"

  if [ ! -f "$PACKAGE_JSON" ]; then
    err "package.json is missing, so the typescript lane has no manifest to honour"
    summary
    return 1
  fi
  if [ ! -r "$CHECK_PINS" ]; then
    err "scripts/check-pins.sh is missing; the lane ships it and it guards every pin in package.json"
    summary
    return 1
  fi
  if ! have npm; then
    err "npm is not on PATH - install Node $(pin_value NODE_VERSION) from https://nodejs.org so npm is available"
    summary
    return 1
  fi
  if ! have python3; then
    err "python3 is not on PATH - it parses package.json for the pin and script guards (apt-get install -y python3)"
    summary
    return 1
  fi
  note "node $(node --version 2>/dev/null), npm $(npm --version 2>/dev/null)"

  section "pins"
  phase "scripts/check-pins.sh"
  if ! (cd "$ROOT_DIR" && bash "$CHECK_PINS"); then
    err "pin check failed; nothing below this line can be trusted, so the run stops here"
    summary
    return 1
  fi
  ok "package.json and tool-versions.env agree"

  if ! install_dependencies; then
    summary
    return 1
  fi

  section "tool guards"
  require_tool tsc typescript TYPESCRIPT_VERSION
  require_tool eslint eslint ESLINT_VERSION
  require_tool vitest vitest VITEST_VERSION
  ok "tsc, eslint and vitest are runnable from node_modules/.bin"

  run_lint_stages

  summary
  [ "$SUMMARY_FAIL" -eq 0 ]
}

main "$@"
