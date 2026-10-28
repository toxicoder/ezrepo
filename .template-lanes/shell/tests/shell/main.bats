#!/usr/bin/env bats
#
# ## main.bats - behavioural coverage for src/main.sh (lane: shell)
#
# The CLI contract pinned here, one assertion group per exit-code row:
# `greet <name>` prints exactly one line; GREETING_WORD changes the word and
# blank means the documented default; `--version` prints "<project> <semver>";
# `--help` succeeds and names both commands; and every argv mistake (no
# command, unknown command, greet with no name) exits 2 with the complaint on
# stderr and nothing on stdout.
#
# These run src/main.sh as a real subprocess, which is the only way to prove
# the exit codes and the stdout/stderr split. The pure renderer is covered
# separately, in-process, by tests/shell/lib_unit.bats.
#
# Usage: bats tests/shell/main.bats        (or: tests/run.sh --lane shell)
# Safety: no network, no docker, no writes outside bats' own tmpdir.

bats_require_minimum_version 1.5.0

MAIN=""

setup() {
  local root
  root="$(cd -- "$BATS_TEST_DIRNAME/../.." && pwd)"
  MAIN="$root/src/main.sh"
  # A suite whose subject vanished must fail, not silently pass zero tests.
  [ -f "$MAIN" ]
  # The host's value must never leak in and move an assertion.
  unset GREETING_WORD
}

@test "greet prints one greeting line for the given name" {
  run --separate-stderr bash "$MAIN" greet Ada
  [ "$status" -eq 0 ]
  [ "$output" = "Hello, Ada!" ]
  [ ${#lines[@]} -eq 1 ]
  [ -z "$stderr" ]
}

@test "greet trims surrounding space off the name" {
  run --separate-stderr bash "$MAIN" greet "  Grace  "
  [ "$status" -eq 0 ]
  [ "$output" = "Hello, Grace!" ]
}

@test "greet honours GREETING_WORD" {
  GREETING_WORD="Howdy" run --separate-stderr bash "$MAIN" greet Ada
  [ "$status" -eq 0 ]
  [ "$output" = "Howdy, Ada!" ]
}

@test "greet falls back to the default word when GREETING_WORD is blank" {
  GREETING_WORD="   " run --separate-stderr bash "$MAIN" greet Ada
  [ "$status" -eq 0 ]
  [ "$output" = "Hello, Ada!" ]
}

@test "version prints the project name and a semver" {
  run --separate-stderr bash "$MAIN" --version
  [ "$status" -eq 0 ]
  [ "$output" = "__PROJECT_NAME__ 0.1.0" ]
  [[ $output =~ ^__PROJECT_NAME__\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "help succeeds and names both commands" {
  run --separate-stderr bash "$MAIN" --help
  [ "$status" -eq 0 ]
  [[ $output == *"greet <name>"* ]]
  [[ $output == *"--version"* ]]
  [[ $output == *"GREETING_WORD"* ]]
  [ -z "$stderr" ]
}

@test "greet without a name exits 2 and complains on stderr only" {
  run --separate-stderr bash "$MAIN" greet
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [[ $stderr == *"greet needs a name"* ]]
}

@test "greet with a blank name exits 2" {
  run --separate-stderr bash "$MAIN" greet "   "
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [[ $stderr == *"greet needs a name"* ]]
}

@test "no command at all exits 2 with usage on stderr" {
  run --separate-stderr bash "$MAIN"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [[ $stderr == *"no command given"* ]]
  [[ $stderr == *"Usage:"* ]]
}

@test "unknown command exits 2 and names the offending word" {
  run --separate-stderr bash "$MAIN" frobnicate
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [[ $stderr == *"unknown command: frobnicate"* ]]
}
