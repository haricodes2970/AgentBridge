#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
BRIDGE="$PROJECT_DIR/.AgentBridge"
AGENT="${AGENT_NAME:-unknown}"
STAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SESSION_FILE="$BRIDGE/sessions/$(date -u +"%Y-%m-%d-%H%M")-$AGENT.md"

if [[ ! -d "$BRIDGE" ]]; then
  echo "No .AgentBridge found at $BRIDGE"
  exit 1
fi

cd "$PROJECT_DIR"

BRANCH="$(git branch --show-current 2>/dev/null || echo 'unknown')"
HEAD="$(git rev-parse --short HEAD 2>/dev/null || echo 'none')"
DIRTY_LIST="$(git status --porcelain 2>/dev/null || true)"
DIRTY_COUNT="$(echo -n "$DIRTY_LIST" | grep -c . || true)"
UNPUSHED="$(git log --oneline @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ' || echo 'n/a')"

cat > "$BRIDGE/git-state.md" <<EOF
# Git state

- Updated: $STAMP
- Branch: \`$BRANCH\`
- HEAD: \`$HEAD\`
- Dirty files: $DIRTY_COUNT
- Unpushed commits: $UNPUSHED

## Dirty file list
\`\`\`
${DIRTY_LIST:-clean}
\`\`\`
EOF

if [[ ! -f "$SESSION_FILE" ]]; then
  cat > "$SESSION_FILE" <<EOF
---
session_id: $(date -u +"%Y%m%d%H%M%S")
agent: $AGENT
start: $STAMP
end: $STAMP
outcome: partial
commit: $HEAD
---

## Goal this session
(Read from .AgentBridge/goal.md)

## What happened
- Checkpoint written automatically.

## Decisions made
- (none recorded)

## Files changed
- (see git-state.md)

## Next action
- (read .AgentBridge/next.md)
EOF
fi

# append index row if not present
INDEX="$BRIDGE/sessions/INDEX.md"
if [[ -f "$INDEX" ]]; then
  ROW="| $(date -u +"%Y-%m-%d") | $AGENT | $(basename "$SESSION_FILE") | $HEAD |"
  if ! grep -qF "$ROW" "$INDEX" 2>/dev/null; then
    echo "$ROW" >> "$INDEX"
  fi
fi

echo "Checkpoint written: $SESSION_FILE"