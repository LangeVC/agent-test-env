# HOWTO — Writing Tests for agent-test-env

## Test Framework

All tests use [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core). BATS is auto-installed to `/tmp/bats-core` by `tests/run_tests.sh`.

## File Structure

```
tests/
├── helpers.bash              ← Shared setup loaded by all test files
├── run_tests.sh              ← BATS suite runner (unit|integration|smoke|all)
├── unit/
│   ├── test_opencode_adapter.bats
│   ├── test_claude_adapter.bats
│   └── test_codex_adapter.bats
├── integration/
│   └── test_install_all.bats
└── smoke/
    └── test_fingerprint.bats
```

## Creating a New Test File

```bash
#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "framework opencode has lifecycle scripts" {
    for script in _lib install verify test clean; do
        [ -f "frameworks/opencode/scripts/${script}.sh" ]
        [ -x "frameworks/opencode/scripts/${script}.sh" ]
    done
}

@test "framework opencode install fails on bad fixture" {
    run bash scripts/test-framework.sh opencode nonexistent-fixture
    [ "$status" -ne 0 ]
}
```

## Available Test Patterns

### Running Framework + Fixture Tests

```bash
# Test a specific framework against a fixture via Docker Compose
bash scripts/test-framework.sh opencode test-skill
bash scripts/test-framework.sh claude-code test-mcp-server
```

### Exit Code Assertions

```bash
# Success
[ "$status" -eq 0 ]

# Failure
[ "$status" -ne 0 ]

# Either OK
[ "$status" -eq 0 ] || [ "$status" -eq 1 ]
```

### Output Assertions

```bash
# Text in output
[[ "$output" =~ "PASS" ]]

# Case-insensitive
[[ "$output" =~ [Pp]ass ]]

# Output contains non-empty text
[[ "$output" =~ [A-Za-z0-9] ]]
```

### JSON Validation

```bash
# Simple: valid JSON?
echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || skip "not JSON"

# Structured: check fields
echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert 'name' in d, 'missing name'
assert 'version' in d, 'missing version'
assert 'kind' in d, 'missing kind'
" 2>/dev/null || skip "validation failed"
```

### Validating capability.yaml

```bash
@test "test-skill capability.yaml is valid" {
    local yaml_file="fixtures/test-skill/capability.yaml"
    [ -f "$yaml_file" ]

    # YAML validity (uses python for broad compatibility)
    python3 -c "
import yaml
with open('$yaml_file') as f:
    d = yaml.safe_load(f)
    assert d['name'], 'missing name'
    assert d['kind'], 'missing kind'
" 2>/dev/null || skip "YAML validation failed"
}
```

### Graceful Skips

```bash
# Skip when feature not available
[ "$status" -eq 0 ] || skip "feature not available"

# Skip when remote dependency missing
if [ "$status" -eq 0 ]; then
    echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || skip "JSON parse failed"
else
    skip "service not reachable"
fi
```

### Framework Adapter Tests

```bash
@test "opencode framework directory exists" {
    [ -d "frameworks/opencode" ]
}

@test "opencode Dockerfile exists and has FROM" {
    [ -f "frameworks/opencode/Dockerfile" ]
    grep -q "FROM" "frameworks/opencode/Dockerfile"
}

@test "opencode has all 5 lifecycle scripts + _lib" {
    for script in _lib install verify test clean; do
        [ -f "frameworks/opencode/scripts/${script}.sh" ]
        [ -x "frameworks/opencode/scripts/${script}.sh" ]
    done
}

@test "opencode scripts pass bash syntax check" {
    for script in install verify test clean; do
        bash -n "frameworks/opencode/scripts/${script}.sh"
    done
}
```

### Docker Compose Integration Tests

```bash
@test "opencode container starts with docker compose" {
    docker compose up -d opencode 2>/dev/null
    run docker compose ps --status running opencode
    [ "$status" -eq 0 ]
}

@test "fixture test runs in opencode container" {
    run docker compose exec -T opencode /scripts/test.sh test-skill
    [ "$status" -eq 0 ]
}
```

### Error Path Tests

```bash
@test "test-framework.sh without args fails" {
    run bash scripts/test-framework.sh
    [ "$status" -ne 0 ]
}

@test "test-framework.sh invalid framework fails" {
    run bash scripts/test-framework.sh nonexistent-framework test-skill
    [ "$status" -ne 0 ]
}
```

## Adding New Fixtures

1. Create the fixture directory under `fixtures/<name>/`:

```bash
fixtures/test-new-kind/
├── capability.yaml    # Required: name, version, kind, description
└── content-file       # At least one content file
```

2. Add the fixture to `fixtures.yaml.example`:

```yaml
fixtures:
  - test-skill
  - test-mcp-server
  - test-new-kind
```

3. The fixture is now available to all framework `test.sh` scripts.

## Adding a New Test to an Existing File

1. Add a new `@test` block after the last existing one.
2. Follow the file's section header convention (comment lines like `# ── section name ──`).
3. Keep tests independent — each `@test` should not rely on state from a previous test.

## Running Tests

```bash
# All BATS suites
bash tests/run_tests.sh all

# Single suite
bash tests/run_tests.sh unit
bash tests/run_tests.sh integration
bash tests/run_tests.sh smoke

# Single framework + fixture (non-BATS)
bash scripts/test-framework.sh opencode test-skill

# Single BATS file directly
bats tests/unit/test_opencode_adapter.bats

# Single test by name filter
bats tests/unit/test_opencode_adapter.bats -f "lifecycle scripts"
```

## Debugging Tests

```bash
# Verbose output (BATS prints full output on failure)
bats --print-output-on-failure tests/unit/test_opencode_adapter.bats

# Run BATS in trace mode (prints every command)
bats --trace tests/unit/test_opencode_adapter.bats

# Add debug output in test
@test "debugging" {
    run docker compose exec -T opencode /scripts/test.sh test-skill
    echo "STATUS=$status" >&3      # stderr in BATS goes to terminal
    echo "OUTPUT=$output" >&3
    [ "$status" -eq 0 ]
}

# Check fixture content
ls fixtures/test-skill/
cat fixtures/test-skill/capability.yaml

# Check container state
docker compose ps
docker compose logs opencode
```
