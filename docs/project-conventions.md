# Project conventions

The rules an agent (or a human) must obey before a diff is mergeable. Where this
file and a language's own convention disagree, this file wins for anything it
covers, and the gap gets written down rather than silently patched.

**What this enables**: writing a change that passes `make lint` and `make test` the
first time, and reviewing one without arguing about style.

## Shell

The dialect is bash. Every `.sh` file starts with exactly this:

```bash
#!/usr/bin/env bash
# shellcheck shell=bash
#
# ## filename.sh -- what it does and whether it is an entry point or a library
```

Then, for an entry point (a script that is run, not sourced):

```bash
set -euo pipefail
```

- `set -e`, `set -u`, `set -o pipefail`. Always all three. A sourced library
  deliberately omits them and inherits the caller's options.
- Quote every expansion: `"${var}"`. Unquoted is correct only where word splitting
  and globbing are the point, and that needs a comment saying so.
- `[[ ]]` for conditionals, `[ ]` only where POSIX portability is required (remote
  probes and other code that has to run under a plain `sh`).
- `$(...)` for command substitution. Backticks are banned.
- **`eval` is banned.** No exceptions, including for indirect lookups; use bash
  indirect expansion (`${!name}`) or an explicit allowlist.
- `local` for every function variable; a function that touches a global says so in
  its doc block.
- Arrays for lists, never a space-separated string you later split.
- Every function carries the doc block above its definition:

  ```bash
  # @function name
  # One sentence that says what it does.
  # Globals:
  #   NAME, or None
  # Arguments:
  #   $1 - meaning
  # Outputs:
  #   What is printed, and where
  # Returns:
  #   0, a status, or the exit code
  ```

- `shellcheck -x --severity=warning` must be clean, with no inline `disable=`
  unless the line explains the false positive.
- `shfmt -i 2 -ci` is the formatter and its output is the standard: 2-space indent,
  switch cases indented. `make fmt` writes it, `make lint` checks it.

## The no-silent-skip rule

The one anti-pattern this project exists to kill:

```bash
# BANNED: prints a friendly line, exits 0, CI is green, nothing was checked.
if ! command -v shellcheck >/dev/null; then
  echo "shellcheck not found ... Skipping"
  return 0
fi
```

- A missing tool is an **error**, with the install hint and the pin name. `tests/run.sh`
  and every Makefile target follow this; the `NEED` macro in the Makefile is the
  reusable form.
- A skipped check must be visible and counted. `warning:` lines feed the closing
  `summary: N ok, W warnings, F failed` line, so a run that quietly did nothing is
  distinguishable from one that checked something.
- Never `|| true` on a check whose failure you have not read. `|| true` needs a
  comment naming the failure you are choosing to ignore.
- Never claim a pass for something you did not run. `tests/run.sh --dry-run` prints
  `planned, not executed` rather than `ok: passed`.

## Naming

- Files: `kebab-case` for docs and configs, `snake_case` for python, the language's
  own convention otherwise. No spaces, no `final2`, no `copy`, no `.old`.
- Functions: `verb_noun` or `verb-noun`, matching the surrounding file.
- Variables: `UPPER_SNAKE` for globals and env, `lower_snake` for locals.
- Branches: `feat/`, `fix/`, `refactor/`, `docs/`, `test/`, `chore/`, `ci/`.
- Tests read as assertions: `test_config_missing_key_errors`, not `test_config2`.
- One meaning per name inside a scope. Do not shadow a tool name with a function
  name (`test`, `lint`, `docs` are Makefile targets, so do not name a script that).

## Size limits

A file you have to scroll for ten minutes is a file with two responsibilities.

| Unit                   | Soft limit | Reach for a split at  |
| ---------------------- | ---------- | --------------------- |
| Shell / source file    | 300 lines  | 500 lines             |
| Function               | 40 lines   | 60 lines              |
| Test file              | 200 lines  | 300 lines             |
| Makefile target recipe | 40 lines   | move it into a script |

Exceeding a hard limit is allowed when the split would be worse (a generated file, a
state machine table) and the file says why in its header.

## Errors and exit codes

- `0` means the work happened. Anything else means it did not.
- `1` for a generic failure; reserve distinct codes for conditions a caller can
  branch on, and list them in the file header.
- Error text goes to stderr and names the thing that failed: the file, the key, the
  command, the pin. "Something went wrong" is a bug report, not an error message.
- Every failure path prints what to do next, when there is something to do.
- Do not swallow a subprocess exit code; propagate it or handle it explicitly.

## Logging

- Prose to stdout, problems to stderr. Never both for the same line.
- Prefix vocabulary, used consistently by the entry points here:
  `== section ==`, `-> phase`, `ok:`, `warning:`, `note:`, `error:`, and a closing
  `summary: N ok, W warnings, F failed`.
- No timestamp, level, or color baked into a line that a human reads once.
- Machine-readable output only behind an explicit flag, and then stdout carries only
  that output.
- Never log a secret, a token, a `.env` value, or a whole request body.

## Comments

- Comments state the constraint that is not obvious: why this order, why this
  timeout, why this weird quoting, which upstream bug the workaround is for.
- Do not restate the code. `# increment the counter` above `count=$((count + 1))` is
  noise that has to be maintained.
- No commented-out code and no placeholder TODOs for work you are not doing in this
  commit. A `TODO(owner)` marks a deliberate hole in a skeleton, with a name or a
  file next to it.
- Match the surrounding file's density and tone. Do not narrate your implementation
  choices in a comment as if the reviewer cannot read the diff.

## Tests

- Tests land in the same commit as the code they cover. See [../src/README.md](../src/README.md).
- A test asserts; it does not merely execute. A test that cannot fail is deleted.
- No network, no clock, no ordering dependence in the fast tier.
- Give the run a reason to be trusted: for a bug fix, show the test failing before
  the fix and passing after it.
