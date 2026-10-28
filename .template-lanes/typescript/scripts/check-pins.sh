#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## check-pins.sh - package.json / tool-versions.env drift guard (entry point)
#
# Two files in this repo name the same tools, and neither tool reads the other:
# `npm ci` installs what package.json says, while CI installs and `make doctor`
# probes what tool-versions.env says. The day they drift, your editor runs one
# version of eslint and CI runs another, and a green local run stops meaning
# anything. That drift is the bug class this template exists to prevent, and this
# script is the only thing that notices it.
#
# It asserts two things, both cheap and both expensive to discover late:
#
#   1. each key shared with tool-versions.env (prettier, typescript, eslint,
#      vitest) appears in devDependencies at exactly the pinned version;
#   2. every devDependencies entry is an exact version. A range (`^`, `~`, `*`,
#      `latest`, `workspace:`) is a pin that moves on its own between two
#      `npm ci` runs, which is how a flaky build gets mistaken for a flaky test.
#
# The JSON is read with python3 + json.load rather than grep on purpose: a grep
# for "typescript" also matches "typescript-eslint" and "@types/node", and a
# guard that checks the wrong key is worse than no guard at all.
#
# A checkout with no package.json has nothing to cross-check, so this exits 0
# with an ok: line. The shell, python and go lanes call it unconditionally and
# must not trip over a lane they did not install.
#
# Usage:
#   scripts/check-pins.sh
#
# Returns: 0 when every pin agrees, 1 otherwise.

set -euo pipefail

SCRIPT_NAME="${0##*/}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="$ROOT_DIR/tool-versions.env"
PACKAGE_JSON="$ROOT_DIR/package.json"

SUMMARY_OK=0
SUMMARY_WARN=0
SUMMARY_FAIL=0

# The checker, as a string handed to `python3 -c` so the JSON is parsed by a
# JSON parser. It is one variable rather than an inline literal because it is
# long, and its text uses only double quotes so the bash single quoting below
# never has to be escaped.
readonly PY_PROG='
import json
import re
import sys

EXACT = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$")
KEY_RE = re.compile(r"^[A-Z0-9_]+$")
SHARED = (
    ("prettier", "PRETTIER_VERSION"),
    ("typescript", "TYPESCRIPT_VERSION"),
    ("eslint", "ESLINT_VERSION"),
    ("vitest", "VITEST_VERSION"),
)


def err(text):
    print("error: " + text, file=sys.stderr)


def load_pins(path):
    pins = {}
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            if KEY_RE.match(key):
                # tool-versions.env is documented as unquoted KEY=value, so a stray
                # quote here is a typo that must fail loudly rather than compare
                # equal to the version package.json declares.
                pins[key] = value.strip()
    return pins


def main(argv):
    pkg_path, pins_path = argv[1], argv[2]
    try:
        with open(pkg_path, encoding="utf-8") as handle:
            pkg = json.load(handle)
    except OSError as exc:
        err("%s cannot be read: %s" % (pkg_path, exc))
        return 1
    except ValueError as exc:
        err("%s is not valid JSON: %s" % (pkg_path, exc))
        return 1
    if not isinstance(pkg, dict):
        err("%s is not a JSON object, so its dependencies cannot be read" % pkg_path)
        return 1

    deps = pkg.get("devDependencies")
    if not isinstance(deps, dict) or not deps:
        err("%s declares no devDependencies, so nothing in the typescript lane is pinned" % pkg_path)
        return 1

    try:
        pins = load_pins(pins_path)
    except OSError as exc:
        err("%s cannot be read: %s" % (pins_path, exc))
        return 1
    if not pins:
        err("%s holds no KEY=value lines, so there is nothing to compare against" % pins_path)
        return 1

    print("note: %s declares %d devDependencies entries" % (pkg_path, len(deps)), flush=True)

    failed = 0
    for name in sorted(deps):
        spec = deps[name]
        if not isinstance(spec, str) or EXACT.match(spec) is None:
            err("devDependencies[%s] = %s is not an exact version; the allowed form is "
                "1.2.3 or 1.2.3-beta.1, so ^, ~, *, latest, workspace: and || are rejected" % (
                    json.dumps(name), json.dumps(spec)))
            failed += 1

    for name, key in SHARED:
        expected = pins.get(key)
        if expected is None:
            err("%s has no %s= line; that key is what pins %s for CI and make doctor" % (pins_path, key, name))
            failed += 1
            continue
        if name not in deps:
            err("devDependencies has no %s entry, so %s=%s is not the version this "
                "repo installs" % (json.dumps(name), key, expected))
            failed += 1
            continue
        actual = deps[name]
        if actual != expected:
            err("devDependencies[%s] is %s but %s sets %s; npm installs one version "
                "and CI the other" % (json.dumps(name), json.dumps(actual), key, expected))
            failed += 1

    if failed:
        err("%d pin problem(s) in the typescript lane. Edit package.json or tool-versions.env "
            "so the two agree; do not work around this script." % failed)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
'

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
# Record and print a soft warning. A warning never fails the run.
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
${SCRIPT_NAME} -- assert package.json and tool-versions.env name the same versions

Usage:
  ${SCRIPT_NAME} [--help]

Exit codes:
  0  every shared pin agrees and every devDependency is an exact version, or
     there is no package.json to check (a lane this repo does not have)
  1  a pin drifted, a pin is missing, or the checker itself could not run
EOF
  exit 0
}

# @function parse_args
# Validate argv.
# Globals:
#   SCRIPT_NAME
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   None
# Returns:
#   0, or exits 2 on an unknown flag
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help | -h) usage ;;
      *)
        printf 'error: unknown argument: %s (try --help)\n' "$1" >&2
        exit 2
        ;;
    esac
    shift
  done
}

# @function run_guard
# Run the python checker once and record its outcome.
# Globals:
#   PACKAGE_JSON, PINS_FILE, PY_PROG, SUMMARY_OK, SUMMARY_FAIL
# Arguments:
#   None
# Outputs:
#   The checker's note:/error: lines, then this script's ok: or error: line
# Returns:
#   0 when the pins agree, 1 otherwise
run_guard() {
  phase "reading devDependencies with python3 -c and json.load"
  if python3 -c "$PY_PROG" "$PACKAGE_JSON" "$PINS_FILE"; then
    ok "every devDependencies entry is an exact version"
    ok "prettier, typescript, eslint and vitest match tool-versions.env"
    return 0
  fi
  err "package.json and tool-versions.env disagree; see the error lines above"
  return 1
}

# @function main
# Check the pins, or say loudly why the checker could not run.
# Globals:
#   PACKAGE_JSON, PINS_FILE, SCRIPT_NAME
# Arguments:
#   "$@" - the CLI arguments
# Outputs:
#   Full run transcript
# Returns:
#   0 when the pins agree or there is no package.json, 1 otherwise
main() {
  parse_args "$@"
  section "check-pins: package.json vs tool-versions.env"

  if [ ! -f "$PACKAGE_JSON" ]; then
    note "this checkout has no package.json, so the typescript lane is not installed"
    ok "nothing to cross-check"
    summary
    return 0
  fi
  if [ ! -r "$PACKAGE_JSON" ]; then
    err "$PACKAGE_JSON exists but is not readable; fix the mode instead of skipping the check"
    summary
    return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    err "$SCRIPT_NAME needs python3 to parse package.json; install it with apt-get install -y python3"
    summary
    return 1
  fi

  local rc=0
  run_guard || rc=1
  summary
  return "$rc"
}

main "$@"
