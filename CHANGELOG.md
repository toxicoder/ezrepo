# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Reading this file

- **`[Unreleased]`** is where every merged change lands first. It is the list of
  what a user gets if they run `main` today instead of the latest tag. Add to it in
  your pull request, under the right subsection; a PR that changes behaviour
  without an entry is incomplete.
- Versions are **`[X.Y.Z]`** and are dated `YYYY-MM-DD` at release time. The tag is
  cut from `main` and the release is built from that tag by
  [`.github/workflows/release.yml`](.github/workflows/release.yml), which lifts the
  matching section of this file into the release notes.
- The order is newest first. Never edit a released section after the fact; a
  correction is a new entry that says what was wrong.
- Dates are ISO 8601 (`YYYY-MM-DD`) so they sort and cannot be misread between
  locales.

### The four subsections, and which one your change belongs in

| Section      | Use it for                                                                                   | SemVer signal                                           |
| ------------ | -------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `Added`      | New functionality, a new command, flag, config key, or public symbol.                        | Minor (or Major if it breaks something)                 |
| `Changed`    | A change in how existing behaviour works, or a changed default.                              | Major if user-visible and incompatible, otherwise Minor |
| `Deprecated` | Functionality that still works but is scheduled to be removed. Say which version removes it. | Minor                                                   |
| `Removed`    | Something previously deprecated that is now gone.                                            | Major                                                   |

Fixes go in `Fixed`, not `Changed`. Documentation-only, test-only, and CI-only
changes do not need an entry unless they change what a user can rely on - a typo in
a README is not a release. `Security` is a fifth subsection you may add for a
vulnerability fix; name the affected range and the fixed version, and keep the
exploit details in the advisory rather than here.

### Deprecations

A deprecated feature works and warns for at least one minor release before it is
removed, and the `Deprecated` entry names the version that removes it. Removal
happens in a major release and moves the text from `Deprecated` to `Removed`.

## [Unreleased]

### Added

- Language-neutral scaffold: governance files, CI workflows, pre-commit hooks, and
  issue/PR templates.

### Changed

- Nothing yet.

### Fixed

- Nothing yet.

### Removed

- Nothing yet.

<!--
Release entries are cut from [Unreleased]. When you tag a release:
  1. Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`, keeping its subsections.
  2. Add a fresh empty `## [Unreleased]` block above it with all four subsections.
  3. Drop "Nothing yet." placeholders out of the released section.
Then commit, tag `vX.Y.Z`, and push the tag; release.yml publishes from it.
-->

## [1.0.0] - 2026-01-15

First public release. This entry is kept as the format example: it shows the
subsection order, the one-fact-per-bullet style, and how a breaking change is
labelled so a reader can tell at a glance whether upgrading costs them anything.

### Added

- Command-line interface with `run`, `validate`, and `version` subcommands.
- Configuration via `__PROJECT_NAME__` keys in `.env`, documented in
  `.env.example`, with every key required at startup rather than defaulting
  silently.
- `make lint`, `make test`, and `make validate` as the single gate surface for both
  contributors and CI.
- GitHub Actions workflows for CI, release, and security scanning, with every
  third-party action pinned to a major tag.
- Conformance test suite covering the documented behaviour, run in CI on every pull
  request.

### Changed

- **Breaking:** configuration moved from positional arguments to flags, so
  `tool name --flag` becomes `tool --name <name> --flag`. Pass `--help` for the new
  form; the old positional form now exits non-zero with a message naming the
  migration instead of guessing what you meant.
- Default log level raised from `debug` to `info`, because `debug` was writing
  request payloads to stdout in production deployments.

### Deprecated

- `--legacy-format`. Still accepted, emits a one-line warning naming the release
  that removes it. Use `--format` instead.

### Fixed

- Empty input produced exit code 0 with no output; it now exits non-zero with a
  message, because a check that silently succeeds is indistinguishable from a check
  that passed.
- Trailing whitespace in config values was significant, so a file edited on
  Windows failed to match. Values are now trimmed at parse time.

### Removed

- Nothing removed in this release.

[Unreleased]: https://github.com/__PROJECT_OWNER__/__PROJECT_NAME__/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/__PROJECT_OWNER__/__PROJECT_NAME__/releases/tag/v1.0.0
