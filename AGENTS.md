# AGENTS.md -- **PROJECT_NAME**

The contract for anyone (human or agent) editing this repository. It is the only
agent-instruction file here: no CLAUDE.md, no .cursor/, no .mdc, no windsurf config.
If another tool wants its own dialect, generate it from this file, do not fork it.

## Read before you edit

- [README.md](README.md) -- what the project is and how to run it.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) -- components, data flow, cross-cutting rules.
- [docs/project-conventions.md](docs/project-conventions.md) -- shell dialect, naming, size limits, the no-silent-skip rule.
- [src/README.md](src/README.md) -- where code goes and which test must accompany it.
- [docs/adr/](docs/adr/) -- settled decisions. Do not contradict one without a superseding ADR.
- `git log --oneline -15` and the files you are about to touch, in full. An edit made
  without reading the file is a guess.

## Working rules

- Small, focused patches. One logical change per commit, one logical change per branch.
- No drive-by refactors, no drive-by reformats, no renames, no touching a neighbour's
  line because you would have written it differently. A formatter's diff that buries
  your change is a review blocker.
- Match the patterns already in the file you are editing: quoting, naming, log
  vocabulary, error shape. Consistency beats taste.
- No new dependency without asking. A dependency is a maintenance promise, not an
  import. If it is a toolchain version, it belongs in `tool-versions.env`, and every
  key there needs a consumer.
- Prefer patch over rewrite. Delete dead code you _caused_; leave dead code you found
  for its own commit.
- Never disable a check to make a target pass. Fix the finding, or explain in the PR
  why the check is wrong and change the check.

## Definition of done

Done is a claim with a quote attached. "It should work" is not a status.

1. The relevant tests actually ran. Quote the **exact command and its result** in your
   report and in the PR body, including the closing `summary: N ok, W warnings, F failed`
   line. `0 warnings` is part of the claim.
2. `make lint` is clean for every lane present.
3. Docs that describe what you changed were changed in the same PR.
4. New behavior has a test that would have failed without it -- and you showed that run.
5. Nothing silently skipped: no new `command not found` path, no bare `|| true`.
6. `make doctor` is green, so the pin you tested against is the pin CI uses.

## Which check do I run first

Cost-tiered. Start at the top; only descend when the tier above cannot answer your
question. Running the whole suite after a one-line doc edit is not thorough, it is slow.

| Tier | Check                                    | Command                                                                                                                         | Approx. cost | Proves                                                 |
| ---- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------------------------------------------------------ |
| 1    | Shell syntax + style of what you touched | `make lint` (shell part)                                                                                                        | ~2 s         | shellcheck + shfmt clean                               |
| 1    | Fast lane check, plan included           | `make test-fast`                                                                                                                | ~2-5 s       | the shell lane still passes; every runner exists       |
| 2    | Full lint, every lane                    | `make lint`                                                                                                                     | ~10-30 s     | ruff/mypy/eslint/tsc/golangci-lint clean where present |
| 2    | Every lane's tests                       | `make test`                                                                                                                     | ~15-60 s     | behavior, all lanes, no silent skip                    |
| 3    | Coverage                                 | `make coverage`                                                                                                                 | ~1-2 min     | the new lines are executed by something                |
| 3    | Strict docs build                        | `make docs`                                                                                                                     | ~10 s        | links resolve, formatting and ADR numbering hold       |
| 4    | The whole local gate                     | `make validate`                                                                                                                 | ~2-4 min     | what CI runs on your PR                                |
| 4    | Everything, hermetic                     | `make test-all`                                                                                                                 | ~3-6 min     | lint + all lanes + coverage + docs                     |
| 4    | Container, in a clean image              | `docker build -f Dockerfile.test --build-arg TEST_MODE=all -t __PROJECT_SLUG__:test . && docker run --rm __PROJECT_SLUG__:test` | ~5-10 min    | it works with nothing preinstalled                     |

One file changed: tier 1. A function others call: tier 2. A public symbol, a shared
helper, a config key, or anything a cross-layer invariant touches: tier 3-4.

## Tests

- **The same-commit rule.** Every change to a production path lands with the test file
  that covers it, in the same commit. The mapping is positional -- see the table in
  [src/README.md](src/README.md). A commit with `src/` and no `tests/` change needs a
  one-line reason in its message, and a reviewer is entitled to ask for one.
- **TDD, both runs shown.** For a bug fix or new behavior: write the failing test, run
  it, paste the **red** output; implement, run again, paste the **green** output. Two
  runs, both quoted, in the PR body. A test you never saw fail is a test you do not
  trust -- it may be asserting nothing.
- One assertion per behavior. Name the test after the behavior, not the function.
- No network, no wall clock, no sleeps, no ordering dependence in tiers 1-2.
- Run one test, not the suite, while iterating:
  `bats -f '<test name>' tests/<file>.bats`, `python3 -m pytest tests/test_<m>.py -k <name>`,
  `npm test -- <file>`, `go test ./src/<pkg> -run TestName`.
- A missing runner is an error with an install hint. Never edit a test to make it
  skip because a tool is absent -- fix the toolchain (`make doctor` names the pin).

## Documentation maintenance

Docs ship. If you change behavior, you change the sentence that describes it, in the
same PR, or the PR is incomplete:

- behavior, flags, config keys -> `README.md` and/or the file header
- a component, a boundary, a data path -> `docs/ARCHITECTURE.md`
- a convention or a naming rule -> `docs/project-conventions.md`
- a contestable, hard-to-reverse choice -> a new numbered `docs/adr/NNNN-*.md`
- a new Makefile target -> its `## name - description` line, or it is invisible to `make help`

`make docs` enforces formatting, link resolution, and ADR numbering, and CI runs it.

## Secret hygiene

- Never commit a credential, token, key, cookie, or `.env` value. Not in code, not in
  a test fixture, not in a comment, not in a commit message, not in a PR body.
- Every env file gets an `.example` twin with placeholder values only: `.env.example`
  next to `.env`. `.env` stays gitignored; `.env.example` is what ships.
- Real values arrive from the environment or a secret store, never from a default in
  code, and never get echoed into a log line.
- Rotate anything that reached a commit even briefly; deletion from the tip does not
  remove it from history.
- `make hooks` installs the gitleaks pre-commit hook. If a scan trips on a fixture,
  the fixture is wrong -- do not add an allowlist entry to make it quiet.

## Branching and commits

- Short-lived branch from the tip of `main`: `feat/`, `fix/`, `refactor/`, `docs/`,
  `test/`, `chore/`, `ci/`. One logical change per branch. PR into `main`.
- Commit messages: conventional prefix, imperative summary of 72 characters or less,
  blank line, then bullets -- one fact each, blank line between bullets.
- Each commit is one coherent change and must build on its own. Do not squash three
  unrelated things into one commit because the branch is already dirty.
- Never force-push a shared branch, never rewrite pushed history, never merge your own
  PR without review.
- Say what you ran in the PR body, with the command and the result.

## Cross-layer invariants

The changes that break this repo are the ones that span layers. If an invariant below
applies to your diff, every row it touches must be updated in the same PR, and the
test must cover the seam, not just one side of it.

| Invariant       | Change here -> update there                                                                                    | Enforced by                                                                            | Example                                                                                                  |
| --------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Toolchain pins  | `tool-versions.env` key -> `.devcontainer/Dockerfile` install line and `.github/workflows/ci.yml` install step | `make doctor` (a key with no consumer, or a tool answering a different version, fails) | bump `BATS_VERSION` -> the devcontainer clone tag and the CI setup step move with it, in the same commit |
| Test dispatch   | a new language lane -> its manifest, its runner branch in `tests/run.sh`, and its row in `src/README.md`       | `make test` errors on a selected lane whose runner is missing                          | adding the python lane -> `pytest.ini` + `tests/test_*.py` + the mapping row, together                   |
| Command surface | a new check -> a `## name - description` Makefile target and the cost table above                              | `make help` output; CI runs the target                                                 | a new markdown gate -> `make docs` grows the check, the table names its cost                             |
| _your row_      |                                                                                                                |                                                                                        | copy this row, fill it in, delete the blank one when you have three of your own                          |

Add a row the first time a change breaks somewhere you did not expect. That is what
this table is for.

## End-of-session reflection (mandatory)

Close every session with this block, filled in, in your final message. No omissions,
no "everything looks good".

```text
Reflection
- Changed: <files, one clause each, what and why>
- Verified: <exact command -> result, e.g. `make test` -> summary: 3 ok, 0 warnings, 0 failed>
- Not verified: <what you did not run and why it is probably fine; name the tier you skipped>
- Left undone: <the next concrete step, with the file it starts in>
- Follow-ups: <tests to add, docs to fix, ADR to write; or "none">
```

If "Not verified" is empty, you probably ran less than you think.
