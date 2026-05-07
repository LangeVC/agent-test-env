#!/usr/bin/env bats

setup() {
    load '../helpers'
}

@test "claude-code framework directory exists" {
    [ -d "frameworks/claude-code" ]
}

@test "claude-code Dockerfile exists and has FROM" {
    [ -f "frameworks/claude-code/Dockerfile" ]
    grep -q "FROM" "frameworks/claude-code/Dockerfile"
}

@test "claude-code has all 5 lifecycle scripts + _lib" {
    for script in _lib install verify test clean; do
        [ -f "frameworks/claude-code/scripts/${script}.sh" ]
        [ -x "frameworks/claude-code/scripts/${script}.sh" ]
    done
}

@test "claude-code scripts pass bash syntax check" {
    for script in install verify test clean; do
        bash -n "frameworks/claude-code/scripts/${script}.sh"
    done
}
