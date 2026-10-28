# Lane: shell

The default lane: every render gets it, and it is the reference shape the other
three copy. Bash only, no framework, no package manager - the toolchain is three
static binaries.

## What it installs into your repo

| Path                          | Role                                                                                 |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| `src/main.sh`                 | the CLI: `greet <name>`, `--version`, `--help`, `GREETING_WORD`                      |
| `src/lib/greet.sh`            | the one pure helper (`build_greeting`, `trim`), sourced not executed                 |
| `tests/shell/main.bats`       | subprocess behaviour: output, exit codes, stdout/stderr split                        |
| `tests/shell/lib_unit.bats`   | in-process unit tests for the pure helper                                            |
| `scripts/lint-shell.sh`       | shellcheck `-x --severity=warning` + `shfmt -d -i 2 -ci` over `src/ scripts/ tests/` |
| `scripts/test-shell.sh`       | lint then bats, the full local gate                                                  |
| `.shellcheckrc`               | the repo-wide shellcheck profile (one option, one comment)                           |
| `.github/workflows/shell.yml` | the CI job (adds a workflow; does not replace `ci.yml`)                              |

Nothing in this lane replaces a core template file.

## What the tools are and where the version lives

`shellcheck`, `shfmt`, `bats-core`. Versions come from `tool-versions.env` at the
repo root - keys `SHELLCHECK_VERSION`, `SHFMT_VERSION`, `BATS_VERSION`. Change a
pin there; this lane reads it in CI and in the install hints its scripts print.

## Makefile targets it powers

`make lint` and `make test` (both dispatch through the core `Makefile` into
`tests/run.sh`), plus `make doctor` for the pin report. The lane adds no target
of its own: `scripts/lint-shell.sh` and `scripts/test-shell.sh` are the commands
those targets end up running for this lane.

## Runner command

The dispatcher entry is:

```bash
tests/run.sh --lane shell
```

which resolves to `bats <every .bats file under tests/>`. The wider local gate,
and what the CI job runs, is:

```bash
scripts/test-shell.sh            # == scripts/lint-shell.sh, then bats --timing
scripts/test-shell.sh --lint-only
```

## CI job

`.github/workflows/shell.yml`, job `shell`, on `ubuntu-24.04`, `permissions:
contents: read`, per-job `concurrency` with `cancel-in-progress: true`. It reads
the three pins out of `tool-versions.env` (a missing key fails the step), installs
shellcheck / shfmt / bats at exactly those versions, runs a guard step that fails
if any binary is still absent, then runs `scripts/lint-shell.sh` and
`scripts/test-shell.sh`.

## Edit first

1. `src/lib/greet.sh` - the rendering. It is pure, so the assertion that proves
   it is a two-line call in `tests/shell/lib_unit.bats`.
2. `src/main.sh` - `run_command()` for a new subcommand, `usage()` for its help
   text, and one `@test` per exit-code row in `tests/shell/main.bats`.
3. Keep the `# @function` block (summary, `Globals:`, `Arguments:`, `Outputs:`,
   `Returns:`) above every new function: it is the house contract, and
   `tests/shell/main.bats` is the template for the next suite.

## Rules this lane holds

- Diagnostics on stderr, results on stdout, never the reverse.
- A wrong argument exits `2`; only a ran command exits `0`.
- A missing tool fails the job with its pinned install command. There is no code
  path in this lane that prints "skipping" and returns 0.
