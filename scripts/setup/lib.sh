#!/usr/bin/env bash
# =============================================================================
# scripts/setup/lib.sh — Shared utilities for all setup modules
# Source this file at the top of any setup script:
#   source "$DOTFILES_DIR/scripts/setup/lib.sh"
# =============================================================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# ── Colors + logging ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { printf '%b\n' "${BLUE}▶ $*${RESET}"; }
success() { printf '%b\n' "${GREEN}✓ $*${RESET}"; }
warn()    { printf '%b\n' "${YELLOW}⚠ $*${RESET}"; }
error()   { printf '%b\n' "${RED}✗ $*${RESET}"; exit 1; }
header()  { printf '%b\n' "\n${BOLD}${BLUE}━━━ $* ━━━${RESET}\n"; }

# ── Machine detection ─────────────────────────────────────────────────────────
detect_machine() {
  ARCH=$(uname -m)
  OS_VERSION=$(sw_vers -productVersion)
  HOSTNAME=$(hostname -s)
  CURRENT_USER=$(whoami)

  if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
    CHIP="Apple Silicon"
  else
    BREW_PREFIX="/usr/local"
    CHIP="Intel"
  fi
}

# ── Account management ────────────────────────────────────────────────────────

# Reconstruct GH_USERNAMES / GH_NAMES / GH_EMAILS / GH_FOLDERS arrays
# from the space-separated GITHUB_ACCOUNTS var and per-account exports
# stored in machine.sh. Returns 1 if no account data is found.
load_accounts_from_machine() {
  GH_USERNAMES=()
  GH_NAMES=()
  GH_EMAILS=()
  GH_FOLDERS=()

  [[ -f "$DOTFILES_DIR/.local/machine.sh" ]] && source "$DOTFILES_DIR/.local/machine.sh" || return 1
  [[ -z "${GITHUB_ACCOUNTS:-}" ]] && return 1

  for acct in $GITHUB_ACCOUNTS; do
    local upper
    upper="$(echo "$acct" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
    local name_var="GH_${upper}_NAME"
    local email_var="GH_${upper}_EMAIL"
    local folder_var="GH_${upper}_FOLDER"
    GH_USERNAMES+=("$acct")
    GH_NAMES+=("${!name_var:-}")
    GH_EMAILS+=("${!email_var:-}")
    GH_FOLDERS+=("${!folder_var:-}")
  done

  [[ ${#GH_USERNAMES[@]} -gt 0 ]] || return 1
}

# Interactively collect GitHub account data from the user
collect_accounts() {
  GH_USERNAMES=()
  GH_NAMES=()
  GH_EMAILS=()
  GH_FOLDERS=()
  local count=0

  echo -e "${BOLD}Set up your GitHub accounts.${RESET}"
  echo "Each account gets its own SSH key and git identity, scoped by folder."
  echo ""

  while true; do
    local num=$((count + 1))
    if [[ $count -eq 0 ]]; then
      echo -e "${BOLD}── Account 1 (primary) ──────────────────────${RESET}"
    else
      echo -e "${BOLD}── Account $num ─────────────────────────────${RESET}"
    fi

    local gh_user gh_name gh_email gh_folder default_folder
    read -rp "  GitHub username: " gh_user
    read -rp "  Your name:       " gh_name
    read -rp "  Email:           " gh_email

    if   [[ $count -eq 0 ]]; then default_folder="personal"
    elif [[ $count -eq 1 ]]; then default_folder="work"
    else                           default_folder="github-${gh_user}"
    fi

    read -rp "  Repos folder     (~/${default_folder}/): " gh_folder
    gh_folder="${gh_folder:-$default_folder}"
    gh_folder="${gh_folder#~/}"
    gh_folder="${gh_folder%/}"

    GH_USERNAMES+=("$gh_user")
    GH_NAMES+=("$gh_name")
    GH_EMAILS+=("$gh_email")
    GH_FOLDERS+=("$gh_folder")
    count=$((count + 1))

    echo ""
    echo -e "  ${GREEN}→ SSH host alias:${RESET} github-${gh_user}"
    echo -e "  ${GREEN}→ SSH key:${RESET}        ~/.ssh/id_ed25519_${gh_user}"
    echo -e "  ${GREEN}→ Repos in:${RESET}       ~/${gh_folder}/"
    echo ""

    read -rp "Add another GitHub account? [y/N]: " add_more
    [[ ! "$add_more" =~ ^[Yy]$ ]] && break
    echo ""
  done
}

# Load accounts from machine.sh if available, otherwise collect interactively
ensure_accounts() {
  if load_accounts_from_machine; then
    info "Loaded ${#GH_USERNAMES[@]} account(s) from machine.sh"
    for i in "${!GH_USERNAMES[@]}"; do
      echo "    @${GH_USERNAMES[$i]} → ~/${GH_FOLDERS[$i]}/"
    done
    echo ""
  else
    warn "No account data found in machine.sh — collecting now"
    echo ""
    collect_accounts
  fi
}
