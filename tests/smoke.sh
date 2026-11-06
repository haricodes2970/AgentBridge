#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

ok()  { echo "ok: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP="$(mktemp -d)"
git init -q "$TMP"
trap 'rm -rf "$TMP"' EXIT

echo "== init-bridge creates .AgentBridge with all 7 files =="
bash "$REPO_ROOT/scripts/init-bridge.sh" "$TMP"

for f in goal.md state.md decisions.md next.md git-state.md environment.md sessions/INDEX.md; do
  if [[ -f "$TMP/.AgentBridge/$f" ]]; then ok ".AgentBridge/$f exists"; else fail ".AgentBridge/$f missing"; fi
done

if [[ -s "$TMP/.AgentBridge/git-state.md" ]]; then ok "git-state.md is non-empty"; else fail "git-state.md is empty"; fi

echo "== checkpoint twice -> exactly one session file and one INDEX data row =="
AGENT_NAME=smoke-agent bash "$REPO_ROOT/scripts/checkpoint.sh" "$TMP"
AGENT_NAME=smoke-agent bash "$REPO_ROOT/scripts/checkpoint.sh" "$TMP"

gen="$(ls -1 "$TMP/.AgentBridge/sessions/"[0-9]*-*.md 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$gen" -eq 1 ]]; then ok "exactly one generated session file"; else fail "expected 1 session file, got $gen"; fi

headers="$(grep -cE '^\| Date \|' "$TMP/.AgentBridge/sessions/INDEX.md" 2>/dev/null || echo 0)"
if [[ "$headers" -eq 1 ]]; then ok "INDEX.md has exactly one table header line"; else fail "INDEX.md has $headers header lines, expected 1"; fi

rows="$(grep -cE '^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \|' "$TMP/.AgentBridge/sessions/INDEX.md" 2>/dev/null || echo 0)"
if [[ "$rows" -eq 1 ]]; then ok "INDEX.md has exactly one data row"; else fail "INDEX.md has $rows data rows, expected 1"; fi

echo "== running checkpoint again in same minute does not add a second data row ==="
AGENT_NAME=smoke-agent bash "$REPO_ROOT/scripts/checkpoint.sh" "$TMP"
rows2="$(grep -cE '^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \|' "$TMP/.AgentBridge/sessions/INDEX.md" 2>/dev/null || echo 0)"
if [[ "$rows2" -eq 1 ]]; then ok "INDEX.md still has exactly one data row after re-checkpoint"; else fail "INDEX.md has $rows2 data rows after re-checkpoint, expected 1"; fi

echo "== init-bridge is idempotent =="
if bash "$REPO_ROOT/scripts/init-bridge.sh" "$TMP" >/dev/null 2>&1; then ok "second init-bridge run succeeded"; else fail "second init-bridge run failed"; fi

if [[ "$FAIL" -ne 0 ]]; then echo "SMOKE TEST FAILED" >&2; exit 1; fi
echo "SMOKE TEST PASSED"
exit 0