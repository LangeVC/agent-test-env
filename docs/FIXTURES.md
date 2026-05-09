# Fixture Guide — agent-test-env

## Overview

Fixtures are minimal, self-contained capability packages used as test subjects across all agent frameworks. Each fixture lives in `fixtures/<name>/` and is registered in `fixtures.json`.

## Fixture Registry (`fixtures.json`)

The central registry at the repo root:

```json
[
  {"name": "test-skill", "kind": "skill", "version": "1.0.0"},
  {"name": "test-mcp-server", "kind": "mcp-server", "version": "1.0.0"},
  ...
]
```

Tests auto-discover fixture kinds via `python3 -c "import json; ..."` in `helpers.bash`. No test file modifications needed when adding a new fixture.

## Current Fixture Inventory (12)

| Fixture | Kind | Version | Purpose | Content Files |
|---------|------|---------|---------|--------------|
| `test-skill` | skill | 1.0.0 | Basic install/verify lifecycle | capability.yaml, SKILL.md |
| `test-mcp-server` | mcp-server | 1.0.0 | MCP server install + discovery | capability.yaml, server.js |
| `test-tool` | tool | 1.0.0 | Tool capability install | capability.yaml, tool.sh |
| `test-prompt` | prompt | 1.0.0 | Prompt capability install | capability.yaml, prompt.md |
| `test-template` | template | 1.0.0 | Template capability install | capability.yaml, template.md |
| `test-workflow` | workflow | 1.0.0 | Workflow capability install | capability.yaml, workflow.md |
| `test-connector-pack` | connector-pack | 1.0.0 | Connector-pack install | capability.yaml, connectors.json |
| `test-runtimes-skill` | skill | 1.0.0 | Runtime pre-flight checks | capability.yaml, SKILL.md |
| `test-broken-manifest` | skill | 1.0.0 | Error path testing (invalid manifest) | capability.yaml, SKILL.md |
| `test-dependency` | skill | 1.0.0 | Lock file / dependency testing | capability.yaml, SKILL.md |
| `test-bundle` | bundle | 1.0.0 | Bundle with sub-capabilities | capability.yaml, SKILL.md, sub-skill/, sub-tool/ |
| `test-signed-cap` | skill | 1.0.0 | Sign/verify cryptographic tests | capability.yaml, SKILL.md |

## Adding a New Fixture

### Step 1: Create Directory Structure

```bash
mkdir -p fixtures/test-new-kind
```

### Step 2: Create `capability.yaml`

Minimal valid manifest:

```yaml
name: test-new-kind
version: 1.0.0
kind: skill
description: Test capability for agent-test-env
author: agent-test-env
```

For specific kinds, add required fields:

```yaml
# MCP server
kind: mcp-server
runtimes:
  node: ">=18"
mcp:
  transport: stdio
  command: node
  args: ["server.js"]
  supported_clients:
    - opencode
    - claude-code
    - codex-cli
    - gemini-cli
    - continue
    - cursor

# With dependencies
kind: skill
dependencies:
  - name: test-skill
    version: ">=1.0.0"

# With runtimes
kind: skill
runtimes:
  uv: ">=0.4.0"
  node: ">=20"

# Bundle
kind: bundle
capabilities:
  - name: sub-skill
    source: ./sub-skill
  - name: sub-tool
    source: ./sub-tool
```

### Step 3: Add Content Files

At minimum, one content file matching the kind convention:

| Kind | Content file |
|------|-------------|
| skill | SKILL.md |
| tool | tool.sh (executable) |
| prompt | prompt.md |
| template | template.md |
| workflow | workflow.md |
| connector-pack | connectors.json |
| mcp-server | server.js (or equivalent command file) |
| bundle | SKILL.md + sub-capability directories |

### Step 4: Register in `fixtures.json`

Add an entry:

```json
{"name": "test-new-kind", "kind": "skill", "version": "1.0.0"}
```

### Step 5: Done

No test file modifications needed. `fixture_cleanup()` in `helpers.bash` auto-discovers the new fixture name from `fixtures.json` and cleans it up before/after tests.

## Fixture Naming Convention

- Fixture directory name: `test-<description>` (kebab-case)
- All fixture names start with `test-` to avoid namespace pollution
- `capability.yaml` `name` field matches directory name

## How Fixtures Are Installed

Each framework's `test.sh` script installs fixtures via symlink into the framework's skills directory:

| Framework | Skills Directory |
|-----------|-----------------|
| OpenCode | `~/.opencode/skills/<fixture>` |
| Claude Code | `~/.claude/skills/<fixture>` |
| Codex CLI | `~/.codex/skills/<fixture>` |
| Gemini CLI | `~/.gemini/skills/<fixture>` |
| Continue.dev | `~/.continue/skills/<fixture>` |
| Cursor | `~/.cursor/` (MCP config, not skills) |

The `fixture_install()` and `fixture_remove()` helpers in `tests/helpers.bash` handle symlink creation and removal for each framework:

```bash
fixture_install opencode test-skill
# → ln -sf fixtures/test-skill ~/.opencode/skills/test-skill

fixture_remove opencode test-skill
# → rm -f ~/.opencode/skills/test-skill
```

## Cleanup Contract

The `fixture_cleanup()` function in `helpers.bash` removes all symlinks for a framework:

```bash
fixture_cleanup opencode
# → rm -rf ~/.opencode/skills/*
```

This ensures:
- **Before each test**: No residual installs from previous test runs
- **Cross-test isolation**: Installing in test A doesn't break test B
- **Auto-discovery**: Adding a fixture to `fixtures.json` automatically includes it in cleanup

## Broken/Error Fixtures

`test-broken-manifest` deliberately violates manifest requirements:

```yaml
name: broken manifest        # Spaces in name
version: 1.0.0
description: Deliberately broken manifest for error path testing
author: agent-test-env
# No 'kind' field — missing
```

Used for error path testing in framework `test.sh` scripts:
- Install from invalid manifest
- Verify on invalid capability
- Package from invalid manifest

## Bundle Fixtures

`test-bundle` is a bundle with two sub-capabilities:

```
test-bundle/
├── capability.yaml          # kind: bundle, capabilities: [sub-skill, sub-tool]
├── SKILL.md
├── sub-skill/
│   ├── capability.yaml      # kind: skill
│   └── SKILL.md
└── sub-tool/
    ├── capability.yaml      # kind: tool
    └── tool.sh
```

Used for:
- Bundle fingerprint computation
- Bundle install with sub-capability reference tracking
- Bundle remove with reference counting
