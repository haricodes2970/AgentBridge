#!/usr/bin/env bash
###############################################################################
# AgentBridge hook — SessionShutdown (Cline)
#
# Runs when the session ends. Performs a final checkpoint so credit-limit
# interruptions are lossless: the next agent resumes from four small files.
###############################################################################
set -uo pipefail

ROOT="$(pwd)"
AB="${ROOT}/.AgentBridge"

echo "## AgentBridge — session shutdown (SessionShutdown)"

if [[ ! -d "$AB" ]]; then
  echo "No .AgentBridge/ found. Nothing to checkpoint."
  exit 0
fi

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
  echo "Final git-state.md checkpointed (${branch} @ ${commit}, ${dirty})."
else
  echo "Not a git repo; skipping git-state.md refresh."
fi

echo
echo "=== Session handoff checklist ==="
echo "[ ] .AgentBridge/goal.md   — current objective is up to date"
echo "[ ] .AgentBridge/next.md   — immediate next action is written"
echo "[ ] .AgentBridge/state.md  — progress, blockers, files touched noted"
echo "[ ] .AgentBridge/git-state.md — branch/commit/dirty recorded"
echo "[ ] .AgentBridge/sessions/ — session summary appended (optional, cold path)"
echo
echo "Credit limits are abrupt. Checkpoint continuously, not only at session end."