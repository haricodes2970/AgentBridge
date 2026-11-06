#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="${1:-$PWD}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --) shift; PROJECT_DIR="${1:-$PWD}"; break ;;
    *) PROJECT_DIR="$1"; shift ;;
  esac
done

BRIDGE="$PROJECT_DIR/.AgentBridge"
GI="$PROJECT_DIR/.gitignore"
CLINE_HOOK="$PROJECT_DIR/.cline/hooks/session-shutdown.sh"
AGENTS_MD="$PROJECT_DIR/AGENTS.md"
CLAUDE_SETTINGS="$PROJECT_DIR/.claude/settings.json"
HOOK_CMD='AGENT_NAME=claude bash "$HOME/.claude/skills/AgentBridge/scripts/checkpoint.sh" "$PWD" || true'

# 1. Remove .AgentBridge/ from the target project
if [[ -d "$BRIDGE" ]]; then
  rm -rf "$BRIDGE"
  echo "Removed .AgentBridge/ from $PROJECT_DIR"
else
  echo ".AgentBridge/ not found at $BRIDGE (already removed)"
fi

# 2. Remove the .AgentBridge/ line from .gitignore (exact-line match only)
if [[ -f "$GI" ]] && grep -qxF '.AgentBridge/' "$GI"; then
  grep -vxF '.AgentBridge/' "$GI" > "${GI}.tmp" 2>/dev/null || true
  mv "${GI}.tmp" "$GI"
  echo "Removed .AgentBridge/ from .gitignore"
else
  echo ".AgentBridge/ not in .gitignore"
fi

# 3. Remove .cline/hooks/session-shutdown.sh if it exactly matches the
#    AgentBridge-generated file.
if [[ -f "$CLINE_HOOK" ]]; then
  EXPECTED='#!/usr/bin/env bash
AGENT_NAME=cline bash "$HOME/.cline/skills/AgentBridge/scripts/checkpoint.sh" "$PWD" || true'
  ACTUAL="$(cat "$CLINE_HOOK" 2>/dev/null || true)"
  if [[ "$ACTUAL" == "$EXPECTED" ]]; then
    rm -f "$CLINE_HOOK"
    echo "Removed .cline/hooks/session-shutdown.sh"
  else
    echo ".cline/hooks/session-shutdown.sh does not match AgentBridge-generated content; leaving it"
  fi
fi

# 4. Remove the AgentBridge block from AGENTS.md if markers exist
if [[ -f "$AGENTS_MD" ]] && grep -qF '<!-- AgentBridge:start -->' "$AGENTS_MD" && grep -qF '<!-- AgentBridge:end -->' "$AGENTS_MD"; then
  awk '
    /<!-- AgentBridge:start -->/ { skip=1; next }
    skip && /<!-- AgentBridge:end -->/ { skip=0; next }
    !skip { print }
  ' "$AGENTS_MD" > "${AGENTS_MD}.tmp" && mv "${AGENTS_MD}.tmp" "$AGENTS_MD"
  echo "Removed AgentBridge block from $AGENTS_MD"
elif [[ -f "$AGENTS_MD" ]]; then
  echo "AgentBridge block not found in $AGENTS_MD"
fi

# 5. Remove the SessionEnd hook entry from .claude/settings.json if it exists
if [[ -f "$CLAUDE_SETTINGS" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$CLAUDE_SETTINGS" 2>/dev/null; then
      echo "WARNING: $CLAUDE_SETTINGS is not valid JSON; skipping SessionEnd hook removal"
      echo "Manual: remove the AgentBridge SessionEnd entry from $CLAUDE_SETTINGS"
    else
      python3 - "$CLAUDE_SETTINGS" "$HOOK_CMD" <<'PY'
import json, sys
path, cmd = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
hooks = data.get("hooks", {})
existing = hooks.get("SessionEnd", [])
if cmd in existing:
    existing.remove(cmd)
    hooks["SessionEnd"] = existing
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("Removed SessionEnd hook from %s" % path)
else:
    print("SessionEnd hook not found in %s" % path)
PY
    fi
  elif command -v jq >/dev/null 2>&1; then
    if ! jq empty "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
      echo "WARNING: $CLAUDE_SETTINGS is not valid JSON; skipping SessionEnd hook removal"
      echo "Manual: remove the AgentBridge SessionEnd entry from $CLAUDE_SETTINGS"
    else
      TMPJQ="$(mktemp)"
      jq --arg cmd "$HOOK_CMD" '
        .hooks.SessionEnd = (
          (.hooks.SessionEnd // [])
          | map(select(. != $cmd))
        )
      ' "$CLAUDE_SETTINGS" > "$TMPJQ" && mv "$TMPJQ" "$CLAUDE_SETTINGS"
      echo "Removed SessionEnd hook from $CLAUDE_SETTINGS"
    fi
  else
    echo "WARNING: neither python3 nor jq available; cannot remove SessionEnd hook from $CLAUDE_SETTINGS"
    echo "Manual: remove the AgentBridge SessionEnd entry from $CLAUDE_SETTINGS"
  fi
fi

echo ""
echo "Note: The AgentBridge skill directory (~/.cline/skills/AgentBridge,"
echo "~/.config/opencode/skills/AgentBridge, ~/.claude/skills/AgentBridge)"
echo "was NOT deleted. Remove it manually if desired (e.g. rm -rf ~/.cline/skills/AgentBridge)."

exit 0