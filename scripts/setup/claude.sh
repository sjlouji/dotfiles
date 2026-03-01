#!/usr/bin/env bash
# =============================================================================
# scripts/setup/claude.sh — Claude / MCP server setup
#
# Standalone usage:  bash ~/.dotfiles/scripts/setup/claude.sh
# Via bootstrap:     bootstrap.sh claude
#
# Opens mcp.env for token entry, then wires up GitHub, Figma, Slack,
# and Notion into Claude. Only tokens you fill in are activated.
# =============================================================================

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
source "$DOTFILES_DIR/scripts/setup/lib.sh"

header "Claude / MCP setup"

MCP_ENV="$DOTFILES_DIR/.local/mcp.env"

if [[ ! -f "$MCP_ENV" ]]; then
  warn "mcp.env not found — creating template at $MCP_ENV"
  mkdir -p "$DOTFILES_DIR/.local"
  cat > "$MCP_ENV" <<'EOF'
# MCP token file — gitignored, never pushed
# Fill in the services you use. Leave others blank to skip them.

GITHUB_TOKEN=
FIGMA_TOKEN=
SLACK_TOKEN=
NOTION_TOKEN=
EOF
  success "mcp.env template created"
fi

echo ""
echo "  Opening mcp.env — add your API tokens, then save and close."
echo "  Leave any you don't use blank."
echo ""
read -rp "  Open mcp.env now? [Y/n]: " OPEN_ENV
if [[ ! "$OPEN_ENV" =~ ^[Nn]$ ]]; then
  open -e "$MCP_ENV" 2>/dev/null \
    || ${EDITOR:-nano} "$MCP_ENV"
  echo ""
  read -rp "  Done editing? Press Enter to continue..."
fi

echo ""
bash "$DOTFILES_DIR/scripts/setup-mcp.sh" || {
  warn "MCP setup encountered issues — check output above"
  echo "  → Fix your tokens in: $MCP_ENV"
  echo "  → Then re-run: setup-mcp"
}
