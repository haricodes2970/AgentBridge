# shellcheck shell=bash
# Harness registry for AgentBridge.
# Source this file, do not execute it.

# Shared canonical location. Most modern harnesses read this directly.
AGENTBRIDGE_CANONICAL="${HOME}/.agents/skills/AgentBridge"

# Prints the global skills directory for a harness name.
# Returns 1 if the harness is unknown.
harness_global_dir() {
  case "$1" in
    cline)     printf '%s\n' "${HOME}/.cline/skills" ;;
    opencode)  printf '%s\n' "${HOME}/.config/opencode/skills" ;;
    claude)    printf '%s\n' "${HOME}/.claude/skills" ;;
    codex)     printf '%s\n' "${HOME}/.codex/skills" ;;
    gemini)    printf '%s\n' "${HOME}/.gemini/skills" ;;
    cursor)    printf '%s\n' "${HOME}/.cursor/skills" ;;
    copilot)   printf '%s\n' "${HOME}/.copilot/skills" ;;
    windsurf)  printf '%s\n' "${HOME}/.codeium/windsurf/skills" ;;
    amp)       printf '%s\n' "${HOME}/.config/amp/skills" ;;
    kiro)      printf '%s\n' "${HOME}/.kiro/skills" ;;
    roo)       printf '%s\n' "${HOME}/.roo/skills" ;;
    kilo)      printf '%s\n' "${HOME}/.kilo/skills" ;;
    factory)   printf '%s\n' "${HOME}/.factory/skills" ;;
    warp)      printf '%s\n' "${HOME}/.agents/skills" ;;
    goose)     printf '%s\n' "${HOME}/.agents/skills" ;;
    augment)   printf '%s\n' "${HOME}/.augment/skills" ;;
    qwen)      printf '%s\n' "${HOME}/.qwen/skills" ;;
    continue)  printf '%s\n' "${HOME}/.continue/skills" ;;
    aider)     printf '%s\n' "${HOME}/.aider/skills" ;;
    *)         return 1 ;;
  esac
}

# Returns 0 if this harness's global dir IS ~/.agents/skills (no symlink needed).
harness_is_shared() {
  case "$1" in
    warp|goose) return 0 ;;
    *) return 1 ;;
  esac
}

# Returns 0 if this harness supports automatic hooks in a project.
harness_has_hooks() {
  case "$1" in
    cline|claude|opencode) return 0 ;;
    *) return 1 ;;
  esac
}

# Prints all known harness names, one per line, in display order.
harness_list() {
  cat <<'EOF'
cline
opencode
claude
codex
gemini
cursor
copilot
windsurf
amp
kiro
roo
kilo
factory
warp
goose
augment
qwen
continue
aider
EOF
}

# Detects installed harnesses by checking for config directories.
# Prints matching harness names, one per line.
harness_detect() {
  local h dir
  while IFS= read -r h; do
    harness_is_shared "$h" && continue
    dir="$(harness_global_dir "$h")" || continue
    # Check the parent config dir, not the skills subdir (which may not exist yet)
    case "$h" in
      opencode)  [[ -d "${HOME}/.config/opencode" || -d ".opencode" ]] && echo "$h" ;;
      claude)    [[ -d "${HOME}/.claude" || -d ".claude" ]] && echo "$h" ;;
      cline)     [[ -d "${HOME}/.cline" || -d ".cline" || -f ".clinerules" ]] && echo "$h" ;;
      windsurf)  [[ -d "${HOME}/.codeium/windsurf" ]] && echo "$h" ;;
      amp)       [[ -d "${HOME}/.config/amp" || -d "${HOME}/.amp" ]] && echo "$h" ;;
      continue)  [[ -d "${HOME}/.continue" ]] && echo "$h" ;;
      aider)     [[ -f "${HOME}/.aider.conf.yml" || -d "${HOME}/.aider" ]] && echo "$h" ;;
      *)         [[ -d "$(dirname "$dir")" || -d ".${h}" ]] && echo "$h" ;;
    esac
  done < <(harness_list)
}
