# claude-statusline-pro

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash%204%2B-4EAA25?logo=gnu-bash&logoColor=white)](statusline.sh)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20WSL-blue)](docs/features.md)

> Terminal HUD status bar for [Claude Code](https://claude.ai/code) — tokens, cost, git state, tool freshness, and session handoff in three lines.

A 3-line HUD status bar for [Claude Code](https://claude.ai/code) that surfaces AI metrics, git state, token savings, and tool freshness at a glance — without leaving your terminal.

## Live preview

The status bar renders as three monospace lines at the bottom of Claude Code — no GUI window:

```
╭─ 👾 claude-sonnet-4-6 │ 🧠 42% ⚡ 78% │ ↓ 12.4k ↑ 2.1k │ 💵 $0.23 @$0.18/h ⌚ 1h12m │ ⏱️ 5% 🔄 14:30 ⏳ 12% 🔄 22/05 09:00
├─ 📁 my-project │ 🔒 main ±3/1 ⇡2⇣0 #a1b2c3 │ 🕒 45m
╰─ 🛠  🔌 gitnexus[✅ 14:22] │ 🕸  graphify[⚠ 21/05 23:36] │ 🏗  2/42 │ 📋✅ │ 💾 72% (-1.2k)
```

Install with the one-liner below and restart Claude Code to see your live session metrics.

## Features

| Indicator | Line | Description |
|-----------|------|-------------|
| `👾 model` | 1 | Active Claude model name |
| `🧠 N% ⚡ N%` | 1 | Context window used % / cache hit % |
| `↓ Nk ↑ Nk` | 1 | Input / output tokens this session |
| `💵 $N @$N/h ⌚ Nh` | 1 | Cost, rate ($/h), session duration |
| `⏱️ N% 🔄 HH:MM ⏳ N% 🔄 dd/mm HH:MM` | 1 | 5h and 7d rate limit usage + reset times |
| `📁 dir` | 2 | Current project folder name |
| `🔒/🔓 branch` | 2 | Dirty / clean indicator + branch name |
| `±A/D ⇡N⇣N #hash` | 2 | Diff stats, ahead/behind remote, short commit hash |
| `🕒 Xm/h/d` | 2 | Time elapsed since last commit |
| `🔌 gitnexus[stamp]` | 3 | GitNexus index freshness vs HEAD |
| `🕸 graphify[stamp]` | 3 | Graphify knowledge graph freshness vs HEAD |
| `🏗 L/G` | 3 | Local / global skill count (SKILL.md files) |
| `📋✅ / 📋⚠ / 📋∅` | 3 | STATE.md session handoff freshness |
| `💾 N% (-Xk)` | 3 | RTK token savings % + absolute tokens saved today |
| `🟢/🔴 label` | 3 | Custom project health check (config-driven) |

**Stamp format:** `✅ HH:MM` if updated today, `⚠ dd/mm HH:MM` if stale.  
**Graceful degradation:** every indicator silently hides when its tool is absent.

## Requirements

| Dependency | Required | Install |
|------------|----------|---------|
| `bash` 4+ | **Yes** | macOS: `brew install bash` (system bash is 3.x) |
| `git` | **Yes** | Any recent version |
| `jq` | **Yes** | `apt install jq` / `brew install jq` |
| `python3` | **Yes** | RTK DB queries; usually pre-installed |
| `curl` | No | Optional — dynamic project health checks only |
| `rtk` | No | Token savings (`💾`). See [RTK integration](docs/rtk-integration.md) |

## Quick Install

**One-liner:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/andreafinazziinfo/claude-statusline-pro/main/install.sh)
```

**Or clone:**
```bash
git clone https://github.com/andreafinazziinfo/claude-statusline-pro.git
cd claude-statusline-pro
bash install.sh
```

Restart Claude Code after installation to activate the status bar.

## Configuration

Copy the example config and edit it:
```bash
cp config.example.sh ~/.config/claude-statusline/config.sh
```

### Dynamic project health checks

Show live 🟢/🔴 for your local dev servers by directory name:
```bash
CSL_DYNAMIC_PROJECTS=(
    "my-api:http://localhost:8080/health:api"
    "frontend:http://localhost:3000:fe"
    "docs:http://localhost:4000:docs"
)
```
When `$DIR_NAME` matches an entry, the status bar checks the URL and shows `🟢 api` or `🔴 api`.

### STATE.md location

Override where `STATE.md` lives (default: git root of current project):
```bash
CSL_STATE_FILE="$HOME/dev/my-project/STATE.md"
```

### RTK DB path

If RTK stores its database at a custom path:
```bash
RTK_DB_PATH="$HOME/.local/share/rtk/rtk.db"
```

## Session Handoff (STATE.md)

`update-state.sh` keeps a `STATE.md` in your repo fresh after every commit.  
Pair it with Claude Code slash commands:

- `/save-state` — Claude fills the narrative sections (decisions, open items, next action)
- `/load-state` — bootstraps the next session from STATE.md

**📋 indicator states:**
| Icon | Meaning |
|------|---------|
| `📋✅` | STATE.md updated after last commit |
| `📋⚠` | STATE.md is stale (commit is newer) |
| `📋∅` | STATE.md missing or has unfilled template placeholders |

See [docs/state-handoff.md](docs/state-handoff.md) for the full workflow.

## RTK Integration

[RTK](https://github.com/andreafinazzi/rtk) filters noisy CLI output before Claude reads it, saving 60–90% of tokens on commands like `git diff`, `cargo test`, and `git log`. When installed, `💾 N% (-Xk)` shows today's savings percentage and absolute token count.

See [docs/rtk-integration.md](docs/rtk-integration.md).

## Uninstall

```bash
bash uninstall.sh
```

## License

MIT © 2026 Andrea Finazzi
