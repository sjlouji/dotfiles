# macos/

Mac system preferences and background services.

| File | What it does |
|---|---|
| `defaults.sh` | Applies sensible Mac settings automatically |
| `com.dotfiles.sync.plist` | Background service that checks for dotfile updates every 30 minutes |

---

## What defaults.sh changes

Run automatically by `bootstrap.sh`. Covers:

- **Finder** — show hidden files, show file extensions, list view by default, search current folder
- **Dock** — auto-hide, faster animation, no recent apps
- **Keyboard** — faster key repeat, disable autocorrect and smart quotes
- **Trackpad** — tap to click, natural scrolling
- **Screenshots** — save to `~/Desktop/Screenshots`, no drop shadow, PNG format
- **General** — expand save dialogs by default, don't write `.DS_Store` on network drives

To re-apply settings after a macOS update:

```sh
bash ~/.dotfiles/macos/defaults.sh
```

---

## Auto-sync service

`com.dotfiles.sync.plist` is a macOS LaunchAgent — a background service that wakes up every 30 minutes to check if there are new dotfile updates on GitHub. If there are, it pulls them silently. It never auto-pushes.

Check the sync log at any time:

```sh
cat /tmp/dotfiles-sync.log
```
