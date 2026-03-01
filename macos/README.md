# macos/

macOS system configuration files.

## defaults.sh

Sets macOS system preferences via `defaults write`. Run manually or via bootstrap:

```sh
bash ~/.dotfiles/macos/defaults.sh
# or
bootstrap.sh defaults
```

**Covers:** Finder, Dock, Keyboard, Trackpad, Screen, Menu Bar, Activity Monitor, Safari, TextEdit, App Store.

Some changes take effect immediately after the affected app restarts (Finder, Dock, SystemUIServer are killed at the end of the script). A few require logout or full restart.

## com.captures.watcher.plist

LaunchAgent installed by `setup-captures`. Watches `~/Desktop` and moves screenshots and screen recordings to `~/Downloads/Screenshots` and `~/Downloads/Screen Recordings` automatically.
