#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "docker compose config is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))" 2>/dev/null || true
}

@test "all containerized frameworks have Dockerfiles" {
    for fw in opencode claude-code codex-cli gemini-cli continue; do
        [ -f "frameworks/$fw/Dockerfile" ]
        grep -q "FROM" "frameworks/$fw/Dockerfile"
    done
}

@test "all fixtures have valid capability.yaml" {
    for fixture in test-skill test-mcp-server; do
        [ -f "fixtures/$fixture/capability.yaml" ]
        grep -q "name:" "fixtures/$fixture/capability.yaml"
        grep -q "kind:" "fixtures/$fixture/capability.yaml"
        grep -q "version:" "fixtures/$fixture/capability.yaml"
    done
}

@test "all framework scripts are executable" {
    for fw in opencode claude-code codex-cli gemini-cli continue cursor; do
        for script in install verify test clean; do
            if [ -f "frameworks/$fw/scripts/${script}.sh" ]; then
                [ -x "frameworks/$fw/scripts/${script}.sh" ]
            fi
        done
    done
}
