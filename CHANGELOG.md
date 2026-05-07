# Changelog

All notable changes to agent-test-env will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
