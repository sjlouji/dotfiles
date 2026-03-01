# bin/

Custom terminal commands. All of these are available anywhere in your terminal once dotfiles are installed.

Run any command with `--help` to see usage details.

---

## Setup & Audit

| Command | What it does |
|---|---|
| `dotcheck` | Audit the full dotfiles setup — shows what is active, missing, or broken with fix commands |

## System

| Command | What it does |
|---|---|
| `flushdns` | Flush the DNS cache |
| `findport` | List every port currently in use |
| `findport 3000` | Show what's running on port 3000 |
| `findport node` | Show all ports used by a process name |
| `killport 3000` | Show what's on a port, confirm, then kill it |
| `killport 3000 --force` | Kill a port immediately without asking |
| `clearcache` | Clear npm, pip, and Xcode caches |
| `diskcheck` | Show disk usage — warns if over 80% full |
| `sysinfo` | Quick summary: macOS version, chip, RAM, IP, uptime |
| `purge` | Free up inactive memory |
| `setup-captures` | Set up auto-organised folders for screenshots and screen recordings |

## Files

| Command | What it does |
|---|---|
| `cppath` | Copy the current folder's path to clipboard |
| `cppath file.txt` | Copy a file's full path to clipboard |
| `mkcd new-folder` | Create a folder and move into it |
| `batchrename 's/old/new/g'` | Rename multiple files — shows a preview first |
| `imgresize photo.png 800` | Resize an image to 800px wide (keeps ratio) |
| `convert2jpg` | Convert all PNG/HEIC files in this folder to JPG |
| `zipdir ./my-folder` | Zip a folder with today's date in the filename |
| `trash file.txt` | Move a file to Trash instead of deleting permanently |

## Git

| Command | What it does |
|---|---|
| `gnuke` | Delete local branches that are already merged |
| `gnuke --dry-run` | Preview what would be deleted without deleting |
| `gpr` | Pick an open PR from a list and check it out |
| `grepo myorg` | Clone every repo from a GitHub org into one folder |
| `ghealthcheck` | Show git status, stashes, unpushed branches, large files |
| `gclean` | Remove .DS_Store files, prune stale remotes, tidy up |
