# ssh/

SSH client configuration.

| File | What it does |
|---|---|
| `config` | Connection settings for GitHub and other hosts |

---

## What's configured

- **GitHub (personal)** — uses `~/.ssh/id_ed25519` with your `sjlouji` account
- **GitHub (work)** — commented out by default, uncomment to use with your `jlouji` account
- **Connection multiplexing** — reuses existing SSH connections so repeated connections to the same host are instant
- **Apple Keychain** — SSH key passphrases are stored in Keychain so you're not asked every time

---

## Private keys

Private keys are **not** stored in this repo. They live only on each Mac at `~/.ssh/`.

To generate a new key on a fresh Mac, run:

```sh
bash ~/.dotfiles/scripts/ssh-keygen.sh
```

This creates the key and offers to add it to GitHub automatically.
