# zsh/

Shell configuration for Zsh with Oh My Zsh.

| File | What it does |
|---|---|
| `.zshrc` | Main shell config — loads plugins, sets PATH, configures tools |
| `.zshenv` | Loaded for every shell (interactive or not) — minimal, just env vars |
| `aliases.zsh` | All shortcuts and command aliases |

---

## How it works

`.zshrc` is the main file. It loads Oh My Zsh, sets up tools like `fzf` and `zoxide`, then sources `aliases.zsh` at the end.

`.zshenv` is intentionally small — only things that need to be available even in non-interactive shells (like scripts).

---

## Machine-specific overrides

If you want to add something that only applies to one Mac, put it in `.local/.zshrc.local`. That file is loaded last and will override anything above it. It's gitignored so it never gets pushed.

---

## Useful aliases

A few highlights from `aliases.zsh`:

```sh
dots        # go to the dotfiles folder
dsync       # push dotfile changes to GitHub
dsync pull  # pull dotfile changes from GitHub
reload      # reload the shell without opening a new window
brewup      # update all Homebrew packages in one shot
ll          # detailed file list with icons and git status
h           # fuzzy search your command history
```
