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

echo "Done. Restart your agent and say: 'Activate AgentBridge'."
