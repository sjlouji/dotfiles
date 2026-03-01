#!/usr/bin/env bash
# =============================================================================
# ssh-keygen.sh — Generate a new ed25519 SSH key for this machine
# =============================================================================

set -euo pipefail

[[ -f "$HOME/.dotfiles/.local/machine.sh" ]] && source "$HOME/.dotfiles/.local/machine.sh"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

MACHINE_NAME="${MACHINE_NAME:-$(hostname -s)}"
GIT_EMAIL="${GIT_EMAIL:-}"
KEY_PATH="$HOME/.ssh/id_ed25519"

echo -e "${BLUE}▶ SSH Key Setup${RESET}"

if [[ -z "$GIT_EMAIL" ]]; then
  read -rp "  Email for SSH key comment: " GIT_EMAIL
fi

if [[ -f "$KEY_PATH" ]]; then
  echo -e "${BOLD}  SSH key already exists at $KEY_PATH${RESET}"
  echo -e "  Public key:"
  cat "${KEY_PATH}.pub"
  echo ""
  echo "  Add this to GitHub: https://github.com/settings/ssh/new"
  exit 0
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

echo "  Generating ed25519 key..."
ssh-keygen -t ed25519 -C "${GIT_EMAIL} (${MACHINE_NAME})" -f "$KEY_PATH" -N ""

# Add to ssh-agent
eval "$(ssh-agent -s)" &>/dev/null
ssh-add --apple-use-keychain "$KEY_PATH" 2>/dev/null || ssh-add "$KEY_PATH"

echo ""
echo -e "${GREEN}${BOLD}✓ SSH key generated${RESET}"
echo ""
echo "  Public key (copy this to GitHub):"
echo "  ────────────────────────────────"
cat "${KEY_PATH}.pub"
echo "  ────────────────────────────────"
echo ""
echo "  → Add to GitHub: https://github.com/settings/ssh/new"
echo "  → Or run: gh ssh-key add ${KEY_PATH}.pub --title \"${MACHINE_NAME}\""
echo ""

# Offer to auto-add via gh CLI
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  read -rp "  Auto-add to GitHub via gh CLI? [y/N]: " AUTOADD
  if [[ "$AUTOADD" =~ ^[Yy]$ ]]; then
    gh ssh-key add "${KEY_PATH}.pub" --title "${MACHINE_NAME} ($(date +%Y-%m-%d))"
    echo -e "${GREEN}✓ SSH key added to GitHub${RESET}"
  fi
fi
