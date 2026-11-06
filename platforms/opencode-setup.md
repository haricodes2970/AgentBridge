# OpenCode setup

1. Run `curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash -s -- --platform opencode --project "$PWD"`.
2. Restart OpenCode.
3. Say: "Activate AgentBridge".

`install.sh` automatically adds an AgentBridge checkpoint instruction block to your project's `AGENTS.md` (delimited by `<!-- AgentBridge:start -->` / `<!-- AgentBridge:end -->`). Run the listed `checkpoint.sh` command before ending each OpenCode session.

OpenCode also reads `.agents/skills/` and `.claude/skills/`, so the same skill works across tools if you prefer a shared location.

## If auto-install failed

If the AGENTS.md block was not added, create it manually:

```markdown
<!-- AgentBridge:start -->
## AgentBridge
Before ending this session, run:
`AGENT_NAME=opencode bash "$HOME/.config/opencode/skills/AgentBridge/scripts/checkpoint.sh" "$PWD"`
Do not skip this. If the command fails, note it in .AgentBridge/state.md.
<!-- AgentBridge:end -->
```
