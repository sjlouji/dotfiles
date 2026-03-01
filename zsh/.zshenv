# =============================================================================
# .zshenv — Loaded for ALL zsh instances (interactive, non-interactive, scripts)
# Keep this minimal — only things every shell process needs
# =============================================================================

# Dotfiles location (used before machine.sh is available)
export DOTFILES_DIR="$HOME/.dotfiles"

# XDG base dirs (many tools respect these)
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Suppress Homebrew hints
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1    # we update manually via dsync/brew bundle

# Mise — set data dir
export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
