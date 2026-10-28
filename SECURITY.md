# Security

This project takes vulnerabilities seriously, and this file is the contract for
how they are handled. It exists because a README line that says "report issues"
is not a process: without a stated intake channel, an SLA, and a supported-version
list, a reporter has no idea whether anyone will read their finding and a
maintainer has no defensible answer about scope.

If you think you have found a vulnerability, read the two sections below and
report it. You do not need permission, a proof of concept that is production
quality, or a fix. You do need to keep it private until it is patched.

## Supported Versions

Security fixes are backported only to the versions listed here. Anything outside
this table is fixed forward on `main` and shipped in the next release; that is a
support decision, not a judgment about how serious your finding is.

| Version                       | Supported   | Notes                                                               |
| ----------------------------- | ----------- | ------------------------------------------------------------------- |
| `main` (tip)                  | Yes         | Where every fix lands first. CI runs on every push to it.           |
| Latest release (`vX.Y.Z`)     | Yes         | Gets the fix as a patch release, usually within the SLA below.      |
| Previous minor (`vX.(Y-1).x`) | Best effort | Backported when the patch applies cleanly and the exposure is real. |
| Anything older                | No          | Upgrade and re-test. Report again if it still reproduces.           |

The table is a promise about effort, not a guarantee of a date. When a version
stops being supported, that is stated here in the same commit that removes it, not
discovered later by someone who filed a report.

## Reporting a vulnerability

**Do not open a public issue.** An issue is a disclosure: it publishes the
affected versions, the vulnerable code path, and often a working reproduction, all
before anything is patched. Use one of these instead.

**1. Private Security Advisory (preferred).** Open a draft advisory on GitHub and
we collaborate there, in private, with a fix branch and a CVE reservation available:

<https://github.com/__PROJECT_OWNER__/__PROJECT_NAME__/security/advisories/new>

If that link 404s, private vulnerability reporting is not yet enabled on the
repository. Fall back to (2) and say so; enabling the setting is a repository
Admin action under _Settings -> Security -> Advanced Security ->
Private vulnerability reporting_.

**2. Encrypted email.** Write to `security@__PROJECT_OWNER__.example.com`,
replacing that placeholder with the address published on the repository's Security
Policy page. Encrypt with the maintainer's public PGP key if one is published
under `.well-known/` or linked from the profile; otherwise keep the report
self-contained and free of credentials. Expect an acknowledgement inside the SLA
below, and mention if you have not received one.

**3. Direct message to a named maintainer**, only if the two above fail. Treat it
as a fallback and ask for a private channel rather than answering in the open.

### What a useful report contains

- The affected version or commit (`git rev-parse HEAD`), and whether it still
  reproduces on `main`.
- Exact steps to reproduce, with the input that triggers it. A script or a test
  case that fails is ideal; a failing test is a patch that is half done.
- The impact in plain terms: what an attacker gains, and what they must already
  have to get there.
- Anything about the environment that matters (OS, container, dependency version).
- Whether the issue is publicly known anywhere, including in a dependency's
  advisory.

### What is out of scope

Findings that need the operator to have already chosen an unsafe configuration
(disabled TLS verification, a secret committed by hand, a service bound to a
public interface against the documented default) are configuration problems:
still worth telling us, but they are triaged as documentation and hardening work,
not as vulnerabilities. Scanners reporting on dependencies you added yourself, or
on a version older than the table above, get the same treatment.

## Response SLA

Times are business days from the first report, and the clock starts at the report,
not at the moment someone notices it.

| Stage               | Target                                                              | What you get                                                   |
| ------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------- |
| Acknowledgement     | 3 business days                                                     | A human reply confirming receipt and an owner assigned.        |
| Triage and severity | 7 business days                                                     | Reproduced or not, affected range, severity, and a rough plan. |
| Fix and disclosure  | 30 days for high and critical, 90 for moderate, best effort for low | Patch, advisory, release, and credit unless you ask for none.  |
| CVE                 | With the fix, for high and critical                                 | Requested through GitHub's advisory, not after the fact.       |

If you have not heard back inside the acknowledgement window, bump the advisory or
send one follow-up. Silence is usually a missed notification, not a refusal.

Two commitments, stated plainly because they are the ones reporters ask about:

- **No legal threat for good-faith research.** Research that stays inside this
  policy - no data exfiltration, no persistence, no denial of service against
  hosted services, no social engineering - is welcome and will not be reported.
- **Coordinated disclosure, your timeline respected.** We ask for 90 days before
  public disclosure and will tell you early if that is not achievable. If we go
  quiet past the SLA, you are entitled to disclose; please tell us first.

## Secrets Policy

A secret in git history is not recoverable by deleting it - history rewrite is
cheap to describe and painful to execute, and every clone keeps the copy. The rules
below are the ones that prevent it, and CI enforces them rather than trusting
intent.

### Never committed

These paths are git-ignored and are refused in review regardless:

- `.env` and every `.env.*` variant that holds values (`.env.local`,
  `.env.production`, `.envrc` with real values).
- Private keys and keystores: `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`,
  `id_ed25519`.
- Service-account and cloud credential files: `credentials.json`,
  `service-account*.json`, `.aws/`, `.gcloud/`.
- Anything under `secrets/`, plus any file whose name says `token`, `secret`, or
  `credential` and contains a real value.

If any of these reaches a commit, treat the credential as compromised: rotate it
first, then clean the history, in that order. Cleaning history without rotating
fixes nothing.

### The `.env` / `.env.example` twin rule

Every env file ships a committed `.example` twin:

| Real file (git-ignored) | Committed twin            |
| ----------------------- | ------------------------- |
| `.env`                  | `.env.example`            |
| `.env.production`       | `.env.production.example` |

The twin documents every key the real file needs, with an obviously-fake value
(`change-me-...`, hosts on the reserved `.invalid` TLD). When you add a variable,
you add it to the twin in the same commit, with a comment saying what it does and
what happens when it is unset. The twin is what makes a fresh clone runnable
instead of failing with an error naming a variable nobody has heard of.

Never put a real value in a twin, not even a "public" one, and not even an example
copied from a working deployment. "Public" is how a rotated secret gets published.

### Scanning runs in CI

`gitleaks` and CodeQL run in CI, so a secret cannot reach `main` by accident:

- [`.github/workflows/security.yml`](.github/workflows/security.yml) runs
  `gitleaks/gitleaks-action@v2` over full history (`fetch-depth: 0`) plus CodeQL
  static analysis.
- [`.github/workflows/ci.yml`](.github/workflows/ci.yml) has a `secret-scan` job
  doing the same on every push to `main` and every pull request, so a leak fails
  the PR rather than the release.
- The `detect-private-key` hook in
  [`.pre-commit-config.yaml`](.pre-commit-config.yaml) catches the common case
  before the commit is even created.

A genuine false positive gets a `.gitleaks.toml` allowlist entry with a reason, in
the same PR, reviewed by a human. It does not get a `continue-on-error` on the job
and it does not get the job deleted: a security check that silently skips is a
bug, which is the one failure mode this file promises not to have.

## Reporting a security regression in this repository's own setup

If you find that a guard in this repo does not actually guard - a CI job that
passes while its tool is missing, a workflow with `permissions: write-all`, a
hook that swallows its own failure, `main` without branch protection - report it
as an ordinary bug, not through the private channel. Those findings are useful to
every user of the template and there is nothing to disclose.
