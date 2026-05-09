# Product Requirements Document: agent-test-env Gap Closure

**Project:** agent-test-env — Capacium Gap Closure
**Version:** 1.0.0
**Date:** 2026-05-09
**Status:** draft

---

## 1. Executive Summary

agent-test-env is a Docker-based multi-agent test infrastructure for AI coding agents (OpenCode, Claude Code, Codex CLI, Gemini CLI, Continue.dev, Cursor). A gap analysis between agent-test-env and its downstream overlay capacium-test-lab revealed critical infrastructure bugs that break all Docker-based CI, missing fixtures covering all capability kinds, missing test infrastructure patterns, and documentation gaps. This PRD defines the work needed to close those gaps — making agent-test-env a more complete, production-grade foundation for any overlay project.

### Key Objectives

1. **Unblock CI**: Fix Dockerfiles so containers stay alive and HEALTHCHECK works
2. **Complete fixture coverage**: Add 10 new fixtures covering all 8 capability kinds + edge cases
3. **Test infrastructure**: Port fixture registry, helper expansions, MCP live test, provisioning scripts
4. **Documentation**: Add HOWTO.md, FIXTURES.md, CI.md
5. **Docker improvements**: Named volumes, healthchecks, `docker compose wait` pattern

---

## 2. Problem Statement

### Current Situation

agent-test-env's 5 Dockerfiles end at `HEALTHCHECK` with no `CMD`. The base image default process needs stdin — with `docker compose up -d`, stdin closes and the process exits immediately. Containers last under 1 second. This means:

- All Docker-based CI is broken
- `docker compose exec` fails with "Container not running"
- HEALTHCHECK never executes
- The entire test infrastructure is unusable in CI

Additionally, the test infrastructure is minimal: 2 fixtures (test-skill, test-mcp-server), a 3-line `helpers.bash`, no fixture registry, no documentation beyond README.

### Existing Alternatives

- **capacium-test-lab** (overlay): Worked around these bugs by rewriting Dockerfiles and adding extensive test infrastructure — but the fixes belong upstream in agent-test-env

### Opportunity

By fixing the root cause (missing CMD) and porting generic improvements from capacium-test-lab, agent-test-env becomes a reliable foundation for any AI agent test project — not just Capacium.

---

## 3. Target Users

### Primary: Downstream Overlay Projects
Projects that use agent-test-env as a base for testing their own agent capabilities (Capacium and others). They need:
- Working Docker containers in CI
- Comprehensive fixture coverage for all capability kinds
- Clear documentation for extending the test infrastructure

### Secondary: Framework Contributors
Developers adding new agent frameworks to agent-test-env. They need:
- Reliable container lifecycle
- Standardized patterns for scripts, fixtures, tests
- Clear contribution guides

---

## 4. Solution Overview

### Phase A: Critical Infrastructure Fixes (P0)
Fix all 5 Dockerfiles: add `CMD ["tail", "-f", "/dev/null"]` to keep containers alive, bake `RUN install.sh` at build time, add `--start-period=30s` to HEALTHCHECK. Add `die()` and `check_fixture()` to all `_lib.sh` scripts. Make all `verify.sh` scripts fatal (exit 1 on missing agent). Replace `sleep 5` kludge with `docker compose wait`.

### Phase B: Fixture Expansion (P0)
Add 10 new fixtures from capacium-test-lab covering all 8 capability kinds: test-tool, test-prompt, test-template, test-workflow, test-connector-pack, test-bundle, test-dependency, test-runtimes-skill, test-broken-manifest, test-signed-cap. Each fixture includes a `capability.yaml` with `name`, `version`, `kind`, and agent-test-env authorship.

### Phase C: Test Infrastructure (P1)
Add `fixtures.json` registry for auto-discovery. Expand `tests/helpers.bash` from 3 to 49 lines with fixture discovery, cleanup, and install functions (renamed from `cap_*` to `fixture_*`). Add `tests/integration/test_verify_all.bats` and `tests/smoke/test_signature.bats`. Port `scripts/test-mcp-live.sh`, `scripts/provision.sh`, `scripts/ci-entrypoint.sh`.

### Phase D: Documentation & Docker Improvements (P2)
Add `docs/HOWTO.md`, `docs/FIXTURES.md`, `docs/CI.md`. Add named volumes for skill persistence in `docker-compose.yml`. Add healthcheck on opencode service. Auto-install BATS in `tests/run_tests.sh`.

---

## 5. Functional Requirements

### 5.1 Core Features

**Feature: Docker Container Lifespan Fix**
- Description: All 5 framework Dockerfiles must produce containers that stay alive indefinitely
- Priority: Critical
- Acceptance Criteria:
  1. `docker compose up -d` keeps containers running (not exiting in <1s)
  2. `docker compose ps` shows all services as "Up (healthy)"
  3. `docker compose exec <service> /scripts/verify.sh` returns 0
  4. HEALTHCHECK reports healthy within 60 seconds of startup
  5. `docker compose wait <service>` returns 0 (not timeout)
- Dependencies: None

**Feature: Build-Time Agent Installation**
- Description: Install agent CLI at Docker build time, not runtime
- Priority: Critical
- Acceptance Criteria:
  1. `RUN /scripts/install.sh` executes during `docker compose build` and succeeds
  2. No `npm install` or `pip install` runs at container startup
  3. `verify.sh` confirms agent binary exists after `docker compose up`
- Dependencies: FEAT-001

**Feature: Fatal verify.sh**
- Description: All verify.sh scripts exit 1 when agent is not installed
- Priority: High
- Acceptance Criteria:
  1. claude-code `verify.sh` exits 1 when claude not found (currently exits 0)
  2. gemini-cli `verify.sh` exits 1 when gemini not found
  3. continue `verify.sh` exits 1 when continue not found
  4. HEALTHCHECK correctly reports unhealthy for failed installs
- Dependencies: FEAT-002

**Feature: _lib.sh Enhancement**
- Description: Add `die()` and `check_fixture()` functions to all framework `_lib.sh` files
- Priority: High
- Acceptance Criteria:
  1. All 6 `_lib.sh` files define `die()` function (logs error + exits 1)
  2. All 6 `_lib.sh` files define `check_fixture()` function (validates fixture dir + capability.yaml)
  3. `check_fixture` exits with clear error message on missing/invalid fixture
- Dependencies: None

**Feature: docker compose wait Pattern**
- Description: Replace sleep-based polling with `docker compose wait` in test-framework.sh and CI
- Priority: High
- Acceptance Criteria:
  1. `scripts/test-framework.sh` uses `docker compose wait` instead of `sleep 5`
  2. `.github/workflows/test.yml` uses `docker compose wait` instead of `sleep`+`grep` polling
  3. No arbitrary sleep delays in test orchestration
- Dependencies: FEAT-001

**Feature: 10 New Fixtures**
- Description: Port all generic fixtures from capacium-test-lab with agent-test-env authorship
- Priority: High
- Acceptance Criteria:
  1. `fixtures/test-tool/` exists with `capability.yaml` (kind: tool) and `tool.sh`
  2. `fixtures/test-prompt/` exists with `capability.yaml` (kind: prompt) and `prompt.md`
  3. `fixtures/test-template/` exists with `capability.yaml` (kind: template) and `template.md`
  4. `fixtures/test-workflow/` exists with `capability.yaml` (kind: workflow) and `workflow.md`
  5. `fixtures/test-connector-pack/` exists with `capability.yaml` (kind: connector-pack) and `connectors.json`
  6. `fixtures/test-bundle/` exists with bundle structure + sub-skill + sub-tool
  7. `fixtures/test-dependency/` exists with capability.yaml declaring dependencies
  8. `fixtures/test-runtimes-skill/` exists with runtime requirements
  9. `fixtures/test-broken-manifest/` exists with intentionally invalid capability.yaml
  10. `fixtures/test-signed-cap/` exists for signing/verification tests
  11. All `capability.yaml` files have `author: agent-test-env`
  12. All `capability.yaml` files have valid `name`, `version`, `kind` fields
- Dependencies: None

**Feature: fixtures.json Registry**
- Description: Central JSON registry for auto-discovery of all test fixtures
- Priority: Medium
- Acceptance Criteria:
  1. `fixtures.json` exists at repository root
  2. Contains JSON array of 12 entries (name, kind, version)
  3. `tests/helpers.bash` uses `fixtures.json` for `ALL_CAP_KINDS` auto-discovery
  4. Adding a new fixture to `fixtures/` + updating `fixtures.json` makes it discoverable by tests
- Dependencies: FEAT-006

**Feature: Expanded tests/helpers.bash**
- Description: Replace 3-line stub with full test helper infrastructure
- Priority: Medium
- Acceptance Criteria:
  1. Exports `TEST_LAB_ROOT`, `FIXTURES_DIR` variables
  2. Auto-discovers `ALL_CAP_KINDS` from `fixtures.json`
  3. Provides `fixture_cleanup()`, `fixture_install()`, `fixture_remove()` functions
  4. No `cap_*` naming — all functions use generic `fixture_*` prefix
  5. Sourced correctly by all BATS test files
- Dependencies: FEAT-007

**Feature: New Test Scripts**
- Description: Port test-mcp-live.sh, provision.sh, ci-entrypoint.sh
- Priority: Medium
- Acceptance Criteria:
  1. `scripts/test-mcp-live.sh` performs MCP JSON-RPC handshake (initialize + tools/list)
  2. `scripts/provision.sh` starts containers and creates skill directories
  3. `scripts/ci-entrypoint.sh` orchestrates framework+capability test combinations
  4. All scripts pass `bash -n` syntax check
  5. All scripts are executable (`chmod +x`)
- Dependencies: FEAT-001

**Feature: Documentation**
- Description: Add HOWTO.md, FIXTURES.md, CI.md to `docs/`
- Priority: Low
- Acceptance Criteria:
  1. `docs/HOWTO.md` covers BATS patterns, JSON validation, debugging
  2. `docs/FIXTURES.md` lists all 12 fixtures, how to add new ones
  3. `docs/CI.md` describes CI workflow, local testing instructions
  4. All Capacium-specific references removed, replaced with agent-test-env context
- Dependencies: FEAT-006, FEAT-007

**Feature: Docker Compose Improvements**
- Description: Add named volumes, healthchecks, explicit build blocks
- Priority: Low
- Acceptance Criteria:
  1. Named volumes for opencode/claude/codex/gemini/continue skill directories
  2. Healthcheck on opencode service with `depends_on: condition: service_healthy`
  3. Explicit `build: { context: ..., dockerfile: ... }` blocks (not ambiguous paths)
  4. Compose version bump from 3.8 to 3.9
- Dependencies: FEAT-001

**Feature: Auto-Install BATS in run_tests.sh**
- Description: `tests/run_tests.sh` auto-installs BATS if not found on PATH
- Priority: Low
- Acceptance Criteria:
  1. Running `bash tests/run_tests.sh all` on a system without BATS auto-installs it
  2. BATS installed to `/tmp` or similar — no system-level mutation
  3. Does not re-install if BATS already available
- Dependencies: None

### 5.2 User Stories

- As a downstream overlay maintainer, I want Docker containers to stay alive so my CI pipeline passes
- As a fixture developer, I want a registry file so I can add capabilities without modifying test code
- As a CI operator, I want `docker compose wait` instead of `sleep` so tests are fast and reliable
- As a new contributor, I want documentation explaining how fixtures, tests, and CI work

---

## 6. Non-Functional Requirements

### Performance
- All 5 containers must reach healthy state within 60 seconds of `docker compose up`
- `docker compose wait` must poll at the interval specified by HEALTHCHECK, not arbitrary sleep

### Reliability
- `install.sh` must succeed during `docker build` — builds must be reproducible
- `clean.sh` must remain idempotent (succeed even when no fixtures exist)

### Compatibility
- Changes must not break the overlay pattern: downstream `test.sh` overrides must still work
- `$1` fixture parameter contract in `test.sh` must be preserved

### Security
- Fix `curl | bash` patterns in install.sh scripts — validate downloaded content
- `apk add` / `apt-get install` must use `--no-cache` / clean up to minimize image size

---

## 7. Technical Architecture

### Docker Container Lifecycle

```
docker compose build        →  RUN install.sh (bakes agent CLI)
docker compose up -d        →  CMD tail -f /dev/null (stays alive)
HEALTHCHECK --start-period=30s → verify.sh (probes every 10s)
docker compose wait <svc>   →  blocks until healthy
docker compose exec <svc>   →  /scripts/test.sh <fixture>
```

### Overlay Pattern (unchanged)

```
agent-test-env (base)              Overlay (e.g., Capacium)
─────────────────────              ─────────────────────────
frameworks/*/Dockerfile            ← kept as-is (now with CMD!)
frameworks/*/scripts/_lib.sh       ← kept as-is (now with die/check_fixture)
frameworks/*/scripts/install.sh    ← kept as-is
frameworks/*/scripts/verify.sh     ← kept as-is (now fatal)
frameworks/*/scripts/clean.sh      ← kept as-is
frameworks/*/scripts/test.sh       → OVERRIDDEN by overlay
fixtures/*                         → EXTENDED by overlay
fixtures.json                      → EXTENDED by overlay
docker-compose.yml                 → EXTENDED by overlay
```

### File Changes Map

| Change | Files Affected |
|--------|---------------|
| CMD + build-time install | 5 Dockerfiles |
| --start-period | 5 Dockerfiles |
| die() + check_fixture() | 6 _lib.sh files |
| Fatal verify.sh | 3 verify.sh files |
| docker compose wait | test-framework.sh, test.yml |
| New fixtures | 10 new directories in fixtures/ |
| fixtures.json | 1 new file |
| Expanded helpers.bash | 1 file |
| New test scripts | 3 new script files |
| Docs | 3 new doc files |
| Docker compose improvements | 1 file |
| Auto-install BATS | run_tests.sh |

---

## 8. Success Metrics (Binary & Testable)

| # | Metric | Target | Measurement |
|---|--------|--------|-------------|
| 1 | Containers stay alive | 5/5 services Up (healthy) | `docker compose ps` |
| 2 | CI matrix passes | 12/12 jobs (6 agents × 2 fixtures) | GitHub Actions test.yml |
| 3 | HEALTHCHECK works | All services healthy within 60s | `docker compose wait` exit 0 |
| 4 | verify.sh is fatal | 3 previously non-fatal scripts now exit 1 | `bash scripts/verify.sh; echo $?` |
| 5 | All fixture kinds covered | 12 fixtures across 8 kinds | `ls fixtures/*/capability.yaml \| wc -l` = 12 |
| 6 | No sleep polling | 0 occurrences of `sleep` in test orchestration | `grep -r sleep scripts/test-framework.sh .github/workflows/test.yml` |
| 7 | BATS auto-install works | `bash tests/run_tests.sh all` succeeds on bare system | Fresh container test |
| 8 | fixtures.json valid | JSON parses, all entries have name/kind/version | `python3 -c "import json; json.load(open('fixtures.json'))"` |
| 9 | helpers.bash sourced correctly | All BATS tests source helpers without error | `bats tests/` |
| 10 | No Capacium references in base | 0 occurrences of "capacium" in source files | `grep -ri capacium fixtures/ docs/ scripts/ tests/ \| grep -v .git` |

---

## 9. Scope & Constraints

### In Scope (This PRD)
- Fix all 5 Dockerfiles (CMD, build-time install, start-period)
- Add `die()` and `check_fixture()` to 6 `_lib.sh` files
- Make 3 verify.sh scripts fatal
- Replace sleep polling with `docker compose wait` in 2 files
- Add 10 new fixtures to `fixtures/`
- Add `fixtures.json` registry
- Expand `tests/helpers.bash`
- Add `scripts/test-mcp-live.sh`, `scripts/provision.sh`, `scripts/ci-entrypoint.sh`
- Add `docs/HOWTO.md`, `docs/FIXTURES.md`, `docs/CI.md`
- Named volumes, healthchecks, auto-install BATS

### Out of Scope
- `framework.env` DRY config (nice-to-have, future PRD)
- GHCR pre-built images (documentation only, no implementation)
- `tests/cli/` BATS tests (Capacium-specific `cap` CLI testing)
- `Dockerfile.runner` (Capacium-specific test-runner container)
- `cursor` framework Docker support
- Capacity for parallel test-lab instances (`PROJECT_NAME` env)
- Changes to framework `test.sh` files (these are the overlay injection point)

### Constraints
- Must preserve backward compatibility with capacium-test-lab overlay
- Must not introduce Capacium-specific naming (`cap` prefixes, author branding)
- All new fixtures must use `author: agent-test-env` in `capability.yaml`

---

## 10. Timeline & Milestones

### Milestone 1: CI Unblocked (Phase A)
- **Deliverables**: All 5 Dockerfiles fixed, _lib.sh enhanced, verify.sh fatal, sleep removed
- **Estimate**: 30 minutes
- **Dependencies**: None
- **Verification**: `docker compose up -d && docker compose ps` shows all healthy

### Milestone 2: Fixtures Complete (Phase B)
- **Deliverables**: 10 new fixtures + fixtures.json
- **Estimate**: 45 minutes
- **Dependencies**: None (parallel with Milestone 1)
- **Verification**: All 12 `capability.yaml` files parse, fixtures.json valid

### Milestone 3: Test Infrastructure (Phase C)
- **Deliverables**: helpers.bash, test-mcp-live.sh, provision.sh, ci-entrypoint.sh, new BATS tests
- **Estimate**: 20 minutes
- **Dependencies**: Milestone 2 (needs fixtures.json)
- **Verification**: `bash tests/run_tests.sh all` passes

### Milestone 4: Docs & Polish (Phase D)
- **Deliverables**: docs/, docker-compose improvements, auto-install BATS
- **Estimate**: 15 minutes
- **Dependencies**: Milestones 1-3
- **Verification**: CI matrix fully green

---

## 11. Resource Requirements

### Development
- 1 developer, ~2 hours total implementation time
- Access to capacium-test-lab repository for fixture copying
- Docker daemon for local testing

### Infrastructure
- Existing GitHub Actions CI
- Docker Hub / GHCR for base images (unchanged)

---

## 12. Assumptions & Dependencies

### Key Assumptions
1. **`tail -f /dev/null` is available in all base images** — Impact if wrong: Need alternative keep-alive (e.g., `sleep infinity`). Validation: Test on all 5 base images (node:22-alpine, python:3.12-slim)
2. **`docker compose wait` is available in CI runner Docker version** — Impact if wrong: Fallback to health polling loop. Validation: Check CI runner Docker version
3. **BATS auto-install from GitHub works in CI** — Impact if wrong: Pre-install BATS in CI step. Validation: Test on GitHub Actions ubuntu-latest
4. **Overlay projects have their own test.sh** — Impact if wrong: agent-test-env's symlink-based test.sh works as fallback. Validation: Already verified in capacium-test-lab

### External Dependencies
- capacium-test-lab repository for fixture source files (read access)
- GitHub Actions for CI execution
- Docker Hub for base images (node:22-alpine, python:3.12-slim)

### Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-----------|--------|------------|
| Container keep-alive breaks existing overlay | Low | High | Test full overlay flow before merge |
| `docker compose wait` not available in CI | Low | Medium | Feature-detect and fallback to polling |
| Fixture YAML incompatible with overlays | Medium | Medium | Keep `capability.yaml` structure identical, only change `author` field |
| Build-time install slows `docker compose build` | Low | Low | Accept trade-off for reliability |

---

## Ralph Loop Adaptations

### Binary Criteria
All acceptance criteria use pass/fail verification: container status, exit codes, file counts, grep counts. No subjective criteria.

### Task Decomposition
Tasks are atomic and independent where possible:
- Phase A (Dockerfiles) is independent of Phase B (fixtures)
- Phase B (fixtures) is independent of Phase A
- Phase C depends on Phase B (needs fixtures.json)
- Phase D depends on Phases A-C

### Memory System
- `progress.txt` tracks iteration history
- `agents.md` captures patterns (Dockerfile patterns, fixture conventions)
