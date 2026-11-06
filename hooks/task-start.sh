#!/usr/bin/env bash
###############################################################################
# AgentBridge hook — TaskStart (Cline)
#
# Runs at the start of a task. Restores durable context from .AgentBridge/
# so the agent resumes losslessly instead of re-reading the whole repo.
###############################################################################
set -uo pipefail

ROOT="$(pwd)"
AB="${ROOT}/.AgentBridge"

echo "## AgentBridge — context restore (TaskStart)"

if [[ ! -d "$AB" ]]; then
  echo "No .AgentBridge/ found. Install with:"
  echo "  curl -sSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash"
  exit 0
fi

echo "### Goal"
if [[ -f "${AB}/goal.md" ]]; then sed -n '1,40p' "${AB}/goal.md"; else echo "_(none)_"; fi

echo
echo "### Next action"
if [[ -f "${AB}/next.md" ]]; then sed -n '1,40p' "${AB}/next.md"; else echo "_(none)_"; fi

echo
echo "### State"
if [[ -f "${AB}/state.md" ]]; then sed -n '1,60p' "${AB}/state.md"; else echo "_(none)_"; fi

echo
echo "### Git state"
if [[ -f "${AB}/git-state.md" ]]; then sed -n '1,40p' "${AB}/git-state.md"; else echo "_(none)_"; fi

echo
echo "---"
echo "AgentBridge: context restored. Update .AgentBridge/state.md and .AgentBridge/next.md"
echo "after every meaningful step. (No runtime, no MCP, Markdown only.)"