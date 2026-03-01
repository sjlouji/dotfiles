# vscode/

VS Code settings synced across all Macs.

| File | What it does |
|---|---|
| `settings.json` | Editor preferences — font, theme, formatting, behaviour |
| `keybindings.json` | Custom keyboard shortcuts |
| `extensions.txt` | List of extensions installed automatically by `bootstrap.sh` |

---

## How it works

`symlink.sh` links these files directly into VS Code's config folder:

```
~/Library/Application Support/Code/User/settings.json
~/Library/Application Support/Code/User/keybindings.json
```

Any change you make in VS Code's settings UI will write back to these files, and `dsync` will pick them up.

---

## Adding an extension

Install it in VS Code normally, then add the extension ID to `extensions.txt` so it gets installed automatically on every other Mac.

You can find the extension ID by right-clicking it in the Extensions panel → "Copy Extension ID".
