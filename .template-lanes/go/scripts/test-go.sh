#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## test-go.sh - the go lane's full local gate (entry point)
#
# gofmt, go vet, golangci-lint, go test, coverage, in that order, each behind a
# presence guard. The order is cheap-to-expensive and each stage answers a
# different question: does it read canonically (gofmt), does it compile and pass
# the compiler's own analyses (vet), does it satisfy the style and security
# profile in .golangci.yml (golangci-lint), does it work (go test), was any of it
# executed at all (coverage).
#
# The test run happens once. With the coverage gate on, the single `go test`
# invocation carries -coverprofile; there is no second pass that re-runs the
# suite and could disagree with the first.
#
# The anti-silent-skip rule: a missing go or golangci-lint fails the run and
# prints the pinned install line naming the key in tool-versions.env. A go lane
# that "passed" because golangci-lint was absent is a false green, so there is no
# code path in this file that prints "skipping" and returns 0.
#
# Usage:
#   scripts/test-go.sh              # gofmt + vet + golangci-lint + tests + coverage
#   scripts/test-go.sh --no-cov     # same, without the coverage floor
#   scripts/test-go.sh --lint-only  # gofmt + vet + golangci-lint, no test run
#
# Returns: 0 when every stage passed, 1 otherwise.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="$ROOT_DIR/tool-versions.env"
COVERAGE_FILE="coverage.out"

# COVERAGE_FLOOR is the only home for the go lane's coverage threshold. Go has no
# config file that can carry one (unlike [tool.coverage.report] fail_under in the
# python lane), so the number lives here and nowhere else, and it is compared by
# awk rather than by -ge because the figure go prints is a float.
readonly COVERAGE_FLOOR="90"

# The directories this lane's module owns. gofmt looks here and nowhere else, so
# a vendor/ tree or a node_modules directory can never enter the gate or slow it
# down.
readonly -a GO_SRC_DIRS=("src" "internal")

SUMMARY_OK=0
SUMMARY_WARN=0
SUMMARY_FAIL=0
WITH_COV=1
LINT_ONLY=0

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
# Print a fact about the run that changes how the output should be read, and
# costs nothing when it is wrong.
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

# @function pin_value
# Read one version pin out of tool-versions.env with grep, never with source. A
# malformed pin must not take the test run down with it. The `if grep -q` guard
# is there so a missing key is an empty answer rather than a non-zero grep status
# under `set -e`.
# Globals:
#   PINS_FILE
# Arguments:
#   $1 - KEY, for example GO_VERSION
# Outputs:
#   The value on stdout, or the empty string when the key is absent
# Returns:
#   0
pin_value() {
  local key="$1"
  local line=""

  if [ -r "$PINS_FILE" ] && grep -q -m1 -E "^${key}=" "$PINS_FILE" 2>/dev/null; then
    line="$(grep -m1 -E "^${key}=" "$PINS_FILE")"
  fi
  printf '%s\n' "${line#*=}"
}

# @function require_tool
# Abort with the pinned install command when a lane tool is not on PATH.
# Globals:
#   SCRIPT_NAME, PINS_FILE, ROOT_DIR
# Arguments:
#   $1 - binary name, e.g. golangci-lint
#   $2 - the tool-versions.env KEY that pins it
#   $3 - install command template, with <VERSION> where the pin goes
# Outputs:
#   Three error lines on stderr
# Returns:
#   never returns (exits 1) when the tool is absent
require_tool() {
  local binary="$1"
  local key="$2"
  local install="$3"
  if command -v "$binary" >/dev/null 2>&1; then
    return 0
  fi

  local version
  version="$(pin_value "$key")"
  [ -n "$version" ] || version='<VERSION>'
  printf 'error: %s needs %s, which is not on PATH\n' "$SCRIPT_NAME" "$binary" >&2
  printf 'error:   this repo pins %s in %s\n' "$key" "${PINS_FILE#"$ROOT_DIR"/}" >&2
  printf 'error:   install it: %s\n' "${install//<VERSION>/"$version"}" >&2
  exit 1
}

# @function check_format
# Fail when a lane source file is not gofmt-clean, naming the files.
# Globals:
#   ROOT_DIR, GO_SRC_DIRS
# Arguments:
#   None
# Outputs:
#   The offending paths on stderr, plus an ok: or error: line
# Returns:
#   0 when clean, 1 otherwise
check_format() {
  local -a targets=()
  local dir=""
  for dir in "${GO_SRC_DIRS[@]}"; do
    if [ -d "$ROOT_DIR/$dir" ]; then
      targets+=("$dir")
    else
      warn "no ${dir}/ directory, so gofmt cannot see the sources the lane expects there"
    fi
  done

  if [ ${#targets[@]} -eq 0 ]; then
    err "no go source directory to check (looked in: ${GO_SRC_DIRS[*]})"
    return 1
  fi

  phase "gofmt -l ${targets[*]}"
  local unformatted=""
  unformatted="$(cd "$ROOT_DIR" && gofmt -l "${targets[@]}")"
  if [ -n "$unformatted" ]; then
    printf '%s\n' "$unformatted" >&2
    err "the files above are not gofmt-clean; run 'make fmt'"
    return 1
  fi

  ok "gofmt clean over ${targets[*]}"
  return 0
}

# @function coverage_gate
# Run the suite once under -coverprofile and hold the total at COVERAGE_FLOOR.
# Globals:
#   ROOT_DIR, COVERAGE_FILE, COVERAGE_FLOOR
# Arguments:
#   None
# Outputs:
#   The go test output and the cover summary line
# Returns:
#   0 when the run passed and the floor held, 1 otherwise
coverage_gate() {
  phase "go test -coverprofile=${COVERAGE_FILE} ./..."
  if ! (cd "$ROOT_DIR" && go test "-coverprofile=${COVERAGE_FILE}" ./...); then
    err "go test with coverage failed"
    return 1
  fi

  local report=""
  report="$(cd "$ROOT_DIR" && go tool cover "-func=${COVERAGE_FILE}" | tail -n 1)"
  printf '%s\n' "$report"

  local total=""
  total="$(printf '%s\n' "$report" | awk '{gsub(/%/, "", $NF); print $NF}')"
  if [ -z "$total" ]; then
    err "could not read a coverage total from 'go tool cover -func=${COVERAGE_FILE}'"
    return 1
  fi

  if awk -v got="$total" -v floor="$COVERAGE_FLOOR" 'BEGIN { exit((got + 0) >= (floor + 0) ? 0 : 1) }'; then
    ok "coverage ${total}% is at or above the ${COVERAGE_FLOOR}% floor"
    return 0
  fi

  err "coverage ${total}% is below the ${COVERAGE_FLOOR}% floor; the fix is a test, not the floor"
  return 1
}

# @function failed_stage
# Say out loud that a stage already reported its own failure and the run is
# continuing. The stage helpers return non-zero on purpose; the `||` that keeps
# `set -e` from aborting the run is exactly where a silent skip would hide, so it
# prints instead of swallowing.
# Globals:
#   None
# Arguments:
#   $1 - label of the stage that failed
# Outputs:
#   "-> label" continuation line on stdout
# Returns:
#   0
failed_stage() {
  printf -- '-> %s reported a failure; continuing with the remaining stages\n' "$1"
  return 0
}

# @function parse_args
# Validate argv and set the run mode.
# Globals:
#   WITH_COV, LINT_ONLY, SCRIPT_NAME
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   None
# Returns:
#   0, or exits 2 on an unknown flag
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-cov)
        WITH_COV=0
        ;;
      --lint-only)
        LINT_ONLY=1
        ;;
      --help | -h)
        printf 'Usage: %s [--no-cov] [--lint-only]\n' "$SCRIPT_NAME"
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
  phase "${label}: $*"
  if (cd "$ROOT_DIR" && "$@"); then
    ok "$label"
  else
    err "${label} failed"
    return 1
  fi
  return 0
}

# @function check_module_floor
# Warn when go.mod's `go` directive and the pinned CI toolchain disagree.
# Globals:
#   ROOT_DIR
# Arguments:
#   None
# Outputs:
#   An ok: or warning: line
# Returns:
#   0 always; a floor that only differs in the patch number is not worth a red run
check_module_floor() {
  local pinned=""
  pinned="$(pin_value GO_VERSION)"
  local directive=""
  directive="$(awk '$1 == "go" { print $2; exit }' "$ROOT_DIR/go.mod")"

  if [ -z "$pinned" ] || [ -z "$directive" ]; then
    warn "cannot compare the go.mod go directive with GO_VERSION (one of them is unreadable)"
    return 0
  fi
  if [[ ${pinned} == "${directive}".* ]]; then
    ok "go.mod declares go ${directive}, the major.minor of GO_VERSION=${pinned}"
    return 0
  fi

  warn "go.mod declares go ${directive} while tool-versions.env pins GO_VERSION=${pinned}; CI builds a different language version than the module floor asks for"
  return 0
}

# @function main
# Guard the toolchain, then format, vet, lint, test.
# Globals:
#   ROOT_DIR, SUMMARY_OK, SUMMARY_WARN, SUMMARY_FAIL, WITH_COV, LINT_ONLY
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   Full run transcript
# Returns:
#   0 when every stage passed, 1 otherwise
main() {
  parse_args "$@"
  section "test: go"

  if [ ! -f "$ROOT_DIR/go.mod" ]; then
    err "go.mod is missing, so this checkout is not a Go module and the go lane has nothing to run"
    printf 'summary: %d ok, %d warnings, %d failed\n' "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
    return 1
  fi

  require_tool go GO_VERSION \
    'curl -fsSLo /tmp/go.tgz "https://go.dev/dl/go<VERSION>.linux-amd64.tar.gz" && sudo tar -C /usr/local -xzf /tmp/go.tgz && export PATH="$PATH:/usr/local/go/bin" (swap linux-amd64 for your GOOS/GOARCH)'
  require_tool golangci-lint GOLANGCI_LINT_VERSION \
    'curl -fsSLo /tmp/gcl.tgz "https://github.com/golangci/golangci-lint/releases/download/v<VERSION>/golangci-lint-<VERSION>-linux-amd64.tar.gz" && tar -xzf /tmp/gcl.tgz -C /tmp && sudo install -m 0755 "/tmp/golangci-lint-<VERSION>-linux-amd64/golangci-lint" /usr/local/bin/golangci-lint (swap linux-amd64 for your GOOS/GOARCH)'

  local go_report=""
  if ! go_report="$(go version 2>&1)"; then
    err "'go' is on PATH but 'go version' failed: ${go_report}"
    printf 'summary: %d ok, %d warnings, %d failed\n' "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
    return 1
  fi
  local lint_report=""
  if ! lint_report="$(golangci-lint --version 2>&1 | head -n 1)"; then
    err "'golangci-lint' is on PATH but '--version' failed: ${lint_report}"
    printf 'summary: %d ok, %d warnings, %d failed\n' "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
    return 1
  fi
  ok "toolchain present: ${go_report}"
  ok "linter present: ${lint_report}"

  check_module_floor

  section "static"
  check_format || failed_stage "gofmt"
  run_stage "go vet" go vet ./... || failed_stage "go vet"
  run_stage "golangci-lint" golangci-lint run ./... || failed_stage "golangci-lint"

  section "tests"
  if [ "$LINT_ONLY" -eq 1 ]; then
    note "--lint-only: the test run and the coverage floor were not executed"
  elif [ "$WITH_COV" -eq 1 ]; then
    coverage_gate || failed_stage "coverage"
  else
    note "--no-cov: the ${COVERAGE_FLOOR}% floor is not being enforced by this run"
    run_stage "go test" go test ./... || failed_stage "go test"
  fi

  printf 'summary: %d ok, %d warnings, %d failed\n' "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
  [ "$SUMMARY_FAIL" -eq 0 ]
}

main "$@"
