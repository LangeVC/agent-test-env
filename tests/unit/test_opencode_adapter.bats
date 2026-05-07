#!/usr/bin/env bats

setup() {
    load '../helpers'
}

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
