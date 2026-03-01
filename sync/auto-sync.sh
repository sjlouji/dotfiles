#!/usr/bin/env bash
# =============================================================================
# auto-sync.sh — Called by the LaunchAgent every 30 minutes
# Only pulls (never auto-commits/pushes — that's always manual via dsync)
# =============================================================================

set -euo pipefail

[[ -f "$HOME/.dotfiles/.local/machine.sh" ]] && source "$HOME/.dotfiles/.local/machine.sh"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BRANCH="main"
LOG_FILE="/tmp/dotfiles-sync.log"
CHECK_ONLY="${1:-}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log "Auto-sync check started (host: $(hostname -s))"

# Bail if not a git repo
if ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  log "ERROR: $DOTFILES_DIR is not a git repo"
  exit 1
fi

# Bail if no network
if ! ping -c 1 -t 3 github.com &>/dev/null; then
  log "No network — skipping"
  exit 0
fi

# Fetch quietly
git -C "$DOTFILES_DIR" fetch --quiet origin "$BRANCH" 2>> "$LOG_FILE" || {
  log "Fetch failed"
  exit 0
}

BEHIND=$(git -C "$DOTFILES_DIR" rev-list "HEAD..origin/$BRANCH" --count 2>/dev/null || echo 0)

if [[ "$BEHIND" -eq 0 ]]; then
  log "Already up to date"
  exit 0
fi

log "$BEHIND new commit(s) available on origin/$BRANCH"

# In check-only mode, just notify — don't pull
if [[ "$CHECK_ONLY" == "--check-only" ]]; then
  exit 0
fi

# Check for local uncommitted changes — don't pull if dirty
DIRTY=$(git -C "$DOTFILES_DIR" status --porcelain | grep -v '^!!' || true)
if [[ -n "$DIRTY" ]]; then
  log "Local changes present — skipping auto-pull (run 'dsync pull' manually)"
  exit 0
fi

# Safe to pull
log "Pulling $BEHIND commit(s)..."
git -C "$DOTFILES_DIR" pull --rebase --quiet origin "$BRANCH" 2>> "$LOG_FILE" && {
  log "Pull successful"
  # Re-symlink silently
  bash "$DOTFILES_DIR/scripts/symlink.sh" >> "$LOG_FILE" 2>&1
  log "Symlinks refreshed"
} || {
  log "Pull failed — manual intervention needed"
}
