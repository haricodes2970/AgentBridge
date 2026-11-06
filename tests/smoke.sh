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

echo "== git-state.md separates user vs AgentBridge dirt =="
if grep -qF '## User changes' "$TMP/.AgentBridge/git-state.md"; then ok "git-state.md has User changes section"; else fail "git-state.md missing User changes section"; fi
if grep -qF '## AgentBridge-managed artifacts (expected)' "$TMP/.AgentBridge/git-state.md"; then ok "git-state.md has AgentBridge-managed artifacts section"; else fail "git-state.md missing AgentBridge-managed artifacts section"; fi

echo "== checkpoint does not count AgentBridge hooks as user dirt =="
mkdir -p "$TMP/.cline/hooks"
printf '#!/usr/bin/env bash\necho hook\n' > "$TMP/.cline/hooks/post-tool-use.sh"
AGENT_NAME=smoke-agent bash "$REPO_ROOT/scripts/checkpoint.sh" "$TMP"
if grep -qF '.cline/hooks/post-tool-use.sh' "$TMP/.AgentBridge/git-state.md"; then ok "post-tool-use.sh appears under AgentBridge-managed artifacts"; else fail "post-tool-use.sh missing from AgentBridge-managed artifacts"; fi
if ! grep -qF ' M .cline/hooks/post-tool-use.sh' "$TMP/.AgentBridge/git-state.md"; then ok "post-tool-use.sh does not inflate user Dirty files count"; else fail "post-tool-use.sh incorrectly counted as user dirt"; fi

echo "== read-bridge.sh and status.sh =="
read_out="$(bash "$REPO_ROOT/scripts/read-bridge.sh" "$TMP")"
if [[ $? -eq 0 ]]; then ok "read-bridge.sh exits 0"; else fail "read-bridge.sh exited non-zero"; fi
if echo "$read_out" | grep -qF '===== goal.md ====='; then ok "read-bridge.sh output has goal.md section"; else fail "read-bridge.sh output missing goal.md section"; fi
if echo "$read_out" | grep -qF '===== next.md ====='; then ok "read-bridge.sh output has next.md section"; else fail "read-bridge.sh output missing next.md section"; fi

status_out="$(bash "$REPO_ROOT/scripts/status.sh" "$TMP")"
if [[ $? -eq 0 ]]; then ok "status.sh exits 0"; else fail "status.sh exited non-zero"; fi
if echo "$status_out" | grep -qF 'bridge exists: yes'; then ok "status.sh reports bridge exists: yes"; else fail "status.sh missing bridge exists: yes"; fi

echo "== init-bridge is idempotent =="
if bash "$REPO_ROOT/scripts/init-bridge.sh" "$TMP" >/dev/null 2>&1; then ok "second init-bridge run succeeded"; else fail "second init-bridge run failed"; fi

echo "== validate-bridge.sh =="
if bash "$REPO_ROOT/scripts/validate-bridge.sh" "$TMP"; then ok "validate-bridge.sh exits 0"; else fail "validate-bridge.sh exited non-zero"; fi

echo "== uninstall.sh (twice, idempotent) =="
if bash "$REPO_ROOT/scripts/uninstall.sh" "$TMP"; then ok "uninstall.sh exits 0 (first run)"; else fail "uninstall.sh exited non-zero (first run)"; fi
if [[ -d "$TMP/.AgentBridge" ]]; then fail ".AgentBridge/ still exists after uninstall"; else ok ".AgentBridge/ removed after uninstall"; fi
if bash "$REPO_ROOT/scripts/uninstall.sh" "$TMP"; then ok "uninstall.sh exits 0 (second run)"; else fail "uninstall.sh exited non-zero (second run)"; fi

if [[ "$FAIL" -ne 0 ]]; then echo "SMOKE TEST FAILED" >&2; exit 1; fi
echo "SMOKE TEST PASSED"
exit 0