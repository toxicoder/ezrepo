# __PROJECT_NAME__ -- single command entry point
#
# This Makefile is the ONE command surface for this repository. If you are about
# to type a raw tool invocation (pytest, eslint, golangci-lint, shellcheck,
# bats, ...), stop and find the target that wraps it: CI runs these same
# targets, so anything you run ad hoc is a check nobody enforces.
#
# CI (.github/workflows/ci.yml) calls, in this order:
#   make doctor    first, always: proves every pin in tool-versions.env has a
#                  consumer and that the tool answers --version with that pin
#   make lint
#   make test
#   make docs
# `make validate` is the local mirror of that sequence; `make test-all` adds
# coverage on top. Run the cheapest target that can prove your change first --
# see the cost-tiered table in AGENTS.md.
#
# What this Makefile deliberately does NOT wrap:
#   - git and gh: you are the author; no target should hide a push
#   - publishing and releases: owned by .github/workflows/release.yml
#   - test discovery: tests/run.sh owns it, so `make test` is a one-line
#     delegation and a new language lane never needs a Makefile edit
#
# Self-documenting: every target carries a `## name - description` line directly
# above it and `make help` greps them out. Keep that line ASCII and on one line,
# or your target disappears from `make help`.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

PINS := tool-versions.env
RUNNER := tests/run.sh
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
CONSUMERS := .devcontainer/Dockerfile .github/workflows/ci.yml
# Files that find-based targets scan. node_modules and .git never enter a scan.
FIND_SH := find . -type f -name '*.sh' -not -path './.git/*' -not -path './node_modules/*'

# $(call NEED,<binary>,<PIN_KEY>) aborts with an install hint when a tool a
# present lane depends on is not installed. There is no path in this file that
# prints "not found" and exits 0: a missing tool is a failed target.
NEED = command -v $(1) >/dev/null 2>&1 || { printf 'error: %s is not installed but this repository needs it (pin $(2) in $(PINS); installed by .devcontainer/Dockerfile). Run "make doctor" for the full list.\n' '$(1)' '$(2)'; exit 1; }

.PHONY: help doctor fmt lint test test-fast test-all coverage validate docs clean hooks self-check

## help - list every target with its description (default goal)
help:
	@printf '%s\n' '__PROJECT_NAME__ - single command entry point'
	@printf '\n%s\n' 'Usage: make <target>'
	@grep -hE '^## [a-z0-9-]+ - ' $(MAKEFILE_PATH) | sed -E 's/^## //' | awk -F' - ' '{printf "  %-11s %s\n", $$1, $$2}'
	@printf '\n%s\n' 'Run "make doctor" first when a tool seems missing; "make validate" is the full local gate.'

## doctor - prove each present lane's pins have a consumer and answer --version
doctor:
	@set -eu; \
	fail=0; \
	if [ ! -r $(PINS) ]; then printf 'error: %s is not readable\n' '$(PINS)'; exit 1; fi; \
	set -a; . ./$(PINS); set +a; \
	keys=$$(grep -E '^[A-Z0-9_]+=' $(PINS) | cut -d= -f1); \
	if [ -z "$$keys" ]; then printf 'error: %s declares no KEY=version lines\n' '$(PINS)'; exit 1; fi; \
	if [ -r $(RUNNER) ]; then lanes=$$(bash $(RUNNER) --lanes 2>/dev/null | tr '\n' ' '); else lanes='shell python typescript go'; fi; \
	printf '== doctor ==\n'; \
	printf -- '-> lanes present: %s\n' "$${lanes:-none}"; \
	printf -- '-> consumer audit\n'; \
	for key in $$keys; do \
	hit=0; \
	for f in $(CONSUMERS); do \
	if [ -f "$$f" ] && grep -q -- "$$key" "$$f"; then hit=1; fi; \
	done; \
	if [ "$$hit" -eq 0 ]; then printf 'error: %s has no consumer in: %s (delete the key and its consumer line together)\n' "$$key" '$(CONSUMERS)'; fail=1; fi; \
	done; \
	printf -- '-> version probe\n'; \
	for key in $$keys; do \
	pinlane=$$(awk -v k="$$key" '/^# -- /{ln="core"; if (match($$0, /-- [A-Za-z]+ lane/)) {ln=tolower(substr($$0, RSTART+3, RLENGTH-8))}} /^[A-Z0-9_]+=/ {split($$0, a, "="); if (a[1]==k) {print ln; exit}}' $(PINS)); \
	if [ -n "$$pinlane" ] && [ "$$pinlane" != core ] && ! printf ' %s ' "$$lanes" | grep -q " $$pinlane "; then \
	printf 'note: %s is a %s-lane pin and no %s lane is in this checkout; not required\n' "$$key" "$$pinlane" "$$pinlane"; \
	continue; \
	fi; \
	want=$${!key}; \
	if [ -z "$$want" ]; then printf 'error: %s has an empty value\n' "$$key"; fail=1; continue; fi; \
	case "$$key" in \
	SHELLCHECK_VERSION) bin=shellcheck; cmd='shellcheck --version' ;; \
	SHFMT_VERSION) bin=shfmt; cmd='shfmt --version' ;; \
	BATS_VERSION) bin=bats; cmd='bats --version' ;; \
	YAMLLINT_VERSION) bin=yamllint; cmd='yamllint --version' ;; \
	PRE_COMMIT_VERSION) bin=pre-commit; cmd='pre-commit --version' ;; \
	GITLEAKS_VERSION) bin=gitleaks; cmd='gitleaks version' ;; \
	PRETTIER_VERSION) bin=prettier; cmd='prettier --version' ;; \
	RUFF_VERSION) bin=ruff; cmd='ruff --version' ;; \
	MYPY_VERSION) bin=mypy; cmd='mypy --version' ;; \
	PYTEST_VERSION) bin=python3; cmd='python3 -m pytest --version' ;; \
	NODE_VERSION) bin=node; cmd='node --version' ;; \
	TYPESCRIPT_VERSION) bin=tsc; cmd='tsc --version' ;; \
	ESLINT_VERSION) bin=eslint; cmd='eslint --version' ;; \
	VITEST_VERSION) bin=vitest; cmd='vitest --version' ;; \
	GO_VERSION) bin=go; cmd='go version' ;; \
	GOLANGCI_LINT_VERSION) bin=golangci-lint; cmd='golangci-lint --version' ;; \
	*) printf 'error: %s has no doctor probe; add a case to the doctor target\n' "$$key"; fail=1; continue ;; \
	esac; \
	if ! command -v "$$bin" >/dev/null 2>&1; then \
	printf 'error: %s (the tool behind %s=%s) is not on PATH; rebuild the dev container or install it per .devcontainer/Dockerfile\n' "$$bin" "$$key" "$$want"; fail=1; continue; \
	fi; \
	if ! out=$$($$cmd 2>&1 | head -n 3); then \
	printf 'error: probe command failed: %s\n' "$$cmd"; fail=1; continue; \
	fi; \
	if printf '%s\n' "$$out" | grep -qF -- "$$want"; then \
	printf 'ok: %s reports %s\n' "$$bin" "$$want"; \
	else \
	printf 'error: %s does not report %s (expected pin for %s); got: %s\n' "$$bin" "$$want" "$$key" "$$(printf '%s\n' "$$out" | head -n 1)"; fail=1; \
	fi; \
	done; \
	if [ "$$fail" -ne 0 ]; then printf 'error: doctor is red; fix the pins or the toolchain before any other target\n'; exit 1; fi; \
	printf 'ok: every pin this checkout needs has a consumer and answers --version\n'

## fmt - rewrite code into canonical form (shfmt plus each present lane's formatter)
fmt:
	@set -eu; \
	printf '== fmt ==\n'; \
	$(call NEED,shfmt,SHFMT_VERSION); \
	count=$$($(FIND_SH) | wc -l | tr -d ' '); \
	if [ "$$count" -gt 0 ]; then printf -- '-> shfmt (%s file(s))\n' "$$count"; $(FIND_SH) -exec shfmt -i 2 -ci -w {} +; printf 'ok: shfmt wrote %s file(s)\n' "$$count"; else printf 'warning: no .sh files found, nothing for shfmt to do\n'; fi; \
	if [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -d tests/python ] || ls tests/test_*.py tests/*_test.py >/dev/null 2>&1; then \
	$(call NEED,ruff,RUFF_VERSION); printf -- '-> ruff format\n'; ruff format .; printf 'ok: ruff format done\n'; \
	fi; \
	if [ -f package.json ]; then \
	$(call NEED,prettier,PRETTIER_VERSION); printf -- '-> prettier\n'; prettier --write '**/*.{ts,tsx,js,mjs,cjs,json,md}' >/dev/null; printf 'ok: prettier done\n'; \
	fi; \
	if [ -f go.mod ]; then \
	$(call NEED,go,GO_VERSION); printf -- '-> go fmt\n'; go fmt ./...; printf 'ok: go fmt done\n'; \
	fi; \
	if ls *.md docs/*.md docs/**/*.md >/dev/null 2>&1; then \
	$(call NEED,prettier,PRETTIER_VERSION); printf -- '-> prettier (markdown)\n'; prettier --write 'docs/**/*.md' './*.md' >/dev/null; printf 'ok: markdown formatted\n'; \
	fi

## lint - run every static check for the lanes that are present (a missing tool fails)
lint:
	@set -eu; \
	printf '== lint ==\n'; \
	$(call NEED,shellcheck,SHELLCHECK_VERSION); \
	$(call NEED,shfmt,SHFMT_VERSION); \
	printf -- '-> shellcheck -x --severity=warning\n'; \
	if $(FIND_SH) | grep -q .; then $(FIND_SH) -exec shellcheck -x --severity=warning {} +; printf 'ok: shellcheck clean\n'; else printf 'warning: no .sh files to check\n'; fi; \
	printf -- '-> shfmt -d -i 2 -ci\n'; \
	if $(FIND_SH) | grep -q .; then $(FIND_SH) -exec shfmt -d -i 2 -ci {} +; printf 'ok: shfmt clean\n'; else printf 'warning: no .sh files to check\n'; fi; \
	$(call NEED,yamllint,YAMLLINT_VERSION); \
	if find . -maxdepth 2 -type f \( -name '*.yml' -o -name '*.yaml' \) -not -path './node_modules/*' | grep -q .; then \
	printf -- '-> yamllint\n'; find . -maxdepth 2 -type f \( -name '*.yml' -o -name '*.yaml' \) -not -path './node_modules/*' -exec yamllint -c .yamllint.yml {} +; printf 'ok: yamllint clean\n'; \
	else printf 'warning: no YAML files to check\n'; fi; \
	if [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -d tests/python ] || ls tests/test_*.py tests/*_test.py >/dev/null 2>&1; then \
	$(call NEED,ruff,RUFF_VERSION); printf -- '-> ruff check\n'; ruff check .; ruff format --check .; printf 'ok: ruff clean\n'; \
	$(call NEED,mypy,MYPY_VERSION); printf -- '-> mypy\n'; mypy .; printf 'ok: mypy clean\n'; \
	fi; \
	if [ -f package.json ]; then \
	$(call NEED,eslint,ESLINT_VERSION); printf -- '-> eslint\n'; eslint .; printf 'ok: eslint clean\n'; \
	$(call NEED,tsc,TYPESCRIPT_VERSION); printf -- '-> tsc --noEmit\n'; tsc --noEmit; printf 'ok: tsc clean\n'; \
	fi; \
	if [ -f go.mod ]; then \
	$(call NEED,golangci-lint,GOLANGCI_LINT_VERSION); printf -- '-> golangci-lint run\n'; golangci-lint run ./...; printf 'ok: golangci-lint clean\n'; \
	fi

## test - run every language lane present (delegates to tests/run.sh)
test:
	@set -eu; \
	if [ ! -r $(RUNNER) ]; then printf 'error: %s is missing; every test run goes through it\n' '$(RUNNER)'; exit 1; fi; \
	bash $(RUNNER)

## test-fast - cheapest check that can still fail you: lane plan plus the shell lane
test-fast:
	@set -eu; \
	if [ ! -r $(RUNNER) ]; then printf 'error: %s is missing\n' '$(RUNNER)'; exit 1; fi; \
	printf '== test-fast ==\n'; \
	bash $(RUNNER) --list; \
	if ls tests/*.bats >/dev/null 2>&1; then bash $(RUNNER) --lane shell; \
	else printf 'warning: no shell lane tests, so test-fast ran none; use make test\n'; fi

## test-all - the expensive hermetic gate: lint, every lane, coverage, docs
test-all: lint test coverage docs
	@printf 'summary: test-all finished: lint, every lane, coverage, docs\n'

## coverage - measure coverage per lane (lanes with no coverage tool are reported, not hidden)
coverage:
	@set -eu; \
	printf '== coverage ==\n'; ran=0; \
	if ls tests/*.bats >/dev/null 2>&1; then printf 'warning: the shell lane has no coverage gate; make test is its gate\n'; fi; \
	if [ -f pyproject.toml ] || [ -f pytest.ini ] || ls tests/test_*.py tests/*_test.py >/dev/null 2>&1; then \
	$(call NEED,python3,PYTEST_VERSION); \
	if ! python3 -m coverage --version >/dev/null 2>&1; then printf 'error: python lane needs coverage (python3 -m pip install coverage)\n'; exit 1; fi; \
	printf -- '-> python coverage\n'; python3 -m coverage run -m pytest -q tests && python3 -m coverage report -m; ran=1; \
	fi; \
	if [ -f package.json ]; then \
	$(call NEED,npm,NODE_VERSION); \
	if grep -q '"coverage"[[:space:]]*:' package.json; then printf -- '-> typescript coverage\n'; npm run coverage --silent; ran=1; \
	elif grep -q '"test:coverage"[[:space:]]*:' package.json; then printf -- '-> typescript coverage\n'; npm run test:coverage --silent; ran=1; \
	else printf 'warning: package.json declares no coverage script; the typescript lane is unmeasured\n'; fi; \
	fi; \
	if [ -f go.mod ]; then \
	$(call NEED,go,GO_VERSION); printf -- '-> go coverage\n'; go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out | tail -n 1; ran=1; \
	fi; \
	if [ "$$ran" -eq 0 ]; then printf 'warning: no lane with a coverage tool is present; nothing was measured\n'; fi

## validate - the local gate CI mirrors: doctor, lint, test, docs
validate: doctor lint test docs
	@printf 'summary: validate passed: doctor, lint, test, docs\n'

## docs - strict documentation build: format check, link audit, ADR numbering audit
docs:
	@set -eu; fail=0; \
	printf '== docs ==\n'; \
	$(call NEED,prettier,PRETTIER_VERSION); \
	printf -- '-> prettier --check (markdown and yaml)\n'; \
	if ! prettier --check '**/*.md' '**/*.yml' '**/*.yaml' >/dev/null; then \
	printf 'error: documentation is not prettier-clean; run "make fmt"\n'; fail=1; \
	else printf 'ok: markdown and YAML are prettier-clean\n'; fi; \
	printf -- '-> relative link audit\n'; \
	while IFS= read -r md; do \
	while IFS= read -r link; do \
	case "$$link" in ''|http://*|https://*|mailto:*|'|'*) continue ;; esac; \
	target=$${link%%#*}; [ -n "$$target" ] || continue; \
	if [ ! -e "$${md%/*}/$$target" ] && [ ! -e "$$target" ]; then printf 'error: %s links to a missing file: %s\n' "$$md" "$$link"; fail=1; fi; \
	done < <(grep -oE '\]\([^)]+\)' "$$md" 2>/dev/null | sed -E 's/^\]\(//; s/\)$$//'); \
	done < <(find docs -type f -name '*.md' 2>/dev/null; find . -maxdepth 1 -name '*.md'); \
	printf -- '-> ADR numbering audit\n'; \
	if [ -d docs/adr ]; then \
	nums=$$(find docs/adr -maxdepth 1 -type f -name '[0-9][0-9][0-9][0-9]-*.md' -exec basename {} .md \; | cut -d- -f1 | sort); \
	if [ -z "$$nums" ]; then printf 'error: docs/adr/ has no numbered ADR; copy docs/adr/template.md\n'; fail=1; \
	else \
	if [ "$$(printf '%s\n' $$nums | uniq -d | wc -l)" -gt 0 ]; then printf 'error: duplicate ADR numbers: %s\n' "$$(printf '%s\n' $$nums | uniq -d | tr '\n' ' ')"; fail=1; fi; \
	expected=1; for n in $$nums; do \
	if [ "$$((10#$$n))" -ne "$$expected" ]; then printf 'error: ADR numbers must be gapless; found %s, expected %s\n' "$$n" "$$expected"; fail=1; fi; \
	expected=$$((expected + 1)); done; \
	if [ ! -f docs/adr/template.md ]; then printf 'error: docs/adr/template.md is missing\n'; fail=1; fi; \
	fi; \
	else printf 'error: docs/adr/ is missing\n'; fail=1; fi; \
	if [ "$$fail" -ne 0 ]; then printf 'error: docs is red; documentation is a built artifact, not decoration\n'; exit 1; fi; \
	printf 'ok: docs build clean\n'

## clean - remove generated artifacts (node_modules only with CLEAN_ALL=1)
clean:
	@set -eu; \
	printf '== clean ==\n'; \
	for d in .pytest_cache .mypy_cache .ruff_cache .coverage htmlcov coverage coverage.xml dist build; do \
	if [ -e "$$d" ]; then rm -rf -- "$$d"; printf -- '-> removed %s\n' "$$d"; fi; \
	done; \
	find . -type d -name __pycache__ -not -path './node_modules/*' -prune -exec rm -rf -- {} + ; \
	if [ "$${CLEAN_ALL:-0}" = "1" ]; then if [ -d node_modules ]; then rm -rf -- node_modules; printf -- '-> removed node_modules\n'; fi; fi; \
	printf 'ok: clean\n'

## hooks - install the git hooks declared in .pre-commit-config.yaml
hooks:
	@set -eu; \
	printf '== hooks ==\n'; \
	$(call NEED,pre-commit,PRE_COMMIT_VERSION); \
	if [ ! -f .pre-commit-config.yaml ]; then printf 'error: .pre-commit-config.yaml is missing; restore it before installing hooks\n'; exit 1; fi; \
	printf -- '-> pre-commit install --install-hooks\n'; \
	pre-commit install --install-hooks; \
	printf 'ok: hooks installed from .pre-commit-config.yaml (%s)\n' "$$(pre-commit --version)"

## self-check - run the template's own conformance suite (absent in a rendered project)
self-check:
	@set -eu; \
	if [ -d .self-check ]; then \
	if [ ! -f .self-check/run.sh ]; then printf 'error: .self-check/ is present but .self-check/run.sh is not; restore it before running this target\n'; exit 1; fi; \
	bash .self-check/run.sh; \
	else printf 'note: .self-check/ is generator-owned and not in this tree; the template suite is absent by design in a rendered project, so there is nothing to run\n'; fi
