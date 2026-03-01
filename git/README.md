# git/

Global Git configuration that applies to every repo on this machine.

| File | What it does |
|---|---|
| `.gitconfig` | Main git settings — editor, aliases, diff tool, identity rules |
| `.gitignore_global` | Files git should always ignore on every repo (e.g. `.DS_Store`, `.env`) |

---

## Identity (personal vs work)

Git identity is set per-folder, not globally. This means:

- Repos inside `~/personal/` or `~/projects/` → uses your personal email
- Repos inside `~/work/` → uses your work email

This is handled automatically using git's `includeIf` feature. The identity files live in `.local/` (not in this repo) and are created when you run `bootstrap.sh`.

---

## Useful git aliases

These are set in `.gitconfig` and work as regular git commands:

```sh
git st          # short status
git lg          # visual commit history graph
git undo        # undo the last commit (keeps your changes)
git wip         # quick "work in progress" commit
git whoami      # show which identity git is using right now
git recent      # list branches sorted by most recently used
```

---

## Diff tool

Uses [delta](https://github.com/dandavison/delta) for nicer-looking diffs with syntax highlighting and side-by-side view.
