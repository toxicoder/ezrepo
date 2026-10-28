# Architecture

Status: skeleton. Every section is real and every `TODO(owner)` is a hole you are
expected to fill in the PR that creates the need for it. An empty section is a lie by
omission; a `TODO(owner)` is an honest gap.

**Update this file in the same PR that changes behavior.** Not after. A pull request
that moves a component, adds a service, changes a wire format, or renames a public
module without touching this file is incomplete, and the reviewer should send it back
before reading the diff.

## Context

**PROJECT_DESCRIPTION**

Who consumes it, and what happens if it is wrong:

- TODO(owner): primary user and their job to be done
- TODO(owner): what a failure costs them

## Constraints

Hard limits a design must live inside. Each one needs a source; a constraint without
one is a preference, and preferences get argued about.

| Constraint                                    | Why                                                                        | Source                            |
| --------------------------------------------- | -------------------------------------------------------------------------- | --------------------------------- |
| Runs in a 2 cpu / 4gb container               | The devcontainer `hostRequirements` is the dev and CI floor                | `.devcontainer/devcontainer.json` |
| No version pinned outside `tool-versions.env` | Two copies of a version drift, and the second copy is the one nobody reads | `tool-versions.env`               |
| No silent skip in any check                   | A green run that ran nothing is worse than a red one                       | `AGENTS.md`                       |
| TODO(owner)                                   |                                                                            |                                   |

## System overview

Replace this with the real topology. Keep it under 20 nodes; if the diagram needs a
legend, split it.

```mermaid
flowchart LR
  user[User / caller] --> cli[CLI entry point<br/>src/bin/__PROJECT_SLUG__]
  cli --> core[Core logic<br/>TODO(owner)]
  core --> store[(Persistence<br/>TODO(owner))]
  core --> ext[External service<br/>TODO(owner)]
  ci[CI: make lint / test / docs] -.-> cli
```

## Components

One row per component you can break without breaking the rest.

| Component       | Path           | Responsibility                                  | Test file               | Owner       |
| --------------- | -------------- | ----------------------------------------------- | ----------------------- | ----------- |
| Entry point     | `src/main.sh`  | parse argv, wire config, exit codes             | `tests/shell/main.bats` | TODO(owner) |
| Test dispatcher | `tests/run.sh` | find lanes, run runners, fail on a missing tool | lane tests              | template    |
| Make surface    | `Makefile`     | the only command entry point                    | CI runs every target    | template    |
| TODO(owner)     |                |                                                 |                         |             |

Every row's `Test file` cell must be a file that exists. A component with no test
file is either untested (say so) or misdescribed.

## Data flow

Trace one real request end to end, including where it can fail.

1. TODO(owner): input enters at ...
2. TODO(owner): validation rejects ... with error ... (name the message; the test
   asserts on it)
3. TODO(owner): transformation ...
4. TODO(owner): output leaves as ...

## Cross-cutting concerns

- **Logging.** Human-readable lines to stdout, problems to stderr. Machine output
  only behind an explicit `--json` flag, and then stdout carries only that. No
  timestamps unless something downstream sorts on them.
- **Errors.** Fail fast, fail with a message that names the file, key, or command
  and says what to do next. Exit `0` only when the work actually happened. Never
  exit `0` after printing that a tool was missing.
- **Configuration.** Precedence is documented once, here: defaults in code, then
  `.env`, then environment, then flags. Every key in `.env` has an `.example` twin;
  every key is read in exactly one place.
- **Secrets.** Never in git, never in a log line, never in an error message, never
  in a test fixture. They arrive from the environment or a secret store. Every env
  file that holds one ships a placeholder-only `.example` beside it.
- **Concurrency / retries / timeouts.** TODO(owner): state the bound and the unit.
  An unbounded retry is an outage with extra steps.

## Decisions

Settled designs live in [adr/](adr/). When you contradict one, write a new ADR that
supersedes it; do not quietly edit the old one.
