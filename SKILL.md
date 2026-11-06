---
name: AgentBridge
description: |
  Cross-agent context handoff. Triggers: "activate AgentBridge", "switch agent",
  "new session", "handoff", "credit limit". Maintains a local .AgentBridge/ folder
  (goal.md, next.md, state.md, git-state.md) so any coding agent resumes from four
  small Markdown files instead of re-reading the whole repo. Zero runtime, no MCP
  server, no secrets.
---

# AgentBridge

Cross-agent context handoff for lossless agent and session switching.

## Why it exists

When an agent hits a credit or context limit, the next agent starts with zero memory.
It re-reads files, re-greps symbols, and re-infers the goal—burning tokens and time
before doing any real work. AgentBridge stores durable task state (goal, decisions,
progress, next action, git state, session summaries) in plain Markdown so the next
agent resumes from four small files instead of the whole repo.

## Tiered storage

### Hot path (read every session)
| File | Purpose |
|------|---------|
| `.AgentBridge/goal.md` | Current objective |
| `.AgentBridge/next.md` | Immediate next action |
| `.AgentBridge/state.md` | Progress, blockers, decisions summary |
| `.AgentBridge/git-state.md` | Branch, commit, working-tree state |

### Cold path (read on demand)
| File | Purpose |
|------|---------|
| `.AgentBridge/environment.md` | Environment summary |
| `.AgentBridge/decisions.md` | Key architectural decisions |
| `.AgentBridge/sessions/` | Per-session summaries |

## Design principles

- **Markdown only, no runtime.** Any agent can read it without an MCP server,
  daemon, or graph build.
- **Summarize, don't dump.** No raw transcripts. No secrets. Reference artifacts
  by path/URL.
- **Checkpoint continuously.** Credit limits are abrupt. Write after every
  meaningful step, not only at session end.
- **Cross-platform.** Works with Cline, OpenCode, Claude Code, and Codex.

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash
```

The installer detects your platform (Cline `.cline/`, OpenCode `.opencode/` or
`.agents/`, Claude Code `.claude/`), installs the skill, seeds `.AgentBridge/`,
and adds it to `.gitignore`.

## Usage

1. Edit `.AgentBridge/goal.md` with your current objective.
2. Edit `.AgentBridge/next.md` with the immediate next action.
3. Trigger the skill in your agent:
   - "activate AgentBridge"
   - "switch agent"
   - "new session"
   - "handoff"
   - "credit limit"
4. After every meaningful step, update `.AgentBridge/state.md` and
   `.AgentBridge/next.md`.

## Hooks

Cline supports `TaskStart`, `TaskComplete`, `SessionShutdown`, and `PostToolUse`
hooks. The installer wires them into `.cline/settings.json` so `.AgentBridge/`
stays current automatically. For agents without hooks, the SKILL.md instructions
are the fallback.

## License

MIT