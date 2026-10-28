# ADR 0001: Record architecture decisions in docs/adr

- Status: Accepted
- Date: 2026-10-27
- Deciders: **PROJECT_LICENSE_HOLDER** and whoever reviews the PR

## Context

**PROJECT_NAME** starts as a template, which means most of its structure is a choice
someone made once and every later repo inherits without hearing the argument. Two
failures show up in repos that never wrote anything down:

1. **The silent reversal.** A new contributor "simplifies" something back to the
   obvious design, and nobody remembers that the obvious design was tried and lost.
   The cost is paid twice, by the same team, in the same quarter.
2. **The folklore gate.** Decisions live in the head of the person who made them.
   They cannot be reviewed, they cannot be challenged, and they leave the repo when
   that person does.

The project already has `docs/ARCHITECTURE.md` for what is true now. That file
describes the current state; it cannot record why an alternative was rejected, and a
file that gets edited in place loses the history of the argument.

There is also a cost side to weigh: an ADR no one writes, or a pile of 40 ADRs no one
reads, is worse than no ADRs, because it adds ceremony without adding memory.

## Decision

We will record every contestable, hard-to-reverse decision as a numbered markdown
file in `docs/adr/`, copied from [template.md](template.md), in the same PR that
implements it. Each ADR states Context, Decision, Consequences (positive **and**
negative), Alternatives considered, and a Revisit-when trigger.

Enforced by three checks:

- `make docs` fails when `docs/adr/` has no `template.md`, has no numbered ADR, or
  has a gap or a duplicate in the four-digit numbering. Gapless numbering is what
  makes "did we skip one?" answerable at a glance.
- The reviewer's checklist in [../../AGENTS.md](../../AGENTS.md) makes an ADR link a
  required part of any PR that adds a dependency, changes a wire format, changes the
  test strategy, or drops an invariant.
- Superseding is additive: a new ADR replaces an old one and sets
  `Status: Superseded by ADR NNNN` on it. Nobody edits history in place.

## Consequences

Positive:

- A newcomer can answer "why is it this way" without finding a person.
- Reopening a decision costs one file read, not one investigation.
- The negative-consequences section is mandatory, so a decision that was really a
  trade-off reads like one instead of like a victory lap.
- Numbering plus a status line makes drift visible: an `Accepted` ADR describing
  behavior that no longer exists is itself a bug you can see.

Negative:

- Extra file per meaningful change. Small fixes must not produce one, which means
  someone has to judge "is this contestable?" and that judgment is sometimes wrong.
- The numbering rule forces an ordering decision when two PRs add an ADR at once, and
  whoever rebases renumbers their file and its links.
- An ADR goes stale silently unless a reader notices. Nothing here detects a decision
  that stopped being true; only a reader can.
- Two places can now describe the same design (`ARCHITECTURE.md` and an ADR), which
  is exactly the drift the rules below are meant to prevent.

## Alternatives considered

| Alternative                                       | Why it lost                                                                                           |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Comments in `ARCHITECTURE.md` only                | Edits in place erase the argument; you keep the winner and lose the debate                            |
| Wikis, issues, or a Confluence page               | Drifts out of reach the moment the code moves; no diff, no review, no `git blame`                     |
| Architecture Decision Records as code annotations | Decisions are cross-file and cross-repo; a tool that reads them becomes a dependency nobody maintains |
| Writing no ADRs at all                            | Every reversal has to be argued from scratch, and it always is, twice                                 |

## Revisit when

- A reader says the ADR set is "just noise": then delete the requirement for a class
  of change instead of deleting the directory.
- `docs/adr/` passes 30 files: split by subsystem and index them.
- The numbering conflicts routinely enough that renumbering becomes a chore: switch
  to date-prefixed identifiers and change the `make docs` audit with it, in one PR.
