# Changelog

All notable changes to agent-test-env will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-05-09

### Added

- 10 new test fixtures covering all 8 capability kinds: tool, prompt, template, workflow, connector-pack, bundle, dependency, runtimes-skill, broken-manifest, signed-cap
- `fixtures.json` central fixture registry with auto-discovery in BATS tests
- `die()` and `check_fixture()` functions to all 6 `_lib.sh` framework scripts
- `scripts/test-mcp-live.sh` — MCP JSON-RPC handshake test (initialize + tools/list)
- `scripts/provision.sh` — framework container provisioning
- `scripts/ci-entrypoint.sh` — CI matrix orchestrator
- `tests/integration/test_verify_all.bats` — script existence and executability validation
- `tests/smoke/test_signature.bats` — docker-compose structure validation
- `docs/HOWTO.md` — BATS test writing guide
- `docs/FIXTURES.md` — fixture inventory and conventions
- `docs/CI.md` — CI reference and local testing instructions
- Expanded `tests/helpers.bash` with `fixture_cleanup`, `fixture_install`, `fixture_remove` utilities
- Named Docker volumes for skill directory persistence (5 volumes)
- Healthcheck on opencode service in docker-compose.yml
- Auto-install BATS in `tests/run_tests.sh` when not found on PATH

### Changed

- All 5 Dockerfiles: added `CMD ["tail", "-f", "/dev/null"]`, `RUN /scripts/install.sh` at build time, `HEALTHCHECK --start-period=30s`
- Docker Compose version bumped from 3.8 to 3.9
- All `verify.sh` scripts now fatal (exit 1 on missing agent) — previously non-fatal for claude-code, gemini-cli, continue
- Replaced `sleep` polling with `docker compose wait` in `scripts/test-framework.sh` and `.github/workflows/test.yml`
- README rewritten with badges, architecture updates, fixture docs, release naming convention

### Fixed

- Containers exiting immediately after `docker compose up -d` (missing CMD)
- Silent `cap install` failures in overlay test.sh (now uses `--yes` flag)

### Release Naming Convention

All releases follow the pattern `AI Agent Testing Environment v<MAJOR>.<MINOR>.<PATCH>`.
Tags use strict semver: `v<MAJOR>.<MINOR>.<PATCH>`.

## [1.0.0] — 2026-05-07

### Added

- Initial release of agent-test-env — generic Docker-based AI agent test environment
- 6 agent frameworks: OpenCode, Claude Code, Codex CLI, Gemini CLI, Continue.dev, Cursor
- Standardized lifecycle script API (`_lib.sh`, `install.sh`, `verify.sh`, `test.sh`, `clean.sh`) per agent
- Docker Compose multi-service topology with shared bridge network and read-only fixture mounts
- Default test fixtures: `test-skill` (skill) and `test-mcp-server` (MCP server)
- `test-framework.sh` orchestrator for single agent+fixture testing
- BATS test suites: unit, integration, smoke
- GitHub Actions CI matrix workflow (agent × fixture)
- GHCR release workflow for pre-built Docker images
- Overlay pattern support for downstream projects
- Declarative `fixtures.yaml` configuration
- Architecture documentation (`ARCHITECTURE.md`)
- Agent developer guide (`AGENTS.md`)
- Apache 2.0 license
