# Architecture

## System Overview

agent-test-env provides a Docker-based multi-agent test environment. Each AI coding agent runs in an isolated container with shared read-only fixture mounts. A standardized lifecycle script API enables consistent testing across all agents.

```
┌────────────────────────────────────────────────────────────┐
│  agent-test-env                                            │
│                                                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │ OpenCode │  │ Claude   │  │  Codex   │  ... 5 agents    │
│  │ node:22  │  │  Code    │  │  CLI     │                 │
│  │ alpine   │  │ node:22  │  │ py:3.12  │                 │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                 │
│       │             │             │                        │
│       └─────────────┼─────────────┘                        │
│                     │                                      │
│           ┌─────────▼─────────┐                            │
│           │   /fixtures (ro)  │   ← Shared read-only mount │
│           │   test-skill/     │                            │
│           │   test-mcp-server │                            │
│           └───────────────────┘                            │
│                     │                                      │
│          agent-test-network (bridge)                       │
└────────────────────────────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ test-framework  │  ← Orchestration script
                    │ .sh             │
                    │ verify → test   │
                    │ → clean         │
                    └─────────────────┘
```

## Component Design

### Docker Compose Topology

- **5 containerized agents** (opencode, claude-code, codex-cli, gemini-cli, continue)
- **1 scripts-only framework** (cursor — GUI-only, tested via config-file manipulation)
- **Shared bridge network** (`agent-test-network`) for inter-container communication
- **Read-only fixture mount** (`./fixtures:/fixtures:ro`) on all containerized agents
- **Healthchecks** on all containers using `verify.sh`

### Lifecycle Script API

Every framework provides an identical contract:

```
frameworks/<agent>/scripts/
├── _lib.sh      → log(), log_ok(), log_warn(), log_error()
├── install.sh   → Install agent CLI (npm/pip)
├── verify.sh    → Check agent is functional (--version)
├── test.sh      → Install fixture as symlink, verify exists
└── clean.sh     → Remove symlinks, reset state
```

### test-framework.sh Orchestrator

```
test-framework.sh <framework> <fixture>
         │
         ▼
  ┌──────────────────┐
  │ Check container   │
  │ running           │── no ──→ docker compose up -d
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ docker exec       │
  │ verify.sh         │── fail ──→ warn (non-fatal)
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ docker exec       │
  │ test.sh <fixture> │── fail ──→ RESULT: FAIL (exit 1)
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ docker exec       │
  │ clean.sh          │
  └──────┬───────────┘
         │
         ▼
    RESULT: PASS (exit 0)
```

## Data Flow

### Fixture Installation Flow

1. Fixture source: `fixtures/<name>/` on host
2. Mounted read-only at `/fixtures/<name>/` inside each container
3. `test.sh` creates a symlink from agent's skills directory to `/fixtures/<name>/`
4. Verifies symlink exists and is valid
5. `clean.sh` removes the symlink

No files are written to the host during testing. All state changes happen inside containers.

### Special Case: Cursor

Cursor is a GUI-only macOS application. It cannot be containerized. Instead:

- `test.sh` manipulates `~/.cursor/mcp.json` on the host
- MCP server config references `/fixtures/test-mcp-server/server.js`
- `clean.sh` removes the MCP config file
- No symlink-based skill testing (Cursor doesn't use skill directories)

## Overlay Pattern

agent-test-env is designed as a **base** that downstream projects overlay.

```
agent-test-env (base repo)
    │
    │  docker-compose.yml      ← Agent topology
    │  frameworks/             ← 6 agent Dockerfiles + scripts
    │  scripts/                ← test-framework.sh
    │  tests/                  ← BATS harness tests
    │  fixtures/               ← Default test fixtures
    │
    ▼
downstream project
    │
    │  fixtures/               ← Project-specific test capabilities
    │  fixtures.yaml           ← Declare which fixtures to test
    │  project tests           ← Additional BATS suites
    │
    ▼
  bash scripts/test-framework.sh <agent> <project-fixture>
```

The overlay never modifies agent-test-env files. Fixtures and configs are additive.

## Design Decisions

| ID | Decision | Rationale |
|----|---------|-----------|
| DEC-001 | Docker Compose v2 | Proven in wp-test-env, capacium-test-lab |
| DEC-002 | Bash lifecycle scripts | Universal, zero deps, matches existing patterns |
| DEC-003 | BATS test framework | TAP output, bash-native, git-installable |
| DEC-004 | GHCR distribution | Free for OSS, GitHub-native, proven pattern |
| DEC-005 | YAML fixture config | Declarative, overlay-friendly |
| DEC-006 | Apache 2.0 license | Matches LangeVC portfolio |
| DEC-007 | 6 agents v1 | Inherited from capacium-test-lab |
| DEC-008 | Cursor scripts-only | GUI-only app, can't be containerized |

## Adding a New Agent

1. Create `frameworks/<agent>/Dockerfile`
2. Create all 5 lifecycle scripts
3. Add service to `docker-compose.yml`
4. Add to CI matrix in `.github/workflows/test.yml`
5. Run `bash tests/run_tests.sh unit` to validate

## Security

- Agents run as root in isolated containers (no host access beyond fixture mount)
- Fixture directories mounted read-only (`:ro`)
- No secrets embedded in Docker images
- `.env` files gitignored
- GHCR images built with OIDC-based keyless signing (planned)
