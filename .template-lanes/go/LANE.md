# Lane: go

A two-package module - a command in `src/` and one exported helper package - with the
full Go gate behind one script: gofmt, vet, golangci-lint, `go test`, and a coverage
floor. There is no build step and no runtime dependency, so the lane is green or red on
style, vet, and behaviour alone.

## What it installs into your repo

| Path                           | Role                                                              |
| ------------------------------ | ----------------------------------------------------------------- |
| `go.mod`                       | `module github.com/__PROJECT_OWNER__/__PROJECT_SLUG__`, `go 1.27` |
| `src/main.go`                  | `package main`: `usage`, `resolveWord`, `cmdGreet`, `run`, `main` |
| `src/main_test.go`             | table-driven tests over `run` and `resolveWord`, both exit codes  |
| `internal/greet/greet.go`      | exported `Greeting(word, name)` - the helper the command calls    |
| `internal/greet/greet_test.go` | one case per branch, including the empty-name default             |
| `.golangci.yml`                | golangci-lint **v2** schema: `version: "2"` at the root           |
| `scripts/test-go.sh`           | gofmt, vet, golangci-lint, `go test`, coverage floor              |
| `.github/workflows/go.yml`     | the CI job (adds a workflow; does not replace `ci.yml`)           |

Nothing in this lane replaces a core template file.

`internal/` is the Go-idiomatic home for code the module owns but does not publish: the
compiler refuses an import from outside the module, so a helper landing in `pkg/`
becomes a public promise you did not agree to make.

## Pins

`tool-versions.env` at the repo root: `GO_VERSION` and `GOLANGCI_LINT_VERSION`. A
missing key fails the CI job at the pin step and names the key, because both install
steps read them with a `${KEY:?}` guard.

The lint config also carries `run.go: "1.27"`. It is a second copy of the language
version on purpose: golangci-lint parses with its own embedded toolchain list, and a
`go.mod` that outpaces it produces a parse error rather than a lint failure.

## Makefile targets it powers

`make fmt` (`go fmt ./...`), `make lint`, `make test`, and `make coverage`
(`go test -coverprofile=coverage.out ./...` plus `go tool cover -func`). Each of those
branches is guarded by `[ -f go.mod ]`, which is what this lane creates. The lane adds
no target of its own.

## Runner command

The dispatcher entry is:

```bash
tests/run.sh --lane go
```

which resolves to `go test ./...`. The wider local gate, and what CI runs, is:

```bash
scripts/test-go.sh              # gofmt + vet + golangci-lint + tests + coverage
scripts/test-go.sh --no-cov     # same, without the coverage floor
scripts/test-go.sh --lint-only  # gofmt + vet + golangci-lint, no test run
```

The coverage floor is `COVERAGE_FLOOR` at the top of `scripts/test-go.sh` - 90 today.
Go has no config file that can hold a threshold, so that constant is its only home, and
it is compared by awk because the figure `go tool cover` prints is a float.

## CI job

`.github/workflows/go.yml`, job `go`, `ubuntu-24.04`, `permissions: contents: read`,
per-job `concurrency` with `cancel-in-progress: true`. It loads the pins, sets up Go at
`$GO_VERSION` with the module cache keyed on `go.mod`, installs golangci-lint at
`$GOLANGCI_LINT_VERSION` from its release archive, asserts both binaries report the
pinned version, then runs `scripts/test-go.sh`.

## Edit first

1. `internal/greet/greet.go` - the behaviour lives here, not in the command. A new
   branch needs a case in `greet_test.go` or the floor moves against you.
2. `src/main.go` - `run` takes `stdout`, `stderr` and `getenv` as parameters instead of
   touching the process. Keep it that way: that is what lets the tests assert on
   diagnostics without spawning a subprocess.
3. `.golangci.yml` - `default: standard` plus an explicit `enable` list. A new linter
   belongs in that list with a one-line reason comment, and `nolintlint` will refuse a
   `//nolint` that arrives without an explanation.

## Rules this lane holds

- Diagnostics go to `stderr`, results to `stdout`, and `run` returns an exit code rather
  than calling `os.Exit`, so the tests can call it directly.
- One `go test` invocation per gate. With coverage on, that single run carries
  `-coverprofile`; there is no second pass that could disagree with the first.
- A missing `go` or `golangci-lint` is a hard failure that prints the pinned install
  line. A lane that "passed" because the linter was absent is a false green.
- No `//nolint` without the reason it needs.
