# sync/

Everything that keeps this repo in sync across Macs.

| File | What it does |
|---|---|
| `dsync.sh` | The `dsync` command — push, pull, or check sync status |
| `auto-sync.sh` | Called by the background LaunchAgent every 30 minutes |
| `hooks/pre-push` | Blocks any accidental push of secrets or `.local/` files |
| `hooks/post-merge` | Re-applies symlinks automatically after a pull |

---

## dsync commands

```sh
dsync           # commit all changes and push to GitHub
dsync pull      # pull latest from GitHub and re-apply symlinks
dsync status    # show what's different between this Mac and GitHub
```

---

## How auto-sync works

1. A LaunchAgent runs `auto-sync.sh` every 30 minutes
2. It checks for new commits on GitHub
3. If there are updates and no local uncommitted changes, it pulls automatically
4. If there are local changes, it skips and logs a message instead — it never overwrites your work

---

## Safety

The `pre-push` hook runs before every `git push` and will block the push if it finds any of these in the commit:

- `.local/` files
- Files ending in `.pem`, `.key`, `_ed25519`, `_rsa`
- Files named `.env`, `machine.sh`, or anything with "secret", "token", or "password" in the name
