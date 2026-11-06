#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
BRIDGE="$PROJECT_DIR/.AgentBridge"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$SKILL_DIR/templates"

if [[ -d "$BRIDGE" ]]; then
  echo ".AgentBridge already exists at $BRIDGE"
  exit 0
fi

mkdir -p "$BRIDGE/sessions"
cp "$TEMPLATES/goal.md" "$BRIDGE/goal.md"
cp "$TEMPLATES/state.md" "$BRIDGE/state.md"
cp "$TEMPLATES/decisions.md" "$BRIDGE/decisions.md"
cp "$TEMPLATES/next.md" "$BRIDGE/next.md"
cp "$TEMPLATES/git-state.md" "$BRIDGE/git-state.md"
cp "$TEMPLATES/environment.md" "$BRIDGE/environment.md"
cp "$TEMPLATES/INDEX.md" "$BRIDGE/sessions/INDEX.md"

# seed git-state
cd "$PROJECT_DIR"
BRANCH="$(git branch --show-current 2>/dev/null || echo 'unknown')"
HEAD="$(git rev-parse --short HEAD 2>/dev/null || echo 'none')"
DIRTY="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
cat > "$BRIDGE/git-state.md" <<EOF
# Git state

- Updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Branch: \`$BRANCH\`
- HEAD: \`$HEAD\`
- Dirty files: $DIRTY
- Unpushed commits: (run checkpoint.sh to refresh)
- Last push: unknown
EOF

echo ".AgentBridge initialized at $BRIDGE"