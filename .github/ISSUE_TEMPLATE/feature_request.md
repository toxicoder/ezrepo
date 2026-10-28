---

name: Feature request
about: Something is missing that you want added, or existing behaviour should change.
title: "feat: "
labels: ["enhancement", "triage"]
assignees: []
body:

- type: markdown
  attributes:
  value: |
  The most persuasive request describes a problem you hit, not a feature you
  have already designed. Design can change once the constraint is on the table;
  a solution nobody can connect to a problem gets closed.

      Before you file: check the open and closed issues, and check whether the
      behaviour is configurable already. If it is configurable but the config is
      hard to find, that is a documentation bug - file it as one, it will get fixed
      faster.

- type: textarea
  id: problem
  attributes:
  label: The problem
  description: >-
  What you were trying to do, where you got stuck, and what you did instead.
  Concrete beats general: "I run this command 40 times a day and each run needs
  the same six flags" beats "the CLI should be easier to use".
  placeholder: |
  I export a report for three environments every morning. There is no way to
  pass more than one --env, so I run the command three times and merge the
  output by hand in a shell loop that breaks on filenames with spaces.
  validations:
  required: true

- type: textarea
  id: proposal
  attributes:
  label: Proposed solution
  description: >-
  The interface you would like, as concretely as you can - the command line, the
  function signature, the config key, the output shape. A sketch you would
  actually accept is worth more than a spec you are attached to; be explicit
  about which parts are negotiable.
  placeholder: |
  Accept --env repeatedly, like `__PROJECT_NAME__ --env dev --env prod`, and emit
  one document with a top-level key per environment. Repeating a flag is already
  how --tag behaves, so it would not be a new convention.
  validations:
  required: true

- type: textarea
  id: alternatives
  attributes:
  label: Alternatives you considered
  description: >-
  What else would solve this, and why you did not pick it. Include the workaround
  you are living with now and what it costs you - if nothing is tolerable, say
  what would make this "won't fix" rather than "no". Also state what you
  rejected as out of scope.
  placeholder: | - A config file listing environments: works, but it puts per-machine state in
  a file and does not help in CI, where flags are the only interface. - Wrapping the tool in my own script: fine short-term, but the loop belongs in
  the tool because everyone hits this.
  validations:
  required: true

- type: textarea
  id: impact
  attributes:
  label: Who this helps and how much
  description: >-
  Frequency and blast radius, since that is how requests get ranked against each
  other. Rough numbers are fine. If you know of other projects that solved this,
  name them and link the specific design you have in mind.
  placeholder: |
  Every user who runs this against more than one environment - roughly 30 people
  on our team, once or twice a day each. Comparable to how the --tag flag works.
  validations:
  required: true

- type: textarea
  id: breaking
  attributes:
  label: Breaking change?
  description: >-
  Does this change existing behaviour, rename a flag or public symbol, or alter
  an output format? Say so here rather than letting it surface in review - it
  decides whether this is a minor or a major release under SemVer 2.0.0, see
  CHANGELOG.md.
  placeholder: |
  No. Purely additive: today a repeated flag is a parse error, so no existing
  invocation changes meaning.
  validations:
  required: false

- type: textarea
  id: already-tried
  attributes:
  label: What you already tried
  description: >-
  What you searched, read, and attempted before deciding this needed a change
  upstream. Include the docs page or source file you looked at - if the feature
  exists and was simply not discoverable, that is itself the finding, and the
  right fix may be a docs change with a link.
  placeholder: |
  Read the README "Configuration" section and searched the source for "env"; the
  parser at the flags module only binds a single value per option.
  validations:
  required: true

- type: dropdown
  id: willingness
  attributes:
  label: Are you able to open a PR?
  description: >-
  Not a requirement. A small additive change with tests is usually merged faster
  than it is triaged. Say so here so nobody duplicates your work.
  options: - "Yes, I will open a PR" - "Yes, with guidance on where to start" - "No, requesting only"
  validations:
  required: false
