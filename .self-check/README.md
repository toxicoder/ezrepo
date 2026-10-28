# `.self-check/` -- the conformance suite for this repository as a template

The lane suites under `tests/` and `.template-lanes/<lane>/` check the code a
rendered project writes. This suite checks the template itself: the things that can
only break here, and only before a render.

It answers the questions no linter can answer:

- is every render token in the tree one a generator actually substitutes, or will a
  placeholder ship as literal text in someone's new repository?
- do the lane directories on disk match the lanes the contract declares, and does
  each one ship the `LANE.md` plus `gitignore.fragment` pair the render consumes?
- does every pin in [tool-versions.env](../tool-versions.env) have a reader, and is
  each one a version rather than a moving tag?
- can any gate in the tree report green while doing nothing (`|| exit 0`,
  `continue-on-error: true`, `pull_request_target`, an unpinned action)?
- do the docs' relative links resolve, and does the test dispatcher behave on a tree
  with no lane at all?

## A rendered project does not carry this

`.self-check/` is generator-owned, like `.template-lanes/` and `.git`: a project
rendered from this template has no `.self-check/` directory and no obligation to
have one. That is why `make self-check` prints a `note:` and succeeds when the
directory is absent, and why [.github/workflows/self-check.yml](../.github/workflows/self-check.yml)
guards the run the same way. Adding a hard dependency on this suite in anything a
rendered project executes is a bug: it would make every repository built from the
template red on its first commit.

## Running it

```bash
make self-check          # the entry point, from the repository root
bash .self-check/run.sh  # the same, without make
```

The runner needs `bats` on PATH. A missing `bats` is an `error:` that quotes the
install command for `BATS_VERSION` in [tool-versions.env](../tool-versions.env),
never a skip: a check that silently skips is a bug
([docs/project-conventions.md](../docs/project-conventions.md)). Every run closes with
`summary: N ok, W warnings, F failed`, and a skipped assertion is reported as a
warning, because a skipped check is a check nobody made.

## Editing it

The suite is self-contained on purpose: plain bats plus `bash`, `grep`, `find`,
`sed`, `awk`, and `python3`. It loads no test helper and needs no build system, so a
contributor can run it in a clean clone. `fail` and `assert_eq` are defined inside
[the suite](self-check.bats) rather than imported, because bats core does not ship
them.

The declared contract (render tokens, lane ids, generator-owned paths) lives at the
top of the suite. It is the authority the generator follows, not a mirror of it: when
the two disagree, the suite is the review artifact and the generator is the bug.
