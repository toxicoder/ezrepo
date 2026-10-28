#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## main.sh - the __PROJECT_NAME__ command line entry point (entry point)
#
# __PROJECT_DESCRIPTION__
#
# The whole CLI is two commands and one environment variable, and that is the
# point: this file is the reference shape every other file in the repo copies.
#   - `greet <name>` prints one greeting line.
#   - `--version` prints "<project> <semver>" so a packager and a smoke test can
#     both parse it.
#   - `GREETING_WORD` changes the word; unset or blank means "Hello".
#
# Exit codes, asserted by tests/shell/main.bats:
#   0   the command ran
#   2   argv was wrong: no command, unknown command, or greet without a name
#
# Anything fatal goes to stderr and nothing fatal goes to stdout, so
# `__PROJECT_NAME__ greet Ada > out.txt` never writes a diagnostic into the
# file. The rendering itself lives in src/lib/greet.sh, not here: this file
# parses argv, chooses an exit code, and prints.

set -euo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/greet.sh
source "$SELF_DIR/lib/greet.sh"

readonly PROJECT_NAME="__PROJECT_NAME__"
readonly PROJECT_VERSION="0.1.0"
readonly DEFAULT_GREETING_WORD="Hello"

# Exit codes. Named, because "return 2" in three places tells a reader nothing.
readonly EXIT_USAGE=2

# @function usage
# Print the command list and the environment contract.
# Globals:
#   PROJECT_NAME, DEFAULT_GREETING_WORD
# Arguments:
#   None
# Outputs:
#   Usage text on stdout
# Returns:
#   0
usage() {
  cat <<EOF
${PROJECT_NAME} ${PROJECT_VERSION} - __PROJECT_DESCRIPTION__

Usage:
  ${PROJECT_NAME} greet <name>
  ${PROJECT_NAME} --version
  ${PROJECT_NAME} --help

Environment:
  GREETING_WORD   word used by "greet" (default: ${DEFAULT_GREETING_WORD})

Exit codes:
  0  success
  2  bad arguments
EOF
}

# @function resolve_word
# Print the greeting word this invocation should use.
# The variable is optional: unset, empty, or all-whitespace all mean "use the
# documented default", because an accidentally blank GREETING_WORD in a
# container environment should print "Hello, X!" and not ", X!".
# Globals:
#   GREETING_WORD, DEFAULT_GREETING_WORD
# Arguments:
#   None
# Outputs:
#   The word on stdout
# Returns:
#   0
resolve_word() {
  local word="${GREETING_WORD-$DEFAULT_GREETING_WORD}"
  if [ -z "${word//[[:space:]]/}" ]; then
    word="$DEFAULT_GREETING_WORD"
  fi
  printf '%s' "$word"
}

# @function cmd_greet
# Handle `greet <name>`.
# Globals:
#   PROJECT_NAME
# Arguments:
#   $1 - the name to greet; missing or blank is a usage error
# Outputs:
#   The greeting line on stdout, or one error line on stderr
# Returns:
#   0 on success, EXIT_USAGE when no name was given
cmd_greet() {
  local name="${1-}"
  if [ -z "$(trim "$name")" ]; then
    printf 'error: greet needs a name, for example: %s greet Ada\n' "$PROJECT_NAME" >&2
    return "$EXIT_USAGE"
  fi
  build_greeting "$(resolve_word)" "$name"
}

# @function run_command
# Dispatch one argv vector to a subcommand.
# Globals:
#   PROJECT_NAME, PROJECT_VERSION
# Arguments:
#   "$@" - the full argv after the program name
# Outputs:
#   Whatever the subcommand prints
# Returns:
#   The subcommand's exit code, or EXIT_USAGE for no/unknown command
run_command() {
  if [ "$#" -eq 0 ]; then
    printf 'error: no command given\n' >&2
    usage >&2
    return "$EXIT_USAGE"
  fi

  case "$1" in
    greet)
      shift
      cmd_greet "$@"
      ;;
    --version | version)
      printf '%s %s\n' "$PROJECT_NAME" "$PROJECT_VERSION"
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      printf 'error: unknown command: %s\n' "$1" >&2
      usage >&2
      return "$EXIT_USAGE"
      ;;
  esac
}

# @function main
# Program entry: hand argv to the dispatcher and propagate its code.
# Globals:
#   None
# Arguments:
#   "$@" - the command line arguments
# Outputs:
#   Whatever the dispatched subcommand prints
# Returns:
#   The subcommand's exit code
main() {
  run_command "$@"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
