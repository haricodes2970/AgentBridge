#!/usr/bin/env bash
set -euo pipefail

SRC="/tmp/agentbridge-dogfood"
DST="/tmp/agentbridge-dogfood-control"

echo "=== AgentBridge dogfood control (no bridge) ==="
echo "Copying $SRC -> $DST"

# Remove source to ensure a clean copy.
rm -rf "$DST"
cp -r "$SRC" "$DST"

# Remove .AgentBridge/ from the copy.
if [[ -d "$DST/.AgentBridge" ]]; then
  rm -rf "$DST/.AgentBridge"
  echo "Removed .AgentBridge/ from $DST"
fi

# Remove the AgentBridge line from .gitignore in the copy.
if [[ -f "$DST/.gitignore" ]] && grep -qxF '.AgentBridge/' "$DST/.gitignore"; then
  grep -vxF '.AgentBridge/' "$DST/.gitignore" > "${DST}.gitignore.tmp" && mv "${DST}.gitignore.tmp" "$DST/.gitignore"
  echo "Removed .AgentBridge/ from $DST/.gitignore"
fi

echo ""
echo "Control project ready: $DST"
echo "Follow docs/CROSS-AGENT-TEST.md."