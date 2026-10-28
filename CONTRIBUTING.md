# Contributing

Thanks for taking the time. This file is the whole contract: branches, commits,
the commands that must be green, and what makes a pull request easy to merge. Most
of it exists because of a specific failure that has already happened somewhere, and
the reasoning is stated inline so the rule survives the person who added it.

If something here is unclear or wrong, that is a bug in this file - open an issue or
just fix it, it is a normal contribution.

## Before you start

- Read the README. If you cannot get the project running from it alone, file an
  issue; that is the highest-value bug report available.
- Search open and closed issues before writing code. Two people writing the same
  fix in parallel is the most common wasted effort in a small project.
- For anything larger than a typo or an obvious one-line fix, open an issue first
  and get a yes. A change that restructures something is not a small change, no
  matter how clean the diff looks, and a "no" costs you ten minutes instead of a
  weekend.
- For a security problem, do not open an issue. See [SECURITY.md](SECURITY.md).

## Get a development container up

The container is the supported development path because it is the same image CI
runs: if it is green on your machine it is green in Actions, and "works for me"
stops being an argument. You install nothing on the host.

With VS Code and the Dev Containers extension:

1. Open the folder in VS Code.
2. Command palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) -> **Dev Containers: Reopen in
   Container**.
3. Wait for the build and `postCreateCommand`. First build pulls the base image and
   installs the pinned toolchain; later ones hit the layer cache.
4. Open a terminal in the container (`Ctrl+`` `) and confirm the tools are actually
   present. This is not a formality - a missing tool used to print "Skipping" and
   report success:

   ```sh
   make validate
   ```

Alternatives, if you would rather not use VS Code:

```sh
# Build and drop into the container directly.
docker build -t __PROJECT_SLUG__-dev .
docker run --rm -it -v "$PWD":/work -w /work __PROJECT_SLUG__-dev bash

# Or run the gate inside the image without a long-lived container.
docker run --rm -v "$PWD":/work -w /work __PROJECT_SLUG__-dev make validate
```

If the container will not build, stop and open an issue with the failing step and
the last 30 lines of output. Do not work around it by installing tools ad hoc on
your host: that is how an environment that only builds for one person appears.

## The gate: `make lint`, `make test`, `make validate`

Three commands, and they are the same three CI runs. Run them before you push, not
after CI tells you.

| Command         | What it does                                                                                                                                      | Roughly             |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `make lint`     | Formatting and static analysis: the pre-commit hooks over every file (shellcheck, shfmt, yamllint, prettier) plus language linters from the lane. | Seconds             |
| `make test`     | The unit and integration suites, with coverage reported.                                                                                          | Seconds to a minute |
| `make validate` | Everything above, plus config parsing, template rendering, and link checks. This is the merge gate.                                               | A minute            |

Run all three the way CI does:

```sh
make lint && make test && make validate
```

**A check that silently skips is a bug.** This is the rule that matters most here,
and it is why the hooks in `.pre-commit-config.yaml` fail loudly when their binary
is missing instead of printing a warning. If a tool is not installed:

- Install it. `make lint` prints the exact install command for the tool it could
  not find.
- Never add `|| exit 0`, `|| true`, `continue-on-error`, or a `command -v foo ||
exit 0` guard to a check to make a red run green. If you do, the review rejects
  it, and rightly so: you have not fixed the failure, you have hidden it, and the
  next person inherits a gate that lies.
- If a check is genuinely wrong for this project, delete it and say why in the
  commit message. Removing a check openly is honest; neutering it is not.

Pre-commit hooks run automatically once installed:

```sh
pre-commit install
pre-commit run --all-files   # one-off sweep, also what CI runs
```

## Branching

Trunk-based. `main` is the only long-lived branch: it stays green, it is what
releases are cut from, and it is deployable at every commit. There is no `dev`,
`staging`, or `release` branch to merge forward through, which means no drift and no
cherry-pick ladder after a hotfix.

| Prefix      | Use for                                                                  | Release impact  |
| ----------- | ------------------------------------------------------------------------ | --------------- |
| `feat/`     | New user-visible functionality, or a `Deprecated` entry.                 | Minor version   |
| `fix/`      | A defect that exists on `main` today.                                    | Patch version   |
| `refactor/` | Behaviour-preserving restructuring. No functional change.                | None on its own |
| `docs/`     | README, comments, this file, diagrams.                                   | None            |
| `test/`     | Tests only - new coverage, a flake fix, a harness change.                | None            |
| `chore/`    | Dependency bumps, toolchain pins, housekeeping with no behaviour change. | None            |
| `ci/`       | Workflow and pipeline changes.                                           | None            |
| `hotfix/`   | Urgent `main` defect, expedited review. Still a PR; never a direct push. | Patch version   |

Rules:

- Branch from the current tip of `main` (`git switch -c feat/short-kebab-name main`,
  after a fetch), one logical change per branch.
- Name it for the change, not the author or the ticket filler: `fix/empty-input-exit-0`
  over `fix/bug-1234-2`.
- Delete the branch the moment it merges. Stale branches are how a forgotten
  half-finished idea becomes someone else's confusion.
- Long-lived feature branches are discouraged. If work must span days, put it
  behind a flag and merge it to `main` incomplete but inert, rather than letting a
  branch drift until the merge is unreviewable.
- Rebase or merge `main` in before requesting review, so CI runs against a tree that
  is close to what will actually merge.
- Never push directly to `main`, and never force-push or rewrite history on it.
  Local history on your own branch is yours to tidy.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/), always. The history is
the changelog's source and the first thing a future reader bisects through, so it is
written for them, not for you.

```
<type>: <imperative summary, 72 characters or fewer>

<optional body: one fact per bullet, each bullet its own paragraph>
```

- Types: `feat`, `fix`, `docs`, `test`, `chore`, `ci`, `refactor`. Scope in
  parentheses is allowed when it helps: `fix(ci): ...`.
- The summary is imperative and describes the change, not the act: "add retry on
  transient 429", not "adds a retry" or "updated the code".
- 72 characters, no trailing period.
- Blank line between summary and body; blank line between each bullet; one fact per
  bullet. A body of two or three bullets is normally enough.
- The body explains _why_, and anything a reader cannot re-derive from the diff:
  the constraint, the alternative rejected, the number that motivated it. Never
  narrate what the code plainly does.
- A `fix` commit names the symptom in the summary, because that is the phrase
  someone greps for. Never "fix bug".
- Do not mix a `refactor/` with a `feat/` in one commit: a reviewer cannot tell the
  behaviour change from the moved code, and `git bisect` loses its resolution.

### Worked example

The diff adds a retry around one HTTP call and one test. Bad:

```
update
```

Good:

```
fix: retry transient 429 responses instead of failing the run

- Wrap the export call in three retries with exponential backoff (1s, 2s,
  4s) and jitter, because the upstream rate limiter returns 429 for a few
  hundred milliseconds under normal morning load and the whole run used to
  abort on the first one.

- Retry only 429 and 503. A 4xx other than those is a client bug, and
  retrying it multiplies the error while hiding the cause.

- Add a regression test that serves two 429s then a 200, and asserts the
  final result plus three attempts, so a future refactor cannot quietly
  drop the retry and still pass.
```

What makes the second one good: the summary is grep-able and states the behaviour;
each bullet is one fact and gives the _why_ (the three-retries choice, why 4xx is
excluded, what the test pins); nothing restates the diff; and a reader who never
opens the files learns the constraint.

Releases are generated from these messages, so a commit message that says "update"
produces release notes that say "update".

## Pull requests

- **One logical change per PR.** If the title needs an "and" - "add CSV export and
  fix the logger init" - it is two PRs. Split them, even when the second is trivial,
  because they may be decided differently, land at different times, or need to be
  reverted independently. A revert of a mixed PR takes the working half with it.
- Size: under roughly 400 changed lines where the change allows it. Beyond that,
  stack PRs, or land the refactor first and the behaviour change second.
- Use the template. Every section, filled with specifics: the exact command and the
  real output, not "tests pass". If a section does not apply, write `N/A` and the
  reason - deleting a heading is indistinguishable from skipping it.
- Add a `CHANGELOG.md` entry under `[Unreleased]` when the change is user-visible.
- Add or update tests with the change. A fix gets a regression test that fails
  before the fix and passes after; say which in the PR so the reviewer can check.
- Update docs in the same PR: README, comments, `.env.example` if you added a
  variable. A feature nobody can discover is a feature nobody uses.
- No secrets, no `.env`, no keys, no real hostnames or tokens - see the Secrets
  Policy in [SECURITY.md](SECURITY.md). CI scans for these and the pre-commit hooks
  catch the common cases earlier.
- No new dependency for something five lines can do, and no `@latest` / `:latest` /
  unpinned version anywhere. Pin the version and, for a third-party action, the
  commit SHA.
- Keep the architecture. If your change diverges from how the project is already
  structured, that is a conversation to have in an issue first.
- Respond to every review comment or resolve it with a reason. Then merge when the
  checks are green and the code owner has approved; you merge your own PR once it
  meets those bars.

## Style, in one paragraph

Match the surrounding code rather than your preferences; the formatter is the
arbiter and `make lint` enforces `.editorconfig`, so formatting arguments should not
exist. The importable package is `src/__PROJECT_MODULE__/` and its tests mirror that
path under `tests/`; when you add a module, add its test file in the same commit,
because a module that lands without tests is a module nobody will add tests to later.
Comments explain constraints and choices, not sequence ("increment the
counter" is not a comment). Prefer the boring, explicit version; cleverness has to
be justified by a number. Fail loudly - an unexpected state raises or exits non-zero
with a message that says what to do next; it does not print a warning and carry on.
Delete dead code instead of commenting it out.

## Getting help

Open an issue using the template, or start a discussion if it is a question rather
than a defect. State what you tried and what you expected; a report that includes a
reproduction is normally answered the same day.
