---
name: AgentBridge
description: Cross-agent context handoff and session continuity. Use when switching AI coding agents (OpenCode, Cline, Claude Code, Codex), starting a new session in the same tool, running low on credits or context, or when the user says "activate AgentBridge", "set up AgentBridge", "switch agent", "new session", "handoff", "resume context", or "credit limit". Maintains a .AgentBridge/ folder with goal, state, decisions, next action, git state, and session summaries so any agent can resume without re-reading the entire repository.
---

# AgentBridge

## What this skill does

AgentBridge is a file-based handoff protocol. It creates and maintains a `.AgentBridge/` folder at the project root containing plain Markdown files that any coding agent can read. The goal: **make switching agents or starting a new session lossless and near-instant**, so the next agent does not re-explore the repository.

## Activation (first time only)

When the user says "Activate AgentBridge" or similar:

1. Run `bash "$SKILL_DIR/scripts/init-bridge.sh" "$PWD"` to create `.AgentBridge/` from templates.
2. Verify `.AgentBridge/` is in `.gitignore`. If not, append it.
3. Read `goal.md`, `next.md`, `state.md`, `git-state.md`.
4. Confirm: "AgentBridge activated. I will read `.AgentBridge/` before touching source files and update it after every meaningful step."

If `$SKILL_DIR` is unknown, find the skill directory by checking `.cline/skills/AgentBridge`, `~/.cline/skills/AgentBridge`, `.opencode/skills/AgentBridge`, or `~/.config/opencode/skills/AgentBridge`.

## Every session: read order

Preferred: run `bash <skill-dir>/scripts/read-bridge.sh "$PWD"` and read its output. Fallback if the script is unavailable: read the four hot-path files manually in the same order.

1. `.AgentBridge/goal.md` — stable objective, constraints, definition of done.
2. `.AgentBridge/next.md` — the single next action and open questions.
3. `.AgentBridge/state.md` — current focus, files touched, tests run, blockers.
4. `.AgentBridge/git-state.md` — branch, HEAD, unpushed commits, dirty files.
5. `.AgentBridge/decisions.md` — read the last 5 entries only.
6. If `.AgentBridge/code-map.md` exists and is non-empty, read it before grepping the repo.

If `sessions/INDEX.md` exists, read it to find the most recent session summary. Open that file only if you need more history.

## Every meaningful step: write immediately

After each meaningful action (file edit, state-changing command, architectural decision, test run), update the bridge **immediately**. Do not wait for session end—credit limits are abrupt.

- Append a one-line bullet to `state.md` under `## Activity log` with timestamp, action, and result.
- If you made a decision, append to `decisions.md`: decision, reason, alternatives rejected.
- Update `next.md` with the single next action.
- Update `git-state.md` if you committed, pushed, or changed branches.

## Before ending a session or when context/credits are low

Run:

```bash
bash "$SKILL_DIR/scripts/checkpoint.sh" "$PWD"
```

This refreshes git-state.md, creates sessions/YYYY-MM-DD-HHMM-<agent>.md, and appends a row to sessions/INDEX.md.

If the script is unavailable, manually write the session summary using templates/session.md.

## Rules

- Summarize, don't dump. Never store raw prompts, responses, or transcripts. Store decisions, outcomes, next actions.
- Never store secrets. No API keys, tokens, passwords, PII. Reference env var names only.
- Reference artifacts, don't duplicate. Link to PRs, issues, ADRs, commits by path or URL.
- One next action. next.md must be unambiguous.
- Keep the hot path small. goal.md, next.md, state.md, git-state.md each under ~100 lines.
- Freshness beats completeness. A slightly stale bridge is useful; a missing bridge is not. Write early and often.
