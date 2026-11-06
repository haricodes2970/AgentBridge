#!/usr/bin/env bash
###############################################################################
# AgentBridge installer
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/main/install.sh | bash
#
# What it does:
#   1. Detects the agent platform(s) configured in the project (Cline, OpenCode, Claude Code)
#   2. Installs the AgentBridge skill into the platform's skills directory
#   3. Seeds a local .AgentBridge/ folder (goal.md, next.md, state.md, git-state.md, ...)
#   4. Adds .AgentBridge/ to .gitignore
###############################################################################
set -euo pipefail

REPO_SLUG="haricodes2970/AgentBridge"
BRANCH="${AGENTBRIDGE_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${BRANCH}"
SKILL_DIR_NAME="AgentBridge"

PROJECT_ROOT="$(pwd)"
FORCE=0
SKIP_SEED=0
PLATFORMS=""

log()  { printf '\033[1;32m[agentbridge]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[agentbridge]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[agentbridge] error:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: install.sh [options]

Options:
  --platform cline|opencode|claude   Install only for this platform (default: detect all)
  --force                            Overwrite existing files
  --skip-seed                        Do not seed .AgentBridge/ in project root
  -h, --help                         Show this help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORMS="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --skip-seed) SKIP_SEED=1; shift ;;
    -h|--help) usage ;;
    *) err "unknown option: $1" ;;
  esac
done

have() { command -v "$1" >/dev/null 2>&1; }

fetch() {
  local url="$1" dest="$2"
  if have curl; then
    curl -fsSL "$url" -o "$dest"
  elif have wget; then
    wget -qO "$dest" "$url"
  else
    err "curl or wget is required to run the installer"
  fi
}

copy_asset() {
  local src_rel="$1" dest="$2"
  local url="${RAW_BASE}/${src_rel}"
  mkdir -p "$(dirname "$dest")"
  fetch "$url" "$dest"
}

detect_platforms() {
  local found=()
  [[ -d "${PROJECT_ROOT}/.cline" ]]                                               && found+=("cline")
  [[ -d "${PROJECT_ROOT}/.opencode" || -d "${PROJECT_ROOT}/.agents" ]]            && found+=("opencode")
  [[ -d "${PROJECT_ROOT}/.claude" ]]                                              && found+=("claude")
  if [[ ${#found[@]} -eq 0 ]]; then
    warn "No agent platform config found (.cline / .opencode / .agents / .claude)."
    warn "Defaulting to the Cline skills layout (.cline/skills/AgentBridge/)."
    found=("cline")
  fi
  echo "${found[*]}"
}

if [[ -z "$PLATFORMS" ]]; then
  PLATFORMS="$(detect_platforms)"
fi
log "Detected platforms: ${PLATFORMS}"
install_skill() {
  local platform="$1" skills_dir hooks_dir
  case "$platform" in
    cline)
      skills_dir="${PROJECT_ROOT}/.cline/skills/${SKILL_DIR_NAME}"
      hooks_dir="${PROJECT_ROOT}/.cline/hooks"
      ;;
    opencode)
      if [[ -d "${PROJECT_ROOT}/.agents" ]]; then
        skills_dir="${PROJECT_ROOT}/.agents/skills/${SKILL_DIR_NAME}"
      else
        skills_dir="${PROJECT_ROOT}/.opencode/skills/${SKILL_DIR_NAME}"
      fi
      hooks_dir="${PROJECT_ROOT}/.opencode/hooks"
      ;;
    claude)
      skills_dir="${PROJECT_ROOT}/.claude/skills/${SKILL_DIR_NAME}"
      hooks_dir="${PROJECT_ROOT}/.claude/hooks"
      ;;
    *) err "unknown platform: $platform" ;;
  esac

  log "Installing AgentBridge skill -> ${skills_dir}"

  mkdir -p "$skills_dir"
  copy_asset "SKILL.md" "${skills_dir}/SKILL.md"

  # Hook scripts (Cline-style; other agents can still read/source them)
  mkdir -p "$hooks_dir"
  for h in task-start task-complete session-shutdown post-tool-use; do
    copy_asset "hooks/${h}.sh" "${hooks_dir}/${h}.sh"
    chmod +x "${hooks_dir}/${h}.sh"
  done

  # Wire Cline hooks via settings.json if present
  if [[ "$platform" == "cline" ]]; then
    wire_cline_hooks "${PROJECT_ROOT}/.cline/settings.json" "$hooks_dir"
  fi

  log "Skill installed for ${platform}."
}

wire_cline_hooks() {
  local settings="$1" hooks_dir="$2"
  if [[ ! -f "$settings" ]]; then
    mkdir -p "$(dirname "$settings")"
    cat > "$settings" <<JSON
{
  "hooks": {
    "TaskStart": ["${hooks_dir}/task-start.sh"],
    "TaskComplete": ["${hooks_dir}/task-complete.sh"],
    "SessionShutdown": ["${hooks_dir}/session-shutdown.sh"],
    "PostToolUse": ["${hooks_dir}/post-tool-use.sh"]
  }
}
JSON
    log "Created .cline/settings.json with AgentBridge hooks"
    return
  fi
  warn ".cline/settings.json already exists — add AgentBridge hooks manually (see .cline/hooks/)"
}

refresh_git_state() {
  local ab="$1" file="${ab}/git-state.md"
  local branch commit dirty status
  if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$PROJECT_ROOT" symbolic-ref --short HEAD 2>/dev/null \
      || git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo detached)"
    commit="$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    if git -C "$PROJECT_ROOT" diff --quiet && git -C "$PROJECT_ROOT" diff --cached --quiet; then
      dirty="clean"
    else
      dirty="dirty"
    fi
    status="$(git -C "$PROJECT_ROOT" status --short --branch 2>/dev/null | head -20 || true)"
  else
    branch="n/a"; commit="n/a"; dirty="n/a (not a git repo)"; status=""
  fi
  cat > "$file" <<EOF
# Git State

## Branch
${branch}

## Last commit
${commit}

## Working tree
${dirty}

## Status
\`\`\`
${status}
\`\`\`

_Updated automatically by AgentBridge hooks._
EOF
}
seed_ab() {
  [[ "${SKIP_SEED:-0}" -eq 1 ]] && return 0
  local ab="${PROJECT_ROOT}/.AgentBridge"
  if [[ -d "$ab" && "$FORCE" -eq 0 ]]; then
    warn ".AgentBridge/ already exists (use --force to overwrite). Skipping seed."
    return 0
  fi
  log "Seeding .AgentBridge/ -> ${ab}"
  mkdir -p "$ab/sessions"
  copy_asset ".AgentBridge-template/goal.md"       "${ab}/goal.md"
  copy_asset ".AgentBridge-template/next.md"        "${ab}/next.md"
  copy_asset ".AgentBridge-template/state.md"       "${ab}/state.md"
  copy_asset ".AgentBridge-template/git-state.md"   "${ab}/git-state.md"
  copy_asset ".AgentBridge-template/environment.md" "${ab}/environment.md"
  copy_asset ".AgentBridge-template/decisions.md"   "${ab}/decisions.md"
  copy_asset ".AgentBridge-template/sessions/README.md" "${ab}/sessions/README.md"
  refresh_git_state "$ab"
  log ".AgentBridge/ seeded."
}

gitignore_add() {
  local gi="${PROJECT_ROOT}/.gitignore"
  local entry=".AgentBridge/"
  if [[ -f "$gi" ]] && grep -qx -- "$entry" "$gi"; then
    return 0
  fi
  {
    [[ -f "$gi" ]] && cat "$gi"
    [[ -s "$gi" ]] && echo
    echo "# AgentBridge — local session memory, not project source"
    echo "$entry"
  } > "${gi}.tmp" && mv "${gi}.tmp" "$gi"
  log "Added ${entry} to .gitignore"
}

main() {
  for p in $PLATFORMS; do install_skill "$p"; done
  seed_ab
  gitignore_add

  log "AgentBridge installed."
  echo
  echo "Next steps:"
  echo "  1. Edit .AgentBridge/goal.md  with your current objective."
  echo "  2. Edit .AgentBridge/next.md  with the immediate next action."
  echo "  3. Trigger the skill: \"activate AgentBridge\" / \"switch agent\" / \"new session\""
  echo "     / \"handoff\" / \"credit limit\""
  echo
  echo "Read more: https://github.com/${REPO_SLUG}"
}

main "$@"