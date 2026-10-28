# Lane: python

A src-layout package with three small functions, a strict type gate, and a
coverage threshold that lives in the tool config. Nothing here needs a virtualenv
to be correct, and nothing here installs itself: CI installs the pinned tools and
runs them against `src/` directly.

## What it installs into your repo

| Path                                 | Role                                                                  |
| ------------------------------------ | --------------------------------------------------------------------- |
| `pyproject.toml`                     | metadata + ruff + pytest + coverage settings (the only home for each) |
| `mypy.ini`                           | `strict = True` with every member flag spelled out                    |
| `src/__PROJECT_MODULE__/__init__.py` | `__version__`, the single version string                              |
| `src/__PROJECT_MODULE__/cli.py`      | `greet()`, `build_greeting()`, `main(argv)`                           |
| `tests/python/test_cli.py`           | 21 pytest assertions: rendering, exit codes, both error paths         |
| `scripts/test-python.sh`             | ruff, mypy, pytest+coverage, each behind a presence guard             |
| `.github/workflows/python.yml`       | the CI job (adds a workflow; does not replace `ci.yml`)               |

Nothing in this lane replaces a core template file.

## Pins

`tool-versions.env` at the repo root: `RUFF_VERSION`, `MYPY_VERSION`,
`PYTEST_VERSION`, and one key this lane adds, `PYTEST_COV_VERSION` (the `--cov`
flag comes from pytest-cov, and an unpinned plugin is an unpinned gate). A missing
key fails the CI job at the pin step, naming the key.

The interpreter floor is `requires-python = ">=3.11"` in `pyproject.toml`; the CI
job runs 3.12.

## Makefile targets it powers

`make lint` and `make test` (via the core dispatcher). The lane adds no target of
its own.

## Runner command

The dispatcher entry is:

```bash
tests/run.sh --lane python
```

which resolves to `python3 -m pytest -q tests`. The wider local gate, and what CI
runs, is:

```bash
scripts/test-python.sh           # ruff check . && mypy src tests && pytest --cov
scripts/test-python.sh --no-cov  # same, without the coverage gate
```

`PYTHON_BIN=/path/to/python scripts/test-python.sh` points the whole gate at
another interpreter.

## CI job

`.github/workflows/python.yml`, job `python`, `ubuntu-24.04`, `permissions:
contents: read`, per-job `concurrency` with `cancel-in-progress: true`. Installs
`ruff==`, `mypy==`, `pytest==`, `pytest-cov==` at the pinned versions (pip cache
keyed on `tool-versions.env`), guards that each is importable, then runs
`scripts/test-python.sh`.

## Edit first

1. `src/__PROJECT_MODULE__/cli.py` - add a function with a return annotation and
   a Google-style docstring (`Args:` / `Returns:` / `Raises:`), because ruff's `D`
   and `ANN` rule sets fail the build without them.
2. `tests/python/test_cli.py` - one test per branch. The gate is
   `fail_under = 100` in `pyproject.toml`; a new branch with no test is a red
   build, and the fix is the test, not the `omit` list.
3. Reach for a rule exception in `[tool.ruff.lint.per-file-ignores]` only with a
   reason comment - the list is short on purpose.

## Rules this lane holds

- Exit codes are returned, never raised via `sys.exit`, so tests run in-process.
- Diagnostics to stderr, results to stdout.
- Thresholds live in tool config; no shell compares a coverage number with `-ge`.
- A missing tool fails with its pinned `pip install` line.
