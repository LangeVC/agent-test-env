#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "named volumes exist in docker-compose.yml" {
    python3 -c "
import yaml
config = yaml.safe_load(open('docker-compose.yml'))
volumes = config.get('volumes', {})
expected = ['opencode_skills', 'claude_skills', 'codex_skills', 'gemini_skills', 'continue_skills']
for vol in expected:
    assert vol in volumes, f'named volume {vol} not found in docker-compose.yml'
print('All named volumes defined in docker-compose.yml')
"
}

@test "healthcheck is present on opencode service" {
    python3 -c "
import yaml
config = yaml.safe_load(open('docker-compose.yml'))
services = config.get('services', {})
opencode = services.get('opencode', {})
assert 'healthcheck' in opencode, 'opencode service missing healthcheck'
hc = opencode['healthcheck']
assert 'test' in hc, 'healthcheck missing test'
print('opencode service healthcheck is configured')
"
}

@test "no sleep-based polling in CI workflow" {
    grep -rq "sleep" .github/workflows/test.yml 2>/dev/null && false || true
    grep -q "docker compose wait" .github/workflows/test.yml
    echo "CI workflow uses docker compose wait"
}
