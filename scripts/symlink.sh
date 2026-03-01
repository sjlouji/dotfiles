#!/usr/bin/env bash
# =============================================================================
# symlink.sh — Create symlinks from dotfiles repo into the right places
# Safe to run multiple times (idempotent)
# =============================================================================

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RESET='\033[0m'
info()    { echo -e "${BLUE}  → $*${RESET}"; }
success() { echo -e "${GREEN}  ✓ $*${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠ $*${RESET}"; }

link() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir=$(dirname "$dest")

  mkdir -p "$dest_dir"

  if [[ -L "$dest" ]]; then
    # Already a symlink — update if target changed
    local current_target
    current_target=$(readlink "$dest")
    if [[ "$current_target" != "$src" ]]; then
      rm "$dest"
      ln -s "$src" "$dest"
      success "Updated: $dest → $src"
    else
      info "Already linked: $dest"
    fi
  elif [[ -f "$dest" ]]; then
    # Real file exists — back it up
    local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    warn "Backed up existing: $dest → $backup"
    ln -s "$src" "$dest"
    success "Linked: $dest → $src"
  else
    ln -s "$src" "$dest"
    success "Linked: $dest → $src"
  fi
}

echo -e "\n${BLUE}▶ Creating symlinks...${RESET}\n"

# ── Zsh ───────────────────────────────────────────────────────────────────────
link "$DOTFILES_DIR/zsh/.zshrc"   "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/.zshenv"  "$HOME/.zshenv"

# ── Git ───────────────────────────────────────────────────────────────────────
link "$DOTFILES_DIR/git/.gitconfig"         "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES_DIR/git/.gitmessage"        "$HOME/.gitmessage"

# git commit template directory (hooks live here when templateDir is set)
mkdir -p "$HOME/.git_template/hooks"

# ── SSH ───────────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.ssh" "$HOME/.ssh/control"
chmod 700 "$HOME/.ssh"
link "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# ── Claude ────────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.claude"
link "$DOTFILES_DIR/claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json"   "$HOME/.claude/settings.json"

# Claude Desktop MCP config
CLAUDE_DESKTOP_DIR="$HOME/Library/Application Support/Claude"
mkdir -p "$CLAUDE_DESKTOP_DIR"
link "$DOTFILES_DIR/claude/mcp.json" "$CLAUDE_DESKTOP_DIR/claude_desktop_config.json"

# ── VS Code ───────────────────────────────────────────────────────────────────
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_DIR"
link "$DOTFILES_DIR/vscode/settings.json"    "$VSCODE_DIR/settings.json"
link "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"

# ── Make all bin/ scripts executable ─────────────────────────────────────────
if [[ -d "$DOTFILES_DIR/bin" ]]; then
  find "$DOTFILES_DIR/bin" -type f ! -name "*.md" -exec chmod +x {} \;
  success "bin/ scripts marked executable"
fi

# ── Make all scripts/ scripts executable ──────────────────────────────────────
if [[ -d "$DOTFILES_DIR/scripts" ]]; then
  find "$DOTFILES_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
fi

# ── Make all macos/ scripts executable ────────────────────────────────────────
if [[ -d "$DOTFILES_DIR/macos" ]]; then
  find "$DOTFILES_DIR/macos" -type f -name "*.sh" -exec chmod +x {} \;
fi

# ── Make all sync/ scripts executable ─────────────────────────────────────────
if [[ -d "$DOTFILES_DIR/sync" ]]; then
  find "$DOTFILES_DIR/sync" -type f -exec chmod +x {} \;
fi

# ── dsync command ─────────────────────────────────────────────────────────────
link "$DOTFILES_DIR/sync/dsync.sh" "$DOTFILES_DIR/bin/dsync"

echo -e "\n${GREEN}✓ All symlinks created.${RESET}\n"
