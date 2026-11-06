#!/usr/bin/env bash
###############################################################################
# AgentBridge hook — TaskComplete (Cline)
#
# Runs when a task completes. Checkpoints progress and refreshes git state so
# the next agent/session can resume from .AgentBridge/.
###############################################################################
set -uo pipefail

ROOT="$(pwd)"
AB="${ROOT}/.AgentBridge"

echo "## AgentBridge — checkpoint (TaskComplete)"

if [[ ! -d "$AB" ]]; then
  echo "No .AgentBridge/ found. Nothing to checkpoint."
  exit 0
fi

# Refresh git state (safe, automatic)
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$ROOT" symbolic-ref --short HEAD 2>/dev/null || git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo detached)"
  commit="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  if git -C "$ROOT" diff --quiet && git -C "$ROOT" diff --cached --quiet; then dirty="clean"; else dirty="dirty"; fi
  status="$(git -C "$ROOT" status --short --branch 2>/dev/null | head -20 || true)"
  cat > "${AB}/git-state.md" <<EOF
# Git State

## Branch
${branch}

## Last commit
${commit}

## Working tree
${dirty}

## Status
\`\`\`
${status}
\`\`\`

_Updated automatically by AgentBridge hooks._
EOF
  echo "git-state.md refreshed (${branch} @ ${commit}, ${dirty})."
else
  echo "Not a git repo; skipping git-state.md refresh."
fi

echo
echo "Remember to update .AgentBridge/state.md and .AgentBridge/next.md before stopping."
echo "If ending the session, also append a summary to .AgentBridge/sessions/."