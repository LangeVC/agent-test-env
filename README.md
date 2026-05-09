# AI Agent Testing Environment

[![CI](https://github.com/LangeVC/agent-test-env/actions/workflows/test.yml/badge.svg)](https://github.com/LangeVC/agent-test-env/actions/workflows/test.yml)
[![Release](https://img.shields.io/badge/Release-v1.1.0-blue.svg)](https://github.com/LangeVC/agent-test-env/releases)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![BATS](https://img.shields.io/badge/Tested%20with-BATS-blue.svg)](https://github.com/bats-core/bats-core)

> Generic, reusable Docker-based test environment for AI coding agent capabilities. One command to test any capability across every AI coding agent.

## Quick Start

```bash
git clone https://github.com/LangeVC/agent-test-env.git
cd agent-test-env

# Start all agent containers
docker compose up -d

# Test a fixture on one agent
bash scripts/test-framework.sh opencode test-skill

# Run the BATS test suite (validates the harness itself)
bash tests/run_tests.sh all
```

**Prerequisites:** Docker with Compose v2 plugin.

### Using Pre-Built Docker Images

Pre-built images are available via GitHub Container Registry:

```bash
docker pull ghcr.io/langevc/agent-test-env-opencode:latest
docker pull ghcr.io/langevc/agent-test-env-claude-code:latest
docker pull ghcr.io/langevc/agent-test-env-codex-cli:latest
docker pull ghcr.io/langevc/agent-test-env-gemini-cli:latest
docker pull ghcr.io/langevc/agent-test-env-continue:latest
```

## Supported Agents

| Agent | Type | Status |
|-------|------|--------|
| [OpenCode](https://opencode.ai) | CLI | Containerized |
| [Claude Code](https://claude.ai) | CLI | Containerized |
| [Codex CLI](https://github.com/openai/codex) | CLI | Containerized |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | CLI | Containerized |
| [Continue.dev](https://continue.dev) | CLI | Containerized |
| [Cursor](https://cursor.sh) | GUI | Scripts-only (see `frameworks/cursor/README.md`) |

## Architecture

```
agent-test-env (this repo)
├── docker-compose.yml                    ← Multi-agent stack with healthchecks
├── fixtures/                             ← 12 test fixtures across 8 capability kinds
│   ├── test-skill/                       ← skill
│   ├── test-mcp-server/                  ← mcp-server
│   ├── test-tool/                        ← tool
│   ├── test-prompt/                      ← prompt
│   ├── test-template/                    ← template
│   ├── test-workflow/                    ← workflow
│   ├── test-connector-pack/              ← connector-pack
│   ├── test-bundle/                      ← bundle (sub-skill + sub-tool)
│   ├── test-dependency/                  ← skill with dependencies
│   ├── test-runtimes-skill/              ← skill with runtime requirements
│   ├── test-broken-manifest/             ← invalid manifest (error-path testing)
│   └── test-signed-cap/                  ← skill for sign/verify tests
├── fixtures.json                         ← Central fixture registry (auto-discovery)
├── frameworks/                           ← One directory per agent
│   ├── opencode/
│   │   ├── Dockerfile
│   │   └── scripts/
│   │       ├── _lib.sh                   ← Shared logging helpers + die()/check_fixture()
│   │       ├── install.sh               ← Install agent CLI
│   │       ├── verify.sh                ← Verify agent is functional (fatal on failure)
│   │       ├── test.sh                  ← Install fixture and verify
│   │       └── clean.sh                 ← Remove installed fixtures (idempotent)
│   ├── claude-code/
│   ├── codex-cli/
│   ├── gemini-cli/
│   ├── continue/
│   └── cursor/                           ← Scripts-only, no Dockerfile
├── scripts/
│   ├── test-framework.sh                 ← Orchestrate one agent+fixture
│   ├── provision.sh                      ← Provision all framework containers
│   ├── ci-entrypoint.sh                  ← CI entrypoint for matrix testing
│   └── test-mcp-live.sh                  ← MCP JSON-RPC handshake test
├── tests/
│   ├── run_tests.sh                      ← BATS suite runner (auto-installs BATS)
│   ├── helpers.bash                      ← Shared BATS helpers with fixture utilities
│   ├── unit/                             ← Framework structure tests
│   ├── integration/                      ← Docker + fixture tests
│   └── smoke/                            ← YAML + volume validation
├── docs/
│   ├── HOWTO.md                          ← Test writing guide
│   ├── FIXTURES.md                       ← Fixture inventory and conventions
│   └── CI.md                             ← CI reference and local testing
└── fixtures.yaml.example                 ← Declarative fixture config
```

### Lifecycle Script Contract

Every agent framework provides identical scripts with these contracts:

| Script | Purpose | Exit Code |
|--------|---------|-----------|
| `_lib.sh` | Shared `log`, `log_ok`, `log_warn`, `log_error`, `die`, `check_fixture` | N/A (sourced) |
| `install.sh` | Install agent CLI in the container | 0 on success |
| `verify.sh` | Confirm agent is functional | 0 on success, 1 on failure |
| `test.sh <fixture>` | Install fixture, verify it's accessible | 0 on success, 1 on failure |
| `clean.sh` | Remove installed fixtures, reset state | Always succeeds |

## Overlay Pattern

`agent-test-env` is designed as a **generic base** that downstream projects overlay with their own fixtures and tests — without forking.

```
┌──────────────────────────────┐
│  agent-test-env (base)       │
│  docker-compose.yml          │
│  frameworks/ (6 agents)      │
│  fixtures.json               │
│  scripts/test-framework.sh   │
│  tests/ (BATS suites)        │
└──────────┬───────────────────┘
           │ overlay your config
           ▼
┌──────────────────────────────┐
│  Your Project                │
│  ├── fixtures/               │   ← Your test capabilities
│  │   ├── my-skill/           │
│  │   └── my-mcp-server/      │
│  ├── fixtures.json           │   ← Register your fixtures
│  └── project-specific tests  │
└──────────────────────────────┘
```

**To create an overlay:**

1. Clone `agent-test-env`
2. Create your fixtures in `fixtures/`
3. Add entries to `fixtures.json`
4. Run `bash scripts/test-framework.sh <agent> <your-fixture>`

No code changes to agent-test-env needed.

## Testing

```bash
# Individual BATS suites
bash tests/run_tests.sh unit        # Framework structure checks
bash tests/run_tests.sh integration # Docker compose + fixture checks
bash tests/run_tests.sh smoke       # YAML + volume validation
bash tests/run_tests.sh all         # All suites

# Single agent+fixture test
bash scripts/test-framework.sh opencode test-skill
bash scripts/test-framework.sh claude-code test-mcp-server

# MCP live handshake test
bash scripts/test-mcp-live.sh
```

## CI with GitHub Actions

CI matrix runs automatically on push/PR to `main`. All agent × fixture combinations in parallel. Uses healthcheck-based `docker compose wait` (no sleep polling).

See `.github/workflows/test.yml` and `docs/CI.md`.

## Adding a New Agent

1. Create `frameworks/<agent>/Dockerfile` with bash, git, and the agent CLI
2. Ensure Dockerfile includes `RUN install.sh`, `CMD ["tail", "-f", "/dev/null"]`, and `HEALTHCHECK` with `--start-period=30s`
3. Create `frameworks/<agent>/scripts/` with all 5 lifecycle scripts
4. Add `die()` and `check_fixture()` to `_lib.sh`
5. Make `verify.sh` fatal (exit 1 on missing agent)
6. Add the service to `docker-compose.yml` with a named volume for skills
7. Add the agent to the CI matrix in `.github/workflows/test.yml`

## Adding a New Fixture

1. Create `fixtures/<name>/` directory
2. Add `capability.yaml` with `name`, `version`, `kind`, `author: agent-test-env`
3. Add fixture-specific content files (skill.md, tool.sh, server.js, etc.)
4. Add entry to `fixtures.json`
5. See `docs/FIXTURES.md` for full conventions

## Release Naming Convention

All releases follow the pattern:

```
AI Agent Testing Environment v<MAJOR>.<MINOR>.<PATCH>
```

Tags follow strict semver: `v<MAJOR>.<MINOR>.<PATCH>`

## License

Apache 2.0 — see [LICENSE](LICENSE)
