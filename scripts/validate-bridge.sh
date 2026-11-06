#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="${1:-$PWD}"
BRIDGE="$PROJECT_DIR/.AgentBridge"

FAIL=0
WARN=0
PASS=0

ok()  { echo "PASS: $1"; PASS=$((PASS + 1)); }
warn() { echo "WARN: $1"; WARN=$((WARN + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# Check bridge exists
if [[ ! -d "$BRIDGE" ]]; then
  fail ".AgentBridge/ does not exist at $BRIDGE"
  echo ""
  echo "Summary: $PASS pass, $WARN warn, $FAIL fail"
  exit 1
fi
ok ".AgentBridge/ exists"

# Check required files exist and are non-empty
for f in goal.md next.md state.md git-state.md decisions.md environment.md; do
  path="$BRIDGE/$f"
  if [[ ! -f "$path" ]]; then
    fail "$f missing"
  elif [[ ! -s "$path" ]]; then
    if [[ "$f" == "environment.md" ]]; then
      warn "$f is empty (empty environment.md is allowed)"
    else
      fail "$f is empty"
    fi
  else
    ok "$f exists and is non-empty"
  fi
done

# Check next.md contains a "## Do this next" heading
if grep -q '^## Do this next' "$BRIDGE/next.md" 2>/dev/null; then
  ok "next.md contains '## Do this next' heading"
else
  fail "next.md missing '## Do this next' heading"
fi

# Grep for common secret patterns in hot-path files
SECRET_PATTERNS='sk-|AKIA|ghp_|-----BEGIN|password=|api_key=|token='
HOT_FILES="$BRIDGE/goal.md $BRIDGE/next.md $BRIDGE/state.md $BRIDGE/git-state.md"
for f in $HOT_FILES; do
  if [[ -f "$f" ]]; then
    while IFS=: read -r fname lineno rest; do
      [[ -z "$fname" ]] && continue
      warn "Possible secret in $fname line $lineno"
    done < <(grep -inE "$SECRET_PATTERNS" "$f" 2>/dev/null || true)
  fi
done

# Summary
echo ""
echo "Summary: $PASS pass, $WARN warn, $FAIL fail"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0