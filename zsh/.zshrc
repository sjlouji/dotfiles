# =============================================================================
# .zshrc — Main Zsh config
# Loaded for every interactive shell
# =============================================================================

# ── Machine Identity (must be first) ──────────────────────────────────────────
[[ -f "$DOTFILES_DIR/.local/machine.sh" ]] && source "$DOTFILES_DIR/.local/machine.sh"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BREW_PREFIX="${BREW_PREFIX:-/opt/homebrew}"

# ── Homebrew ──────────────────────────────────────────────────────────────────
eval "$("$BREW_PREFIX/bin/brew" shellenv)"

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"           # change to your preferred theme

# Homebrew-managed completion dirs are group-writable by design — suppress the
# OMZ security check so it doesn't block startup on a fresh Homebrew install
export ZSH_DISABLE_COMPFIX=true

# fzf: set base path before OMZ loads, but only add the plugin if fzf exists
# (avoids errors on a fresh Mac before brew bundle has run)
export FZF_BASE="$BREW_PREFIX/opt/fzf"

# Plugins — keep this list lean, slow plugins hurt startup time
# Note: direnv is handled below with an explicit guard (no OMZ plugin needed)
plugins=(
  git
  macos
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
  you-should-use
)
# Add fzf plugin only when fzf is actually installed
[[ -d "$FZF_BASE" ]] && plugins+=(fzf)

source "$ZSH/oh-my-zsh.sh"

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$DOTFILES_DIR/bin:$PATH"                 # custom scripts
export PATH="$HOME/.local/bin:$PATH"                  # local user bins
export PATH="$BREW_PREFIX/opt/curl/bin:$PATH"         # brew curl over system
export PATH="$BREW_PREFIX/opt/git/bin:$PATH"          # brew git over system

# ── Mise (runtime version manager) ───────────────────────────────────────────
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# ── Zoxide (smarter cd) ───────────────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# ── FZF ───────────────────────────────────────────────────────────────────────
if [[ -f "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  source "$BREW_PREFIX/opt/fzf/shell/completion.zsh"
fi
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR="code --wait"
export VISUAL="$EDITOR"
export PAGER="bat --style=plain"

# ── Locale ────────────────────────────────────────────────────────────────────
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ── History ───────────────────────────────────────────────────────────────────
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt SHARE_HISTORY           # share history across sessions
setopt HIST_IGNORE_DUPS        # don't record duplicates
setopt HIST_IGNORE_SPACE       # don't record lines starting with space
setopt HIST_VERIFY             # show command before executing from history

# ── Completion ────────────────────────────────────────────────────────────────
fpath+=("$BREW_PREFIX/share/zsh-completions" "$BREW_PREFIX/share/zsh/site-functions")
autoload -Uz compinit && compinit -i
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case insensitive

# ── Aliases ───────────────────────────────────────────────────────────────────
source "$DOTFILES_DIR/zsh/aliases.zsh"

# ── Direnv ────────────────────────────────────────────────────────────────────
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# ── 1Password CLI (op) ────────────────────────────────────────────────────────
if command -v op &>/dev/null; then
  eval "$(op completion zsh)"; compdef _op op
fi

# ── GH CLI completions ────────────────────────────────────────────────────────
if command -v gh &>/dev/null; then
  eval "$(gh completion -s zsh)"
fi

# ── Background dotfile sync check (once per day, non-blocking) ────────────────
_DOTFILES_LAST_CHECK="$DOTFILES_DIR/.local/.last_sync_check"
if [[ ! -f "$_DOTFILES_LAST_CHECK" ]] || \
   [[ $(find "$_DOTFILES_LAST_CHECK" -mtime +1 2>/dev/null) ]]; then
  (
    touch "$_DOTFILES_LAST_CHECK"
    cd "$DOTFILES_DIR" 2>/dev/null || exit
    git fetch --quiet origin 2>/dev/null
    BEHIND=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo 0)
    if [[ "$BEHIND" -gt 0 ]]; then
      echo -e "\033[1;33m dotfiles: $BEHIND new commit(s) on remote. Run \`dsync pull\` to update.\033[0m"
    fi
  ) &!
fi

# ── Machine-local overrides (last — wins over everything) ─────────────────────
[[ -f "$DOTFILES_DIR/.local/.zshrc.local" ]] && source "$DOTFILES_DIR/.local/.zshrc.local"
