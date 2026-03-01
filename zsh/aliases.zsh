# =============================================================================
# aliases.zsh — Sourced by .zshrc
# =============================================================================

# ── Navigation ────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'                    # go back to previous dir

# ── ls → eza ─────────────────────────────────────────────────────────────────
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first --git'
  alias lt='eza --tree --icons --level=2'
  alias lta='eza --tree --icons --level=3 --all'
else
  alias ls='ls -G'
  alias ll='ls -lahG'
fi

# ── cat → bat ─────────────────────────────────────────────────────────────────
if command -v bat &>/dev/null; then
  alias cat='bat --style=auto'
  alias catp='bat --style=plain'      # plain output, no decorations
fi

# ── grep → ripgrep ────────────────────────────────────────────────────────────
if command -v rg &>/dev/null; then
  alias grep='rg'
fi

# ── Git ───────────────────────────────────────────────────────────────────────
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gpl='git pull --rebase --autostash'
alias gf='git fetch --all --prune'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --decorate --graph -20'
alias gla='git log --oneline --decorate --graph --all'
alias gst='git stash'
alias gstp='git stash pop'
alias gundo='git reset HEAD~1 --soft'   # undo last commit, keep changes staged
alias gwip='git add -A && git commit -m "wip: $(date +%Y-%m-%d)"'

# ── Dotfiles ──────────────────────────────────────────────────────────────────
alias dots='cd $DOTFILES_DIR'
alias dotss='dsync status'
alias dotsp='dsync'                # push dotfile changes
alias dotspl='dsync pull'          # pull dotfile changes

# ── macOS ────────────────────────────────────────────────────────────────────
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; echo "DNS flushed"'
alias sleepnow='pmset sleepnow'
alias emptytrash='rm -rf ~/.Trash/*'
alias cleanup='find . -name ".DS_Store" -delete && echo "DS_Store files removed"'

# ── Network ───────────────────────────────────────────────────────────────────
alias myip='curl -s https://ipinfo.io/ip'
alias localip="ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1"
alias ping='ping -c 5'

# ── Dev ───────────────────────────────────────────────────────────────────────
alias python='python3'
alias pip='pip3'
alias serve='python3 -m http.server 8080'     # quick local server
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'  # show listening ports

# ── VS Code ───────────────────────────────────────────────────────────────────
alias c='code .'
alias ci='code-insiders .'

# ── Misc ─────────────────────────────────────────────────────────────────────
alias reload='exec $SHELL -l'         # reload shell
alias path='echo $PATH | tr ":" "\n"' # print PATH one per line
alias brewup='brew update && brew upgrade && brew autoremove && brew cleanup'
alias h='history | fzf'              # fuzzy search history
alias hosts='sudo $EDITOR /etc/hosts'
alias week='date +%V'                 # current week number
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# ── Safety nets ───────────────────────────────────────────────────────────────
alias rm='trash'                      # use our safe trash script instead of rm
alias cp='cp -iv'                     # confirm overwrites
alias mv='mv -iv'                     # confirm overwrites
