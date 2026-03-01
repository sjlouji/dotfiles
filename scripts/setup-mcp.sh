#!/usr/bin/env bash
# =============================================================================
# setup-mcp.sh — Install and configure MCP servers for Claude
#
# This wires up MCP servers for both Claude Desktop and Claude Code.
# Tokens are read from .local/mcp.env (gitignored — never pushed to GitHub).
#
# Usage:
#   bash ~/.dotfiles/scripts/setup-mcp.sh
# =============================================================================

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
MCP_ENV="$DOTFILES_DIR/.local/mcp.env"
MCP_CONFIG_SRC="$DOTFILES_DIR/claude/mcp.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${BLUE}  → $*${RESET}"; }
success() { echo -e "${GREEN}  ✓ $*${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠ $*${RESET}"; }

echo -e "\n${BOLD}${BLUE}━━━ MCP Server Setup ━━━${RESET}\n"

# ── 1. Create .local/mcp.env if it doesn't exist ─────────────────────────────
if [[ ! -f "$MCP_ENV" ]]; then
  info "Creating $MCP_ENV — fill in your API tokens here"
  cat > "$MCP_ENV" <<'EOF'
# MCP Server API Tokens
# This file is gitignored — never pushed to GitHub
# Store sensitive values in Apple Keychain and reference them here
#
# How to retrieve from Apple Keychain (optional):
#   security find-generic-password -s "github-token" -w

# GitHub — gh auth token gives you this automatically
export GITHUB_TOKEN=""

# Figma — Figma → Settings → Personal access tokens
export FIGMA_API_KEY=""

# Slack — https://api.slack.com/apps → Bot Token (xoxb-...)
export SLACK_BOT_TOKEN=""
export SLACK_TEAM_ID=""

# Notion — https://www.notion.so/my-integrations → create integration
export NOTION_TOKEN=""
EOF
  echo ""
  warn "Fill in your tokens in: $MCP_ENV"
  warn "Then re-run this script."
  echo ""
fi

# ── 2. Load tokens ────────────────────────────────────────────────────────────
if [[ -f "$MCP_ENV" ]]; then
  source "$MCP_ENV"
fi

# ── 3. Check npx is available ─────────────────────────────────────────────────
if ! command -v npx &>/dev/null; then
  warn "npx not found — install Node.js via mise first:"
  warn "  mise use --global node@lts"
  warn "Then re-run: setup-mcp"
  exit 0
fi

# ── 4. Pre-install MCP packages globally ─────────────────────────────────────
info "Installing MCP server packages..."

MCP_PACKAGES=(
  "@modelcontextprotocol/server-github"
  "@modelcontextprotocol/server-filesystem"
  "@modelcontextprotocol/server-slack"
  "@modelcontextprotocol/server-memory"
  "@notionhq/notion-mcp-server"
  "figma-developer-mcp"
)

for pkg in "${MCP_PACKAGES[@]}"; do
  npm install -g "$pkg" --silent 2>/dev/null && success "$pkg" || warn "Failed: $pkg (skipping)"
done

# ── 5. Wire up Claude Desktop config ─────────────────────────────────────────
CLAUDE_DESKTOP_DIR="$HOME/Library/Application Support/Claude"
CLAUDE_DESKTOP_CONFIG="$CLAUDE_DESKTOP_DIR/claude_desktop_config.json"

mkdir -p "$CLAUDE_DESKTOP_DIR"

if [[ ! -f "$CLAUDE_DESKTOP_CONFIG" ]]; then
  # Copy config as-is; Claude Desktop resolves ${VAR} from the environment at runtime.
  # In the normal setup flow symlink.sh handles this instead (mcp.json → claude_desktop_config.json).
  cp "$MCP_CONFIG_SRC" "$CLAUDE_DESKTOP_CONFIG"
  success "Claude Desktop config written → $CLAUDE_DESKTOP_CONFIG"
else
  warn "Claude Desktop config already exists — skipping (edit manually if needed)"
  info "Config location: $CLAUDE_DESKTOP_CONFIG"
fi

# ── 6. Wire up Claude Code (claude mcp add) ───────────────────────────────────
if command -v claude &>/dev/null; then
  echo ""
  info "Registering servers with Claude Code..."

  # Register each server — skips if already registered
  claude mcp add github     -- npx -y @modelcontextprotocol/server-github                    2>/dev/null && success "claude mcp: github"     || warn "github already registered or failed"
  claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$HOME/personal" "$HOME/work" "$HOME/projects" 2>/dev/null && success "claude mcp: filesystem" || warn "filesystem already registered or failed"
  claude mcp add figma      -- npx -y figma-developer-mcp --stdio                            2>/dev/null && success "claude mcp: figma"      || warn "figma already registered or failed"
  claude mcp add slack      -- npx -y @modelcontextprotocol/server-slack                     2>/dev/null && success "claude mcp: slack"      || warn "slack already registered or failed"
  claude mcp add notion     -- npx -y @notionhq/notion-mcp-server                            2>/dev/null && success "claude mcp: notion"     || warn "notion already registered or failed"
  claude mcp add memory     -- npx -y @modelcontextprotocol/server-memory                    2>/dev/null && success "claude mcp: memory"     || warn "memory already registered or failed"
else
  warn "Claude Code CLI not found — skipping claude mcp add"
  warn "Install Claude Code first, then re-run this script"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ MCP setup complete${RESET}"
echo ""
echo "  Next steps:"
echo "  1. Fill in API tokens:  $MCP_ENV"
echo "  2. Restart Claude Desktop to pick up the new config"
echo "  3. Check active servers: claude mcp list"
echo ""
echo "  Token sources:"
echo "  • GitHub:  gh auth token"
echo "  • Figma:   Figma → Settings → Personal access tokens"
echo "  • Slack:   api.slack.com/apps → Bot Token (xoxb-...)"
echo "  • Notion:  notion.so/my-integrations → create integration"
echo ""
