# dotfiles

My personal Mac setup — configs, tools, and scripts that follow me across every machine.

---

## Setting up a new Mac

Paste this into Terminal and follow the prompts:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sjlouji/dotfiles/main/bootstrap.sh)"
```

It will ask one question: **personal** or **work** Mac? Everything else happens automatically — Homebrew, Oh My Zsh, all apps, settings, and scripts.

---

## What's inside

| Folder | What it does |
|---|---|
| `bootstrap.sh` | Run once on a new Mac to set everything up |
| `Brewfile` | Every app and CLI tool I use |
| `zsh/` | Shell config, shortcuts, and aliases |
| `git/` | Git settings and global ignore rules |
| `ssh/` | SSH connection config (no private keys) |
| `vscode/` | VS Code settings, keybindings, and extensions |
| `claude/` | Claude AI instructions and settings |
| `macos/` | Mac system preferences applied automatically |
| `bin/` | Custom terminal commands available everywhere |
| `sync/` | Keeps the repo synced across Macs |
| `scripts/` | One-time setup helpers |
| `.local/` | Your machine-specific settings — never pushed to GitHub |

---

## Keeping two Macs in sync

```sh
dsync           # save your changes and push to GitHub
dsync pull      # pull the latest changes on another Mac
dsync status    # see what's out of sync
```

The repo also syncs automatically in the background every 30 minutes. If there are new changes, your terminal will show a one-line notification next time you open it.

---

## Machine-specific settings

The `.local/` folder is for things that differ between Macs — your name, email, paths, and any extras. This folder is **never uploaded to GitHub**.

`bootstrap.sh` creates it automatically when you set up a new Mac. If you want to override anything just for one machine, add it to `.local/.zshrc.local`.

---

## Custom commands

All scripts in `bin/` work as normal terminal commands. See [bin/README.md](bin/README.md) for the full list with examples.

---

## Security

- Private SSH keys are never stored here
- `.local/` is gitignored — machine-specific identity and secrets stay off GitHub
- A git hook blocks any accidental push of credentials or secret files

---

## Adding something new

**New app or tool** → add to `Brewfile`, run `brew bundle`, then `dsync`.

**New shell alias** → add to `zsh/aliases.zsh`, then `dsync`.

**Machine-only change** → add to `.local/.zshrc.local` (stays on this Mac only).
