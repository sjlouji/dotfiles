# =============================================================================
# .zshenv — Loaded for ALL zsh instances (interactive, non-interactive, scripts)
# Keep this minimal — only things every shell process needs
# =============================================================================

# Dotfiles location — resolved from the symlink target of this file.
# Falls back to ~/.dotfiles if the symlink isn't set up yet.
if [[ -L "$HOME/.zshenv" ]]; then
  export DOTFILES_DIR="${$(readlink "$HOME/.zshenv")%/zsh/.zshenv}"
else
  export DOTFILES_DIR="$HOME/.dotfiles"
fi

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

# ── Machine-local zshenv (sourced last) ───────────────────────────────────────
# If .zshenv.local modifies PATH, warn the user to move that to .zshrc.local
local _old_path="$PATH"
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
if [[ $PATH != $_old_path ]]; then
  typeset -AHg fg fg_bold
  if [ -t 2 ]; then
    fg[red]=$'\e[31m'
    fg_bold[white]=$'\e[1;37m'
    reset_color=$'\e[m'
  else
    fg[red]=""
    fg_bold[white]=""
    reset_color=""
  fi
  cat <<MSG >&2
${fg[red]}Warning:${reset_color} your \`~/.zshenv.local' configuration seems to edit PATH entries.
Please move that configuration to \`.zshrc.local' like so:
  ${fg_bold[white]}cat ~/.zshenv.local >> ~/.zshrc.local && rm ~/.zshenv.local${reset_color}
MSG
fi
unset _old_path
