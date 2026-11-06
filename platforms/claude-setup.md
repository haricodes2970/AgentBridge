# Claude Code setup

1. Run `curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash -s -- --platform claude --project "$PWD"`.
2. Restart Claude Code.
3. Say: "Activate AgentBridge".

If you use hooks, add a `SessionEnd` hook that calls `checkpoint.sh`.
