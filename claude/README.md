# claude/

Configuration for Claude AI (Cowork and Claude Code).

| File | What it does |
|---|---|
| `CLAUDE.md` | Instructions Claude reads at the start of every session |
| `settings.json` | Permissions and preferences for Claude tools |

---

## CLAUDE.md

This is the most important file here. It tells Claude who you are, how you like to work, your stack, and what tools you have available.

Keep it up to date — when you learn a new preference or add a new bin script, add it here so Claude remembers across sessions.

---

## Updating CLAUDE.md

Just edit the file and run `dsync`. Claude will pick up the changes in the next session.
