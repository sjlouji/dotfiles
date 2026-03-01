# scripts/

One-time setup helpers. These run during `bootstrap.sh` and aren't meant for everyday use.

| File | What it does |
|---|---|
| `symlink.sh` | Links all config files from this repo into the right places on your Mac |
| `ssh-keygen.sh` | Generates a new SSH key and optionally adds it to GitHub |

---

## symlink.sh

Creates symlinks like:

```
~/.zshrc              → ~/.dotfiles/zsh/.zshrc
~/.gitconfig          → ~/.dotfiles/git/.gitconfig
~/.ssh/config         → ~/.dotfiles/ssh/config
~/Library/.../settings.json → ~/.dotfiles/vscode/settings.json
```

Safe to run multiple times — it backs up any existing file before replacing it, so nothing gets lost.

```sh
bash ~/.dotfiles/scripts/symlink.sh
```

## ssh-keygen.sh

Generates a new `ed25519` SSH key, adds it to your Mac's Keychain, and offers to upload the public key to GitHub via the `gh` CLI.

```sh
bash ~/.dotfiles/scripts/ssh-keygen.sh
```
