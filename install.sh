#!/usr/bin/env bash
set -euo pipefail

REPO="haricodes2970/AgentBridge"
BRANCH="main"
SKILL_NAME="AgentBridge"
PROJECT_DIR="${PWD}"
PLATFORM="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ "$PLATFORM" == "auto" ]]; then
  if [[ -d ".cline" ]] || [[ -f ".clinerules" ]]; then PLATFORM="cline"
  elif [[ -d ".opencode" ]]; then PLATFORM="opencode"
  elif [[ -d ".claude" ]]; then PLATFORM="claude"
  else PLATFORM="generic"
  fi
fi

case "$PLATFORM" in
  cline) SKILL_DIR="$HOME/.cline/skills/$SKILL_NAME" ;;
  opencode) SKILL_DIR="$HOME/.config/opencode/skills/$SKILL_NAME" ;;
  claude) SKILL_DIR="$HOME/.claude/skills/$SKILL_NAME" ;;
  *) SKILL_DIR="$HOME/.agentbridge/skills/$SKILL_NAME" ;;
esac

if [[ "${AGENTBRIDGE_SKIP_CLONE:-}" == "1" ]]; then
  echo "Skipping git clone; copying local tree into $SKILL_DIR"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$SCRIPT_DIR"
  rm -rf "$SKILL_DIR"
  mkdir -p "$(dirname "$SKILL_DIR")"
  cp -r "$REPO_ROOT" "$SKILL_DIR"
elif [[ -d "$SKILL_DIR/.git" ]]; then
  echo "Updating $SKILL_NAME in $SKILL_DIR"
  git -C "$SKILL_DIR" pull --ff-only
else
  echo "Installing $SKILL_NAME to $SKILL_DIR"
  mkdir -p "$(dirname "$SKILL_DIR")"
  git clone --depth 1 "https://github.com/${REPO}.git" "$SKILL_DIR"
fi

cd "$PROJECT_DIR"
bash "$SKILL_DIR/scripts/init-bridge.sh" "$PROJECT_DIR"

if ! grep -qxF '.AgentBridge/' .gitignore 2>/dev/null; then
  echo '.AgentBridge/' >> .gitignore
  echo "Added .AgentBridge/ to .gitignore"
fi

# Wire Cline hooks automatically
if [[ "$PLATFORM" == "cline" ]]; then
  HOOKS_DIR="$PROJECT_DIR/.cline/hooks"
  mkdir -p "$HOOKS_DIR"
  cat > "$HOOKS_DIR/session-shutdown.sh" <<'EOF'
#!/usr/bin/env bash
AGENT_NAME=cline bash "$HOME/.cline/skills/AgentBridge/scripts/checkpoint.sh" "$PWD" || true
EOF
  chmod +x "$HOOKS_DIR/session-shutdown.sh"
  echo "Installed Cline SessionShutdown hook at $HOOKS_DIR/session-shutdown.sh"
fi

# Wire Claude Code hooks automatically
if [[ "$PLATFORM" == "claude" ]]; then
  CLAUDE_DIR="$PROJECT_DIR/.claude"
  SETTINGS="$CLAUDE_DIR/settings.json"
  HOOK_CMD='AGENT_NAME=claude bash "$HOME/.claude/skills/AgentBridge/scripts/checkpoint.sh" "$PWD" || true'
  mkdir -p "$CLAUDE_DIR"
  if [[ ! -f "$SETTINGS" ]]; then
    printf '{"hooks":{}}\n' > "$SETTINGS"
    echo "Created .claude/settings.json"
  fi
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SETTINGS" 2>/dev/null; then
      echo "WARNING: $SETTINGS is not valid JSON; skipping hook wiring"
      echo "Manual: add SessionEnd hook to $SETTINGS: $HOOK_CMD"
    else
      python3 - "$SETTINGS" "$HOOK_CMD" <<'PY'
import json, sys
path, cmd = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
hooks = data.setdefault("hooks", {})
existing = hooks.get("SessionEnd", [])
if cmd not in existing:
    existing.append(cmd)
    hooks["SessionEnd"] = existing
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
      echo "Installed Claude Code SessionEnd hook in $SETTINGS"
    fi
  elif command -v jq >/dev/null 2>&1; then
    if ! jq empty "$SETTINGS" >/dev/null 2>&1; then
      echo "WARNING: $SETTINGS is not valid JSON; skipping hook wiring"
      echo "Manual: add SessionEnd hook to $SETTINGS: $HOOK_CMD"
    else
      TMPJQ="$(mktemp)"
      jq --arg cmd "$HOOK_CMD" '
        .hooks.SessionEnd = (
          (.hooks.SessionEnd // [])
          | if index($cmd) == null then . + [$cmd] else . end
        )
      ' "$SETTINGS" > "$TMPJQ" && mv "$TMPJQ" "$SETTINGS"
      echo "Installed Claude Code SessionEnd hook in $SETTINGS"
    fi
  else
    echo "WARNING: neither python3 nor jq available; cannot merge SessionEnd hook into $SETTINGS"
    echo "Manual: add to $SETTINGS hooks.SessionEnd: $HOOK_CMD"
  fi
fi

# Wire OpenCode checkpoint instruction via AGENTS.md
if [[ "$PLATFORM" == "opencode" ]]; then
  AGENTS_MD="$PROJECT_DIR/AGENTS.md"
  AB_START="<!-- AgentBridge:start -->"
  AB_END="<!-- AgentBridge:end -->"
  if [[ -f "$AGENTS_MD" ]] && grep -qF "$AB_START" "$AGENTS_MD"; then
    echo "AgentBridge block already present in $AGENTS_MD"
  else
    TMPMD="$(mktemp)"
    {
      [[ -f "$AGENTS_MD" ]] && cat "$AGENTS_MD"
      [[ -s "$AGENTS_MD" ]] && echo
      cat <<'EOF'
<!-- AgentBridge:start -->
## AgentBridge
Before ending this session, run:
`AGENT_NAME=opencode bash "$HOME/.config/opencode/skills/AgentBridge/scripts/checkpoint.sh" "$PWD"`
Do not skip this. If the command fails, note it in .AgentBridge/state.md.
<!-- AgentBridge:end -->
EOF
    } > "$TMPMD" && mv "$TMPMD" "$AGENTS_MD"
    echo "Updated $AGENTS_MD with AgentBridge checkpoint instruction"
  fi
fi

echo "Done. Restart your agent and say: 'Activate AgentBridge'."
