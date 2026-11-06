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
EXCLUDE_REGEX='(\.cline/hooks/(session-shutdown|post-tool-use)\.sh|\.claude/settings\.json)$'
DIRTY_LIST="$(git status --porcelain --untracked-files=all 2>/dev/null || true)"
DIRTY_USER="$(echo "$DIRTY_LIST" | grep -vE "$EXCLUDE_REGEX" || true)"
DIRTY_AGENTBRIDGE="$(echo "$DIRTY_LIST" | grep -E "$EXCLUDE_REGEX" || true)"
DIRTY_COUNT="$(echo -n "$DIRTY_USER" | grep -c . || true)"
UNPUSHED="$(git log --oneline @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ' || echo 'n/a')"

# Write git-state.md
{
  echo "# Git state"
  echo ""
  echo "- Updated: $STAMP"
  echo "- Branch: $BRANCH"
  echo "- HEAD: $HEAD"
  echo "- Dirty files (user): $DIRTY_COUNT"
  echo "- Unpushed commits: $UNPUSHED"
  echo ""
  echo "## User changes"
  echo "```"
  if [[ -n "$DIRTY_USER" ]]; then
    echo "$DIRTY_USER" | sed '/^$/d'
  else
    echo "clean"
  fi
  echo "```"
  echo ""
  echo "## AgentBridge-managed artifacts (expected)"
  echo "```"
  if [[ -n "$DIRTY_AGENTBRIDGE" ]]; then
    echo "$DIRTY_AGENTBRIDGE" | sed '/^$/d'
  else
    echo "none"
  fi
  echo "```"
} > "$BRIDGE/git-state.md"

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
if [[ ! -f "$INDEX" ]]; then
  SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
  cp "$SKILL_DIR/templates/INDEX.md" "$INDEX"
fi
if [[ -s "$INDEX" ]] && [[ ! "$(tail -c1 "$INDEX")" == $'\n' ]]; then
  echo >> "$INDEX"
fi
ROW="| $(date -u +"%Y-%m-%d") | $AGENT | $(basename "$SESSION_FILE") | $HEAD |"
if ! grep -qF "$ROW" "$INDEX" 2>/dev/null; then
  echo "$ROW" >> "$INDEX"
fi

echo "Checkpoint written: $SESSION_FILE"
