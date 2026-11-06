# Cross-agent handoff test (manual)

Prerequisite: two different coding agents installed (e.g. Cline + OpenCode; the
buddy script does the switching).

Run these commands first:
  bash scripts/dogfood-setup.sh
  bash scripts/dogfood-control.sh

## Arm 1 — with AgentBridge
1. Open /tmp/agentbridge-dogfood in Agent A (e.g. Cline). Do NOT touch the bridge.
2. Ask: "What is the next action?" Record Agent A's answer.
3. Close Agent A without further interaction.
4. Open /tmp/agentbridge-dogfood in Agent B (e.g. OpenCode). Give it exactly:
   "Resume the task. Start by reading .AgentBridge/."
5. Record: first action, files read before first edit, whether it correctly
   identified the goal and next action.

## Arm 2 — control (no bridge)
1. Open /tmp/agentbridge-dogfood-control in Agent B. Give it exactly:
   "Resume the task."
2. Record the same four metrics.

## What to record
- Files read before first edit (both arms)
- Tool calls before first useful action (both arms)
- Whether Agent B located the bug in lib/tax-calculator.js
- Whether Agent B asked any questions (and if so, what the bridge failed to answer)
- Stale bridge? Run scripts/status.sh before Arm 1 and record output.

## Write the report
Copy docs/cross-agent-dogfood-template.md to
docs/cross-agent-dogfood-YYYY-MM-DD.md and fill it in.
