#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "codex-cli framework directory exists" {
    [ -d "frameworks/codex-cli" ]
}

@test "codex-cli Dockerfile exists and has FROM" {
    [ -f "frameworks/codex-cli/Dockerfile" ]
    grep -q "FROM" "frameworks/codex-cli/Dockerfile"
}

@test "codex-cli has all 5 lifecycle scripts + _lib" {
    for script in _lib install verify test clean; do
        [ -f "frameworks/codex-cli/scripts/${script}.sh" ]
        [ -x "frameworks/codex-cli/scripts/${script}.sh" ]
    done
}

@test "codex-cli scripts pass bash syntax check" {
    for script in install verify test clean; do
        bash -n "frameworks/codex-cli/scripts/${script}.sh"
    done
}
