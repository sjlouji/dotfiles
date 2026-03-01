## Setting up a new Mac

Paste this into Terminal and follow the prompts:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sjlouji/dotfiles/main/bootstrap.sh)"
```

It will show a numbered menu — enter the numbers or names you want, comma-separated:

```
  [1] packages  — Homebrew bundle (formulae, casks, fonts)
  [2] shell     — Oh My Zsh, plugins, default shell
  [3] symlinks  — dotfile symlinks
  [4] git       — git identity files per account
  [5] ssh       — SSH keys for GitHub accounts
  [6] claude    — Claude / MCP integrations
  [7] vscode    — VS Code extensions
  [8] defaults  — macOS system preferences
  [9] all       — full fresh Mac setup (Xcode, Homebrew, clone + all modules)

  Modules (comma-separated names or numbers) [all]: _
```

Examples: `all` or just Enter → full setup. `4,5` or `git,ssh` → only those two. `1,3,vscode` → mix of numbers and names.

On a fresh Mac, select `all`. Everything else — Homebrew install, Oh My Zsh, apps, symlinks, git identity — happens automatically.

Git will use the right identity automatically based on which folder your repo lives in. No manual switching needed.

---

## Re-running a module on an existing Mac

From inside `~/.dotfiles`:

```sh
make git       # regenerate git identity files
make ssh       # regenerate SSH keys
make packages  # re-run brew bundle
make shell     # reinstall Oh My Zsh plugins, reset default shell
make symlinks  # recreate dotfile symlinks
make vscode    # reinstall VS Code extensions
make claude    # re-configure Claude / MCP
make defaults  # re-apply macOS system preferences
make           # show all available targets
```

---

## After installation

Once bootstrap finishes, do these three things:

**1. Add your API tokens for Claude integrations**

Bootstrap creates a token file for you at `~/.dotfiles/.local/mcp.env`. Open it and fill in the services you use:

```sh
open ~/.dotfiles/.local/mcp.env
```

Then apply the config:

```sh
setup-mcp
```

This wires up GitHub, Figma, Slack, and Notion directly into Claude. You only need tokens for the services you actually use — skip the rest.

**2. Set up screenshots and recordings**

```sh
setup-captures
```

From now on, screenshots go to `~/Downloads/Screenshots` and screen recordings go to `~/Downloads/Screen Recordings` automatically.

**3. Reload your shell**

```sh
reload
```

---

## Check your setup at any time

```sh
dotcheck
```

This audits everything — symlinks, git identity, SSH, scripts, sync, screenshots — and tells you exactly what's active, what's missing, and what command to run to fix it.

---

## What's inside

| Folder | What it does |
|---|---|
| `bootstrap.sh` | Run once on a new Mac to set everything up |
| `Makefile` | Shortcut targets — `make git`, `make ssh`, `make packages`, etc. |
| `Brewfile` | Every app and CLI tool I use |
| `zsh/` | Shell config, shortcuts, and aliases |
| `git/` | Git settings, global ignore rules, and commit template |
| `ssh/` | SSH connection config (no private keys) |
| `vscode/` | VS Code settings, keybindings, and extensions |
| `claude/` | Claude AI instructions and settings |
| `macos/` | macOS system preferences (`defaults.sh`) |
| `bin/` | Custom terminal commands available everywhere |
| `sync/` | Keeps the repo synced across Macs |
| `scripts/` | One-time setup helpers |
| `.local/` | Your machine-specific settings — never pushed to GitHub |

---

## How git identity works

Bootstrap collects your GitHub accounts and writes per-account identity files into `.local/` (gitignored, never pushed):

```
.local/
  .gitconfig-sjlouji   ← used automatically in ~/personal/
  .gitconfig-jlouji    ← used automatically in ~/work/
```

You never have to set `user.email` per repo. Just put your repos in the right folder and git handles it. Run `git whoami` in any repo to confirm which identity is active.

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

The `.local/` folder is for things that differ between Macs — your name, emails, paths, and any extras. This folder is **never uploaded to GitHub**.

`bootstrap.sh` creates it automatically when you set up a new Mac. To override anything just for one machine, add it to `.local/.zshrc.local`.

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

**New app or tool** → add to `Brewfile`, run `make packages`, then `dsync`.

**New shell alias** → add to `zsh/aliases.zsh`, then `dsync`.

**New git commit habit** → edit `git/.gitmessage` — it opens every time you run `git commit`.

**macOS preference** → add to `macos/defaults.sh`, run `make defaults`, then `dsync`.

**Machine-only change** → add to `.local/.zshrc.local` (stays on this Mac only).
