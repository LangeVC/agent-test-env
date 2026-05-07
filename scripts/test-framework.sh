#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK="${1:-}"
FIXTURE="${2:-}"
EXIT_CODE=0

usage() {
    echo "Usage: test-framework.sh <framework> <fixture>"
    echo "  framework: opencode | claude-code | codex-cli | gemini-cli | continue"
    echo "  fixture:   test-skill | test-mcp-server"
    echo ""
    echo "Runs a fixture test against a framework in Docker Compose."
    echo "Exit 0 = PASS, Exit 1 = FAIL"
    exit 1
}

[ -z "$FRAMEWORK" ] && usage
[ -z "$FIXTURE" ] && usage

FW_DIR="frameworks/$FRAMEWORK"
[ ! -d "$FW_DIR" ] && echo "ERROR: Framework '$FRAMEWORK' not found at $FW_DIR" && exit 1

echo "=== agent-test-env ==="
echo "Framework:  $FRAMEWORK"
echo "Fixture:    $FIXTURE"
echo "========================="

# Step 1: Ensure container is running
if docker compose ps --status running "$FRAMEWORK" 2>/dev/null | grep -q "$FRAMEWORK"; then
    echo "✓ $FRAMEWORK container running"
else
    echo "→ Starting $FRAMEWORK container..."
    docker compose up -d "$FRAMEWORK" 2>/dev/null || {
        echo "✗ Failed to start $FRAMEWORK"
        exit 1
    }
    sleep 5
fi

# Step 2: Run verify.sh (non-fatal for most agents)
echo "→ Running verify.sh..."
docker compose exec -T "$FRAMEWORK" /scripts/verify.sh 2>/dev/null || {
    echo "⚠ verify.sh failed (non-fatal for framework validation)"
}

# Step 3: Run test.sh with fixture
echo "→ Testing fixture installation..."
if docker compose exec -T "$FRAMEWORK" /scripts/test.sh "$FIXTURE" 2>/dev/null; then
    echo "✓ Fixture test PASSED"
else
    echo "✗ Fixture test FAILED"
    EXIT_CODE=1
fi

# Step 4: Clean up
echo "→ Cleaning up..."
docker compose exec -T "$FRAMEWORK" /scripts/clean.sh 2>/dev/null || true

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=== RESULT: PASS ==="
else
    echo ""
    echo "=== RESULT: FAIL ==="
fi

exit $EXIT_CODE
