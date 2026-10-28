#!/usr/bin/env bats
#
# ## lib_unit.bats - in-process unit tests for src/lib/greet.sh (lane: shell)
#
# build_greeting is the repo's one pure helper, so it is tested as a unit: the
# library is sourced into the test file and called directly, with no subprocess,
# which is what "pure" has to buy you or the word means nothing. Together with
# tests/shell/main.bats (subprocess behaviour) this is the pair the shell lane
# holds every new helper to: one file for the function's own logic, one for the
# CLI's argv and exit codes.
#
# Usage: bats tests/shell/lib_unit.bats        (or: tests/run.sh --lane shell)
# Safety: sources one file; touches nothing.

bats_require_minimum_version 1.5.0

# shellcheck source=/dev/null
load '../../src/lib/greet.sh'

@test "build_greeting renders word, name and bang" {
  run build_greeting "Hello" "Ada"
  [ "$status" -eq 0 ]
  [ "$output" = "Hello, Ada!" ]
}

@test "build_greeting trims both arguments" {
  run build_greeting "  Yo  " "  Grace Hopper  "
  [ "$status" -eq 0 ]
  [ "$output" = "Yo, Grace Hopper!" ]
}

@test "build_greeting falls back to Hello for a blank word" {
  run build_greeting "" "Ada"
  [ "$status" -eq 0 ]
  [ "$output" = "Hello, Ada!" ]
}

@test "build_greeting keeps a name with inner space intact" {
  run build_greeting "Hi" "Alan Turing"
  [ "$status" -eq 0 ]
  [ "$output" = "Hi, Alan Turing!" ]
}

@test "trim removes leading and trailing whitespace only" {
  run trim "  a b  "
  [ "$status" -eq 0 ]
  [ "$output" = "a b" ]
}

@test "trim of an unset argument prints nothing instead of failing" {
  run trim
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}
