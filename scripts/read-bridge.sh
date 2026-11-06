#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
BRIDGE="$PROJECT_DIR/.AgentBridge"

if [[ ! -d "$BRIDGE" ]]; then
  echo "Error: .AgentBridge/ not found at $BRIDGE" >&2
  exit 1
fi

print_section() {
  local label="$1" file="$2"
  echo "===== $label ====="
  cat "$file"
}

print_section "goal.md" "$BRIDGE/goal.md"
print_section "next.md" "$BRIDGE/next.md"
print_section "state.md" "$BRIDGE/state.md"
print_section "git-state.md" "$BRIDGE/git-state.md"

# Last 5 entries of decisions.md, split on "## " headings.
if [[ -f "$BRIDGE/decisions.md" ]]; then
  echo "===== decisions.md ====="
  awk '
  BEGIN { count = 0; buf = ""; in_block = 0 }
  /^## / {
    if (in_block) {
      blocks[count] = buf
      count++
    }
    buf = $0 "\n"
    in_block = 1
    next
  }
  in_block { buf = buf $0 "\n" }
  END {
    if (in_block) {
      blocks[count] = buf
      count++
    }
    start = (count > 5) ? count - 5 : 0
    for (i = start; i < count; i++) {
      if (i > start) printf "\n"
      printf "%s", blocks[i]
    }
  }
  ' "$BRIDGE/decisions.md"
fi

if [[ -f "$BRIDGE/sessions/INDEX.md" ]]; then
  print_section "sessions/INDEX.md" "$BRIDGE/sessions/INDEX.md"
fi