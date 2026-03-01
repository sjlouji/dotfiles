#!/usr/bin/env bash
# =============================================================================
# scripts/setup/ssh.sh — Interactive SSH manager
#
# Two sections:
#   GitHub accounts → ~/.ssh/ssh_accounts.conf  (managed, keyed by username)
#   Other hosts     → ~/.ssh/config.local        (bastions, tunnels, servers)
#
# Usage:
#   ssh.sh              → interactive menu
#   ssh.sh list         → list GitHub accounts
#   ssh.sh add          → add GitHub account
#   ssh.sh edit         → edit GitHub account
#   ssh.sh delete       → delete GitHub account
#   ssh.sh test         → test GitHub SSH connections
#   ssh.sh hosts        → manage bastions / tunnels / servers
#
# Via make:  make ssh
# =============================================================================

set -euo pipefail

SSH_DIR="$HOME/.ssh"
SSH_ACCOUNTS_CONF="$SSH_DIR/ssh_accounts.conf"
CONFIG_LOCAL="$SSH_DIR/config.local"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { printf '%b\n' "${BLUE}  → $*${RESET}"; }
success() { printf '%b\n' "${GREEN}  ✓ $*${RESET}"; }
warn()    { printf '%b\n' "${YELLOW}  ⚠ $*${RESET}"; }
error()   { printf '%b\n' "${RED}  ✗ $*${RESET}"; exit 1; }
header()  { printf '%b\n' "\n${BOLD}${BLUE}━━━ $* ━━━${RESET}\n"; }
prompt()  { read -rp "  $1" "$2"; }

mkdir -p "$SSH_DIR/control"
chmod 700 "$SSH_DIR"
touch "$SSH_ACCOUNTS_CONF" "$CONFIG_LOCAL"

# =============================================================================
# GitHub account helpers
# =============================================================================

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

remove_account_block() {
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

generate_key() {
  local gh_user="$1" gh_email="$2"
  local key_path="$SSH_DIR/id_ed25519_${gh_user}"
  local machine_id
  machine_id="$(hostname -s)-$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Serial Number/{print $NF}')"

  if [[ -f "$key_path" ]]; then
    warn "Key already exists: ~/.ssh/id_ed25519_${gh_user}"
    local ow; prompt "Overwrite? [y/N]: " ow
    if [[ "$ow" =~ ^[Yy]$ ]]; then
      rm -f "$key_path" "${key_path}.pub"
    else
      success "Keeping existing key"; return
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

write_account_block() {
  local gh_user="$1"
  remove_account_block "$gh_user"
  printf '\n# @%s\nHost github-%s\n  HostName      github.com\n  User          git\n  IdentityFile  ~/.ssh/id_ed25519_%s\n' \
    "$gh_user" "$gh_user" "$gh_user" >> "$SSH_ACCOUNTS_CONF"
  success "SSH alias configured: github-${gh_user} → @${gh_user}"
}

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
    local autoadd; prompt "Auto-add to GitHub (@${gh_user}) via gh CLI? [y/N]: " autoadd
    if [[ "$autoadd" =~ ^[Yy]$ ]]; then
      local current_user
      current_user=$(gh api user --jq .login 2>/dev/null || echo "")
      if [[ "$current_user" != "$gh_user" ]]; then
        gh auth switch --user "$gh_user" 2>/dev/null \
          || { info "Authenticating @${gh_user} via browser (one-time)..."
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
# Host (config.local) helpers
# =============================================================================

# Populates: HOST_NAMES HOST_TYPES HOST_HOSTNAMES HOST_USERS HOST_KEYS HOST_EXTRAS
# HOST_TYPES: host | bastion | tunnel
parse_hosts() {
  HOST_NAMES=(); HOST_TYPES=(); HOST_HOSTNAMES=(); HOST_USERS=(); HOST_KEYS=(); HOST_EXTRAS=()
  [[ ! -s "$CONFIG_LOCAL" ]] && return
  local cur_type="" cur_name="" cur_hostname="" cur_user="" cur_key="" cur_extra=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ \[(host|bastion|tunnel)\]\ (.+) ]]; then
      # Save previous block
      if [[ -n "$cur_name" ]]; then
        HOST_NAMES+=("$cur_name"); HOST_TYPES+=("$cur_type")
        HOST_HOSTNAMES+=("$cur_hostname"); HOST_USERS+=("$cur_user")
        HOST_KEYS+=("$cur_key"); HOST_EXTRAS+=("$cur_extra")
      fi
      cur_type="${BASH_REMATCH[1]}"; cur_name="${BASH_REMATCH[2]}"
      cur_hostname=""; cur_user=""; cur_key=""; cur_extra=""
    elif [[ "$line" =~ ^[[:space:]]+HostName[[:space:]]+(.+) ]]; then
      cur_hostname="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+User[[:space:]]+(.+) ]]; then
      cur_user="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+IdentityFile[[:space:]]+(.+) ]]; then
      cur_key="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]+(LocalForward|ProxyJump|ForwardAgent)[[:space:]]+(.+) ]]; then
      cur_extra="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    fi
  done < "$CONFIG_LOCAL"
  # Save last block
  if [[ -n "$cur_name" ]]; then
    HOST_NAMES+=("$cur_name"); HOST_TYPES+=("$cur_type")
    HOST_HOSTNAMES+=("$cur_hostname"); HOST_USERS+=("$cur_user")
    HOST_KEYS+=("$cur_key"); HOST_EXTRAS+=("$cur_extra")
  fi
}

remove_host_block() {
  local target="$1"
  [[ ! -f "$CONFIG_LOCAL" ]] && return
  awk -v host="$target" '
    $0 ~ "^# \\[(host|bastion|tunnel)\\] " host "$" { skip=1; next }
    skip && /^$/  { skip=0; next }
    skip          { next }
    { print }
  ' "$CONFIG_LOCAL" > "${CONFIG_LOCAL}.tmp" \
    && mv "${CONFIG_LOCAL}.tmp" "$CONFIG_LOCAL"
}

# =============================================================================
# GitHub account commands
# =============================================================================

cmd_list() {
  parse_accounts
  header "GitHub SSH Accounts"

  if [[ ${#USERNAMES[@]} -eq 0 ]]; then
    warn "No GitHub accounts configured yet."
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

  [[ -z "$gh_user" ]] && prompt "GitHub username: " gh_user
  [[ -z "$gh_user" ]] && error "Username required"
  [[ -z "$gh_email" ]] && prompt "Email for key comment: " gh_email
  [[ -z "$gh_email" ]] && error "Email required"

  generate_key "$gh_user" "$gh_email"
  write_account_block "$gh_user"
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
    echo ""; return
  fi

  cmd_list
  local target; prompt "Username to edit: " target
  [[ -z "$target" ]] && return

  local found=false
  for u in "${USERNAMES[@]}"; do [[ "$u" == "$target" ]] && found=true && break; done
  [[ "$found" == false ]] && error "Account @$target not found"

  echo ""
  local new_email; prompt "New email for key comment (Enter to skip): " new_email
  local regen; prompt "Regenerate SSH key? [y/N]: " regen

  if [[ "$regen" =~ ^[Yy]$ ]]; then
    rm -f "$SSH_DIR/id_ed25519_${target}" "$SSH_DIR/id_ed25519_${target}.pub"
    generate_key "$target" "${new_email:-$target@users.noreply.github.com}"
    write_account_block "$target"
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
    echo ""; return
  fi

  cmd_list
  local target; prompt "Username to delete: " target
  [[ -z "$target" ]] && return

  local found=false
  for u in "${USERNAMES[@]}"; do [[ "$u" == "$target" ]] && found=true && break; done
  [[ "$found" == false ]] && error "Account @$target not found"

  local del_keys; prompt "Also delete key files (~/.ssh/id_ed25519_${target})? [y/N]: " del_keys
  remove_account_block "$target"

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
    echo ""; return
  fi

  for i in "${!USERNAMES[@]}"; do
    local user="${USERNAMES[$i]}"
    local key="${KEY_PATHS[$i]:-$SSH_DIR/id_ed25519_$user}"
    printf '  Testing %-22s' "@${user}..."
    if [[ ! -f "$key" ]]; then
      printf '%b\n' "${YELLOW}⚠ key missing: $(basename "$key")${RESET}"
      continue
    fi
    local result
    result=$(ssh -T -i "$key" -o BatchMode=yes -o ConnectTimeout=5 \
      -o StrictHostKeyChecking=no -o IdentitiesOnly=yes \
      git@github.com 2>&1 || true)
    if echo "$result" | grep -q "successfully authenticated"; then
      printf '%b\n' "${GREEN}✓ connected${RESET}"
    else
      printf '%b\n' "${RED}✗ failed — ${result}${RESET}"
    fi
  done
  echo ""
}

# =============================================================================
# Host management commands (bastions, tunnels, servers → config.local)
# =============================================================================

host_list() {
  parse_hosts
  header "SSH Hosts  (~/.ssh/config.local)"

  if [[ ${#HOST_NAMES[@]} -eq 0 ]]; then
    warn "No hosts configured yet."
    echo ""
    return
  fi

  printf '  %-24s %-10s %-28s %s\n' "ALIAS" "TYPE" "HOSTNAME" "EXTRA"
  printf '  %-24s %-10s %-28s %s\n' "─────" "────" "────────" "─────"
  for i in "${!HOST_NAMES[@]}"; do
    printf '  %-24s %-10s %-28s %s\n' \
      "${HOST_NAMES[$i]}" "${HOST_TYPES[$i]}" \
      "${HOST_HOSTNAMES[$i]}" "${HOST_EXTRAS[$i]:-}"
  done
  echo ""
}

host_add_regular() {
  header "Add SSH Host"
  local alias hostname user key

  prompt "Host alias (e.g. my-server): " alias
  [[ -z "$alias" ]] && error "Alias required"
  prompt "HostName (IP or domain): " hostname
  [[ -z "$hostname" ]] && error "HostName required"
  prompt "User: " user
  [[ -z "$user" ]] && error "User required"
  prompt "IdentityFile (e.g. ~/.ssh/id_ed25519_personal): " key
  [[ -z "$key" ]] && error "IdentityFile required"

  remove_host_block "$alias"
  cat >> "$CONFIG_LOCAL" <<EOF

# [host] ${alias}
Host ${alias}
  HostName      ${hostname}
  User          ${user}
  IdentityFile  ${key}
EOF
  success "Host '${alias}' added to ~/.ssh/config.local"
  echo ""
}

host_add_bastion() {
  header "Add Bastion / Jump Host"
  local alias hostname user key forward

  prompt "Host alias (e.g. prod-bastion): " alias
  [[ -z "$alias" ]] && error "Alias required"
  prompt "HostName (IP or domain): " hostname
  [[ -z "$hostname" ]] && error "HostName required"
  prompt "User: " user
  [[ -z "$user" ]] && error "User required"
  prompt "IdentityFile (e.g. ~/.ssh/id_ed25519_personal): " key
  [[ -z "$key" ]] && error "IdentityFile required"
  local fwd; prompt "Enable ForwardAgent? [y/N]: " fwd

  remove_host_block "$alias"
  {
    printf '\n# [bastion] %s\nHost %s\n  HostName      %s\n  User          %s\n  IdentityFile  %s\n' \
      "$alias" "$alias" "$hostname" "$user" "$key"
    [[ "$fwd" =~ ^[Yy]$ ]] && printf '  ForwardAgent  yes\n'
  } >> "$CONFIG_LOCAL"
  success "Bastion '${alias}' added to ~/.ssh/config.local"
  echo "    Connect with: ssh ${alias}"
  echo "    Use as jump:  ssh -J ${alias} internal-host"
  echo ""
}

host_add_tunnel() {
  header "Add DB Tunnel (LocalForward)"
  local alias bastion_host user key local_port remote_host remote_port

  prompt "Host alias (e.g. staging-db): " alias
  [[ -z "$alias" ]] && error "Alias required"
  prompt "Bastion/jump HostName (IP or domain): " bastion_host
  [[ -z "$bastion_host" ]] && error "HostName required"
  prompt "User on bastion: " user
  [[ -z "$user" ]] && error "User required"
  prompt "IdentityFile (e.g. ~/.ssh/fs-bastion-host.pem): " key
  [[ -z "$key" ]] && error "IdentityFile required"
  prompt "Local port (e.g. 15432): " local_port
  [[ -z "$local_port" ]] && error "Local port required"
  prompt "Remote DB host (e.g. db.internal.example.com): " remote_host
  [[ -z "$remote_host" ]] && error "Remote DB host required"
  prompt "Remote DB port (e.g. 5432): " remote_port
  remote_port="${remote_port:-5432}"

  remove_host_block "$alias"
  cat >> "$CONFIG_LOCAL" <<EOF

# [tunnel] ${alias}
Host ${alias}
  HostName      ${bastion_host}
  User          ${user}
  IdentityFile  ${key}
  LocalForward  ${local_port} ${remote_host}:${remote_port}
EOF
  success "Tunnel '${alias}' added to ~/.ssh/config.local"
  echo "    Open tunnel: ssh -N ${alias}"
  echo "    Then connect your DB client to: localhost:${local_port}"
  echo ""
}

host_delete() {
  parse_hosts
  header "Delete SSH Host"

  if [[ ${#HOST_NAMES[@]} -eq 0 ]]; then
    warn "No hosts configured."
    echo ""; return
  fi

  host_list
  local target; prompt "Alias to delete: " target
  [[ -z "$target" ]] && return

  local found=false
  for n in "${HOST_NAMES[@]}"; do [[ "$n" == "$target" ]] && found=true && break; done
  [[ "$found" == false ]] && error "Host '${target}' not found"

  remove_host_block "$target"
  success "Removed '${target}' from ~/.ssh/config.local"
  echo ""
}

cmd_hosts() {
  while true; do
    host_list
    printf '%b\n' "  ${BOLD}Actions:${RESET}"
    echo "    [1] Add regular host (server, VM)"
    echo "    [2] Add bastion / jump host"
    echo "    [3] Add DB tunnel (LocalForward)"
    echo "    [d] Delete host"
    echo "    [b] Back"
    echo ""
    local choice; prompt "Choice: " choice
    echo ""
    case "$choice" in
      1)        host_add_regular ;;
      2)        host_add_bastion ;;
      3)        host_add_tunnel ;;
      d|delete) host_delete ;;
      b|back)   break ;;
      *)        warn "Unknown choice: '$choice'" ;;
    esac
  done
}

# =============================================================================
# Interactive menu
# =============================================================================

interactive_menu() {
  while true; do
    cmd_list
    printf '%b\n' "  ${BOLD}GitHub accounts:${RESET}"
    echo "    [a] Add GitHub account"
    echo "    [e] Edit GitHub account"
    echo "    [d] Delete GitHub account"
    echo "    [t] Test GitHub connections"
    echo ""
    printf '%b\n' "  ${BOLD}Other hosts:${RESET}"
    echo "    [h] Manage bastions / tunnels / servers"
    echo ""
    echo "    [q] Quit"
    echo ""
    local choice; prompt "Choice: " choice
    echo ""
    case "$choice" in
      a|add)    cmd_add ;;
      e|edit)   cmd_edit ;;
      d|delete) cmd_delete ;;
      t|test)   cmd_test ;;
      h|hosts)  cmd_hosts ;;
      q|quit)   break ;;
      *)        warn "Unknown choice: '$choice'" ;;
    esac
  done
}

# =============================================================================
# Entry point
# =============================================================================

case "${1:-menu}" in
  list)         cmd_list ;;
  add)          cmd_add "${2:-}" "${3:-}" ;;
  edit)         cmd_edit ;;
  delete)       cmd_delete ;;
  test)         cmd_test ;;
  hosts)        header "SSH Host Manager"; cmd_hosts ;;
  menu|*)       header "SSH Manager"; interactive_menu ;;
esac
