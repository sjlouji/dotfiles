#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Dotfiles installer for macOS
#
# Full setup (fresh Mac):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sjlouji/dotfiles/main/bootstrap.sh)"
#
# Run a specific module on an existing setup:
#   bootstrap.sh ssh       — regenerate SSH keys for all GitHub accounts
#   bootstrap.sh git       — rewrite git identity files
#   bootstrap.sh claude    — set up Claude / MCP integrations
#   bootstrap.sh packages  — run brew bundle
#   bootstrap.sh vscode    — reinstall VS Code extensions
#   bootstrap.sh shell     — reinstall Oh My Zsh plugins, set default shell
#   bootstrap.sh symlinks  — recreate all symlinks
# =============================================================================

set -euo pipefail

# ── Colors + logging (inline — lib.sh may not exist yet on fresh installs) ───
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}▶ $*${RESET}"; }
success() { echo -e "${GREEN}✓ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✗ $*${RESET}"; exit 1; }
header()  { echo -e "\n${BOLD}${BLUE}━━━ $* ━━━${RESET}\n"; }

DOTFILES_DIR="$HOME/.dotfiles"

# ── Module dispatch (for existing setups) ─────────────────────────────────────
# If any arguments are passed, run only those modules and exit.
if [[ $# -gt 0 ]]; then
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    error "Dotfiles not found at $DOTFILES_DIR — run bootstrap.sh with no arguments first"
  fi

  source "$DOTFILES_DIR/scripts/setup/lib.sh"

  for module in "$@"; do
    case "$module" in
      ssh|git|claude|packages|vscode|shell|symlinks)
        header "Running module: $module"
        ;;
      *)
        error "Unknown module '$module'. Available: ssh git claude packages vscode shell symlinks"
        ;;
    esac
  done

  for module in "$@"; do
    case "$module" in
      ssh)      bash "$DOTFILES_DIR/scripts/setup/ssh.sh" ;;
      git)      bash "$DOTFILES_DIR/scripts/setup/git.sh" ;;
      claude)   bash "$DOTFILES_DIR/scripts/setup/claude.sh" ;;
      packages) brew bundle --file="$DOTFILES_DIR/Brewfile" || warn "Some items failed — check above" ;;
      vscode)
        if command -v code &>/dev/null; then
          while IFS= read -r ext; do
            [[ -z "$ext" || "$ext" == \#* ]] && continue
            code --install-extension "$ext" --force 2>/dev/null || warn "Failed: $ext"
          done < "$DOTFILES_DIR/vscode/extensions.txt"
          success "VS Code extensions installed"
        else
          warn "VS Code 'code' CLI not found"
        fi
        ;;
      shell)
        ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
          git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
          git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        [[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]] && \
          git clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/you-should-use"
        success "Zsh plugins up to date"
        ;;
      symlinks) bash "$DOTFILES_DIR/scripts/symlink.sh" ;;
    esac
  done

  echo ""
  success "Done. Run 'reload' to pick up any shell changes."
  exit 0
fi

# =============================================================================
# Full bootstrap — runs everything in order on a fresh Mac
# =============================================================================

# ── 1. Detect machine ─────────────────────────────────────────────────────────
header "Detecting machine"

ARCH=$(uname -m)
OS_VERSION=$(sw_vers -productVersion)
HOSTNAME=$(hostname -s)
CURRENT_USER=$(whoami)

if [[ "$ARCH" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"; CHIP="Apple Silicon"
else
  BREW_PREFIX="/usr/local"; CHIP="Intel"
fi

info "Host:    $HOSTNAME"
info "User:    $CURRENT_USER"
info "macOS:   $OS_VERSION"
info "Chip:    $CHIP ($ARCH)"
info "Brew:    $BREW_PREFIX"

# ── 2. Module selection ───────────────────────────────────────────────────────
header "What to configure"

echo -e "  ${BOLD}packages${RESET}  — Homebrew bundle (formulae, casks, fonts)"
echo -e "  ${BOLD}shell${RESET}     — Oh My Zsh, plugins, default shell"
echo -e "  ${BOLD}symlinks${RESET}  — dotfile symlinks"
echo -e "  ${BOLD}git${RESET}       — git identity files per account"
echo -e "  ${BOLD}ssh${RESET}       — SSH keys for GitHub accounts"
echo -e "  ${BOLD}claude${RESET}    — Claude / MCP integrations"
echo -e "  ${BOLD}vscode${RESET}    — VS Code extensions"
echo -e "  ${BOLD}all${RESET}       — everything above"
echo ""
read -rp "  Modules (space-separated) [all]: " _MODULE_INPUT
_MODULE_INPUT="${_MODULE_INPUT:-all}"
SELECTED_MODULES=($_MODULE_INPUT)

should_run() {
  local mod="$1"
  [[ " ${SELECTED_MODULES[*]} " =~ " ${mod} " ]] || [[ " ${SELECTED_MODULES[*]} " =~ " all " ]]
}

info "Configuring: ${SELECTED_MODULES[*]}"

# ── 3. Collect GitHub accounts ────────────────────────────────────────────────
# Accounts are needed when: dotfiles not yet cloned (fresh install),
# or ssh/git modules are selected.

GH_USERNAMES=()
GH_NAMES=()
GH_EMAILS=()
GH_FOLDERS=()
ACCOUNT_COUNT=0
ACCOUNTS_UPDATED=false

NEEDS_ACCOUNTS=false
[[ ! -d "$DOTFILES_DIR" ]] && NEEDS_ACCOUNTS=true
should_run "ssh" && NEEDS_ACCOUNTS=true
should_run "git" && NEEDS_ACCOUNTS=true

if [[ "$NEEDS_ACCOUNTS" == true ]]; then
  header "GitHub accounts"

  if [[ -f "$DOTFILES_DIR/.local/machine.sh" ]]; then
    source "$DOTFILES_DIR/.local/machine.sh"

    for acct in ${GITHUB_ACCOUNTS:-}; do
      upper="$(echo "$acct" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
      name_var="GH_${upper}_NAME"
      email_var="GH_${upper}_EMAIL"
      folder_var="GH_${upper}_FOLDER"
      GH_USERNAMES+=("$acct")
      GH_NAMES+=("${!name_var:-}")
      GH_EMAILS+=("${!email_var:-}")
      GH_FOLDERS+=("${!folder_var:-}")
    done
    ACCOUNT_COUNT=${#GH_USERNAMES[@]}

    success "Loaded $ACCOUNT_COUNT existing account(s):"
    for i in "${!GH_USERNAMES[@]}"; do
      echo "    @${GH_USERNAMES[$i]} → ~/${GH_FOLDERS[$i]}/"
    done
    echo ""

    read -rp "Add another GitHub account? [y/N]: " ADD_MORE
    if [[ "$ADD_MORE" =~ ^[Yy]$ ]]; then
    echo ""
    while true; do
      num=$((ACCOUNT_COUNT + 1))
      echo -e "${BOLD}── Account $num ─────────────────────────────${RESET}"

      read -rp "  GitHub username: " GH_USER
      read -rp "  Your name:       " GH_NAME
      read -rp "  Email:           " GH_EMAIL

      DEFAULT_FOLDER="github-${GH_USER}"
      read -rp "  Repos folder     (~/${DEFAULT_FOLDER}/): " GH_FOLDER
      GH_FOLDER="${GH_FOLDER:-$DEFAULT_FOLDER}"
      GH_FOLDER="${GH_FOLDER#~/}"
      GH_FOLDER="${GH_FOLDER%/}"

      GH_USERNAMES+=("$GH_USER")
      GH_NAMES+=("$GH_NAME")
      GH_EMAILS+=("$GH_EMAIL")
      GH_FOLDERS+=("$GH_FOLDER")
      ACCOUNT_COUNT=$((ACCOUNT_COUNT + 1))
      ACCOUNTS_UPDATED=true

      echo ""
      echo -e "  ${GREEN}→ SSH host alias:${RESET} github-${GH_USER}"
      echo -e "  ${GREEN}→ SSH key:${RESET}        ~/.ssh/id_ed25519_${GH_USER}"
      echo -e "  ${GREEN}→ Repos in:${RESET}       ~/${GH_FOLDER}/"
      echo ""

      read -rp "Add yet another GitHub account? [y/N]: " ADD_MORE
      [[ ! "$ADD_MORE" =~ ^[Yy]$ ]] && break
      echo ""
    done
  fi
else
  echo -e "${BOLD}Set up your GitHub accounts.${RESET}"
  echo "Each account gets its own SSH key and git identity, scoped by folder."
  echo ""

  while true; do
    num=$((ACCOUNT_COUNT + 1))
    if [[ $ACCOUNT_COUNT -eq 0 ]]; then
      echo -e "${BOLD}── Account 1 (primary) ──────────────────────${RESET}"
    else
      echo -e "${BOLD}── Account $num ─────────────────────────────${RESET}"
    fi

    read -rp "  GitHub username: " GH_USER
    read -rp "  Your name:       " GH_NAME
    read -rp "  Email:           " GH_EMAIL

    if   [[ $ACCOUNT_COUNT -eq 0 ]]; then DEFAULT_FOLDER="personal"
    elif [[ $ACCOUNT_COUNT -eq 1 ]]; then DEFAULT_FOLDER="work"
    else                                   DEFAULT_FOLDER="github-${GH_USER}"
    fi

    read -rp "  Repos folder     (~/${DEFAULT_FOLDER}/): " GH_FOLDER
    GH_FOLDER="${GH_FOLDER:-$DEFAULT_FOLDER}"
    GH_FOLDER="${GH_FOLDER#~/}"
    GH_FOLDER="${GH_FOLDER%/}"

    GH_USERNAMES+=("$GH_USER")
    GH_NAMES+=("$GH_NAME")
    GH_EMAILS+=("$GH_EMAIL")
    GH_FOLDERS+=("$GH_FOLDER")
    ACCOUNT_COUNT=$((ACCOUNT_COUNT + 1))

    echo ""
    echo -e "  ${GREEN}→ SSH host alias:${RESET} github-${GH_USER}"
    echo -e "  ${GREEN}→ SSH key:${RESET}        ~/.ssh/id_ed25519_${GH_USER}"
    echo -e "  ${GREEN}→ Repos in:${RESET}       ~/${GH_FOLDER}/"
    echo ""

    read -rp "Add another GitHub account? [y/N]: " ADD_MORE
    [[ ! "$ADD_MORE" =~ ^[Yy]$ ]] && break
    echo ""
  done

  GIT_NAME="${GH_NAMES[0]}"
  GIT_EMAIL="${GH_EMAILS[0]}"

  case "${GH_FOLDERS[0]}" in
    work*) MACHINE_ROLE="work" ;;
    *)     MACHINE_ROLE="${GH_FOLDERS[0]%%/*}" ;;
  esac

  success "Configured $ACCOUNT_COUNT GitHub account(s) — primary: @${GH_USERNAMES[0]}"
  fi  # end NEEDS_ACCOUNTS fresh-install branch
fi    # end NEEDS_ACCOUNTS

# ── 4. Xcode CLI tools ────────────────────────────────────────────────────────
header "Xcode CLI tools"

if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode CLI tools..."
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
  success "Xcode CLI tools installed"
else
  success "Xcode CLI tools already present"
fi

# ── 4. Homebrew ───────────────────────────────────────────────────────────────
header "Homebrew"

if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  success "Homebrew installed"
else
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  success "Homebrew already present"
fi

# ── 5. Clone dotfiles ─────────────────────────────────────────────────────────
header "Dotfiles repo"

PRIMARY_GH_USER="${GH_USERNAMES[0]:-}"

if [[ ! -d "$DOTFILES_DIR" ]]; then
  brew install gh git 2>/dev/null || true

  # Authenticate with HTTPS — SSH keys don't exist yet and won't be set up
  # until step 13. After SSH setup, git_protocol is switched to ssh.
  # admin:public_key scope is required for `gh ssh-key add` in step 13.
  info "Authenticating with GitHub (@${PRIMARY_GH_USER})..."
  gh auth login --hostname github.com --git-protocol https --web --scopes admin:public_key

  info "Cloning dotfiles via HTTPS..."
  gh repo clone "${PRIMARY_GH_USER}/dotfiles" "$DOTFILES_DIR"
  success "Dotfiles cloned to $DOTFILES_DIR"
else
  info "Dotfiles already cloned — pulling latest..."
  git config --global --add safe.directory "$DOTFILES_DIR" 2>/dev/null || true
  sudo chown -R "$CURRENT_USER" "$DOTFILES_DIR/.git" 2>/dev/null || true
  git -C "$DOTFILES_DIR" pull --rebase --autostash
  success "Dotfiles up to date"
fi

# ── 6. Write machine.sh ───────────────────────────────────────────────────────
mkdir -p "$DOTFILES_DIR/.local"

# Only write/update when accounts were actually loaded or collected.
if [[ "${#GH_USERNAMES[@]}" -gt 0 ]]; then

  if [[ ! -f "$DOTFILES_DIR/.local/machine.sh" ]] || [[ "$ACCOUNTS_UPDATED" == true ]]; then
    {
      echo "# Auto-generated by bootstrap.sh on $(date)"
      echo "# DO NOT commit this file — it is gitignored"
      echo "export MACHINE_ROLE=\"${MACHINE_ROLE:-personal}\""
      echo "export MACHINE_NAME=\"${HOSTNAME}\""
      echo "export MACHINE_USER=\"${CURRENT_USER}\""
      echo "export MACHINE_ARCH=\"${ARCH}\""
      echo "export BREW_PREFIX=\"${BREW_PREFIX}\""
      echo "export GIT_NAME=\"${GIT_NAME:-${GH_NAMES[0]}}\""
      echo "export GIT_EMAIL=\"${GIT_EMAIL:-${GH_EMAILS[0]}}\""
      echo "export DOTFILES_DIR=\"${DOTFILES_DIR}\""
      echo "export GITHUB_ACCOUNTS=\"${GH_USERNAMES[*]}\""
      echo ""
      for i in "${!GH_USERNAMES[@]}"; do
        upper="$(echo "${GH_USERNAMES[$i]}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
        echo "export GH_${upper}_NAME=\"${GH_NAMES[$i]}\""
        echo "export GH_${upper}_EMAIL=\"${GH_EMAILS[$i]}\""
        echo "export GH_${upper}_FOLDER=\"${GH_FOLDERS[$i]}\""
      done
    } > "$DOTFILES_DIR/.local/machine.sh"
    if [[ "$ACCOUNTS_UPDATED" == true ]]; then
      success "machine.sh updated with ${#GH_USERNAMES[@]} account(s)"
    else
      success "machine.sh written"
    fi
  fi
fi

# ── 9. Git identity ───────────────────────────────────────────────────────────
if should_run "git"; then
  header "Git identity"

  for i in "${!GH_USERNAMES[@]}"; do
    GH_USER="${GH_USERNAMES[$i]}"
    GH_NAME="${GH_NAMES[$i]}"
    GH_EMAIL="${GH_EMAILS[$i]}"
    GH_FOLDER="${GH_FOLDERS[$i]}"
    GITCFG="$DOTFILES_DIR/.local/.gitconfig-${GH_USER}"
    if [[ ! -f "$GITCFG" ]]; then
      cat > "$GITCFG" <<EOF
[user]
  name  = ${GH_NAME}
  email = ${GH_EMAIL}
EOF
      success "Git identity: @${GH_USER} → ~/${GH_FOLDER}/"
    else
      warn ".gitconfig-${GH_USER} already exists — skipping"
    fi
  done

  {
    echo "# Auto-generated by bootstrap.sh on $(date)"
    echo "# GitHub account identity routing"
    echo ""
    for i in "${!GH_USERNAMES[@]}"; do
      echo "# @${GH_USERNAMES[$i]} → ~/${GH_FOLDERS[$i]}/"
      echo "[includeIf \"gitdir:~/${GH_FOLDERS[$i]}/\"]"
      echo "  path = ~/.dotfiles/.local/.gitconfig-${GH_USERNAMES[$i]}"
      echo ""
    done
  } > "$DOTFILES_DIR/.local/.gitconfig-accounts"
  success ".gitconfig-accounts written"

  if [[ ! -f "$DOTFILES_DIR/.local/.gitconfig.local" ]]; then
    cat > "$DOTFILES_DIR/.local/.gitconfig.local" <<EOF
# Machine-local git config for ${HOSTNAME}
[include]
  path = ~/.dotfiles/.local/.gitconfig-accounts
EOF
    success ".gitconfig.local written"
  fi
fi

# ── 10. Homebrew bundle ───────────────────────────────────────────────────────
if should_run "packages"; then
  header "Installing packages (Brewfile)"

  brew bundle --file="$DOTFILES_DIR/Brewfile" || warn "Some Brewfile items failed — check above"
  if [[ -f "$DOTFILES_DIR/.local/Brewfile.local" ]]; then
    brew bundle --file="$DOTFILES_DIR/.local/Brewfile.local"
  fi
  success "Homebrew bundle complete"
fi

# ── 11. Oh My Zsh + plugins + default shell ───────────────────────────────────
if should_run "shell"; then
  header "Shell"

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed"
  else
    success "Oh My Zsh already present"
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]    && git clone https://github.com/zsh-users/zsh-autosuggestions   "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  [[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]]          && git clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/you-should-use"
  success "Zsh plugins installed"

  ZSH_PATH="$BREW_PREFIX/bin/zsh"
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    grep -qF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
    chsh -s "$ZSH_PATH"
    success "Default shell set to $ZSH_PATH"
  else
    success "Already using $ZSH_PATH"
  fi
fi

# ── 12. Symlinks ──────────────────────────────────────────────────────────────
if should_run "symlinks"; then
  header "Creating symlinks"
  bash "$DOTFILES_DIR/scripts/symlink.sh"
fi

# ── 13. VS Code extensions ────────────────────────────────────────────────────
if should_run "vscode"; then
  header "VS Code extensions"

  if command -v code &>/dev/null; then
    while IFS= read -r ext; do
      [[ -z "$ext" || "$ext" == \#* ]] && continue
      code --install-extension "$ext" --force 2>/dev/null || warn "Failed: $ext"
    done < "$DOTFILES_DIR/vscode/extensions.txt"
    success "VS Code extensions installed"
  else
    warn "VS Code 'code' CLI not found — skipping (run: bootstrap.sh vscode)"
  fi
fi

# ── 14. SSH keys ──────────────────────────────────────────────────────────────
if should_run "ssh"; then
  header "SSH keys"

  mkdir -p "$HOME/.ssh/control"
  chmod 700 "$HOME/.ssh"

  SERIAL=$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Serial Number/{print $NF}')
  SSH_KEY_ID="${HOSTNAME}-${SERIAL}"

  SSH_ACCOUNTS_CONF="$DOTFILES_DIR/.local/ssh_accounts.conf"
  {
    echo "# Auto-generated by bootstrap.sh on $(date)"
    echo "# GitHub SSH host aliases — one per account"
    echo "# Usage: git clone git@github-<username>:org/repo.git"
    echo ""
  } > "$SSH_ACCOUNTS_CONF"

  for i in "${!GH_USERNAMES[@]}"; do
    GH_USER="${GH_USERNAMES[$i]}"
    GH_EMAIL="${GH_EMAILS[$i]}"
    KEY_PATH="$HOME/.ssh/id_ed25519_${GH_USER}"

    echo ""
    info "SSH key for @${GH_USER}"

    GENERATE_KEY=true
    if [[ -f "$KEY_PATH" ]]; then
      warn "Key already exists: ~/.ssh/id_ed25519_${GH_USER}"
      read -rp "  Generate a new key for @${GH_USER}? [y/N]: " REGEN
      if [[ "$REGEN" =~ ^[Yy]$ ]]; then
        rm -f "$KEY_PATH" "${KEY_PATH}.pub"
      else
        GENERATE_KEY=false
      fi
    fi

    if [[ "$GENERATE_KEY" == true ]]; then
      echo ""
      echo "  Generating ed25519 key for @${GH_USER}..."
      echo "  Enter a passphrase when prompted — it will be saved to Apple Keychain."
      echo ""
      ssh-keygen -t ed25519 -C "${GH_EMAIL} (${SSH_KEY_ID})" -f "$KEY_PATH"
      success "Key generated: ~/.ssh/id_ed25519_${GH_USER}"
    fi

    ssh-add --apple-use-keychain "$KEY_PATH" 2>/dev/null \
      || ssh-add "$KEY_PATH" 2>/dev/null \
      || warn "Could not load key — run: ssh-add --apple-use-keychain ~/.ssh/id_ed25519_${GH_USER}"

    cat >> "$SSH_ACCOUNTS_CONF" <<EOF
# @${GH_USER}
Host github-${GH_USER}
  HostName      github.com
  User          git
  IdentityFile  ~/.ssh/id_ed25519_${GH_USER}

EOF

    success "SSH alias: github-${GH_USER} → @${GH_USER}"

    echo ""
    echo -e "  ${BOLD}Public key for @${GH_USER}:${RESET}"
    echo "  ──────────────────────────────────────────────────────────"
    cat "${KEY_PATH}.pub"
    echo "  ──────────────────────────────────────────────────────────"
    echo ""

    if command -v gh &>/dev/null; then
      read -rp "  Auto-add to GitHub (@${GH_USER}) via gh CLI? [y/N]: " AUTOADD
      if [[ "$AUTOADD" =~ ^[Yy]$ ]]; then
        CURRENT_GH_USER=$(gh api user --jq .login 2>/dev/null || echo "")
        if [[ "$CURRENT_GH_USER" != "$GH_USER" ]]; then
          if ! gh auth switch --user "$GH_USER" 2>/dev/null; then
            info "Authenticating @${GH_USER} via browser (one-time per account)..."
            gh auth login --hostname github.com --git-protocol https --web --scopes admin:public_key
          fi
        fi
        if gh ssh-key add "${KEY_PATH}.pub" --title "${SSH_KEY_ID} ($(date +%Y-%m-%d))"; then
          success "SSH key added to GitHub @${GH_USER}"
        else
          warn "Upload failed — run manually:"
          warn "  gh auth refresh -h github.com -s admin:public_key"
          warn "  gh ssh-key add ${KEY_PATH}.pub --title \"${SSH_KEY_ID}\""
        fi
      else
        echo "  → Add manually: https://github.com/settings/ssh/new"
      fi
    else
      echo "  → Add manually: https://github.com/settings/ssh/new"
    fi
  done

  success "SSH setup complete — .local/ssh_accounts.conf written"
  gh config set -h github.com git_protocol ssh 2>/dev/null || true
  success "git protocol switched to SSH"
fi

# ── 15. Claude / MCP ─────────────────────────────────────────────────────────
if should_run "claude"; then
  header "Claude / MCP setup"

  MCP_ENV="$DOTFILES_DIR/.local/mcp.env"
  if [[ ! -f "$MCP_ENV" ]]; then
    mkdir -p "$DOTFILES_DIR/.local"
    cat > "$MCP_ENV" <<'EOF'
# MCP token file — gitignored, never pushed
# Fill in the services you use. Leave others blank to skip them.

GITHUB_TOKEN=
FIGMA_TOKEN=
SLACK_TOKEN=
NOTION_TOKEN=
EOF
    success "mcp.env template created at ~/.dotfiles/.local/mcp.env"
    echo "  → Open it and add your API tokens, then run: setup-mcp"
  fi

  bash "$DOTFILES_DIR/scripts/setup-mcp.sh" || warn "MCP setup had issues — run 'setup-mcp' manually after adding tokens"
fi


# ── 17. Git hooks (always — keeps dotfiles repo in sync) ──────────────────────
GIT_HOOKS_DIR="$DOTFILES_DIR/.git/hooks"
if [[ -f "$DOTFILES_DIR/sync/hooks/post-merge" ]]; then
  cp "$DOTFILES_DIR/sync/hooks/post-merge" "$GIT_HOOKS_DIR/post-merge"
  cp "$DOTFILES_DIR/sync/hooks/pre-push"   "$GIT_HOOKS_DIR/pre-push"
  chmod +x "$GIT_HOOKS_DIR/post-merge" "$GIT_HOOKS_DIR/pre-push"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
header "Bootstrap complete"

echo -e "${GREEN}${BOLD}"
echo "  Configured: ${SELECTED_MODULES[*]}"
echo ""
echo "  GitHub accounts:"
for i in "${!GH_USERNAMES[@]}"; do
  echo "    @${GH_USERNAMES[$i]} → ~/${GH_FOLDERS[$i]}/  (git@github-${GH_USERNAMES[$i]}:...)"
done
echo ""
echo "  Next steps:"
echo "  1. Reload your shell:  reload"
echo "  2. Verify everything:  dotcheck"
echo ""
echo "  Re-run individual modules any time:"
echo "    bootstrap.sh ssh | git | claude | packages | vscode | shell | symlinks"
echo -e "${RESET}"
