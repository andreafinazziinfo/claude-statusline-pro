---
name: Bug report
about: Something isn't displaying correctly or the script crashes
title: "[BUG] "
labels: bug
assignees: ''
---

**Describe the bug**
A clear description of what went wrong.

**Platform**
- OS: [Linux / macOS / WSL]
- Bash version: `bash --version`
- Claude Code version: `claude --version`

**Indicator affected**
Which part of the status bar is broken? (line 1 / line 2 / RTK / STATE.md / gitnexus / graphify / dynamic tools)

**To reproduce**
Steps to reproduce:
1. ...
2. ...

**Expected output**
What should the status bar show?

**Actual output**
What does it show instead? (paste the 3 lines if possible)

**Debug info**
```bash
# Run and paste output:
bash -x ~/.claude/statusline-command.sh <<< '{}' 2>&1 | head -40
```

**Additional context**
Any other relevant info (custom config.sh, unusual PATH, etc.).
