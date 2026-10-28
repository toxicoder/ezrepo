# src

Where the code lives. This directory ships nearly empty on purpose: the template
holds no language-specific application code, because every language lane brings its
own.

## Layout

```text
src/
  README.md            this file
  bin/                 the executable entry point the lane ships
  <lane source>        added by the lane overlay, never invented here
```

- The **default lane is `shell`**. A repo created with no `--lane` flag is a shell
  project: its entry point is `src/main.sh`, and its tests are
  `tests/*.bats`.
- Each lane overlay (`python`, `typescript`, `go`) adds its own source files and
  its own tests, and only its own. `src/` in this template contains no hello world,
  no example module, and no stub to delete.
- Lane layout follows that language's convention, not a template-wide one: `src/`
  plus `tests/` for python, `src/` + `dist/` for typescript, package directories
  for go. Do not flatten one language's layout onto another.

## The rule that does not bend

**A new public symbol gets a new test in the same commit.** Same commit, not the
next one, not the follow-up PR. A symbol with no test is not finished, and the
reviewer is entitled to close the diff without reading it.

The mapping is positional and boring, which is what makes it checkable:

| You changed           | The test that must land in the same commit           |
| --------------------- | ---------------------------------------------------- |
| `src/main.sh`         | `tests/shell/main.bats`                              |
| `src/<module>.py`     | `tests/test_<module>.py`                             |
| `src/<module>.ts`     | `tests/<module>.test.ts`                             |
| `src/<pkg>/<file>.go` | `src/<pkg>/<file>_test.go`                           |
| a new CLI flag        | one test for each of: set, unset, malformed          |
| an error path         | a test that forces that path and asserts the message |

If you add a directory under `src/`, add the mirror rule to the table in the same
commit. If a lane's table row is wrong for that lane, fix the row here rather than
inventing a local convention in the lane's own README.

## What goes elsewhere

- Executable one-off scripts an operator runs: `scripts/` (a lane may add it).
- Everything a test needs that is not a test: `tests/` fixtures, never `src/`.
- Documentation that describes behavior: `docs/`, edited in the same PR as the
  behavior it describes.
