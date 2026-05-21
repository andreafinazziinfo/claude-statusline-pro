# Session Handoff with STATE.md

Session handoff lets you resume a Claude Code session cheaply: instead of paying to re-read the entire codebase, you bootstrap from a compact `STATE.md` snapshot.

## STATE.md Format

```markdown
## SESSION STATE — 2026-05-22 14:30

### Repo & Branch
- repo: my-project
- branch: main
- dirty: yes — 3 file(s) (src/api.py,tests/test_api.py,README.md)

### Decisions (last 3 completed tasks)
- fix: src/api.py → rate limit now returns 429

### Open items
- [ ] Add pagination to /users endpoint

### Next action
Review PR #42 — pagination implementation ready for merge.

### Key paths
- src/api.py
- tests/test_api.py
```

The structural fields (`repo`, `branch`, `dirty`, date header) are filled automatically by `update-state.sh`. The narrative sections are written by Claude via `/save-state`.

## Auto-Update

`update-state.sh` updates the structural fields automatically at two points:

**After every commit** (git post-commit hook):
```bash
# .git/hooks/post-commit
claude-update-state
```
`install.sh` wires this automatically.

**At session start** (Claude Code `UserPromptSubmit` hook):
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "_f=\"/tmp/.state-upd-$(date +%Y%m%d)\"; [ -f \"$_f\" ] || { claude-update-state && touch \"$_f\"; }",
        "timeout": 3000
      }]
    }]
  }
}
```
The tmpfile flag ensures the script runs once per calendar day.

## Slash Commands

Add these to `.claude/commands/` in your project:

**save-state.md** — instructs Claude to fill the narrative sections:
```
Generate a STATE.md in the current working directory.
Fill: date (ISO), repo, branch, dirty, last 3 decisions, open items, next action, key paths.
Max 35 lines. No prose.
Print: "STATE.md saved."
```

**load-state.md** — instructs Claude to read STATE.md and resume:
```
Read STATE.md. If missing or contains template placeholders, respond:
"No active state — run /save-state to create one."
Otherwise display as-is. Do not modify the file.
```

## 📋 Indicator States

| Icon | Condition |
|------|-----------|
| `📋✅` | STATE.md mtime ≥ last git commit timestamp |
| `📋⚠` | STATE.md mtime < last git commit (stale) |
| `📋∅` | File missing, or contains `{data ISO}` / `{repo attivo}` placeholders |
