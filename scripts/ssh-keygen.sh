#!/usr/bin/env bash
# =============================================================================
# ssh-keygen.sh — Generate an ed25519 SSH key for a GitHub account
#
# Usage (interactive):   bash ssh-keygen.sh
# Usage (from script):   bash ssh-keygen.sh <github_username> <email> [machine_name]
#
# Keys are named by GitHub username: ~/.ssh/id_ed25519_<username>
# Passphrases are stored in Apple Keychain — you won't be prompted again.
# Running again for an existing key will ask whether to regenerate it.
# =============================================================================

set -euo pipefail

[[ -f "$HOME/.dotfiles/.local/machine.sh" ]] && source "$HOME/.dotfiles/.local/machine.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { printf '%b\n' "${BLUE}▶ $*${RESET}"; }
success() { printf '%b\n' "${GREEN}✓ $*${RESET}"; }
warn()    { printf '%b\n' "${YELLOW}⚠ $*${RESET}"; }

MACHINE_NAME="${MACHINE_NAME:-$(hostname -s)}"

# ── Collect inputs ─────────────────────────────────────────────────────────────
GH_USER="${1:-}"
KEY_EMAIL="${2:-}"
MACHINE_NAME="${3:-$MACHINE_NAME}"

if [[ -z "$GH_USER" ]]; then
  printf '%b\n' "${BOLD}SSH Key Setup — GitHub Account${RESET}"
  echo ""
  read -rp "  GitHub username: " GH_USER
fi

if [[ -z "$KEY_EMAIL" ]]; then
  read -rp "  Email for key comment: " KEY_EMAIL
fi

KEY_PATH="$HOME/.ssh/id_ed25519_${GH_USER}"
SSH_ACCOUNTS_CONF="$HOME/.ssh/ssh_accounts.conf"

mkdir -p "$HOME/.ssh/control"
chmod 700 "$HOME/.ssh"

# ── Check for existing key ────────────────────────────────────────────────────
GENERATE_KEY=true

if [[ -f "$KEY_PATH" ]]; then
  warn "Key already exists: ~/.ssh/id_ed25519_${GH_USER}"
  echo ""
  read -rp "  Generate a new key for @${GH_USER}? Existing key will be removed. [y/N]: " REGEN
  if [[ "$REGEN" =~ ^[Yy]$ ]]; then
    rm -f "$KEY_PATH" "${KEY_PATH}.pub"
    info "Existing key removed"
  else
    GENERATE_KEY=false
    success "Keeping existing key"
  fi
fi

# ── Generate key ──────────────────────────────────────────────────────────────
if [[ "$GENERATE_KEY" == true ]]; then
  echo ""
  info "Generating ed25519 key for @${GH_USER}..."
  echo "  When prompted for a passphrase, enter one — it will be saved to Apple Keychain."
  echo "  Leave blank only if you intentionally want no passphrase."
  echo ""
  ssh-keygen -t ed25519 -C "${KEY_EMAIL} (${MACHINE_NAME})" -f "$KEY_PATH"
  success "Key generated: ~/.ssh/id_ed25519_${GH_USER}"
fi

# ── Store passphrase in Apple Keychain ────────────────────────────────────────
echo ""
info "Loading key into Apple Keychain..."
if ssh-add --apple-use-keychain "$KEY_PATH" 2>/dev/null; then
  success "Passphrase stored in Apple Keychain — you won't be prompted again"
else
  # Fallback for environments where --apple-use-keychain isn't available
  ssh-add "$KEY_PATH" 2>/dev/null \
    || warn "Could not add key to agent automatically — run: ssh-add --apple-use-keychain ~/.ssh/id_ed25519_${GH_USER}"
fi

# ── Update ssh_accounts.conf ──────────────────────────────────────────────────
# Add or update this account's Host block in .local/ssh_accounts.conf
mkdir -p "$HOME/.dotfiles/.local"

if [[ -f "$SSH_ACCOUNTS_CONF" ]]; then
  # Remove existing block for this user if present, then append updated one
  # Match block from "# @<user>" to the next blank-line-separated block
  awk -v user="$GH_USER" '
    /^# @/ && $0 == "# @" user { skip=1; next }
    skip && /^$/ { skip=0; next }
    skip { next }
    { print }
  ' "$SSH_ACCOUNTS_CONF" > "${SSH_ACCOUNTS_CONF}.tmp" \
    && mv "${SSH_ACCOUNTS_CONF}.tmp" "$SSH_ACCOUNTS_CONF"
fi

cat >> "$SSH_ACCOUNTS_CONF" <<EOF

# @${GH_USER}
Host github-${GH_USER}
  HostName      github.com
  User          git
  IdentityFile  ~/.ssh/id_ed25519_${GH_USER}
EOF

success "SSH alias added: github-${GH_USER} → @${GH_USER}"

# ── Show public key ───────────────────────────────────────────────────────────
echo ""
printf '%b\n' "${BOLD}Public key for @${GH_USER}:${RESET}"
echo "──────────────────────────────────────────────────────────────"
cat "${KEY_PATH}.pub"
echo "──────────────────────────────────────────────────────────────"
echo ""

# ── Offer to add to GitHub via gh CLI ────────────────────────────────────────
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  read -rp "Auto-add to GitHub (@${GH_USER}) via gh CLI? [y/N]: " AUTOADD
  if [[ "$AUTOADD" =~ ^[Yy]$ ]]; then
    gh ssh-key add "${KEY_PATH}.pub" --title "${MACHINE_NAME} ($(date +%Y-%m-%d))"
    success "SSH key added to GitHub @${GH_USER}"
  else
    echo "→ Add manually: https://github.com/settings/ssh/new"
  fi
else
  echo "→ Add manually: https://github.com/settings/ssh/new"
fi

echo ""
printf '%b\n' "${BOLD}Clone repos using:${RESET}"
echo "  git clone git@github-${GH_USER}:${GH_USER}/repo.git"
