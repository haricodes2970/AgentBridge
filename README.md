# AgentBridge

Cross-agent context handoff and session continuity for AI coding agents (OpenCode, Cline, Claude Code, Codex).

## Why it exists

When an agent hits a credit or context limit, the next agent starts with zero memory. It re-reads files, re-greps symbols, and re-infers the goal—burning tokens and time before doing any real work. AgentBridge stores durable task state (goal, decisions, progress, next action, git state, session summaries) in plain Markdown so any agent can resume from four small files instead of the whole repository.

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash
```

Optionally target a platform:

```bash
curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash -s -- --platform cline --project "$PWD"
```

## Activation

Restart your agent, then say: **"Activate AgentBridge"**. This runs `scripts/init-bridge.sh` to create `.AgentBridge/` at the project root and confirms the bridge is active.

## File structure

```
.AgentBridge/
├── goal.md            # hot path: stable objective, constraints, definition of done
├── next.md            # hot path: single next action + open questions
├── state.md           # hot path: current focus, files touched, blockers, activity log
├── git-state.md       # hot path: branch, HEAD, unpushed commits, dirty files
├── decisions.md       # cold path: append-only decisions (last 5 entries read each session)
├── environment.md     # cold path: commands, ports, env var names (no values), quirks
└── sessions/
    ├── INDEX.md       # index of session summaries
    └── YYYY-MM-DD-HHMM-<agent>.md   # per-session summary
```

## How it differs from Graphify

Graphify builds a structural code graph and uses a query-first pattern (consult the graph before grepping). AgentBridge is a lightweight task-state handoff protocol: four small Markdown files, no graph build, no MCP server, no daemon, zero runtime dependencies. It is designed for lossless agent/session switching, not code navigation.

## Design notes

- `.AgentBridge/` is gitignored by design—it is local-only session memory, not project source.
- Summarize, don't dump. No raw transcripts, no secrets.
- Write early and often; credit limits are abrupt.
