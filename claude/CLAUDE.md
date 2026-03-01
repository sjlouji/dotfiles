# CLAUDE.md — Global working memory for Claude

This file is read by Claude Code / Cowork at the start of every session.
Keep it current. It is the single source of truth for how Claude should work with you.

---

## Identity

<!-- Personal details live in .local/CLAUDE.local.md (gitignored) — see .local/CLAUDE.local.md.template -->
- **Machine setup:** Multi-Mac (personal + work), dotfiles synced via ~/.dotfiles

---

## How I like to work

- Be direct and concise — no fluff, no excessive bullet points
- Show me the actual code / file / command, not just describe it
- When something is ambiguous, ask one focused question before proceeding
- Prefer editing existing files over creating new ones unless I ask for a new file
- Always tell me if you're doing something irreversible before doing it

## Communication & response style

- Lead with the solution — code or command first, explanation after if needed
- Keep responses short and direct; don't pad with context I didn't ask for
- No heavy bullet-pointed responses — use prose or inline explanations
- If something is unclear, ask one focused question — never a list of questions
- Don't summarise what you just did at the end of a response; it's obvious

---

## Preferred stack

- **Languages:** Python, Node.js, TypeScript
- **Frontend:** React.js, Vue.js
- **Shell:** Bash / Zsh

---

## Code style preferences

- **Shell:** Bash/Zsh with `set -euo pipefail`, functions over one-liners, comments on non-obvious logic
- **Python:** Black formatting, type hints, f-strings
- **JS/TS:** Prettier defaults, functional style preferred, named exports
- **React:** Functional components, hooks, no class components
- **Vue:** Composition API preferred over Options API
- **General:** Clear variable names, no magic numbers, fail loudly

---

## Environment

- **Terminal:** Mac Terminal with Oh My Zsh
- **Editor:** VS Code
- **Password manager:** Apple Password Manager (Keychain) — never hardcode credentials, use Keychain or env vars
- **Runtime versions:** `mise` for Node, Python, etc. (not nvm/pyenv directly)

---

## Project conventions

- Dotfiles live in `~/.dotfiles`
- Machine-specific files live in `~/.dotfiles/.local/` (gitignored)
- All custom scripts go in `~/.dotfiles/bin/` and should be executable
- Sync dotfiles with `dsync` (push) or `dsync pull`
- macOS system preferences live in `macos/defaults.sh` — run `make defaults` to apply
- `Makefile` at repo root wraps `bootstrap.sh` — prefer `make <module>` for one-off re-runs
- `bootstrap.sh` shows a numbered menu when run with no args; accepts comma-separated names or numbers (`4,5` or `git,ssh`); `all`/`9` = full fresh-Mac setup

---

## MCP servers available

These integrations are active. Use them directly — don't ask me to copy-paste from these tools manually.

| Server | What it can do |
|---|---|
| `github` | Read/write issues, PRs, branches, files, commits across both `sjlouji` and `jlouji` GitHub accounts |
| `filesystem` | Read and write files in `~/personal`, `~/work`, `~/projects` |
| `figma` | Inspect component structure, read design tokens, extract assets |
| `slack` | Read channels, search messages, post updates |
| `notion` | Read and write Notion pages and databases |
| `memory` | Persist facts, entities, and context across sessions |

Tokens live in `~/.dotfiles/.local/mcp.env` (gitignored). Re-run `setup-mcp` after adding new tokens.

---

## Custom bin/ scripts

All scripts live in `~/.dotfiles/bin/` and are on PATH. Always suggest these before recommending external tools or manual commands.

### Setup & Audit
| Script | Usage | What it does |
|---|---|---|
| `dotcheck` | `dotcheck` | Audit the full setup — symlinks, git identity, SSH, scripts, sync, screenshots. Shows ✓/⚠/✗ for every component with exact fix commands |
| `setup-mcp` | `setup-mcp` | Install MCP servers and wire up config for Claude Desktop + Claude Code. Re-run after adding tokens to `.local/mcp.env` |

### Ports
| Script | Usage | What it does |
|---|---|---|
| `findport` | `findport` | List every port currently listening on this Mac |
| `findport` | `findport 3000` | Show process name, PID, user, and command on port 3000 |
| `findport` | `findport node` | Find all ports used by any process matching "node" |
| `killport` | `killport 3000` | Show what's on port 3000, ask to confirm, then kill it |
| `killport` | `killport 3000 --force` | Kill port 3000 immediately without asking |

### System
| Script | Usage | What it does |
|---|---|---|
| `flushdns` | `flushdns` | Flush the DNS cache |
| `clearcache` | `clearcache` | Clear npm, pip, and Xcode derived data caches |
| `clearcache` | `clearcache --dry-run` | Preview what would be cleared without clearing |
| `diskcheck` | `diskcheck` | Disk usage summary — warns if any volume is over 80% |
| `sysinfo` | `sysinfo` | Print macOS version, chip, RAM, IP address, uptime |
| `purge` | `purge` | Free up inactive memory |
| `setup-captures` | `setup-captures` | Set up auto-organised folders for screenshots and screen recordings — routes everything to ~/Downloads/Screenshots and ~/Downloads/Screen Recordings |

### Files
| Script | Usage | What it does |
|---|---|---|
| `cppath` | `cppath` | Copy the current folder's absolute path to clipboard |
| `cppath` | `cppath file.txt` | Copy a specific file's absolute path to clipboard |
| `mkcd` | `mkcd new-folder` | Create a folder and cd into it in one step |
| `batchrename` | `batchrename 's/old/new/g'` | Bulk rename files using a sed pattern — shows preview first |
| `imgresize` | `imgresize photo.png 800` | Resize an image to 800px wide, proportionally, using built-in sips |
| `convert2jpg` | `convert2jpg` | Batch convert all PNG/HEIC/WEBP in current folder to JPG |
| `convert2jpg` | `convert2jpg 90` | Same, with custom quality (1–100, default 85) |
| `zipdir` | `zipdir ./folder` | Zip a folder — output named folder_YYYYMMDD.zip |
| `trash` | `trash file.txt` | Move to ~/.Trash instead of deleting permanently — use instead of rm |

### Git
| Script | Usage | What it does |
|---|---|---|
| `gnuke` | `gnuke` | Delete all local branches already merged into main |
| `gnuke` | `gnuke --dry-run` | Preview which branches would be deleted |
| `gpr` | `gpr` | Fuzzy-pick an open PR from a list and check it out (needs gh + fzf) |
| `grepo` | `grepo myorg` | Clone every repo from a GitHub org into one folder |
| `grepo` | `grepo myorg ~/work` | Same, into a specific destination |
| `ghealthcheck` | `ghealthcheck` | Show git status, stash list, unpushed branches, and large tracked files |
| `gclean` | `gclean` | Remove .DS_Store, prune stale remote refs, run git GC |
| `gclean` | `gclean --dry-run` | Preview what gclean would do |

---

## Shorthand / acronyms I use

- `dots` = dotfiles repo (~/.dotfiles)
- `work mac` = work MacBook
- `home mac` = personal MacBook

---

## Standing instructions

1. When writing shell scripts, always check if a command exists before using it (`command -v foo`)
2. Always suggest `trash` instead of `rm`
3. When creating new scripts, add a `--help` flag
4. When touching dotfiles, remind me to run `dsync` afterward
5. For credentials/secrets, always use Apple Keychain — never hardcode
6. Personal repos go under `sjlouji` GitHub, work repos under `jlouji`
7. Before suggesting a manual terminal command, check if a bin/ script already covers it
