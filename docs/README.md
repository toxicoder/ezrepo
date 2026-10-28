# Documentation

Docs in this repo are a **built artifact**, not decoration. They go through a gate,
they fail the build, and they are edited in the same PR as the behavior they
describe. A doc that has drifted from the code is a bug with a longer fuse.

## How to read them

| Read this                                        | When                                                                   |
| ------------------------------------------------ | ---------------------------------------------------------------------- |
| [../README.md](../README.md)                     | First. What the project is and how to run it in 30 seconds             |
| [../AGENTS.md](../AGENTS.md)                     | Before editing anything. Which check to run first, what counts as done |
| [ARCHITECTURE.md](ARCHITECTURE.md)               | Before a design change. Context, constraints, components, data flow    |
| [project-conventions.md](project-conventions.md) | Before writing shell or naming a file                                  |
| [adr/](adr/)                                     | Before reopening a settled decision. Each ADR records why              |
| [../src/README.md](../src/README.md)             | Where code goes and which test must accompany it                       |

Order matters when you are new: README, then ARCHITECTURE, then conventions. The
ADRs are a reference, not a narrative -- read one when you are about to contradict it.

## The strict build

`make docs` builds the docs and it is not permissive:

- every Markdown and YAML file must be formatter-clean (`make fmt` writes what
  `make docs` checks);
- every relative link must resolve to a file that exists;
- `docs/adr/` must contain `template.md` plus numbered ADRs with **gapless, unique**
  four-digit prefixes, starting at `0001`.

Any finding exits non-zero. `.github/workflows/ci.yml` runs `make docs` on every
pull request, so a broken link is a red check, not a nit.

```bash
make docs      # strict, what CI runs
make fmt       # rewrite docs into the canonical form
make validate  # doctor + lint + test + docs, the whole local gate
```

## Rules that keep it true

- **Docs change with behavior.** If you rename a flag, move a directory, or change
  an error message, the sentence that describes it changes in the same PR. Reviewers
  check this before they check your code.
- **One home per fact.** A version lives in `tool-versions.env`; a rule lives in
  `project-conventions.md`; a decision lives in an ADR. Everywhere else links to it.
- **Record a decision when it is contestable.** If a reasonable engineer could ask
  "why not the other way?", it earns an ADR. Copy [adr/template.md](adr/template.md);
  the worked example is [adr/0001-record-architecture-decisions.md](adr/0001-record-architecture-decisions.md).
- **Never document a secret.** An env var gets an `.example` twin with a placeholder
  value; docs name the variable, never a real credential.
