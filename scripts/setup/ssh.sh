#!/usr/bin/env bash
# =============================================================================
# scripts/setup/ssh.sh — Interactive GitHub SSH manager
#
# Manages GitHub SSH key configs stored in ~/.ssh/ssh_accounts.conf,
# which is included by ~/.ssh/config (symlinked from dotfiles/ssh/config).
#
# Usage:
#   ssh.sh              → interactive menu (list + actions)
#   ssh.sh list         → print all configured accounts
#   ssh.sh add          → add a new GitHub account interactively
#   ssh.sh edit         → pick and edit an existing account
#   ssh.sh delete       → pick and remove an account
#   ssh.sh test         → test SSH connections to GitHub
#
# Via make:  make ssh
# =============================================================================

set -euo pipefail

SSH_DIR="$HOME/.ssh"
SSH_ACCOUNTS_CONF="$SSH_DIR/ssh_accounts.conf"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { printf '%b\n' "${BLUE}  → $*${RESET}"; }
success() { printf '%b\n' "${GREEN}  ✓ $*${RESET}"; }
warn()    { printf '%b\n' "${YELLOW}  ⚠ $*${RESET}"; }
error()   { printf '%b\n' "${RED}  ✗ $*${RESET}"; exit 1; }
header()  { printf '%b\n' "\n${BOLD}${BLUE}━━━ $* ━━━${RESET}\n"; }

mkdir -p "$SSH_DIR/control"
chmod 700 "$SSH_DIR"
touch "$SSH_ACCOUNTS_CONF"

# ── Parse ssh_accounts.conf into arrays ───────────────────────────────────────
# Populates: USERNAMES HOST_ALIASES KEY_PATHS
parse_accounts() {
  USERNAMES=(); HOST_ALIASES=(); KEY_PATHS=()
  [[ ! -s "$SSH_ACCOUNTS_CONF" ]] && return
  local i=-1
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ @(.+) ]]; then
      USERNAMES+=("${BASH_REMATCH[1]}"); (( i++ )) || true
    elif [[ "$line" =~ ^Host[[:space:]]+(.+) && $i -ge 0 ]]; then
      HOST_ALIASES+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ IdentityFile[[:space:]]+(.+) && $i -ge 0 ]]; then
      KEY_PATHS+=("${BASH_REMATCH[1]/#\~/$HOME}")
    fi
  done < "$SSH_ACCOUNTS_CONF"
}

# ── Remove one account block from ssh_accounts.conf ───────────────────────────
remove_block() {
  local target="$1"
  [[ ! -f "$SSH_ACCOUNTS_CONF" ]] && return
  awk -v user="$target" '
    $0 == "# @" user  { skip=1; next }
    skip && /^$/       { skip=0; next }
    skip               { next }
    { print }
  ' "$SSH_ACCOUNTS_CONF" > "${SSH_ACCOUNTS_CONF}.tmp" \
    && mv "${SSH_ACCOUNTS_CONF}.tmp" "$SSH_ACCOUNTS_CONF"
}

# ── Generate + load an ed25519 key ────────────────────────────────────────────
generate_key() {
  local gh_user="$1" gh_email="$2"
  local key_path="$SSH_DIR/id_ed25519_${gh_user}"
  local machine_id
  machine_id="$(hostname -s)-$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Serial Number/{print $NF}')"

  if [[ -f "$key_path" ]]; then
    warn "Key already exists: ~/.ssh/id_ed25519_${gh_user}"
    read -rp "    Overwrite? [y/N]: " ow
    if [[ "$ow" =~ ^[Yy]$ ]]; then
      rm -f "$key_path" "${key_path}.pub"
    else
      success "Keeping existing key"
      return
    fi
  fi

  echo ""
  info "Generating ed25519 key for @${gh_user}..."
  echo "    Enter a passphrase when prompted — it will be saved to Apple Keychain."
  echo ""
  ssh-keygen -t ed25519 -C "${gh_email} (${machine_id})" -f "$key_path"
  success "Key generated: ~/.ssh/id_ed25519_${gh_user}"

  echo ""
  info "Loading key into Apple Keychain..."
  if ssh-add --apple-use-keychain "$key_path" 2>/dev/null; then
    success "Passphrase stored in Apple Keychain"
  else
    ssh-add "$key_path" 2>/dev/null \
      || warn "Could not load key — run: ssh-add --apple-use-keychain ~/.ssh/id_ed25519_${gh_user}"
  fi
}

# ── Write a Host block into ssh_accounts.conf ─────────────────────────────────
write_block() {
  local gh_user="$1"
  remove_block "$gh_user"
  printf '\n# @%s\nHost github-%s\n  HostName      github.com\n  User          git\n  IdentityFile  ~/.ssh/id_ed25519_%s\n' \
    "$gh_user" "$gh_user" "$gh_user" >> "$SSH_ACCOUNTS_CONF"
  success "SSH alias configured: github-${gh_user} → @${gh_user}"
}

# ── Show public key + offer GitHub upload ─────────────────────────────────────
offer_upload() {
  local gh_user="$1"
  local key_path="$SSH_DIR/id_ed25519_${gh_user}.pub"
  [[ ! -f "$key_path" ]] && return

  echo ""
  printf '%b\n' "  ${BOLD}Public key for @${gh_user}:${RESET}"
  echo "  ──────────────────────────────────────────────────────────"
  cat "$key_path"
  echo "  ──────────────────────────────────────────────────────────"
  echo ""

  if command -v gh &>/dev/null; then
    read -rp "    Auto-add to GitHub (@${gh_user}) via gh CLI? [y/N]: " autoadd
    if [[ "$autoadd" =~ ^[Yy]$ ]]; then
      local current_user
      current_user=$(gh api user --jq .login 2>/dev/null || echo "")
      if [[ "$current_user" != "$gh_user" ]]; then
        gh auth switch --user "$gh_user" 2>/dev/null \
          || { info "Authenticating @${gh_user} via browser (one-time)..."; \
               gh auth login --hostname github.com --git-protocol https --web --scopes admin:public_key; }
      fi
      local title="$(hostname -s) ($(date +%Y-%m-%d))"
      if gh ssh-key add "${SSH_DIR}/id_ed25519_${gh_user}.pub" --title "$title"; then
        success "SSH key added to GitHub @${gh_user}"
      else
        warn "Upload failed — add manually: https://github.com/settings/ssh/new"
      fi
    else
      echo "    → Add manually: https://github.com/settings/ssh/new"
    fi
  else
    echo "    → Add manually: https://github.com/settings/ssh/new"
  fi
}

# =============================================================================
# Commands
# =============================================================================

cmd_list() {
  parse_accounts
  header "GitHub SSH Accounts"

  if [[ ${#USERNAMES[@]} -eq 0 ]]; then
    warn "No accounts configured yet. Run 'add' to set up your first account."
    echo ""
    return
  fi

  printf '  %-22s %-28s %-30s %s\n' "USERNAME" "HOST ALIAS" "KEY FILE" "STATUS"
  printf '  %-22s %-28s %-30s %s\n' "────────" "──────────" "────────" "──────"
  for i in "${!USERNAMES[@]}"; do
    local user="${USERNAMES[$i]}"
    local alias="${HOST_ALIASES[$i]:-github-$user}"
    local key_full="${KEY_PATHS[$i]:-$HOME/.ssh/id_ed25519_$user}"
    local key_name; key_name="$(basename "$key_full")"
    local status
    [[ -f "$key_full" ]] && status="${GREEN}✓ key found${RESET}" || status="${RED}✗ key missing${RESET}"
    printf '  %-22s %-28s %-30s ' "@$user" "$alias" "$key_name"
    printf '%b\n' "$status"
  done
  echo ""
}

cmd_add() {
  local gh_user="${1:-}" gh_email="${2:-}"
  header "Add GitHub SSH Account"

  [[ -z "$gh_user" ]] && read -rp "  GitHub username: " gh_user
  [[ -z "$gh_user" ]] && error "Username required"
  [[ -z "$gh_email" ]] && read -rp "  Email for key comment: " gh_email
  [[ -z "$gh_email" ]] && error "Email required"

  generate_key "$gh_user" "$gh_email"
  write_block "$gh_user"
  offer_upload "$gh_user"

  echo ""
  success "Done — clone repos with: git clone git@github-${gh_user}:${gh_user}/repo.git"
  echo ""
}

cmd_edit() {
  parse_accounts
  header "Edit GitHub SSH Account"

  if [[ ${#USERNAMES[@]} -eq 0 ]]; then
    warn "No accounts configured. Use 'add' first."
    echo ""
    return
  fi

  cmd_list
  read -rp "  Username to edit: " target
  [[ -z "$target" ]] && return

  local found=false
  for u in "${USERNAMES[@]}"; do [[ "$u" == "$target" ]] && found=true && break; done
  [[ "$found" == false ]] && error "Account @$target not found"

  echo ""
  read -rp "  New email for key comment (Enter to skip): " new_email
  read -rp "  Regenerate SSH key? [y/N]: " regen

  if [[ "$regen" =~ ^[Yy]$ ]]; then
    rm -f "$SSH_DIR/id_ed25519_${target}" "$SSH_DIR/id_ed25519_${target}.pub"
    local email="${new_email:-$target@users.noreply.github.com}"
    generate_key "$target" "$email"
    write_block "$target"
    offer_upload "$target"
  else
    success "Key unchanged for @${target}"
  fi
  echo ""
}

cmd_delete() {
  parse_accounts
  header "Delete GitHub SSH Account"

  if [[ ${#USERNAMES[@]} -eq 0 ]]; then
    warn "No accounts configured."
    echo ""
    return
  fi

  cmd_list
  read -rp "  Username to delete: " target
  [[ -z "$target" ]] && return

  local found=false
  for u in "${USERNAMES[@]}"; do [[ "$u" == "$target" ]] && found=true && break; done
  [[ "$found" == false ]] && error "Account @$target not found"

  read -rp "  Also delete key files (~/.ssh/id_ed25519_${target})? [y/N]: " del_keys

  remove_block "$target"

  if [[ "$del_keys" =~ ^[Yy]$ ]]; then
    rm -f "$SSH_DIR/id_ed25519_${target}" "$SSH_DIR/id_ed25519_${target}.pub"
    success "Key files deleted"
  fi

  success "Removed @${target} from SSH config"
  echo ""
}

cmd_test() {
  parse_accounts
  header "Test GitHub SSH Connections"

  if [[ ${#USERNAMES[@]} -eq 0 ]]; then
    warn "No accounts configured."
    echo ""
    return
  fi

  for i in "${!USERNAMES[@]}"; do
    local user="${USERNAMES[$i]}"
    local alias="${HOST_ALIASES[$i]:-github-$user}"
    printf '  Testing %-22s' "@${user}..."
    local result
    result=$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 "git@${alias}" 2>&1 || true)
    if echo "$result" | grep -q "successfully authenticated"; then
      printf '%b\n' "${GREEN}✓ connected${RESET}"
    else
      printf '%b\n' "${RED}✗ failed${RESET}"
    fi
  done
  echo ""
}

# ── Interactive menu ───────────────────────────────────────────────────────────
interactive_menu() {
  while true; do
    cmd_list
    printf '%b\n' "  ${BOLD}Actions:${RESET}"
    echo "    [a] Add new account"
    echo "    [e] Edit account (change email or regenerate key)"
    echo "    [d] Delete account"
    echo "    [t] Test connections"
    echo "    [q] Quit"
    echo ""
    read -rp "  Choice: " choice
    echo ""
    case "$choice" in
      a|add)    cmd_add ;;
      e|edit)   cmd_edit ;;
      d|delete) cmd_delete ;;
      t|test)   cmd_test ;;
      q|quit)   break ;;
      *)        warn "Unknown choice: '$choice'" ;;
    esac
  done
}

# ── Entry point ───────────────────────────────────────────────────────────────
case "${1:-menu}" in
  list)         cmd_list ;;
  add)          cmd_add "${2:-}" "${3:-}" ;;
  edit)         cmd_edit ;;
  delete)       cmd_delete ;;
  test)         cmd_test ;;
  menu|*)       header "GitHub SSH Manager"; interactive_menu ;;
esac
