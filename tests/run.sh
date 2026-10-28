#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## tests/run.sh -- language-neutral test dispatcher for __PROJECT_NAME__ (entry point)
#
# Discovers whichever language lanes are present in this checkout and runs each
# one, so `make test`, CI, and a human at a keyboard all execute the same thing.
# Lanes are optional overlays; the default lane is `shell`. A lane turns itself on
# by shipping its own tests and its own manifest:
#
#   lane         manifest that turns it on                  runner
#   shell        tests/**/*.bats                            bats
#   python       pytest.ini / pyproject.toml [tool.pytest]  python3 -m pytest
#              / tests/**/test_*.py
#   typescript   package.json                               npm test
#   go           go.mod                                     go test ./...
#
# Hard contract: a lane whose manifest is present but whose runner binary is
# missing is a FAILURE with an install hint, never a skip. This project ships no
# "tool not found ... Skipping" green runs; see docs/project-conventions.md.
#
# Usage:
#   tests/run.sh                    # every discovered lane
#   tests/run.sh --lane python      # one lane only (error if it is absent)
#   tests/run.sh --list             # print the plan, run nothing
#   tests/run.sh --dry-run          # print each command, run nothing
#   tests/run.sh --lanes            # print the lane ids present, one per line
#
# Returns: 0 when every selected lane passed, 1 otherwise. --lanes is the machine
# readable form and exits 0 even when no lane is present, because `make doctor`
# calls it to decide which pins a given checkout is allowed to demand.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="$ROOT_DIR/tool-versions.env"
ENABLED_FILE="$ROOT_DIR/.template-lanes/enabled"

SUMMARY_OK=0
SUMMARY_WARN=0
SUMMARY_FAIL=0
DRY_RUN=0
LIST_ONLY=0
LANES_ONLY=0
REQUESTED_LANE=""
LANE_PLAN=()

readonly -a KNOWN_LANES=("shell" "python" "typescript" "go")

# @function usage
# Print the CLI contract and exit.
# Globals:
#   SCRIPT_NAME, KNOWN_LANES
# Arguments:
#   None
# Outputs:
#   Usage text on stdout
# Returns:
#   0 (exits)
usage() {
  cat <<EOF
${SCRIPT_NAME} -- run every language lane present in this checkout

Usage:
  ${SCRIPT_NAME} [--lane <id>] [--list] [--dry-run] [--lanes] [--help]

Options:
  --lane <id>   run one lane only: ${KNOWN_LANES[*]}
  --list        print the discovered lanes and exit without running them
  --dry-run     print each runner command and exit without running it
  --lanes       print one present lane id per line and exit (never fails)
  --help        show this text

Exit codes:
  0  every selected lane passed
  1  a lane failed, a runner was missing, or nothing was discovered
EOF
  exit 0
}

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
# Record and print a soft warning. A warning never fails the run; a missing
# runner is an error, not a warning.
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

# @function die
# Print one failure line and abort with the runner's exit code.
# Globals:
#   None
# Arguments:
#   $1 - text without the "error: " prefix
# Outputs:
#   "error: text" on stderr
# Returns:
#   never returns (exits 1)
die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
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
# Read one version pin out of tool-versions.env so install hints quote the same
# number CI installs. Never sources the file: a malformed pin must not take the
# test run down with it.
# Globals:
#   PINS_FILE
# Arguments:
#   $1 - KEY, for example BATS_VERSION
# Outputs:
#   The value on stdout, or "latest" when the key is absent
# Returns:
#   0
pin_value() {
  local key="$1"
  local line=""
  if [ -r "$PINS_FILE" ]; then
    line="$(grep -m1 -E "^${key}=" "$PINS_FILE" 2>/dev/null || true)"
  fi
  if [ -z "$line" ]; then
    printf 'latest\n'
    return 0
  fi
  printf '%s\n' "${line#*=}"
}

# @function lane_manifest_found
# Report whether a lane's manifest is present in this checkout.
# Globals:
#   ROOT_DIR
# Arguments:
#   $1 - lane id from KNOWN_LANES
# Outputs:
#   None
# Returns:
#   0 when present, 1 when absent, 2 for an unknown lane id
lane_manifest_found() {
  local lane="$1"
  case "$lane" in
    shell)
      [ -n "$(find "$ROOT_DIR/tests" -type f -name '*.bats' -print -quit 2>/dev/null)" ]
      ;;
    python)
      if [ -f "$ROOT_DIR/pytest.ini" ] || [ -d "$ROOT_DIR/tests/python" ]; then
        return 0
      fi
      if [ -n "$(find "$ROOT_DIR/tests" -type f \( -name 'test_*.py' -o -name '*_test.py' \) -print -quit 2>/dev/null)" ]; then
        return 0
      fi
      [ -f "$ROOT_DIR/pyproject.toml" ] && grep -q 'tool\.pytest' "$ROOT_DIR/pyproject.toml" 2>/dev/null
      ;;
    typescript)
      [ -f "$ROOT_DIR/package.json" ]
      ;;
    go)
      [ -f "$ROOT_DIR/go.mod" ]
      ;;
    *)
      return 2
      ;;
  esac
}

# @function build_lane_plan
# Decide which lanes to run: the union of the explicit .template-lanes/enabled list and
# what the manifests show. The scaffolding CLI ships no lane state (it strips
# .template-lanes from the render), so that file only exists when a project chooses to pin
# its lanes by hand. An enabled lane with no manifest on disk is an error, never a
# skip.
# Globals:
#   KNOWN_LANES, ENABLED_FILE, REQUESTED_LANE, LANE_PLAN
# Arguments:
#   None
# Outputs:
#   Discovery lines on stdout; fills LANE_PLAN
# Returns:
#   0, or dies on an unknown lane or an enabled lane with no manifest
build_lane_plan() {
  local -a wanted=()
  local lane=""
  local seen=""

  if [ -n "$REQUESTED_LANE" ]; then
    wanted=("$REQUESTED_LANE")
  else
    wanted=("${KNOWN_LANES[@]}")
  fi

  if [ -z "$REQUESTED_LANE" ] && [ -r "$ENABLED_FILE" ]; then
    while IFS= read -r lane; do
      lane="${lane%%#*}"
      lane="${lane//[[:space:]]/}"
      [ -n "$lane" ] || continue
      wanted+=("$lane")
    done <"$ENABLED_FILE"
  fi

  for lane in "${wanted[@]}"; do
    if ! printf '%s\n' "${KNOWN_LANES[@]}" | grep -qx "$lane"; then
      die "unknown lane '$lane'; known lanes are: ${KNOWN_LANES[*]}"
    fi
    if ! lane_manifest_found "$lane"; then
      if [ -n "$REQUESTED_LANE" ] || [ -r "$ENABLED_FILE" ]; then
        die "lane '$lane' is selected but its manifest is missing (see docs/README.md for the lane manifests)"
      fi
      continue
    fi
    case " $seen " in
      *" $lane "*) continue ;;
    esac
    seen="$seen $lane"
    LANE_PLAN+=("$lane")
    phase "discovered lane: $lane"
  done

  if [ ${#LANE_PLAN[@]} -eq 0 ]; then
    die "no test lane found. Expected at least the shell lane (tests/*.bats + bats). Add one with the scaffolding CLI's --lane flag."
  fi
  ok "discovered ${#LANE_PLAN[@]} lane(s)"
}

# @function run_command
# Run one runner command, or print it under --dry-run / --list.
# Globals:
#   DRY_RUN, LIST_ONLY
# Arguments:
#   $1 - lane id (for the log line); rest - the command and its argv
# Outputs:
#   "-> $ ..." then the runner's own output
# Returns:
#   The runner's exit code, or 0 in dry-run and list mode
run_command() {
  local lane="$1"
  shift
  phase "$lane: $*"
  if [ "$LIST_ONLY" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi
  (cd "$ROOT_DIR" && "$@")
}

# @function report_lane
# Record one lane's outcome. Under --list / --dry-run it never claims a pass,
# because nothing ran.
# Globals:
#   LIST_ONLY, DRY_RUN, SUMMARY_OK, SUMMARY_FAIL
# Arguments:
#   $1 - lane id, $2 - runner exit code, $3 - pass text, $4 - fail text
# Outputs:
#   An ok:, error:, or -> line
# Returns:
#   0
report_lane() {
  local lane="$1" rc="$2" pass_text="$3" fail_text="$4"
  if [ "$LIST_ONLY" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    phase "$lane: planned, not executed"
    return 0
  fi
  if [ "$rc" -eq 0 ]; then
    ok "$pass_text"
  else
    err "$fail_text (runner exit $rc)"
  fi
}

# @function run_shell_lane
# Run every bats file under tests/.
# Globals:
#   ROOT_DIR, LIST_ONLY
# Arguments:
#   None
# Outputs:
#   bats output
# Returns:
#   0, or dies when bats is missing
# Note:
#   The manifest check runs before the tool probe, so a lane with no test files
#   fails as "no tests" rather than as "bats not installed".
run_shell_lane() {
  local -a files=()
  mapfile -d '' -t files < <(find "$ROOT_DIR/tests" -type f -name '*.bats' -print0 | sort -z)
  if [ ${#files[@]} -eq 0 ]; then
    err "shell: the bats manifest matched a lane but no .bats file was found under tests/"
    return 0
  fi
  if [ "$LIST_ONLY" -eq 0 ] && ! have bats; then
    require_runner "shell" "bats" "bats-core $(pin_value BATS_VERSION): https://bats-core.github.io/bats-core/installation.html, or apt-get install -y bats"
  fi
  local rc=0
  run_command "shell" bats "${files[@]}" || rc=$?
  report_lane "shell" "$rc" "shell: ${#files[@]} bats file(s) passed" "shell: bats failed"
}

# @function run_python_lane
# Run pytest over tests/.
# Globals:
#   ROOT_DIR, LIST_ONLY
# Arguments:
#   None
# Outputs:
#   pytest output
# Returns:
#   0, or dies when the interpreter or pytest is missing
run_python_lane() {
  if [ "$LIST_ONLY" -eq 0 ]; then
    if ! have python3; then
      require_runner "python" "python3" "apt-get install -y python3 python3-pip"
    fi
    if ! python3 -m pytest --version >/dev/null 2>&1; then
      require_runner "python" "pytest" "python3 -m pip install 'pytest==$(pin_value PYTEST_VERSION)' 'ruff==$(pin_value RUFF_VERSION)' 'mypy==$(pin_value MYPY_VERSION)'"
    fi
  fi
  local rc=0
  run_command "python" python3 -m pytest -q tests || rc=$?
  report_lane "python" "$rc" "python: pytest passed" "python: pytest failed"
}

# @function run_typescript_lane
# Run the package.json test script.
# Globals:
#   ROOT_DIR, LIST_ONLY
# Arguments:
#   None
# Outputs:
#   npm output
# Returns:
#   0, or dies when npm is missing or the install failed
run_typescript_lane() {
  if [ "$LIST_ONLY" -eq 0 ]; then
    if ! have npm; then
      require_runner "typescript" "npm" "install Node $(pin_value NODE_VERSION) (https://nodejs.org) so npm is on PATH"
    fi
    if ! grep -q '"test"[[:space:]]*:' "$ROOT_DIR/package.json" 2>/dev/null; then
      err 'typescript: package.json has no "test" script, so there is nothing to run'
      return 0
    fi
    if [ ! -d "$ROOT_DIR/node_modules" ]; then
      warn "typescript: node_modules missing; running 'npm ci' first"
      if ! (cd "$ROOT_DIR" && npm ci --silent); then
        err "typescript: npm ci failed"
        return 0
      fi
    fi
  fi
  local rc=0
  run_command "typescript" npm test --silent || rc=$?
  report_lane "typescript" "$rc" "typescript: npm test passed" "typescript: npm test failed"
}

# @function run_go_lane
# Run the Go test packages.
# Globals:
#   ROOT_DIR, LIST_ONLY
# Arguments:
#   None
# Outputs:
#   go test output
# Returns:
#   0, or dies when the Go toolchain is missing
run_go_lane() {
  if [ "$LIST_ONLY" -eq 0 ] && ! have go; then
    require_runner "go" "go" "install Go $(pin_value GO_VERSION) from https://go.dev/dl into /usr/local/go"
  fi
  local rc=0
  run_command "go" go test ./... || rc=$?
  report_lane "go" "$rc" "go: go test passed" "go: go test failed"
}

# @function require_runner
# Fail the run because a selected lane's runner is absent, and say how to install it.
# This is the anti-silent-skip guard: there is no path where a missing binary
# leaves the run green.
# Globals:
#   None
# Arguments:
#   $1 - lane id, $2 - binary name, $3 - install hint
# Outputs:
#   Three error lines on stderr
# Returns:
#   never returns (exits 1)
require_runner() {
  local lane="$1" binary="$2" hint="$3"
  printf 'error: lane %s needs %s, which is not on PATH\n' "$lane" "$binary" >&2
  printf 'error:   install it: %s\n' "$hint" >&2
  printf 'error:   or run "make doctor" to see every pin in tool-versions.env that is missing\n' >&2
  exit 1
}

# @function run_lane
# Dispatch one lane to its runner.
# Globals:
#   None
# Arguments:
#   $1 - lane id
# Outputs:
#   A section heading and the runner's output
# Returns:
#   0
run_lane() {
  local lane="$1"
  section "lane: $lane"
  case "$lane" in
    shell) run_shell_lane ;;
    python) run_python_lane ;;
    typescript) run_typescript_lane ;;
    go) run_go_lane ;;
  esac
}

# @function print_lanes
# Print the lane ids whose manifest is present, one per line.
# Globals:
#   KNOWN_LANES, ROOT_DIR
# Arguments:
#   None
# Outputs:
#   One lane id per line on stdout; nothing when no lane is present
# Returns:
#   0, always. An empty checkout is a legitimate answer here, unlike in the run
#   path: `make doctor` calls this to learn which pins this checkout may demand.
print_lanes() {
  local lane=""
  for lane in "${KNOWN_LANES[@]}"; do
    if lane_manifest_found "$lane"; then
      printf '%s\n' "$lane"
    fi
  done
  return 0
}

# @function parse_args
# Validate argv and set the run mode.
# Globals:
#   DRY_RUN, LIST_ONLY, LANES_ONLY, REQUESTED_LANE, KNOWN_LANES
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   None
# Returns:
#   0, or dies on an unknown flag or a missing --lane value
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --list) LIST_ONLY=1 ;;
      --lanes) LANES_ONLY=1 ;;
      --lane)
        [ $# -ge 2 ] || die "--lane needs a value (${KNOWN_LANES[*]})"
        REQUESTED_LANE="$2"
        shift
        ;;
      --lane=*) REQUESTED_LANE="${1#*=}" ;;
      --help | -h) usage ;;
      *) die "unknown argument: $1 (try --help)" ;;
    esac
    shift
  done
}

# @function main
# Discover lanes, run them, print the summary. --lanes short-circuits to the
# machine-readable lane list.
# Globals:
#   LANE_PLAN, SUMMARY_OK, SUMMARY_WARN, SUMMARY_FAIL, LIST_ONLY, LANES_ONLY
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   Full run transcript
# Returns:
#   0 when nothing failed, 1 otherwise
main() {
  parse_args "$@"
  if [ "$LANES_ONLY" -eq 1 ]; then
    print_lanes
    return 0
  fi
  section "discovery"
  build_lane_plan
  local lane=""
  for lane in "${LANE_PLAN[@]}"; do
    run_lane "$lane"
  done
  if [ "$LIST_ONLY" -eq 1 ]; then
    printf 'summary: %d ok, %d warnings, %d failed (list only)\n' \
      "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
    return 0
  fi
  printf 'summary: %d ok, %d warnings, %d failed\n' \
    "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
  [ "$SUMMARY_FAIL" -eq 0 ]
}

main "$@"
