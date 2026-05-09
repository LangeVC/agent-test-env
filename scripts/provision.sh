#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK="${1:-all}"

log() { echo "[provision] $*"; }

declare -A SKILL_DIRS=(
    [opencode]="/root/.opencode/skills"
    [claude-code]="/root/.claude/skills"
    [codex-cli]="/root/.codex/skills"
    [gemini-cli]="/root/.gemini/skills"
    [continue]="/root/.continue/skills"
)

ALL_FRAMEWORKS=(opencode claude-code codex-cli gemini-cli continue)

provision_fixtures() {
    local fw="$1"
    local skill_dir="${SKILL_DIRS[$fw]}"
    log "Provisioning fixtures for $fw..."
    docker compose exec -T "$fw" mkdir -p "$skill_dir" 2>/dev/null || true
    log "  Created $skill_dir"
}

up_framework() {
    local fw="$1"
    log "Starting $fw..."
    docker compose up -d "$fw" 2>/dev/null || {
        log "Warning: docker compose failed, trying docker-compose..."
        docker-compose up -d "$fw" 2>/dev/null || {
            echo "ERROR: Cannot start $fw"
            return 1
        }
        return 0
    }
}

if [ "$FRAMEWORK" = "all" ]; then
    for fw in "${ALL_FRAMEWORKS[@]}"; do
        up_framework "$fw"
        provision_fixtures "$fw"
    done
elif [ -n "${SKILL_DIRS[$FRAMEWORK]:-}" ]; then
    up_framework "$FRAMEWORK"
    provision_fixtures "$FRAMEWORK"
else
    log "ERROR: Unknown framework '$FRAMEWORK'. Valid: all, ${ALL_FRAMEWORKS[*]}"
    exit 1
fi

log "Provision complete"
