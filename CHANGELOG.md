# Changelog

All notable changes to AgentBridge are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-11-06

### Fixed
- sessions/INDEX.md now seeds from a table template, not a session template (affects anyone installing from a pinned version)
- git-state.md now separates AgentBridge-managed artifacts from user changes

### Added
- scripts/read-bridge.sh and scripts/status.sh
- Automatic checkpoint wiring for OpenCode (AGENTS.md block) and Claude Code (SessionEnd hook)
- scripts/uninstall.sh and scripts/validate-bridge.sh
- Optional code-map.md pointer file
- Dogfood validation report

## [0.1.0] - 2026-11-06

### Added
- SKILL.md skill scaffold (`name: AgentBridge`, trigger phrases, read/write rules)
- install.sh — curl installer with `--project`/`--platform`, auto-detection, `.gitignore` wiring
- scripts/init-bridge.sh — creates `.AgentBridge/` from templates, seeds git-state
- scripts/checkpoint.sh — refreshes git-state.md, writes session summary + INDEX
- templates/ — goal.md, state.md, decisions.md, next.md, git-state.md, environment.md, session.md
- platforms/ — cline-setup.md, opencode-setup.md, claude-setup.md
- tests/smoke.sh — verifies init-bridge/checkpoint behavior
- tests/install-dryrun.sh — offline install verification (AGENTBRIDGE_SKIP_CLONE)
- .github/workflows/test.yml — CI: bash -n + smoke + dry-run tests
- Cline hook auto-install (`.cline/hooks/session-shutdown.sh`) via install.sh
- examples/sample-bridge/ — populated `.AgentBridge/` after ~3 sessions

[0.1.0]: https://github.com/haricodes2970/AgentBridge/releases/tag/v0.1.0
