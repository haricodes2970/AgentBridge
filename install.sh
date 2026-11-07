#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/haricodes2970/AgentBridge.git"
CANONICAL="${HOME}/.agents/skills/AgentBridge"
SKIP_CLONE="${AGENTBRIDGE_SKIP_CLONE:-0}"

PROJECT_DIR="$PWD"
HARNESSES=""
MODE=""
NO_HOOKS=0

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  --project DIR        Project directory to seed .AgentBridge/ (default: $PWD)
  --harnesses "a,b,c"  Comma- or space-separated harness names
  --all                Install into every supported harness
  --auto               Detect installed harnesses and install into those
  --interactive        Prompt to pick harnesses
  --no-hooks           Skip hook wiring (Cline/Claude/OpenCode)
  --platform X         Deprecated alias for --harnesses X
  --help               Show this message

Harnesses: cline opencode claude codex gemini cursor copilot windsurf
           amp kiro roo kilo factory warp goose augment qwen continue aider
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)     PROJECT_DIR="$2"; shift 2 ;;
    --harnesses)   HARNESSES="$2"; shift 2 ;;
    --all)         MODE="all"; shift ;;
    --auto)        MODE="auto"; shift ;;
    --interactive) MODE="interactive"; shift ;;
    --no-hooks)    NO_HOOKS=1; shift ;;
    --platform)    HARNESSES="$2"; shift 2; echo "note: --platform is deprecated; use --harnesses" >&2 ;;
    --help|-h)     usage; exit 0 ;;
    *)             echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

# 1. Clone / update canonical
if [[ -d "$CANONICAL/.git" ]]; then
  if [[ "$SKIP_CLONE" == "1" ]]; then
    echo "[1/5] skip-clone: using existing $CANONICAL"
  else
    echo "[1/5] updating $CANONICAL"
    git -C "$CANONICAL" pull --ff-only || echo "  warn: pull failed, continuing with existing"
  fi
else
  echo "[1/5] installing canonical to $CANONICAL"
  mkdir -p "$(dirname "$CANONICAL")"
  if [[ "$SKIP_CLONE" == "1" ]]; then
    SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp -R "$SRC" "$CANONICAL"
  else
    git clone --depth 1 "$REPO_URL" "$CANONICAL"
  fi
fi

# 2. Source harness registry
if [[ ! -f "$CANONICAL/lib/harnesses.sh" ]]; then
  echo "error: $CANONICAL/lib/harnesses.sh missing" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$CANONICAL/lib/harnesses.sh"

# 3. Resolve harness selection
if [[ -z "$HARNESSES" && -z "$MODE" ]]; then
  if [[ -t 0 ]]; then MODE="interactive"; else MODE="auto"; fi
fi

case "$MODE" in
  all)
    HARNESSES="$(harness_list | tr '\n' ' ')"
    echo "[2/5] --all: all harnesses selected"
    ;;
  auto)
    HARNESSES="$(harness_detect | tr '\n' ' ')"
    if [[ -z "${HARNESSES// /}" ]]; then
      echo "error: no harnesses detected. Re-run with --interactive or --harnesses." >&2
      exit 1
    fi
    echo "[2/5] --auto detected: $HARNESSES"
    ;;
  interactive)
    echo "[2/5] select harnesses:"
    mapfile -t names < <(harness_list)
    for i in "${!names[@]}"; do
      printf '  %2d) %s\n' "$((i+1))" "${names[$i]}"
    done
    read -r -p "Enter numbers (space-separated), or 'all': " input
    if [[ "$input" == "all" ]]; then
      HARNESSES="$(harness_list | tr '\n' ' ')"
    else
      selected=()
      for n in $input; do
        if ! [[ "$n" =~ ^[0-9]+$ ]] || (( n < 1 || n > ${#names[@]} )); then
          echo "invalid selection: $n" >&2; exit 1
        fi
        selected+=("${names[$((n-1))]}")
      done
      HARNESSES="${selected[*]}"
    fi
    ;;
  "") ;;
esac

HARNESSES="$(echo "$HARNESSES" | tr ',' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//')"
if [[ -z "$HARNESSES" ]]; then
  echo "error: no harnesses selected" >&2
  exit 1
fi

# 4. Symlink each harness
echo "[3/5] linking into harnesses"
SELECTED_SUMMARY=()
for h in $HARNESSES; do
  if ! harness_global_dir "$h" >/dev/null 2>&1; then
    echo "  warn: unknown harness '$h', skipping"
    continue
  fi
  TARGET_DIR="$(harness_global_dir "$h")"
  if [[ "$TARGET_DIR" == "${HOME}/.agents/skills" ]]; then
    SELECTED_SUMMARY+=("$h:shared")
    echo "  $h: shared (canonical already visible)"
    continue
  fi
  mkdir -p "$(dirname "$TARGET_DIR")"
  mkdir -p "$TARGET_DIR"
  LINK_PATH="$TARGET_DIR/AgentBridge"
  # Path safety: only remove if the link target literally ends with /AgentBridge
  if [[ -e "$LINK_PATH" || -L "$LINK_PATH" ]]; then
    case "$LINK_PATH" in
      */AgentBridge) rm -rf "$LINK_PATH" ;;
      *) echo "  error: refusing to remove unexpected path: $LINK_PATH" >&2; exit 1 ;;
    esac
  fi
  if ln -s "$CANONICAL" "$LINK_PATH" 2>/dev/null; then
    SELECTED_SUMMARY+=("$h:symlink")
    echo "  $h: symlinked → $LINK_PATH"
  else
    cp -R "$CANONICAL" "$LINK_PATH"
    SELECTED_SUMMARY+=("$h:copy")
    echo "  $h: copied → $LINK_PATH"
  fi
done

# 5. Seed project bridge
echo "[4/5] seeding project bridge in $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
bash "$CANONICAL/scripts/init-bridge.sh" "$PROJECT_DIR"

GITIGNORE="$PROJECT_DIR/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  if ! grep -qxF '.AgentBridge/' "$GITIGNORE"; then
    echo '.AgentBridge/' >> "$GITIGNORE"
    echo "  added .AgentBridge/ to .gitignore"
  fi
else
  echo '.AgentBridge/' > "$GITIGNORE"
  echo "  created .gitignore with .AgentBridge/"
fi

# 6. Hooks
if [[ "$NO_HOOKS" == "0" ]]; then
  echo "[5/5] wiring hooks"
  has() { case " $HARNESSES " in *" $1 "*) return 0;; *) return 1;; esac; }
  has cline    && install_cline_hooks    "$PROJECT_DIR" || true
  has claude   && install_claude_hooks   "$PROJECT_DIR" || true
  has opencode && install_opencode_hooks "$PROJECT_DIR" || true
else
  echo "[5/5] hooks skipped (--no-hooks)"
fi

echo ""
echo "Installed harnesses:"
for s in "${SELECTED_SUMMARY[@]}"; do
  echo "  ${s%%:*} → ${s##*:}"
done
echo ""
echo "Canonical skill: $CANONICAL"
echo "Project bridge:  $PROJECT_DIR/.AgentBridge"
echo ""
echo "Restart your agents, then say: Activate AgentBridge"

# ─── Hook installers ────────────────────────────────────────────────────
install_cline_hooks() {
  local proj="$1" hooks_dir="$1/.cline/hooks"
  mkdir -p "$hooks_dir"
  cat > "$hooks_dir/session-shutdown.sh" <<'HOOK'
#!/usr/bin/env bash
AGENT_NAME=cline bash "$HOME/.cline/skills/AgentBridge/scripts/checkpoint.sh" "$PWD" || true
HOOK
  chmod +x "$hooks_dir/session-shutdown.sh"
  cat > "$hooks_dir/post-tool-use.sh" <<'HOOK'
#!/usr/bin/env bash
BRIDGE="$PWD/.AgentBridge"
[ -d "$BRIDGE" ] || exit 0
[ -f "$BRIDGE/state.md" ] || exit 0
case "${CLINE_TOOL_NAME:-unknown}" in
  write_to_file|replace_in_file|execute_command|apply_diff) ;;
  *) exit 0 ;;
esac
printf -- "- %s — %s\n" "$(date -u +%FT%TZ)" "${CLINE_TOOL_NAME:-unknown}" >> "$BRIDGE/state.md"
HOOK
  chmod +x "$hooks_dir/post-tool-use.sh"
  echo "  cline: hooks installed"
}

install_claude_hooks() {
  local proj="$1" settings="$1/.claude/settings.json"
  mkdir -p "$proj/.claude"
  [[ -f "$settings" ]] || echo '{"hooks":{}}' > "$settings"
  local cmd='AGENT_NAME=claude bash "$HOME/.claude/skills/AgentBridge/scripts/checkpoint.sh" "$PWD" || true'
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$settings" "$cmd" <<'PY'
import json, sys
p, cmd = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(p))
except json.JSONDecodeError:
    print("  claude: settings.json is not valid JSON, skipping hook", file=sys.stderr)
    sys.exit(0)
d.setdefault("hooks", {}).setdefault("SessionEnd", [])
if not any(h.get("command") == cmd for h in d["hooks"]["SessionEnd"]):
    d["hooks"]["SessionEnd"].append({"command": cmd})
json.dump(d, open(p, "w"), indent=2)
PY
    echo "  claude: SessionEnd hook wired (python3)"
  elif command -v jq >/dev/null 2>&1; then
    local tmp; tmp="$(mktemp)"
    jq --arg c "$cmd" '.hooks.SessionEnd = ((.hooks.SessionEnd // []) + [{"command":$c}] | unique_by(.command))' \
      "$settings" > "$tmp" && mv "$tmp" "$settings"
    echo "  claude: SessionEnd hook wired (jq)"
  else
    echo "  claude: install python3 or jq to auto-wire hooks; skipping"
  fi
}

install_opencode_hooks() {
  local proj="$1" f="$1/AGENTS.md"
  local start='<!-- AgentBridge:start -->' end='<!-- AgentBridge:end -->'
  if [[ -f "$f" ]] && grep -qF "$start" "$f"; then
    echo "  opencode: AGENTS.md block already present"
    return 0
  fi
  {
    echo ""
    echo "$start"
    echo "## AgentBridge"
    echo "Before ending this session, run:"
    echo '`AGENT_NAME=opencode bash "$HOME/.config/opencode/skills/AgentBridge/scripts/checkpoint.sh" "$PWD"`'
    echo "$end"
  } >> "$f"
  echo "  opencode: AGENTS.md block added"
}