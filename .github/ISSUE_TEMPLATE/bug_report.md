---

name: Bug report
about: Something runs, but not the way it should. Use this when you can point at a command and a wrong result.
title: "fix: "
labels: ["bug", "triage"]
assignees: []
body:

- type: markdown
  attributes:
  value: |
  A report that contains an exact reproduction is usually fixed the same day.
  A report that says "it doesn't work" costs three rounds of questions before
  anyone can start.

      Before you file: search the open and closed issues, and re-run on the latest
      `main` or the newest release. If you found this while reading the code rather
      than running it, say so - a static defect is still a bug, it just has no
      reproduction to paste.

      Do not report security problems here. See SECURITY.md and open a private
      Security Advisory instead; a public issue is already a disclosure.

- type: textarea
  id: what-happened
  attributes:
  label: What happened
  description: >-
  One or two sentences, factual, no interpretation yet. Name the command, the
  file, or the endpoint, and the symptom a person would notice.
  placeholder: |
  `__PROJECT_NAME__ --format json` writes an empty object to stdout and exits 0.
  validations:
  required: true

- type: textarea
  id: reproduction
  attributes:
  label: Steps to reproduce
  description: >-
  Numbered, copy-pasteable, from a clean state. Include the exact command line
  with its real flags and the input file or fixture (or the smallest reduction of
  it that still fails). Delete anything that does not affect the outcome - a
  five-step reproduction that needs three of them is a two-step bug.
  value: | 1. 2. 3.
  placeholder: | 1. git clone https://github.com/__PROJECT_OWNER__/__PROJECT_NAME__ && cd **PROJECT_NAME** 2. cp .env.example .env 3. make test
  validations:
  required: true

- type: textarea
  id: expected
  attributes:
  label: Expected behaviour
  description: >-
  What you believe should have happened, and what makes you believe it - the
  doc sentence, the README line, the previous release you ran, or the error
  message that should have appeared instead of silence. If the docs and the
  behaviour disagree, say which one you think is wrong.
  placeholder: |
  It should print the config object, or fail with a non-zero exit and a message
  naming the missing key. Exit 0 with no output is the one answer that is wrong,
  because a check that silently produces nothing looks like success.
  validations:
  required: true

- type: textarea
  id: actual
  attributes:
  label: Actual behaviour
  description: >-
  Paste the real output - stdout, stderr, and the exit code (`echo $?` right
  after). Trim unrelated log noise, but never trim the traceback, and never
  paraphrase. Redact anything secret before pasting.
  placeholder: |
  $ **PROJECT_NAME** --format json
  {}
  $ echo $?
  0
  render: shell
  validations:
  required: true

- type: textarea
  id: already-tried
  attributes:
  label: What did you already try
  description: >-
  This is the section people skip and the one that saves the most time. List
  what you ruled out and how, including things that felt irrelevant, plus what
  you searched. "Nothing worked" is not an answer; "tried X, Y, Z, and bisected
  to commit abc1234" is.
  placeholder: | - Tried with and without `.env` present: same result either way. - Tried the previous release (v0.3.1): works, so this is a regression. - Set LOG_LEVEL=debug: no additional output, which suggests the code path
  never runs at all.
  validations:
  required: true

- type: textarea
  id: environment
  attributes:
  label: Environment
  description: >-
  Enough that someone can rebuild your exact situation. Version is the one that
  matters most - get it from the tool itself rather than from memory.
  value: | - Version or commit: (paste `__PROJECT_NAME__ --version`, or `git rev-parse HEAD`) - OS and version: - Container or CI, if relevant: - Interpreter / toolchain version: - Install method: (source, container image, package manager)
  validations:
  required: true

- type: textarea
  id: logs
  attributes:
  label: Relevant log output
  description: >-
  Anything with a stack trace, a warning, or a timing. Redact tokens, keys, and
  internal hostnames. If you can run with debug logging, do - and say how you
  enabled it.
  render: shell
  validations:
  required: false

- type: dropdown
  id: willingness
  attributes:
  label: Are you able to open a PR?
  description: >-
  Not a requirement. It sets expectations: "yes" means a maintainer should wait
  for you rather than fix it in parallel, so two people do not write the same
  patch.
  options: - "Yes, I will open a PR" - "Yes, with guidance on where to start" - "No, reporting only"
  validations:
  required: false
