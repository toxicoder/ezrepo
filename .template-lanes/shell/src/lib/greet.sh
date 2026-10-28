# shellcheck shell=bash
#
# ## greet.sh - the pure string half of the greet command (sourced library)
#
# build_greeting is the one piece of __PROJECT_NAME__ that decides what a
# greeting LOOKS like. It is kept here, alone, for two reasons: it reads no
# globals, no environment and no files, so it can be unit-tested by sourcing
# this file and calling it directly (see tests/shell/lib_unit.bats, which never
# spawns a subprocess); and the CLI in src/main.sh stays a thin argv/exit-code
# shell over it. When the greeting format changes, only this file changes and
# the assertion that proves it lives next to it.
#
# Sourced, never executed. There is no main at the bottom and no side effect at
# load time, which is what makes `source ./src/lib/greet.sh` safe from a test
# file, a REPL, or another script.

# @function trim
# Strip leading and trailing whitespace from $1 and print the result.
# Whitespace means the shell's own [:space:] class, so tabs and newlines trim
# the same way spaces do; trimming by pattern rather than by an external `sed`
# is what keeps this callable from inside a subshell-free test.
# Globals:
#   None
# Arguments:
#   $1 - the string to trim, may be empty or unset
# Outputs:
#   The trimmed string on stdout
# Returns:
#   0 always
trim() {
  local value="${1-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

# @function build_greeting
# Compose the single greeting line from a word and a name.
# Pure: given the same two arguments it always prints the same line, touches no
# state, and never fails - an empty word falls back to DEFAULT_GREETING_WORD so
# the caller decides policy and this function only renders.
# Globals:
#   None
# Arguments:
#   $1 - greeting word, for example "Hello"; blank falls back to "Hello"
#   $2 - the name to greet; blank is rendered as-is, callers validate argv
# Outputs:
#   "<word>, <name>!" on stdout, terminated by one newline
# Returns:
#   0 always
build_greeting() {
  local word
  local name
  word="$(trim "${1-}")"
  name="$(trim "${2-}")"
  if [ -z "$word" ]; then
    word="Hello"
  fi
  printf '%s, %s!\n' "$word" "$name"
}
