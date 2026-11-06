# Claude Code setup

1. Run `curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash -s -- --platform claude --project "$PWD"`.
2. Restart Claude Code.
3. Say: "Activate AgentBridge".

`install.sh` automatically creates/updates `.claude/settings.json` with a `SessionEnd` hook that runs `checkpoint.sh` after each Claude Code session.

## If auto-install failed

If `python3` or `jq` is unavailable, or `.claude/settings.json` is not valid JSON, add the hook manually:

```json
{
  "hooks": {
    "SessionEnd": [
      "AGENT_NAME=claude bash \"$HOME/.claude/skills/AgentBridge/scripts/checkpoint.sh\" \"$PWD\" || true"
    ]
  }
}
```

Or run the checkpoint manually at session end:
```bash
AGENT_NAME=claude bash "$HOME/.claude/skills/AgentBridge/scripts/checkpoint.sh" "$PWD"
```
