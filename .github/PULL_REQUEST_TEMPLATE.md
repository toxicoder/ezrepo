<!--
Delete this comment block before opening the PR.

Fill every section with specifics. "Tests pass" is not evidence; the exact
command and its actual output is. A reviewer should be able to decide without
reopening the diff, and the maintainer should not have to ask "did you run
anything". If a section genuinely does not apply, write "N/A - <reason>" rather
than deleting the heading: a deleted heading is indistinguishable from a skipped
one, which is the failure mode this whole repo is built to avoid.
-->

## Summary

One or two sentences: what this PR does and why it exists. Link the issue it
closes (`Fixes #123`) or state that there is no issue and say what prompted it.
Name the branch prefix you used (`feat/`, `fix/`, `refactor/`, `docs/`, `test/`,
`chore/`, `ci/`) matches this description - if the summary says "fix" and the
branch says `feat/`, one of them is wrong.

## What changed

File-level bullets, one per logical change, ordered so a reviewer can read the
diff in this order. Say what the file now does, not that you edited it.

- `path/to/file` - what changed there and why
- `path/to/other` - what changed there and why
- `tests/...` - which new behaviour the added tests pin

Call out anything a reviewer cannot see in the diff: a migration, a changed
default, a renamed symbol and how many call sites moved, a manual GitHub
repository setting this depends on.

## Safety / ops impact

What a person operating this needs to know before merging or deploying. Cover
each of these, or say explicitly that it does not apply:

- **Rollback:** is this revertable by merging the revert, or does it need a data
  step? Name the step.
- **Migrations / state:** does anything change on disk, in a database, or in a
  deployed config? Is it additive or destructive?
- **Config and env:** any new variable added to `.env.example` and documented
  there? Any default value that changes behaviour for an existing deployment?
- **Secrets:** does this touch credential handling? Nothing secret is committed,
  and no new secret is logged or echoed.
- **Destructive commands:** no `rm -rf`, force-push, history rewrite, or
  bulk-delete is introduced by this PR. If one is required, it is called out here
  and run by a human, not by CI.
- **Blast radius:** which environments and which users are affected the moment
  this merges to `main`.

## How tested

One bullet per check. Quote the exact command and the result it actually
produced. Paste real output, trimmed to the verdict lines; do not paraphrase a
run you did not do, and do not report a check as passing when the tool was
missing - install it and run it.

- `make lint` - `all checks passed (4 hooks, 0 failures)`
- `make test` - `142 passed in 8.11s`
- `make validate` - `summary: 6 ok, 0 warnings, 0 failed`
- Manual: `the exact steps you took, and what you observed`

If a check could not run, say so here with the reason and what you did instead.
A silently skipped check is a bug, so a missing tool is an install task, not a
skip.

## Checklist

- [ ] Tests pass for touched areas
- [ ] Docs updated
- [ ] No secrets committed
- [ ] No `@latest` or unpinned dependency added
