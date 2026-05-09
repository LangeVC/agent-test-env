# CI Reference — agent-test-env

## Workflows

### `test.yml` — Framework Integration Tests

Tests fixtures against real agent frameworks in Docker containers.

| Property | Value |
|----------|-------|
| File | `.github/workflows/test.yml` |
| Trigger paths | `frameworks/**`, `fixtures/**`, `scripts/**`, `tests/**`, `docker-compose.yml`, `.github/workflows/test.yml` |
| Runs on | `ubuntu-latest` |
| Matrix | 6 frameworks × 2 fixtures |
| Steps | Checkout → Build framework image → Start container → Wait for healthy → Run test script → Collect results → Cleanup |
| Timeout | ~3 min per job |

**Matrix breakdown:**

| Framework | Container | test-skill | test-mcp-server |
|-----------|-----------|:----------:|:----------------:|
| opencode | Agent container | ✓ | ✓ |
| claude-code | Agent container | ✓ | ✓ |
| codex-cli | Agent container | ✓ | ✓ |
| gemini-cli | Agent container | ✓ | ✓ |
| continue | Agent container | ✓ | ✓ |
| cursor | Scripts-only (no container) | ✗ (excluded) | ✓ |

cursor is excluded from `test-skill` because it has no skills directory — it configures MCP via `~/.cursor/mcp.json` only.

**What it tests:**
- Each framework's lifecycle scripts: `install.sh`, `verify.sh`, `test.sh`, `clean.sh`
- Fixture symlink creation in the agent's skills directory
- MCP server fixture installation and verification

**When it runs:**
- Push to `main` that changes frameworks, fixtures, scripts, tests, Docker Compose config, or this workflow
- Pull requests to `main`
- Manual trigger (`workflow_dispatch`)

### Local BATS Test Suites

Run via `tests/run_tests.sh`. These validate framework structure, Docker behavior, and fixture YAML.

| Suite | Path | What it validates |
|-------|------|-------------------|
| unit | `tests/unit/` | Framework lifecycle script contracts |
| integration | `tests/integration/` | Docker Compose + fixture execution |
| smoke | `tests/smoke/` | Fixture YAML + volume validation |

## CI Runner Requirements

- **OS:** Ubuntu latest (GitHub Actions `ubuntu-latest`)
- **Docker:** Engine with Buildx
- **Docker Compose:** v2+ (plugin, not standalone binary)
- **Shell:** `bash` (all scripts use `set -euo pipefail`)

## Docker Compose Wait Pattern

All steps use `docker compose wait` (not `sleep`). This waits for the container to reach its healthy state before testing begins:

```yaml
# Per-service healthcheck — runs verify.sh every 10s, up to 5 retries
healthcheck:
  test: ["CMD", "/scripts/verify.sh"]
  interval: 10s
  retries: 5
  start_period: 30s
```

In CI steps:

```bash
# Start container (may fail if no Dockerfile — e.g., cursor)
docker compose up -d "$FRAMEWORK" || true

# Wait for healthy (blocks until healthcheck passes or retries exhausted)
docker compose wait "$FRAMEWORK"

# Now safe to exec into the container
docker compose exec -T "$FRAMEWORK" /scripts/test.sh "test-skill"
```

**Why wait, not sleep:**
- `sleep` wastes time on containers that start fast or fails on slow starts
- `docker compose wait` respects the healthcheck — exits 0 only when healthy
- Eliminates flaky "container not ready" CI failures

## Running CI Locally

### Full BATS Suite

```bash
# All suites
bash tests/run_tests.sh all

# Single suite
bash tests/run_tests.sh unit
bash tests/run_tests.sh integration
bash tests/run_tests.sh smoke
```

BATS is auto-installed to `/tmp/bats-core` on first run if not found on `$PATH`.

### Single Framework + Fixture

```bash
# Build and start the framework container
docker compose build opencode
docker compose up -d opencode

# Wait for healthy
docker compose wait opencode

# Run a fixture test
bash scripts/test-framework.sh opencode test-skill
bash scripts/test-framework.sh opencode test-mcp-server

# Cleanup
docker compose down -v
```

The `test-framework.sh` script will also start the container and wait if it isn't already running, so a shorter path works too:

```bash
docker compose build opencode
bash scripts/test-framework.sh opencode test-skill
docker compose down -v
```

### Pre-Commit Checklist

```bash
# Validate shell syntax
bash -n scripts/*.sh
for dir in frameworks/*/scripts; do bash -n "$dir"/*.sh; done

# Run all test suites
bash tests/run_tests.sh all
```

## Adding CI Checks

When modifying CI workflows:

1. **Path triggers**: Be specific — only trigger on files the workflow actually depends on
2. **Matrix exclusions**: Add `exclude` entries for incompatible framework×fixture combinations
3. **`fail-fast: false`**: Let all matrix jobs complete independently
4. **Cleanup**: Always add `if: always()` cleanup steps for Docker services
5. **Timeouts**: Framework tests need ~3 min per job

## Known Limitations

| Issue | Status | Workaround |
|-------|--------|-----------|
| cursor has no Dockerfile | Scripts-only agent | Excluded from `docker compose build`, only tested via direct script invocation |
| cursor has no skills directory | MCP-only configuration | Excluded from `test-skill` fixture in CI matrix |
| gemini-cli install may fail | CLI not always available | `verify.sh` is non-fatal for P1 agents (gemini, continue, cursor) |
| continue install may fail | CLI not always available | Same as above — non-fatal verification |
| BATS auto-install on first run | Requires git + network | Network required for `git clone` of bats-core; cached after first run at `/tmp/bats-core` |
