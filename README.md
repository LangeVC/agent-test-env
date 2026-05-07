# agent-test-env

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)

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
├── docker-compose.yml                    ← Multi-agent stack
├── fixtures/                             ← Default test capabilities
│   ├── test-skill/
│   └── test-mcp-server/
├── frameworks/                           ← One directory per agent
│   ├── opencode/
│   │   ├── Dockerfile
│   │   └── scripts/
│   │       ├── _lib.sh                   ← Shared logging helpers
│   │       ├── install.sh               ← Install agent CLI
│   │       ├── verify.sh                ← Verify agent is functional
│   │       ├── test.sh                  ← Install fixture and verify
│   │       └── clean.sh                 ← Remove installed fixtures
│   ├── claude-code/
│   ├── codex-cli/
│   ├── gemini-cli/
│   ├── continue/
│   └── cursor/                           ← Scripts-only, no Dockerfile
├── scripts/
│   └── test-framework.sh                 ← Orchestrate one agent+fixture
├── tests/
│   ├── run_tests.sh                      ← BATS suite runner
│   ├── unit/                             ← Framework structure tests
│   ├── integration/                      ← Docker + fixture tests
│   └── smoke/                            ← YAML + volume validation
└── fixtures.yaml.example                 ← Declarative fixture config
```

### Lifecycle Script Contract

Every agent framework provides identical scripts with these contracts:

| Script | Purpose | Exit Code |
|--------|---------|-----------|
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
│  ├── fixtures.yaml           │   ← Declare your fixtures
│  └── project-specific tests  │
└──────────────────────────────┘
```

**To create an overlay:**

1. Clone `agent-test-env`
2. Create your fixtures in `fixtures/`
3. Update `fixtures.yaml` with your fixture names
4. Run `bash scripts/test-framework.sh <agent> <your-fixture>`

No code changes to agent-test-env needed.

## Testing

```bash
# Individual BATS suites
bash tests/run_tests.sh unit        # Framework structure checks
bash tests/run_tests.sh integration # Docker compose + fixture checks
bash tests/run_tests.sh smoke       # YAML + volume validation
bash tests/run_tests.sh all         # All suites

# Single agent+ficture test
bash scripts/test-framework.sh opencode test-skill
bash scripts/test-framework.sh claude-code test-mcp-server
```

## CI with GitHub Actions

CI matrix runs automatically on push/PR to `main`. All agent × fixture combinations in parallel.

See `.github/workflows/test.yml`.

## Adding a New Agent

1. Create `frameworks/<agent>/Dockerfile` with bash, git, and the agent CLI
2. Create `frameworks/<agent>/scripts/` with all 5 lifecycle scripts
3. Add the service to `docker-compose.yml`
4. Add the agent to the CI matrix in `.github/workflows/test.yml`

## License

Apache 2.0 — see [LICENSE](LICENSE)
