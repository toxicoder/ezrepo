# ADR NNNN: <short imperative title>

- Status: Proposed | Accepted | Superseded by ADR NNNN
- Date: YYYY-MM-DD
- Deciders: who agreed, and who objected
- Appendix: <!-- OPTIONAL. Remove this line if you have no links; docs/README.md
        fails a link that does not resolve, so do not leave a dead one behind. -->

Write the title as the decision, not the topic. "Run every check in one container"
beats "Testing".

## Context

What is true today, what hurts, and what forces are in play. Facts and constraints
only, no solution language here. A reader who has never seen this repo should be able
to reach the same fork in the road you are standing at.

Name the pressure explicitly: latency, cost, team size, hardware, a dependency you
do not control, a deadline. If the context is "we wanted to", the decision is a
preference and belongs in a comment, not an ADR.

## Decision

One paragraph, active voice, ending in what will be true after this lands:

> We will <do X>, enforced by <the check that makes it stick>.

The enforcement clause is not optional. A decision nobody can violate is a policy; a
decision only some of us remember is folklore. If there is no check yet, the decision
includes writing one, and the ADR links the issue.

## Consequences

Positive:

- What gets cheaper, faster, or safer. Be concrete about the mechanism.

Negative (required -- an ADR with no costs is a sales pitch):

- What you are now paying for: added complexity, a slower path, a lock-in, a new
  operational burden, a group whose workflow got worse.
- What this makes harder to undo later.

## Alternatives considered

List the real options, each with the specific reason it lost. "We considered other
approaches" is not a list. A reader who arrives with the losing idea must be able to
see that someone already argued for it and why it still lost.

| Alternative | Why it lost |
| ----------- | ----------- |
|             |             |

## Revisit when

What evidence would reopen this. An ADR without a revisit trigger eventually becomes
a rule nobody can justify.
