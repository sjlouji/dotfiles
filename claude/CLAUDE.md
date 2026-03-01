# CLAUDE.md — Global working memory for Claude

This file is read by Claude Code / Cowork at the start of every session.
Keep it current. It is the single source of truth for how Claude should work with you.

---

## Identity

- **Name:** Joan
- **Role:** Product + SDE2 Engineer at Freehand
- **Personal email:** sjlouji10@gmail.com
- **Work email:** joanlouji@freehand.ai
- **Personal GitHub:** sjlouji
- **Work GitHub:** jlouji
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

---

## Custom bin/ scripts

These live in `~/.dotfiles/bin/` and are on PATH. Suggest using them when relevant.

**System**
- `flushdns` — flush DNS cache
- `killport <port>` — kill process on a given port
- `clearcache` — clear dev caches (npm, pip, Xcode derived data)
- `diskcheck` — disk usage summary with warnings
- `sysinfo` — quick system overview (macOS, chip, RAM, IP, uptime)
- `purge` — free inactive memory

**Files**
- `cppath [file]` — copy absolute path to clipboard (defaults to cwd)
- `mkcd <dir>` — mkdir + cd in one command
- `batchrename '<sed>'` — bulk rename with preview before applying
- `imgresize <img> <px>` — resize image proportionally (uses built-in sips, no deps)
- `convert2jpg [quality]` — batch convert PNG/HEIC/WEBP → JPG in current dir
- `zipdir <dir>` — zip directory with timestamp
- `trash <files>` — safe delete: moves to ~/.Trash instead of permanent delete

**Git**
- `gnuke [--dry-run]` — delete all local branches merged into main
- `gpr` — interactive PR checkout (gh + fzf)
- `grepo <org> [dir]` — clone all repos from a GitHub org
- `ghealthcheck` — repo health: status, stashes, unpushed branches, large files
- `gclean [--dry-run]` — remove .DS_Store, prune remotes, run git GC

---

## Shorthand / acronyms I use

- `dots` = dotfiles repo (~/.dotfiles)
- `work mac` = work MacBook
- `home mac` = personal MacBook

---

## Standing instructions

1. When writing shell scripts, always check if a command exists before using it (`command -v foo`)
2. When suggesting `rm`, use `trash` instead
3. When creating new scripts, add a `--help` flag
4. When touching dotfiles, remind me to run `dsync` afterward
5. For credentials/secrets, always use Apple Keychain — never hardcode
6. Personal repos go under `sjlouji` GitHub, work repos under `jlouji`
