# agent-test-env — Agents Guide

## Language

English is the REQUIRED language for ALL agent-test-env content.

## Quick Start

```bash
# Start all P0 agent containers
docker compose up -d opencode claude-code codex-cli

# Test a fixture on one agent
bash scripts/test-framework.sh opencode test-skill

# Run BATS suite
bash tests/run_tests.sh all
```

## Architecture

### Directory Structure

```
agent-test-env/
├── docker-compose.yml          # 5 Docker services + shared network
├── fixtures/                   # Default test capabilities
│   ├── test-skill/
│   └── test-mcp-server/
├── frameworks/                 # One per agent
│   ├── opencode/
│   ├── claude-code/
│   ├── codex-cli/
│   ├── gemini-cli/
│   ├── continue/
│   └── cursor/                 # Scripts-only (no Dockerfile)
├── scripts/
│   └── test-framework.sh      # Orchestrate one framework+fixture
├── tests/
│   ├── run_tests.sh            # BATS suite runner
│   ├── helpers.bash            # BATS setup helper
│   ├── unit/                   # Framework structural tests
│   ├── integration/            # Docker + fixture tests
│   └── smoke/                  # YAML + volume validation
├── .github/workflows/
│   ├── test.yml                # CI matrix (agent × fixture)
│   └── release.yml             # GHCR image build + push
└── fixtures.yaml.example       # Declarative fixture config
```

### Test Suites

| Suite | Path | Purpose | Test Framework |
|-------|------|---------|---------------|
| unit | `tests/unit/` | Framework adapter unit tests | BATS |
| integration | `tests/integration/` | Docker compose + fixture checks | BATS |
| smoke | `tests/smoke/` | Fixture YAML + volume validation | BATS |

### Lifecycle Script Contract

Every framework must provide these 5 scripts:

| Script | Purpose | Exit Code | Contract |
|--------|---------|-----------|----------|
| `_lib.sh` | Shared logging helpers (`log`, `log_ok`, `log_warn`, `log_error`) | N/A (sourced) | Must define all 4 functions |
| `install.sh` | Install the agent CLI in the container | 0 on success | Should handle missing npm/pip gracefully |
| `verify.sh` | Confirm agent is functional | 0/1 | Non-fatal for P1 agents (gemini, continue, cursor) |
| `test.sh` | Install a fixture via symlink and verify | 0/1 | Accepts fixture name as `$1`, defaults to `test-skill` |
| `clean.sh` | Remove installed fixtures, reset state | Always 0 | Must be idempotent (succeed on empty state) |

### Skill/Symlink Directories per Agent

| Agent | Skills Directory |
|-------|-----------------|
| OpenCode | `~/.opencode/skills/` |
| Claude Code | `~/.claude/skills/` |
| Codex CLI | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| Continue.dev | `~/.continue/skills/` |
| Cursor | `~/.cursor/mcp.json` (MCP config, not skills) |

### Naming Conventions

- Directories: kebab-case (`claude-code/`, `test-mcp-server/`)
- Scripts: kebab-case `.sh` (`test-framework.sh`, `_lib.sh`)
- Config files: kebab-case `.yaml` (fixtures.yaml)
- Test files: snake_case `.bats` (`test_install_all.bats`)
- Docker images: `ghcr.io/langevc/agent-test-env-<agent>:<tag>`

### Output Convention

| State | Color | Indicator |
|-------|-------|-----------|
| PASS | Green | `✓` |
| FAIL | Red | `✗` |
| WARN | Yellow | `⚠` |
| INFO | Default | `→` |

## Adding a New Agent

1. Create `frameworks/<agent>/Dockerfile`
   - Use `node:22-alpine` for npm-based agents, `python:3.12-slim` for pip-based
   - Include `bash` and `git`
2. Create all 5 lifecycle scripts in `frameworks/<agent>/scripts/`
3. Add the service to `docker-compose.yml`
   - Mount `./fixtures:/fixtures:ro`
   - Join `agent-test-network`
4. Add to CI matrix in `.github/workflows/test.yml`
5. Run `bash tests/run_tests.sh unit` to validate

## Fixtures

- `test-skill` — validates symlink creation in `~/.<agent>/skills/`
- `test-mcp-server` — minimal stdio JSON-RPC MCP server (Node.js)

## Development Workflow

### Running Tests Locally

```bash
# All BATS suites
bash tests/run_tests.sh all

# Single agent+ficture
bash scripts/test-framework.sh opencode test-skill
bash scripts/test-framework.sh claude-code test-mcp-server
```

### Adding New Fixtures

1. Create `fixtures/<name>/capability.yaml` with `name`, `version`, `kind`
2. Add fixture-specific files (skill.md, server.js, etc.)
3. Update `fixtures.yaml.example`
4. Add to CI matrix `fixture:` list

### Pre-Commit Checklist

```bash
bash -n scripts/*.sh
for dir in frameworks/*/scripts; do bash -n "$dir"/*.sh; done
bash tests/run_tests.sh all
```
