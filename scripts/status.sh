#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="${1:-$PWD}"
BRIDGE="$PROJECT_DIR/.AgentBridge"

# bridge exists
if [[ -d "$BRIDGE" ]]; then
  BRIDGE_EXISTS="yes"
else
  BRIDGE_EXISTS="no"
fi
echo "bridge exists: $BRIDGE_EXISTS"

if [[ "$BRIDGE_EXISTS" == "yes" ]]; then
  # last checkpoint timestamp: newest mtime under sessions/*.md or git-state.md
  NEWEST=0
  for f in "$BRIDGE"/sessions/*.md "$BRIDGE/git-state.md"; do
    [[ -f "$f" ]] || continue
    MTIME="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
    if [[ "$MTIME" -gt "$NEWEST" ]]; then
      NEWEST="$MTIME"
    fi
  done

  if [[ "$NEWEST" -gt 0 ]]; then
    LAST_CHECKPOINT="$(date -u -d "@$NEWEST" +"%Y-%m-%dT%H:%M:%SZ")"
  else
    LAST_CHECKPOINT="unknown"
  fi
  echo "last checkpoint: $LAST_CHECKPOINT"

  # count of session files (exclude INDEX.md)
  SESSION_COUNT="$(find "$BRIDGE/sessions" -maxdepth 1 -name '*.md' ! -name 'INDEX.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
  echo "session files: $SESSION_COUNT"

  # staleness warning
  NOW="$(date +%s)"
  if [[ "$NEWEST" -gt 0 ]] && (( NOW - NEWEST > 86400 )); then
    echo "STALE: last checkpoint >24h ago"
  fi
fi

# git branch and HEAD
if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo unknown)"
  HEAD="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo none)"
  echo "branch: $BRANCH"
  echo "HEAD: $HEAD"
else
  echo "branch: n/a (not a git repo)"
  echo "HEAD: n/a"
fi

# .gitignore check
if [[ -f "$PROJECT_DIR/.gitignore" ]] && grep -qxF '.AgentBridge/' "$PROJECT_DIR/.gitignore"; then
  echo "gitignore: .AgentBridge/ is ignored"
else
  echo "gitignore: .AgentBridge/ is NOT ignored"
fi

exit 0