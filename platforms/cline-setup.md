# Cline setup

1. Run `curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/v0.2.0/install.sh | bash -s -- --platform cline --project "$PWD"`.
2. Restart Cline.
3. Say: "Activate AgentBridge".

## Automatic checkpoints (installed by default)

`install.sh` installs two hooks in `.cline/hooks/`:

- `session-shutdown.sh` — runs `checkpoint.sh` after each Cline session
  (refreshes git-state.md, writes a session file, appends an INDEX row).
- `post-tool-use.sh` — appends a one-line activity entry to
  `.AgentBridge/state.md` after each meaningful tool call
  (`write_to_file`, `replace_in_file`, `execute_command`, `apply_diff`).
  It no-ops on unknown tool names by design. If your Cline version sets
  `CLINE_TOOL_NAME` differently, update the case statement in the hook —
  it exits early on unrecognized tools.

Checkpoints happen both per-step (PostToolUse) and at session end
(SessionShutdown), so credit-limit interruptions are lossless.

## If auto-install failed

Create `.cline/hooks/SessionShutdown.sh` manually:

```bash
#!/usr/bin/env bash
PROJECT_DIR="$(pwd)"
bash "$HOME/.cline/skills/AgentBridge/scripts/checkpoint.sh" "$PROJECT_DIR" || true
```

Make it executable: `chmod +x .cline/hooks/*.sh`.
