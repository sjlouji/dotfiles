# CLAUDE.md — Global working memory for Claude

This file is read by Claude Code / Cowork at the start of every session.
Keep it current. It is the single source of truth for how Claude should work with you.

---

## Identity

- **Name:** Joan
- **Email:** joanlouji@pando.ai
- **Role:** [Your role here — e.g. "Product engineer at Pando"]
- **Machine setup:** Multi-Mac (personal + work), dotfiles synced via ~/.dotfiles

---

## How I like to work

- Be direct and concise — no fluff, no excessive bullet points
- Show me the actual code / file / command, not just describe it
- When something is ambiguous, ask one focused question before proceeding
- Prefer editing existing files over creating new ones unless I ask for a new file
- Always tell me if you're doing something irreversible before doing it

---

## Code style preferences

- **Shell:** Bash/Zsh with `set -euo pipefail`, functions over one-liners, comments on non-obvious logic
- **Python:** Black formatting, type hints, f-strings
- **JS/TS:** Prettier defaults, functional style preferred, named exports
- **General:** Clear variable names, no magic numbers, fail loudly

---

## Project conventions

- Dotfiles live in `~/.dotfiles`
- Machine-specific files live in `~/.dotfiles/.local/` (gitignored)
- All custom scripts go in `~/.dotfiles/bin/` and should be executable
- Sync dotfiles with `dsync` (push) or `dsync pull`

---

## Shorthand / acronyms I use

- `dots` = dotfiles repo (~/.dotfiles)
- `work mac` = work MacBook
- `home mac` = personal MacBook
- Add your own here as you go

---

## Things to remember

- I use 1Password for secrets — never hardcode credentials, suggest `op read` instead
- I use `mise` (not nvm/pyenv directly) for runtime version management
- Preferred terminal: iTerm2 with Oh My Zsh
- Preferred editor: VS Code

---

## Standing instructions

1. When writing shell scripts, always check if a command exists before using it (`command -v foo`)
2. When suggesting `rm`, use `trash` instead
3. When creating new scripts, add a `--help` flag
4. When touching dotfiles, remind me to run `dsync` afterward
