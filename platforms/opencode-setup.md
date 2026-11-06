# OpenCode setup

1. Run `curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash -s -- --platform opencode --project "$PWD"`.
2. Restart OpenCode.
3. Say: "Activate AgentBridge".

OpenCode also reads `.agents/skills/` and `.claude/skills/`, so the same skill works across tools if you prefer a shared location.
