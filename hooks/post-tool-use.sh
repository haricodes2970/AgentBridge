#!/usr/bin/env bash
###############################################################################
# AgentBridge hook — PostToolUse (Cline)
#
# Runs after tool calls. Lightweight checkpoint: refresh git state after
# write/edit tools so .AgentBridge/ stays current continuously.
###############################################################################
set -uo pipefail

ROOT="$(pwd)"
AB="${ROOT}/.AgentBridge"

[[ -d "$AB" ]] || exit 0

# Only refresh git state after mutating tools; cheap and safe.
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Re-read git state only if the working tree actually changed since last check.
  if git -C "$ROOT" diff --quiet && git -C "$ROOT" diff --cached --quiet; then
    exit 0  # tree clean, nothing to checkpoint
  fi
  branch="$(git -C "$ROOT" symbolic-ref --short HEAD 2>/dev/null || git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo detached)"
  commit="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  status="$(git -C "$ROOT" status --short --branch 2>/dev/null | head -20 || true)"
  cat > "${AB}/git-state.md" <<EOF
# Git State

## Branch
${branch}

## Last commit
${commit}

## Working tree
dirty

## Status
\`\`\`
${status}
\`\`\`

_Updated automatically by AgentBridge hooks._
EOF
fi

exit 0