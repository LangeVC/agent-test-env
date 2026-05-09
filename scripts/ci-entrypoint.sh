#!/usr/bin/env bash
set -euo pipefail

# CI entrypoint — runs test-framework.sh for each framework+fixture combination
# Called from GitHub Actions matrix or directly with optional framework argument.
#
# Usage:
#   ci-entrypoint.sh            # all frameworks × all fixtures
#   ci-entrypoint.sh opencode   # single framework × all fixtures

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FRAMEWORKS="${FRAMEWORKS:-opencode claude-code codex-cli gemini-cli continue}"
FIXTURES="${FIXTURES:-test-skill test-mcp-server test-tool test-prompt test-template test-workflow test-connector-pack test-runtimes-skill test-broken-manifest test-dependency test-bundle test-signed-cap}"

if [ "${1:-}" != "" ]; then
    FRAMEWORKS="$1"
fi

PASS=0
FAIL=0
RESULTS=""

log_result() {
    local fw="$1" fix="$2" result="$3"
    local line="  $fw + $fix → $result"
    RESULTS="$RESULTS
$line"
    if [ "$result" = "PASS" ]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
}

echo "=== agent-test-env — CI Entrypoint ==="
echo ""

cd "$REPO_ROOT"

for fw in $FRAMEWORKS; do
    for fix in $FIXTURES; do
        echo "--- Testing $fw with $fix ---"
        if bash scripts/test-framework.sh "$fw" "$fix" 2>&1; then
            log_result "$fw" "$fix" "PASS"
        else
            log_result "$fw" "$fix" "FAIL"
        fi
        echo ""
    done
done

echo "=== Results ==="
echo "$RESULTS"
echo ""
echo "Pass: $PASS  Fail: $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
