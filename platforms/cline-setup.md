# Cline setup

1. Run `curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash -s -- --platform cline --project "$PWD"`.
2. Restart Cline.
3. Say: "Activate AgentBridge".

## Optional: automatic checkpoints

Create `.cline/hooks/SessionShutdown.sh`:

```bash
#!/usr/bin/env bash
PROJECT_DIR="$(pwd)"
bash "$HOME/.cline/skills/AgentBridge/scripts/checkpoint.sh" "$PROJECT_DIR" || true
```

And `.cline/hooks/PostToolUse.sh`:

```bash
#!/usr/bin/env bash
# Fires after tool execution. Only checkpoint on file writes/commands if desired.
exit 0
```

Make them executable: `chmod +x .cline/hooks/*.sh`.
