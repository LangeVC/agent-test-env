#!/usr/bin/env bash

export TEST_LAB_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
export FIXTURES_DIR="$TEST_LAB_ROOT/fixtures"

# Auto-discover all capability kinds from fixtures.json
if [ -f "$TEST_LAB_ROOT/fixtures.json" ]; then
    ALL_CAP_KINDS=$(python3 -c "import json; kinds=set(e['kind'] for e in json.load(open('$TEST_LAB_ROOT/fixtures.json'))); print(' '.join(sorted(kinds)))" 2>/dev/null || echo "")
fi

fixture_cleanup() {
    local framework="${1:-}"
    [ -z "$framework" ] && { echo "ERROR: fixture_cleanup requires framework name" >&2; return 1; }
    
    case "$framework" in
        opencode)   local dir="$HOME/.opencode/skills" ;;
        claude-code|claude) local dir="$HOME/.claude/skills" ;;
        codex-cli|codex)    local dir="$HOME/.codex/skills" ;;
        gemini-cli|gemini)  local dir="$HOME/.gemini/skills" ;;
        continue)   local dir="$HOME/.continue/skills" ;;
        cursor)     local dir="$HOME/.cursor" ;;
        *)          echo "ERROR: unknown framework: $framework" >&2; return 1 ;;
    esac
    
    rm -rf "${dir:?}"/*
    echo "Cleaned $framework skills at $dir"
}

fixture_install() {
    local framework="${1:-}"
    local fixture="${2:-}"
    [ -z "$framework" ] && { echo "ERROR: fixture_install requires framework name" >&2; return 1; }
    [ -z "$fixture" ] && { echo "ERROR: fixture_install requires fixture name" >&2; return 1; }
    
    local fixture_path="$FIXTURES_DIR/$fixture"
    [ ! -d "$fixture_path" ] && { echo "ERROR: fixture '$fixture' not found at $fixture_path" >&2; return 1; }
    
    case "$framework" in
        opencode)   local skill_dir="$HOME/.opencode/skills/$fixture" ;;
        claude-code|claude) local skill_dir="$HOME/.claude/skills/$fixture" ;;
        codex-cli|codex)    local skill_dir="$HOME/.codex/skills/$fixture" ;;
        gemini-cli|gemini)  local skill_dir="$HOME/.gemini/skills/$fixture" ;;
        continue)   local skill_dir="$HOME/.continue/skills/$fixture" ;;
        cursor)     local skill_dir="$HOME/.cursor" ;;
        *)          echo "ERROR: unknown framework: $framework" >&2; return 1 ;;
    esac
    
    mkdir -p "$(dirname "$skill_dir")"
    ln -sf "$fixture_path" "$skill_dir"
    echo "Installed $fixture for $framework at $skill_dir"
}

fixture_remove() {
    local framework="${1:-}"
    local fixture="${2:-}"
    [ -z "$framework" ] && { echo "ERROR: fixture_remove requires framework name" >&2; return 1; }
    [ -z "$fixture" ] && { echo "ERROR: fixture_remove requires fixture name" >&2; return 1; }
    
    case "$framework" in
        opencode)   local link="$HOME/.opencode/skills/$fixture" ;;
        claude-code|claude) local link="$HOME/.claude/skills/$fixture" ;;
        codex-cli|codex)    local link="$HOME/.codex/skills/$fixture" ;;
        gemini-cli|gemini)  local link="$HOME/.gemini/skills/$fixture" ;;
        continue)   local link="$HOME/.continue/skills/$fixture" ;;
        cursor)     local link="$HOME/.cursor" ;;
        *)          echo "ERROR: unknown framework: $framework" >&2; return 1 ;;
    esac
    
    rm -f "$link"
    echo "Removed $fixture from $framework"
}
