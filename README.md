# AgentBridge

Cross-agent context handoff for lossless agent and session switching. Installed via
`curl`, lives in a `.AgentBridge/` folder, and works with Cline, OpenCode, Claude
Code, and Codex — no MCP server, no daemon, no runtime.

## Problem

When an agent hits a credit or context limit, the next agent starts with zero
memory. It re-reads files, re-greps symbols, and re-infers the goal—burning tokens
and time before doing any real work.

## Solution

AgentBridge stores durable task state (goal, decisions, progress, next action, git
state, session summaries) in plain Markdown. The next agent resumes from four small
hot-path files instead of the whole repo.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash
```

The installer detects your platform (Cline `.cline/`, OpenCode `.opencode/` or
`.agents/`, Claude Code `.claude/`), installs the skill, seeds `.AgentBridge/`,
and adds it to `.gitignore`.

## Folder layout (hot path first)

```
.AgentBridge/
├── goal.md          # current objective        (read every session)
├── next.md          # immediate next action    (read every session)
├── state.md         # progress & blockers      (read every session)
├── git-state.md     # branch, commit, status   (read every session)
├── environment.md   # environment summary      (cold path)
├── decisions.md     # key decisions            (cold path)
└── sessions/        # per-session summaries    (cold path)
```

## Triggers

Activate the skill in your agent with any of:
- "activate AgentBridge"
- "switch agent"
- "new session"
- "handoff"
- "credit limit"

## Principles

- Markdown only, no runtime
- Summarize, don't dump (no raw transcripts, no secrets)
- Checkpoint continuously, not only at session end
- Cross-platform (Cline, OpenCode, Claude Code, Codex)

## License

MIT