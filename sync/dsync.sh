#!/usr/bin/env bash
# =============================================================================
# dsync — Dotfiles sync command
# Usage:
#   dsync              Push local changes to GitHub
#   dsync pull         Pull from GitHub + re-apply symlinks
#   dsync status       Show sync status
#   dsync --help
# =============================================================================

set -euo pipefail

[[ -f "$HOME/.dotfiles/.local/machine.sh" ]] && source "$HOME/.dotfiles/.local/machine.sh"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BRANCH="main"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}▶ $*${RESET}"; }
success() { echo -e "${GREEN}✓ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✗ $*${RESET}"; exit 1; }

_require_git() {
  if ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    error "Not a git repo: $DOTFILES_DIR"
  fi
}

cmd_status() {
  _require_git
  echo -e "\n${BOLD}Dotfiles sync status${RESET}"
  echo -e "  Repo:   $DOTFILES_DIR"
  echo -e "  Branch: $(git -C "$DOTFILES_DIR" branch --show-current)"
  echo ""

  git -C "$DOTFILES_DIR" fetch --quiet origin 2>/dev/null || warn "Could not reach remote"

  LOCAL=$(git -C "$DOTFILES_DIR" rev-parse HEAD)
  REMOTE=$(git -C "$DOTFILES_DIR" rev-parse "origin/$BRANCH" 2>/dev/null || echo "unknown")
  BASE=$(git -C "$DOTFILES_DIR" merge-base HEAD "origin/$BRANCH" 2>/dev/null || echo "unknown")

  if [[ "$LOCAL" == "$REMOTE" ]]; then
    success "Up to date with origin/$BRANCH"
  elif [[ "$LOCAL" == "$BASE" ]]; then
    BEHIND=$(git -C "$DOTFILES_DIR" rev-list HEAD..origin/$BRANCH --count)
    warn "$BEHIND commit(s) behind — run: dsync pull"
  elif [[ "$REMOTE" == "$BASE" ]]; then
    AHEAD=$(git -C "$DOTFILES_DIR" rev-list origin/$BRANCH..HEAD --count)
    warn "$AHEAD commit(s) ahead — run: dsync"
  else
    warn "Diverged from origin/$BRANCH — manual intervention may be needed"
  fi

  echo ""
  echo -e "${BOLD}Local changes:${RESET}"
  git -C "$DOTFILES_DIR" status --short || true
  echo ""
}

cmd_pull() {
  _require_git
  info "Pulling from origin/$BRANCH..."

  # Stash any local changes first
  STASHED=false
  if ! git -C "$DOTFILES_DIR" diff --quiet || ! git -C "$DOTFILES_DIR" diff --cached --quiet; then
    warn "Stashing local changes..."
    git -C "$DOTFILES_DIR" stash push -m "dsync auto-stash $(date +%Y-%m-%d)"
    STASHED=true
  fi

  git -C "$DOTFILES_DIR" pull --rebase origin "$BRANCH"

  if [[ "$STASHED" == "true" ]]; then
    info "Restoring stashed changes..."
    git -C "$DOTFILES_DIR" stash pop || warn "Could not restore stash — run 'git stash pop' manually"
  fi

  success "Pull complete"

  # Re-run symlinks if any config files changed
  info "Re-applying symlinks..."
  bash "$DOTFILES_DIR/scripts/symlink.sh"

  success "Done. Run 'reload' to apply shell changes."
}

cmd_push() {
  _require_git

  MACHINE_NAME="${MACHINE_NAME:-$(hostname -s)}"

  # Check for unstaged/untracked changes
  CHANGED=$(git -C "$DOTFILES_DIR" status --porcelain | grep -v '^!!' || true)

  if [[ -z "$CHANGED" ]]; then
    info "Nothing to commit."
    git -C "$DOTFILES_DIR" fetch --quiet origin
    AHEAD=$(git -C "$DOTFILES_DIR" rev-list "origin/$BRANCH..HEAD" --count 2>/dev/null || echo 0)
    if [[ "$AHEAD" -gt 0 ]]; then
      info "Pushing $AHEAD unpushed commit(s)..."
      git -C "$DOTFILES_DIR" push origin "$BRANCH"
      success "Pushed."
    else
      success "Already up to date."
    fi
    return
  fi

  echo -e "\n${BOLD}Changes to commit:${RESET}"
  git -C "$DOTFILES_DIR" status --short
  echo ""

  # Pull before push (rebase to avoid diverge)
  info "Pulling remote changes first (rebase)..."
  git -C "$DOTFILES_DIR" pull --rebase --autostash origin "$BRANCH" || {
    error "Rebase failed — resolve conflicts in $DOTFILES_DIR then run 'dsync' again"
  }

  # Commit
  git -C "$DOTFILES_DIR" add -A
  COMMIT_MSG="sync: ${MACHINE_NAME} $(date '+%Y-%m-%d %H:%M')"
  git -C "$DOTFILES_DIR" commit -m "$COMMIT_MSG"

  # Push
  info "Pushing to origin/$BRANCH..."
  git -C "$DOTFILES_DIR" push origin "$BRANCH"

  success "Pushed: $COMMIT_MSG"
}

cmd_help() {
  echo ""
  echo -e "${BOLD}dsync — Dotfiles sync tool${RESET}"
  echo ""
  echo "  dsync              Commit all changes and push to GitHub"
  echo "  dsync pull         Pull latest from GitHub + re-apply symlinks"
  echo "  dsync status       Show what's changed locally vs remote"
  echo "  dsync --help       Show this help"
  echo ""
}

# ── Entry point ───────────────────────────────────────────────────────────────
case "${1:-push}" in
  pull)       cmd_pull ;;
  status)     cmd_status ;;
  push|"")    cmd_push ;;
  --help|-h)  cmd_help ;;
  *)          error "Unknown command: $1. Run 'dsync --help'." ;;
esac
