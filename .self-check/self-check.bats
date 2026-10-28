#!/usr/bin/env bats
#
# ## self-check.bats -- conformance suite for this repository as a template
#
# This tree is source that is never executed here: a generator copies it, renames
# files inside it and substitutes tokens before any of it runs. That leaves a class
# of defect no other suite in this repository can see -- a placeholder nobody
# substitutes, a lane overlay with no metadata, a pin a script asks for that the pin
# file never defines, a gate that reports green while doing nothing. Each test below
# pins one of those.
#
# Self-contained by design: plain bats plus the tools a lane already needs (bash,
# grep, find, sed, awk, python3). No shared test helper, no build system, nothing
# outside this repository. `fail` and `assert_eq` are defined here rather than
# loaded, because bats core does not ship them and a template cannot depend on a
# plugin being installed.
#
# Usage:
#   make self-check                    # from the repository root
#   bash .self-check/run.sh            # the same, without make
#   bats .self-check/self-check.bats   # bats directly
#
# Safety: reads the repository tree; writes nothing outside the scratch tree bats
# hands each test.

bats_require_minimum_version 1.5.0

# ---- the contract ------------------------------------------------------------
#
# This suite is the authority the generator follows, not a mirror of it. The lists
# below are stated here on purpose: a generator that drops a token, invents a lane,
# or strips a path it should keep has to fail this file, rather than have this file
# follow it somewhere nobody reviewed.

# Render tokens substituted in file contents and in path names. The markdown alias
# spelling (the token name wrapped in two asterisks) is legal alongside the
# canonical form because a markdown formatter reads a double-underscore token as
# strong emphasis and rewrites it into that alias, so both spellings appear in the
# tree and both have to be substituted.
readonly RENDER_TOKENS=(
  __PROJECT_NAME__
  __PROJECT_SLUG__
  __PROJECT_MODULE__
  __PROJECT_DESCRIPTION__
  __PROJECT_OWNER__
  __PROJECT_LICENSE_HOLDER__
  __PROJECT_YEAR__
)

# Python and dunder names that merely look like a render token.
readonly TOKEN_LOOKALIKES=(
  __version__ __pycache__ __main__ __name__ __future__ __init__ __all__
  __pkg__ __builtins__ __doc__ __file__ __class__ __module__ __dict__
)

# The lanes a generator can render. A lane is an optional overlay under
# .template-lanes/<lane>/ that turns itself on by shipping its own manifest.
readonly LANES=(shell python typescript go)

# Paths this repository owns as a template and a rendered project does not carry:
# the lane overlays (copied out selectively, then dropped), this suite, and the VCS
# directory. Only the VCS directory is out of every scan: .template-lanes/** is
# copied verbatim into the rendered project, so it is audited like any other
# payload, and .self-check/** is audited too, because a broken suite is a broken
# deliverable even though no project ships it.
readonly GENERATOR_OWNED_PATHS=(".template-lanes/" ".self-check/" ".git")

TEMPLATE_ROOT=""
# Every recursive grep in this file skips the VCS directory: object files are
# binary, and a packed ref is not payload.
readonly GREP_SKIP=(--exclude-dir=.git --exclude-dir=.venv --exclude-dir=node_modules)

# ---- assertion helpers -------------------------------------------------------
#
# bats core provides run and skip but not fail, so this suite carries its own.
# A test body runs under errexit, so returning non-zero from here aborts the test
# and bats reports the line that called it.

# @function fail
# Fail the current test with one message.
# Arguments:
#   $1 - the message
#   $2 - exit status to return, default 1
# Outputs:
#   The message on stderr, which bats echoes as a TAP diagnostic
# Returns:
#   $2, so errexit aborts the test
fail() {
  printf '%s\n' "${1:-assertion failed}" >&2
  return "${2:-1}"
}

# @function assert_eq
# Compare two strings and fail with both sides labelled.
# Arguments:
#   $1 - label, $2 - expected, $3 - actual
# Outputs:
#   Both sides on stderr when they differ
# Returns:
#   0, or aborts the test
assert_eq() {
  if [ "$2" != "$3" ]; then
    printf 'test: %s\nexpected: %s\nactual:   %s\n' "$1" "$2" "$3" >&2
    fail "assertion failed: $1"
  fi
}

# @function token_pattern
# Build the anchored pattern that accepts exactly the declared render tokens.
# Globals:
#   RENDER_TOKENS
# Outputs:
#   '^(a|b|c)$' on stdout
# Returns:
#   0
token_pattern() {
  local joined="" token
  for token in "${@}"; do
    joined+="${joined:+|}${token}"
  done
  printf '^(%s)$' "${joined}"
}

# @function token_alias_pattern
# Build the anchored pattern for the markdown alias spelling. The names are derived
# from RENDER_TOKENS instead of being written out, so this file never carries a
# string that is itself shaped like a token.
# Globals:
#   RENDER_TOKENS
# Outputs:
#   '^\*\*PROJECT_(NAME|...)\*\*$' on stdout
# Returns:
#   0
token_alias_pattern() {
  local joined="" name token
  for token in "${RENDER_TOKENS[@]}"; do
    name="${token#__PROJECT_}"
    name="${name%__}"
    joined+="${joined:+|}${name}"
  done
  printf '^\\*\\*PROJECT_(%s)\\*\\*$' "${joined}"
}

# @function tree_find
# Walk the repository tree, skipping the VCS directory. The caller supplies the print
# action so that -print0 stays usable; a second one here would corrupt the stream.
# Arguments:
#   "$@" - find predicates and its own -print, for example -type f -name '*.sh' -print
# Outputs:
#   One path per line (or per NUL, when the caller asks for -print0)
# Returns:
#   0
tree_find() {
  find -L "${TEMPLATE_ROOT}" \
    \( -path "${TEMPLATE_ROOT}/.git" -o -path "${TEMPLATE_ROOT}/.git/*" \) -prune -o \
    "$@"
}

setup() {
  [ -n "${BATS_TEST_DIRNAME:-}" ] || fail "BATS_TEST_DIRNAME is unset; run this file with bats"
  # The repo root is the parent of the directory this suite lives in, so the suite
  # travels with the tree and needs no marker file to find it.
  TEMPLATE_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." && pwd)"
  if [ ! -f "${TEMPLATE_ROOT}/Makefile" ] || [ ! -f "${TEMPLATE_ROOT}/tool-versions.env" ]; then
    skip "the parent of .self-check/ is not the template root (no Makefile or tool-versions.env)"
  fi
}

# ---- structure ---------------------------------------------------------------

@test "tree carries every file that is always rendered" {
  # Anything a rendered project cannot live without has to be here; a file the
  # generator does not overlay per lane is silently optional otherwise.
  local -a required=(
    README.md AGENTS.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md CHANGELOG.md
    LICENSE template.yml Makefile Dockerfile Dockerfile.test tool-versions.env
    env.example .editorconfig .gitattributes .gitignore .gitleaks.toml .shellcheckrc
    .pre-commit-config.yaml .yamllint.yml
    .devcontainer/devcontainer.json .devcontainer/Dockerfile
    .github/CODEOWNERS .github/dependabot.yml .github/PULL_REQUEST_TEMPLATE.md
    .github/ISSUE_TEMPLATE/bug_report.md .github/ISSUE_TEMPLATE/feature_request.md
    .github/ISSUE_TEMPLATE/config.yml
    .github/workflows/ci.yml .github/workflows/release.yml .github/workflows/security.yml
    .github/workflows/self-check.yml
    docs/README.md src/README.md tests/run.sh
  )
  local -a missing=()
  local f
  for f in "${required[@]}"; do
    [ -f "${TEMPLATE_ROOT}/${f}" ] || missing+=("${f}")
  done
  if [ "${#missing[@]}" -ne 0 ]; then
    fail "the template is missing: ${missing[*]}"
  fi
}

@test "every render token in the tree is one the contract declares" {
  # A typo'd token survives rendering as literal text in the customer's new repo, so
  # the only tokens allowed here are the ones the contract above declares plus the
  # dunder names that merely look like placeholders. Both spellings are checked: a
  # markdown file cannot hold the canonical form outside a code span, because the
  # formatter rewrites it into the alias, which is why the alias is legal too.
  local canonical allowed unknown
  canonical="$(token_pattern "${RENDER_TOKENS[@]}")"
  allowed="$(token_pattern "${TOKEN_LOOKALIKES[@]}")"

  unknown="$(grep -RhoE "${GREP_SKIP[@]}" '__[A-Za-z_][A-Za-z0-9_]*__' "${TEMPLATE_ROOT}" |
    grep -vE "${canonical}" |
    grep -vE "${allowed}" |
    sort -u)"
  [ -z "${unknown}" ] ||
    fail "tokens no generator will ever substitute: $(echo "${unknown}" | tr '\n' ' ')"

  unknown="$(grep -RhoE "${GREP_SKIP[@]}" '\*\*PROJECT_[A-Z_]+\*\*' "${TEMPLATE_ROOT}" |
    grep -vE "$(token_alias_pattern)" |
    sort -u)"
  [ -z "${unknown}" ] ||
    fail "markdown token spellings no generator will ever substitute: $(echo "${unknown}" | tr '\n' ' ')"
}

@test "the lanes on disk are exactly the lanes the contract declares" {
  # A lane directory nobody declared is never rendered, so it rots; a declared lane
  # with no directory is a --lane flag that fails in the customer's terminal.
  local -a on_disk=()
  local d
  for d in "${TEMPLATE_ROOT}/.template-lanes"/*/; do
    [ -d "${d}" ] || continue
    on_disk+=("$(basename "${d}")")
  done
  [ "${#on_disk[@]}" -gt 0 ] || fail "no lane directory under .template-lanes"

  local want got
  want="$(printf '%s\n' "${LANES[@]}" | sort)"
  got="$(printf '%s\n' "${on_disk[@]}" | sort)"
  [ "${want}" = "${got}" ] ||
    fail "the contract declares [$(echo "${want}" | tr '\n' ' ')] but .template-lanes holds [$(echo "${got}" | tr '\n' ' ')]"
}

@test "each lane ships the metadata pair the render strips" {
  local lane name
  for lane in "${TEMPLATE_ROOT}/.template-lanes"/*/; do
    [ -d "${lane}" ] || continue
    name="$(basename "${lane}")"
    [ -f "${lane}LANE.md" ] || fail "lane ${name} has no LANE.md, so nobody can see what it installs"
    [ -f "${lane}gitignore.fragment" ] ||
      fail "lane ${name} has no gitignore.fragment, so its build junk lands in git"
  done
}

@test "the env twin is stored undotted and renders dotted" {
  # The tree spells the documented twin env.example; the dotted name is what the
  # render writes into the new project. Shipping the dotted name here invites an
  # agent or a glob to treat the template's own file as a real env file.
  [ -f "${TEMPLATE_ROOT}/env.example" ] ||
    fail "env.example is absent; the render's rename has nothing to rename"
  [ ! -e "${TEMPLATE_ROOT}/.env.example" ] ||
    fail ".env.example must not be tracked here: the render writes that name itself"
}

@test "no build artifact is committed into the template" {
  # Everything below is derived, so a copy in the tree is a stale claim about what
  # was built, and it lands in every project rendered from here.
  local junk
  junk="$(tree_find \( -name '__pycache__' -o -name '*.pyc' -o -name 'node_modules' \
    -o -name 'package-lock.json' -o -name '.pytest_cache' -o -name '.ruff_cache' \
    -o -name '.mypy_cache' -o -name 'coverage' -o -name 'coverage.out' \) -print | sort)"
  [ -z "${junk}" ] || fail "derived artifacts in a template tree: ${junk}"
}

# ---- executable sources ------------------------------------------------------

@test "every shell source in the tree parses" {
  local -a broken=()
  local f
  while IFS= read -r f; do
    bash -n "${f}" 2>/dev/null || broken+=("${f#"${TEMPLATE_ROOT}/"}")
  done < <(tree_find -type f -name '*.sh' -print | sort)
  [ "${#broken[@]}" -eq 0 ] || fail "bash -n rejects: ${broken[*]}"
}

@test "no shell source can swallow a failing check" {
  # `|| exit 0` is the one idiom that turns a gate green without running it. Scoped
  # to the files where it would actually execute, with comment lines dropped,
  # because the house style rules name the literal in order to forbid it.
  local hits
  hits="$(tree_find -type f \( -name '*.sh' -o -name 'Dockerfile*' -o -name 'Makefile' \) -print0 |
    xargs -0 grep -nE '\|\|[[:space:]]*exit 0' 2>/dev/null |
    grep -vE ':[0-9]+:[[:space:]]*#' || true)"
  [ -z "${hits}" ] || fail "a check that can silently pass: ${hits}"
}

@test "no dependency or action reference floats" {
  # A moving tag is the other way a gate stops checking: today's green is tomorrow's
  # different green. Pinned at the three places a float can hide in this tree.
  local -a floats=()
  local f
  while IFS= read -r f; do
    grep -nE '^[[:space:]]*(FROM|Image)[[:space:]]+[^ ]+:latest' "${f}" >/dev/null 2>&1 &&
      floats+=("${f#"${TEMPLATE_ROOT}/"}: FROM :latest")
    grep -nE '^[[:space:]]*-?[[:space:]]*(uses|image):[[:space:]]*[^ ]*@latest' "${f}" >/dev/null 2>&1 &&
      floats+=("${f#"${TEMPLATE_ROOT}/"}: uses @latest")
  done < <(tree_find -type f \( -name 'Dockerfile*' -o -name '*.yml' -o -name '*.yaml' \) -print | sort)

  # devDependencies must be exact: the drift between package.json and
  # tool-versions.env is the bug this template exists to prevent.
  local drift
  drift="$(
    python3 - "${TEMPLATE_ROOT}/.template-lanes/typescript/package.json" <<'PY'
import json, re, sys
try:
    deps = json.load(open(sys.argv[1])).get("devDependencies", {})
except FileNotFoundError:
    sys.exit(0)
exact = re.compile(r"^\d+\.\d+\.\d+([-+][0-9A-Za-z.-]+)?$")
print(" ".join("%s=%s" % kv for kv in deps.items() if not exact.match(kv[1])))
PY
  )"
  [ -z "${drift}" ] || floats+=("typescript devDependencies not exact: ${drift}")

  [ "${#floats[@]}" -eq 0 ] || fail "$(printf '%s; ' "${floats[@]}")"
}

# ---- declarative files -------------------------------------------------------

@test "every yaml in the tree parses" {
  local -a bad=()
  local f
  while IFS= read -r f; do
    python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))' "${f}" 2>/dev/null ||
      bad+=("${f#"${TEMPLATE_ROOT}/"}")
  done < <(tree_find -type f \( -name '*.yml' -o -name '*.yaml' \) -print | sort)
  [ "${#bad[@]}" -eq 0 ] || fail "yaml.safe_load rejects: ${bad[*]}"
}

@test "every workflow declares its permissions and cannot self-approve a failure" {
  # The floor is the core set plus at least one lane workflow: a tree where the
  # lane overlays carry no CI is a tree whose lanes nobody tests.
  local -a workflows=()
  local f
  while IFS= read -r f; do workflows+=("${f}"); done < <(tree_find -type f -path '*/.github/workflows/*.yml' -print | sort)
  [ "${#workflows[@]}" -ge 5 ] ||
    fail "expected the four core workflows plus at least one lane workflow, found ${#workflows[@]}"

  local -a problems=()
  for f in "${workflows[@]}"; do
    grep -qE '^permissions:' "${f}" || problems+=("${f#"${TEMPLATE_ROOT}/"}: no top-level permissions")
    grep -qE 'continue-on-error:[[:space:]]*true' "${f}" &&
      problems+=("${f#"${TEMPLATE_ROOT}/"}: continue-on-error true")
    grep -qE 'pull_request_target' "${f}" &&
      problems+=("${f#"${TEMPLATE_ROOT}/"}: pull_request_target runs fork code with write tokens")
  done
  [ "${#problems[@]}" -eq 0 ] || fail "$(printf '%s; ' "${problems[@]}")"
}

@test "template.yml is valid and every param offers concrete values" {
  python3 - "${TEMPLATE_ROOT}/template.yml" <<'PY'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
assert isinstance(doc, dict), "template.yml is not a mapping"
for key in ("name", "description", "params"):
    assert key in doc, "template.yml has no %s" % key
assert isinstance(doc["params"], dict) and doc["params"], "template.yml has no params"
for pid, spec in doc["params"].items():
    values = spec.get("values") if isinstance(spec, dict) else None
    assert isinstance(values, list) and values, "param %s has no values list" % pid
    for v in values:
        assert isinstance(v, str) and v.strip(), "param %s carries an empty example" % pid
PY
}

@test "the secret scanner keeps its upstream rule set" {
  local cfg="${TEMPLATE_ROOT}/.gitleaks.toml"
  [ -f "${cfg}" ] || fail ".gitleaks.toml is missing, so nothing scans for secrets"
  grep -qE '^[[:space:]]*useDefault[[:space:]]*=[[:space:]]*true' "${cfg}" ||
    fail ".gitleaks.toml no longer extends the default rules, so the scan checks nothing new"
  ! grep -qE 'regexes[[:space:]]*=[[:space:]]*\[[[:space:]]*"\.\*"' "${cfg}" ||
    fail ".gitleaks.toml allowlists everything with .*"
  grep -qE 'change-me-not-a-real-key' "${TEMPLATE_ROOT}/env.example" ||
    fail "env.example lost the documented placeholder that .gitleaks.toml allowlists"
}

@test "LICENSE carries the holder and year tokens" {
  grep -q '__PROJECT_LICENSE_HOLDER__' "${TEMPLATE_ROOT}/LICENSE" ||
    fail "LICENSE has no holder token to substitute"
  grep -q '__PROJECT_YEAR__' "${TEMPLATE_ROOT}/LICENSE" ||
    fail "LICENSE has no year token to substitute"
}

# ---- pins --------------------------------------------------------------------

@test "every pin the tree asks for is defined in tool-versions.env" {
  # The lookup shapes used in this tree: pin_value KEY, require_module mod pkg KEY,
  # $(call NEED,bin,KEY), the devcontainer's required="..." list, and ${KEY:?...} in
  # a lane workflow. A key asked for but not defined resolves to the empty string at
  # run time, which is how an installer ends up fetching an unpinned tool.
  local -a wanted=()
  local key
  while IFS= read -r key; do
    [ -n "${key}" ] && wanted+=("${key}")
  done < <(
    {
      grep -RhoE "${GREP_SKIP[@]}" '\bpin_value +[A-Z0-9_]+(_VERSION)\b' "${TEMPLATE_ROOT}" | awk '{print $2}'
      grep -RhoE "${GREP_SKIP[@]}" '\brequire_module +[A-Za-z0-9_.-]+ +[A-Za-z0-9_.-]+ +[A-Z0-9_]+(_VERSION)\b' \
        "${TEMPLATE_ROOT}" | awk '{print $4}'
      grep -RhoE "${GREP_SKIP[@]}" 'NEED,[a-z0-9-]+,[A-Z0-9_]+(_VERSION)' "${TEMPLATE_ROOT}" | cut -d, -f3
      grep -RhoE "${GREP_SKIP[@]}" 'required="[A-Z0-9_ ]+"' "${TEMPLATE_ROOT}" |
        sed 's/required="//; s/"//' | tr ' ' '\n'
      grep -RhoE "${GREP_SKIP[@]}" '\$\{[A-Z0-9_]+(_VERSION):[?]' "${TEMPLATE_ROOT}" |
        sed 's/^\${//; s/[:?]$//'
    } | grep -E '_VERSION$' | sort -u
  )
  [ "${#wanted[@]}" -gt 0 ] || fail "this suite found no pin lookups, so it has stopped testing anything"

  local -a undef=()
  for key in "${wanted[@]}"; do
    grep -qE "^${key}=" "${TEMPLATE_ROOT}/tool-versions.env" || undef+=("${key}")
  done
  [ "${#undef[@]}" -eq 0 ] || fail "asked for but not defined in tool-versions.env: ${undef[*]}"
}

@test "every defined pin is read by something" {
  local -a dead=()
  local key
  while IFS= read -r key; do
    [ -n "${key}" ] || continue
    # A pin nobody reads is a version that silently rots. The key has to appear
    # somewhere other than its own definition line.
    if ! grep -RqE "${GREP_SKIP[@]}" --exclude=tool-versions.env "\b${key}\b" "${TEMPLATE_ROOT}"; then
      dead+=("${key}")
    fi
  done < <(grep -oE '^[A-Z0-9_]+_VERSION' "${TEMPLATE_ROOT}/tool-versions.env")
  [ "${#dead[@]}" -eq 0 ] || fail "defined in tool-versions.env but read by nothing: ${dead[*]}"
}

@test "every pin is a version and not a moving tag" {
  local -a bad=()
  while IFS='=' read -r key value; do
    [[ ${key} =~ ^[A-Z0-9_]+_VERSION$ ]] || continue
    [[ ${value} =~ ^[0-9][0-9A-Za-z.+-]*$ ]] || bad+=("${key}=${value}")
  done < <(grep -E '^[A-Z0-9_]+=' "${TEMPLATE_ROOT}/tool-versions.env")
  [ "${#bad[@]}" -eq 0 ] || fail "not a plain version string: ${bad[*]}"
}

# ---- prose -------------------------------------------------------------------

@test "relative links in the tree docs resolve" {
  # A dangling relative link is invisible until a reader follows it, which is after
  # the render and after the person who broke it stopped looking.
  local -a broken=()
  local f target base
  while IFS= read -r f; do
    base="$(dirname "${f}")"
    while IFS= read -r target; do
      [ -n "${target}" ] || continue
      target="${target%%#*}"
      [ -n "${target}" ] || continue
      case "${target}" in
        http://* | https://* | mailto:* | \#* | /*) continue ;;
      esac
      # Angle-bracket and title syntax leftovers, plus tokens that are paths only
      # after rendering.
      [[ ${target} == *__* ]] && continue
      # The env twin is a path that exists only after rendering: the tree stores it
      # undotted (see the header of env.example) and the render writes the dotted name
      # into the new project. Accept the dotted spelling only when its undotted twin is
      # really there next to it, so a broken twin still reads as a dangling link.
      if [ "${target}" = ".env.example" ] && [ -e "${base}/env.example" ]; then
        continue
      fi
      [ -e "${base}/${target}" ] || broken+=("${f#"${TEMPLATE_ROOT}/"} -> ${target}")
    done < <(
      # The -E matters: without it the trailing \) is an unmatched paren, sed dies, and
      # the loop below has nothing left to read while the test stays green.
      grep -ohE '\]\(\.[^)]+\)' "${f}" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//'
    )
  done < <(tree_find -type f -name '*.md' -print | sort)
  [ "${#broken[@]}" -eq 0 ] || fail "dangling relative links: $(printf '%s; ' "${broken[@]}")"
}

# ---- the dispatcher and the doctor -------------------------------------------

@test "the dispatcher lists present lanes without failing on an empty tree" {
  # tests/run.sh --lanes is what make doctor asks for when it decides which pins this
  # checkout may demand. An empty answer has to be a success: an empty tree is a
  # legitimate answer there, unlike in the run path, where it is a failure.
  local scratch="${BATS_TEST_TMPDIR}/lanes"
  mkdir -p "${scratch}/tests"
  cp "${TEMPLATE_ROOT}/tests/run.sh" "${scratch}/tests/run.sh"

  run bash "${scratch}/tests/run.sh" --lanes
  [ "${status}" -eq 0 ] || fail "--lanes must exit 0 on a tree with no lane, got ${status}"
  assert_eq "an empty tree reports no lanes" "" "${output}"

  printf 'module example.com/x\n' >"${scratch}/go.mod"
  printf '{"name":"x"}\n' >"${scratch}/package.json"
  printf '[tool.pytest.ini_options]\n' >"${scratch}/pyproject.toml"
  mkdir -p "${scratch}/tests/python"
  run bash "${scratch}/tests/run.sh" --lanes
  [ "${status}" -eq 0 ]
  assert_eq "each manifest turns its lane on, in KNOWN_LANES order" \
    "$(printf 'python\ntypescript\ngo')" "${output}"

  run bash "${scratch}/tests/run.sh" --lanes --bogus
  [ "${status}" -ne 0 ] || fail "--lanes must still refuse an unknown flag"
}

@test "the doctor demands only the pins of lanes this checkout has" {
  # A shell-only project that cannot start without golangci-lint is a template bug,
  # not a toolchain bug: the doctor scopes each pin by the `# -- <Lane> lane` heading
  # it sits under and skips one whose lane is absent.
  # The whole word matters: a grep for the bare prefix also matches a renamed flag,
  # which is the exact edit that would make the doctor skip its lane probe quietly.
  grep -qE -- '--lanes([[:space:]]|$)' "${TEMPLATE_ROOT}/Makefile" ||
    fail "the doctor no longer asks tests/run.sh which lanes are present"
  grep -qE "not required" "${TEMPLATE_ROOT}/Makefile" ||
    fail "the doctor lost its skip line for an absent lane's pin"

  # Every lane heading has to name a lane the contract can render, or the pin under
  # it is unsatisfiable: no render can ever produce that lane's manifest.
  local heading lane
  local -a unknown=()
  while IFS= read -r heading; do
    lane="${heading% lane}"
    lane="$(printf '%s' "${lane}" | tr '[:upper:]' '[:lower:]')"
    if ! printf '%s\n' "${LANES[@]}" | grep -qxF -- "${lane}"; then
      unknown+=("${heading}")
    fi
  done < <(grep -oE '^# -- [A-Za-z]+ lane' "${TEMPLATE_ROOT}/tool-versions.env" | sed 's/^# -- //')
  [ "${#unknown[@]}" -eq 0 ] ||
    fail "pins are tagged with lanes the contract cannot render: ${unknown[*]}"

  # And each lane the contract declares must have a heading, or its pins land under a
  # non-lane heading and every project is made to install them.
  local -a missing=()
  for lane in "${LANES[@]}"; do
    grep -qiE "^# -- ${lane} lane" "${TEMPLATE_ROOT}/tool-versions.env" || missing+=("${lane}")
  done
  [ "${#missing[@]}" -eq 0 ] ||
    fail "these lanes have no pin heading, so their tools are always required: ${missing[*]}"
}

# ---- the suite's own entry points ---------------------------------------------

@test "make test stages a lane rather than reporting nothing to do" {
  # The template ships no lane at its root, so a test target that demands one fails a
  # template checkout, and a target that tolerates one reports green having run
  # nothing. The template's own tests are the lane overlays, staged and executed.
  local makefile="${TEMPLATE_ROOT}/Makefile"
  grep -qE '^test-lanes:' "${makefile}" ||
    fail "make test has no lane-staging target, so a template checkout runs no test at all"
  grep -qE '^\.PHONY:.*\btest-lanes\b' "${makefile}" ||
    fail "test-lanes is absent from .PHONY, so a file of that name turns it into a no-op"
  grep -qE 'test-lanes' "${makefile}" ||
    fail "make test never delegates to the staging target"
  grep -qE 'bash \$\(RUNNER\) --lane' "${makefile}" ||
    fail "test-lanes never hands a lane to the dispatcher, so it stages nothing it runs"
  # A staged tree that still carries the generator-owned paths is a template wearing
  # a project's clothes, and a lane could reach code a rendered project never has.
  grep -qE 'rm -rf .*\$\{work:\?\}/\.git' "${makefile}" ||
    fail "the staged tree keeps .git, so it is not shaped like a rendered repository"
  grep -qE 'rm -rf .*\.self-check' "${makefile}" ||
    fail "the staged tree keeps .self-check/, so a lane can reach generator-only files"
  # A :? guard on every recursive delete the staging recipe makes: an unset scratch
  # path would delete the checkout instead of a scratch tree.
  local block
  block="$(awk '/^test-lanes:/{f=1} f && /^[a-z0-9_-]+:/ && !/^test-lanes:/{f=0} f' "${makefile}")"
  [ -n "${block}" ] || fail "test-lanes has no recipe, so the target is decoration"
  local unguarded
  unguarded="$(printf '%s\n' "${block}" | grep -nE 'rm -rf' | { grep -v 'work:?' || true; })"
  [ -z "${unguarded}" ] ||
    fail "a recursive delete in test-lanes has no :? guard on its path: ${unguarded}"
}

@test "a staged lane overlay really runs its own tests" {
  # The structural check above proves the target exists; this one proves the thing it
  # stages passes. A lane whose tests cannot run in a clean tree is a lane nobody can
  # render, and only executing it says so.
  local work="${BATS_TEST_TMPDIR}/staged-shell"
  mkdir -p "${work}"
  cp -R "${TEMPLATE_ROOT}/." "${work}/"
  rm -rf "${work:?}/.git" "${work:?}/.template-lanes" "${work:?}/.self-check"
  cp -R "${TEMPLATE_ROOT}/.template-lanes/shell/." "${work}/"
  [ -f "${work}/tests/main.sh" ] ||
    [ -d "${work}/src" ] || fail "staging the shell lane produced no lane files"
  run bash "${work}/tests/run.sh" --lane shell
  [ "${status}" -eq 0 ] ||
    fail "the staged shell lane failed its own suite (exit ${status}): ${output}"
  [[ "${output}" == *"ok: shell"* ]] ||
    fail "the staged shell lane reported no passing result: ${output}"
}

@test "the CodeQL job compiles what it claims to analyse" {
  # A scan that traces nothing reports green, which is the exact lie this suite
  # exists to catch. `none` is refused outright by a compiled extractor, and an
  # omitted build mode hands the decision to autobuild, which here reached for a
  # python2 no runner has.
  local entry="${TEMPLATE_ROOT}/.github/workflows/security.yml"
  [ -f "${entry}" ] || fail ".github/workflows/security.yml is missing"
  if grep -qE 'build-mode:[[:space:]]*none' "${entry}"; then
    fail "the CodeQL job uses build-mode: none, which a compiled extractor refuses"
  fi
  grep -qE 'build-mode:[[:space:]]*manual' "${entry}" ||
    fail "the CodeQL job names no build mode, so autobuild decides what gets traced"
  grep -qE 'go build' "${entry}" ||
    fail "the CodeQL job never compiles the go lane, so its Go scan would be empty"
  grep -qE 'refusing to publish an empty Go scan' "${entry}" ||
    fail "a Go language set with no module passes silently instead of failing"
}

@test "the template's own suite is optional for a rendered project" {
  # .self-check/ is generator-owned, so every entry point that reaches it has to say
  # what it skipped instead of failing a project that never asked for it. A guard
  # that prints a note is not a silent skip: the absent directory is the contract,
  # and the note keeps the decision visible in the log.
  local entry="${TEMPLATE_ROOT}/.github/workflows/self-check.yml"
  local owned
  for owned in "${GENERATOR_OWNED_PATHS[@]}"; do
    [ -e "${TEMPLATE_ROOT}/${owned%/}" ] ||
      fail "the contract calls ${owned} generator-owned, but there is nothing in the tree to strip"
  done
  [ -f "${TEMPLATE_ROOT}/.self-check/run.sh" ] ||
    fail ".self-check/run.sh is missing, so no entry point can reach the suite"
  grep -qE -- '\[ -d \.self-check \]|\[ -f \.self-check/run\.sh \]' "${TEMPLATE_ROOT}/Makefile" ||
    fail "make self-check runs the suite unconditionally, so every rendered project is red"
  grep -qE "note:" "${TEMPLATE_ROOT}/Makefile" ||
    fail "make self-check lost its note for a tree without .self-check/"
  [ -f "${entry}" ] || fail ".github/workflows/self-check.yml is missing"
  grep -qE -- '\[ -d \.self-check \]|\[ -f \.self-check/run\.sh \]' "${entry}" ||
    fail "the self-check workflow runs the suite unconditionally, so every rendered project is red"
}
