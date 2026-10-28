# Lane: typescript

One module, one test file, and a toolchain declared entirely in `package.json`. The
lane is strict by default: `tsc --strict`, eslint with zero warnings allowed, and
coverage thresholds at 100. Its distinguishing feature is not the sample code, it is
the pin discipline - two files name the same tools, and `scripts/check-pins.sh` is
what keeps them telling the same story.

## What it installs into your repo

| Path                               | Role                                                                                              |
| ---------------------------------- | ------------------------------------------------------------------------------------------------- |
| `package.json`                     | the only file npm reads for versions: exact versions, no ranges, seven scripts                    |
| `tsconfig.json`                    | `strict` plus every flag it implies spelled out, `noUncheckedIndexedAccess`, the `@/*` alias      |
| `vitest.config.ts`                 | jsdom environment, `tests/**/*.test.ts` include, the four 100 thresholds                          |
| `eslint.config.mjs`                | flat config: js + typescript-eslint recommended, `no-explicit-any` as an error                    |
| `src/index.ts`                     | `buildGreeting()`, `resolveWord()`, `greet()`, `usageText()`, `main(argv)` returning an exit code |
| `tests/ts/index.test.ts`           | 27 `it()` blocks, 44 assertions: rendering, every argv mistake, every switch label                |
| `scripts/check-pins.sh`            | the drift guard: `package.json` vs `tool-versions.env`, exact versions only                       |
| `scripts/test-typescript.sh`       | pins, install, lint, typecheck, coverage - each behind a presence guard                           |
| `.github/workflows/typescript.yml` | the CI job (adds a workflow; does not replace `ci.yml`)                                           |

Nothing in this lane replaces a core template file.

## Layout, and the one pairing that has to stay in step

`src/index.ts` holds the code and `tests/ts/index.test.ts` holds its tests. Tests
import from `@/index`, and that resolves twice: through the `paths` entry
`"@/*": ["./src/*"]` in `tsconfig.json`, and through `resolve.alias` in
`vitest.config.ts`. They are twins. If only one is edited, `npm run typecheck` and
`npm run test` disagree about what `@/index` means, and neither failure names the
file that drifted - so edit both in one commit, or use a relative import.

## Pins

`tool-versions.env` at the repo root holds `NODE_VERSION`, `TYPESCRIPT_VERSION`,
`ESLINT_VERSION`, `VITEST_VERSION`, and the repo-wide `PRETTIER_VERSION`. A missing
key fails the CI job at the guard step, naming the key.

`package.json` repeats four of those versions, because npm cannot read that file, and
adds seven more for the packages only npm installs (`@eslint/js`, `@types/node`,
`@vitest/coverage-v8`, `globals`, `jsdom`, `typedoc`, `typescript-eslint`). That
second copy is the drift risk, so `scripts/check-pins.sh` parses both files with a
JSON parser and fails the build when `prettier`, `typescript`, `eslint` or `vitest`
disagree, or when any `devDependencies` entry is a range rather than an exact version.
Run it directly with `scripts/check-pins.sh`; it is also the first stage of
`scripts/test-typescript.sh`, and it exits 0 with an `ok:` line in a checkout that has
no `package.json`, so the other lanes can call it unconditionally.

`TYPESCRIPT_VERSION` is deliberately below the npm `latest` tag. `typescript-eslint`
declares `typescript >=4.8.4 <6.1.0` and `typedoc`'s peer list ends at 6.0.x, so
following `latest` makes `npm ci` fail on peer resolution. 6.0.3 is the newest release
both accept. Raise it only when both peers widen, and change `package.json` in the
same commit or the guard stops the build.

## Makefile targets it powers

`make lint` (eslint and `tsc --noEmit`), `make fmt` (prettier), and `make test` (via
the core dispatcher). The lane adds no target of its own. Note that `make lint` runs
the globally installed `eslint` and `tsc` that `make doctor` probes, while
`scripts/test-typescript.sh` runs the copies in `node_modules/.bin` - the install step
is what makes that second set exist, and its guard is what makes their absence a
failure rather than a pass. `make coverage` measures only a lane whose `package.json`
declares a script literally named `coverage`; this lane's gate is `test:coverage`, so
the enforced number is the one `scripts/test-typescript.sh` runs.

## Runner command

The dispatcher entry is:

```bash
tests/run.sh --lane typescript
```

which detects the lane by `package.json` and resolves to `npm test`. The wider local
gate, and what CI runs, is:

```bash
scripts/test-typescript.sh           # pins + install + lint + typecheck + coverage
scripts/test-typescript.sh --no-cov  # same, without the coverage thresholds
scripts/check-pins.sh                # just the pin comparison
```

The thresholds live in `vitest.config.ts`, so `--no-cov` drops the gate rather than
lowering a number in the shell.

## Coverage

`vitest.config.ts` sets `lines`, `functions`, `branches` and `statements` all to 100,
on the v8 provider, with `include: ["src/**/*.ts"]` named explicitly so a file nobody
imports still counts as 0 percent instead of quietly never entering the denominator.
The one excluded region is the module entry guard at the bottom of `src/index.ts`,
boxed in by `/* v8 ignore */` markers: it is the only side effect in the file and it
cannot fire under a test runner. A new branch with no test is a red build, and the fix
is the test, not the exclude list.

## CI job

`.github/workflows/typescript.yml`, job `typescript`, `ubuntu-24.04`, `permissions:
contents: read`, per-job `concurrency` with `cancel-in-progress: true`. It loads the
pins with `grep -E '^[A-Z0-9_]+=' tool-versions.env >>"$GITHUB_ENV"`, fails if a key
this lane needs is unset, sets up Node at `$NODE_VERSION` with the npm cache keyed on
`package-lock.json`, runs `npm ci`, guards that `tsc`, `eslint` and `vitest` are
runnable, then runs `scripts/test-typescript.sh` - the same script you run.

Because `npm ci` and the npm cache both hash the lockfile, a checkout with no
committed `package-lock.json` fails at the guard step with the command that fixes it.
`scripts/test-typescript.sh` on its own degrades to `npm install` with a `warning:`
line, which is the state where your terminal and CI can install different trees.

## Edit first

1. `src/index.ts` - add a pure renderer that returns a string, then wire it through
   `main()`. `main` takes argv and the writers it prints to and returns an exit code;
   it never calls `process.exit`, so the test drives it in-process.
2. `tests/ts/index.test.ts` - one `it()` per branch, including both sides of every
   `??` and every default parameter. The 100 thresholds are why the test file is
   longer than the source file.
3. `package.json` - a new dev tool goes in at an exact version. If it is also a tool
   `make doctor` or CI probes, add its key to `tool-versions.env` in the same commit;
   `scripts/check-pins.sh` tells you if you forget.

## Rules this lane holds

- Exit codes are returned, never raised via `process.exit`, so tests run in-process.
- Diagnostics to stderr, results to stdout.
- Thresholds live in tool config; no shell compares a coverage number with `-ge`.
- Every dependency is an exact version. A range is a pin that moves by itself.
- One version per tool in one file, read by every consumer; the second copy is
  guarded rather than trusted.
- A missing tool fails with its pinned install line. There is no code path in this
  lane that prints "skipping" and returns 0.
