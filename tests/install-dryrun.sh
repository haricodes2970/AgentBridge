#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

ok()  { echo "ok: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP="$(mktemp -d)"
git init -q "$TMP"
trap 'rm -rf "$TMP"' EXIT

echo "== install.sh --platform generic --project <tmp> (offline) =="
AGENTBRIDGE_SKIP_CLONE=1 bash "$REPO_ROOT/install.sh" --platform generic --project "$TMP"

if [[ -d "$TMP/.AgentBridge" ]]; then ok ".AgentBridge/ exists in project"; else fail ".AgentBridge/ missing"; fi
if [[ -f "$TMP/.AgentBridge/goal.md" ]]; then ok "goal.md seeded"; else fail "goal.md missing"; fi
if grep -qxF '.AgentBridge/' "$TMP/.gitignore"; then ok ".gitignore contains .AgentBridge/"; else fail ".gitignore missing .AgentBridge/"; fi

echo "== running twice does not duplicate .gitignore line =="
AGENTBRIDGE_SKIP_CLONE=1 bash "$REPO_ROOT/install.sh" --platform generic --project "$TMP"

count="$(grep -cF '.AgentBridge/' "$TMP/.gitignore" || echo 0)"
if [[ "$count" -eq 1 ]]; then ok ".gitignore has exactly one .AgentBridge/ line"; else fail ".gitignore has $count .AgentBridge/ lines"; fi

if [[ "$FAIL" -ne 0 ]]; then echo "INSTALL DRYRUN FAILED" >&2; exit 1; fi
echo "INSTALL DRYRUN PASSED"
exit 0