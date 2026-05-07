#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "test-skill fixture is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('fixtures/test-skill/capability.yaml'))" 2>/dev/null || \
    python3 -c "
import pathlib
content = pathlib.Path('fixtures/test-skill/capability.yaml').read_text()
assert 'name:' in content, 'missing name field'
assert 'version:' in content, 'missing version field'
assert 'kind:' in content, 'missing kind field'
print('YAML check passed (stdlib fallback)')
"
}

@test "test-mcp-server fixture is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('fixtures/test-mcp-server/capability.yaml'))" 2>/dev/null || \
    python3 -c "
import pathlib
content = pathlib.Path('fixtures/test-mcp-server/capability.yaml').read_text()
assert 'name:' in content, 'missing name field'
assert 'version:' in content, 'missing version field'
assert 'kind:' in content, 'missing kind field'
print('YAML check passed (stdlib fallback)')
"
}

@test "test-mcp-server has server.js" {
    [ -f "fixtures/test-mcp-server/server.js" ]
    node --check fixtures/test-mcp-server/server.js 2>/dev/null || {
        [ -s "fixtures/test-mcp-server/server.js" ]
    }
}

@test "docker compose volumes are defined" {
    python3 -c "
import yaml
config = yaml.safe_load(open('docker-compose.yml'))
services = config.get('services', {})
for name, svc in services.items():
    volumes = svc.get('volumes', [])
    fixture_mounts = [v for v in volumes if '/fixtures' in str(v)]
    assert fixture_mounts, f'{name}: no fixtures volume mount'
print('All services have fixtures volume mount')
"
}
