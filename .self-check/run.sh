#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## .self-check/run.sh -- run the template's own conformance suite (entry point)
#
# The lane suites check the code a rendered project writes. This one checks the
# template: that every render token is one a generator substitutes, that each lane
# ships the metadata the render consumes, that no pin floats, that no gate can
# report green while doing nothing. It is the suite for this repository as a
# template, which is why it sits beside the template rather than under tests/, and
# why a rendered project does not carry it: the generator strips .self-check/.
#
# Self-contained on purpose: bats and the tools every lane already needs, nothing
# else. A contributor with bats on PATH can run it in a clean clone.
#
# Usage:
#   make self-check                    # from the repository root
#   bash .self-check/run.sh            # the same, without make
#
# Returns: 0 when every assertion passed, 1 otherwise. A missing bats is an error
# that quotes the pinned install command, never a skip; see
# docs/project-conventions.md.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
SELF_CHECK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SELF_CHECK_DIR}/.." && pwd)"
SUITE="${SELF_CHECK_DIR}/self-check.bats"
PINS_FILE="${ROOT_DIR}/tool-versions.env"

SUMMARY_OK=0
SUMMARY_WARN=0
SUMMARY_FAIL=0

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
# Print a passed check without counting it. The counts in the closing summary come
# from the TAP transcript, so a preflight line must not inflate them.
# Globals:
#   None
# Arguments:
#   $1 - text without the "ok: " prefix
# Outputs:
#   "ok: text" on stdout
# Returns:
#   0
ok() {
  printf 'ok: %s\n' "$1"
}

# @function note
# Print a fact the reader needs and nobody has to act on.
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

# @function die
# Print one failure line and abort with exit 1.
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

# @function pin_value
# Read one version pin out of tool-versions.env so the install hint quotes the same
# number CI installs. Never sources the file: a malformed pin must not take this
# run down with it.
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

# @function require_bats
# Abort with the pinned install command when bats is missing. The anti-silent-skip
# rule: there is no path where a missing bats leaves this run green.
# Globals:
#   SCRIPT_NAME, ROOT_DIR, PINS_FILE
# Arguments:
#   None
# Outputs:
#   Three error lines on stderr
# Returns:
#   0 when bats resolves, otherwise never returns (exits 1)
require_bats() {
  if command -v bats >/dev/null 2>&1; then
    return 0
  fi
  local version
  version="$(pin_value BATS_VERSION)"
  [ -n "$version" ] || version="<VERSION>"
  printf 'error: %s needs bats, which is not on PATH, so the suite cannot run\n' "$SCRIPT_NAME" >&2
  printf 'error:   this repo pins BATS_VERSION in %s\n' "${PINS_FILE#"$ROOT_DIR"/}" >&2
  printf 'error:   install it: git clone --depth 1 --branch v%s https://github.com/bats-core/bats-core.git /tmp/bats-core && /tmp/bats-core/install.sh /usr/local\n' "$version" >&2
  exit 1
}

# @function tap_count
# Count one kind of TAP result line out of the bats transcript.
# Globals:
#   None
# Arguments:
#   $1 - grep -E pattern for the lines to count
#   $2 - path of the file holding the transcript
# Outputs:
#   The count on stdout (0 when the file holds none)
# Returns:
#   0
tap_count() {
  local count=""
  count="$(grep -cE "$1" "$2" 2>/dev/null || true)"
  printf '%s\n' "${count:-0}"
}

# @function main
# Preflight, run the suite from the repository root, print the closing summary.
# Globals:
#   ROOT_DIR, SUITE, SUMMARY_OK, SUMMARY_WARN, SUMMARY_FAIL
# Arguments:
#   "$@" - none; this entry point takes no flags
# Outputs:
#   bats' own TAP output, then the summary line
# Returns:
#   0 when nothing failed or skipped, 1 otherwise
main() {
  [ -f "$SUITE" ] || die "the suite is missing: ${SUITE#"$ROOT_DIR"/}"
  cd "$ROOT_DIR"

  section "self-check"
  phase "preflight"
  require_bats
  note "bats $(bats --version 2>&1 | head -n 1) on $(uname -s)"
  note "repository root: ${ROOT_DIR}"

  local transcript="" rc=0
  transcript="$(mktemp "${TMPDIR:-/tmp}/self-check.XXXXXX")"
  phase "bats ${SUITE#"$ROOT_DIR"/}"
  bats --formatter tap "${SUITE#"$ROOT_DIR"/}" 2>&1 | tee "$transcript" || rc=$?

  local total failed skipped
  total="$(tap_count '^(ok|not ok) ' "$transcript")"
  failed="$(tap_count '^not ok ' "$transcript")"
  skipped="$(tap_count '^ok .*# skip' "$transcript")"
  rm -f -- "$transcript"

  SUMMARY_OK=$((total - failed - skipped))
  SUMMARY_FAIL=$failed
  SUMMARY_WARN=$skipped

  if [ "$total" -eq 0 ]; then
    SUMMARY_FAIL=1
    printf 'error: bats reported no test results (exit %s); the suite did not run\n' "$rc" >&2
  elif [ "$failed" -gt 0 ]; then
    printf 'error: template conformance: %s assertion(s) failed; fix the tree, not the assertion\n' "$failed" >&2
  elif [ "$rc" -ne 0 ]; then
    SUMMARY_FAIL=1
    printf 'error: bats exited %s without failing an assertion; a suite that cannot finish is not green\n' "$rc" >&2
  else
    ok "template conformance: ${SUMMARY_OK} assertion(s) passed"
  fi

  if [ "$skipped" -gt 0 ]; then
    printf 'warning: %s assertion(s) skipped; a skipped check is a check nobody made\n' "$skipped" >&2
  fi

  printf 'summary: %d ok, %d warnings, %d failed\n' \
    "$SUMMARY_OK" "$SUMMARY_WARN" "$SUMMARY_FAIL"
  [ "$SUMMARY_FAIL" -eq 0 ]
}

main "$@"
