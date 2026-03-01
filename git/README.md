# git/

Global Git configuration that applies to every repo on this machine.

| File | What it does |
|---|---|
| `.gitconfig` | Main git settings — editor, aliases, diff tool, identity routing |
| `.gitignore_global` | Files git should always ignore on every repo (e.g. `.DS_Store`, `.env`) |

---

## Identity (per GitHub account, per folder)

Git identity is set per-folder based on which GitHub account you configured during bootstrap. Each account gets its own identity file and folder mapping — no manual switching, no per-repo config.

Bootstrap generates `.local/.gitconfig-accounts` with all the routing rules, for example:

```
[includeIf "gitdir:~/personal/"]
  path = ~/.dotfiles/.local/.gitconfig-sjlouji

[includeIf "gitdir:~/work/"]
  path = ~/.dotfiles/.local/.gitconfig-jlouji
```

This file is loaded via `.local/.gitconfig.local`, which is included at the bottom of `.gitconfig`. All identity files live in `.local/` — gitignored, never pushed.

**To add a new GitHub account** after initial setup:
```sh
bash ~/.dotfiles/scripts/ssh-keygen.sh
```
Then manually add the corresponding `[includeIf]` block to `.local/.gitconfig-accounts`.

**To verify which identity is active** in any repo:
```sh
git whoami
```

---

## Useful git aliases

| Alias | What it does |
|---|---|
| `git st` | Short status |
| `git lg` | Visual commit graph |
| `git lga` | Graph including all branches |
| `git undo` | Undo last commit, keep changes staged |
| `git wip` | Quick `wip: YYYY-MM-DD` commit of everything |
| `git whoami` | Show which identity is active in this repo |
| `git recent` | List branches sorted by last commit |
| `git ap` | Interactive patch staging |
| `git pf` | Force push with lease (safe) |

---

## Diff tool

Uses [delta](https://github.com/dandavison/delta) for syntax-highlighted, side-by-side diffs with line numbers. Activated automatically for `git diff`, `git show`, and `git log -p`.
