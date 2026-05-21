# Features Reference

## Line 1 — AI Session Metrics

| Segment | Source field | Notes |
|---------|-------------|-------|
| `👾 model` | `model.display_name` | Falls back to raw `model` string |
| `🧠 N%` | `context_window.used_percentage` | Green ≤50%, yellow ≤80%, red >80% |
| `⚡ N%` | `cache_read + cache_creation` / `total_input_tokens` | Prompt cache hit rate |
| `↓ Nk ↑ Nk` | `total_input_tokens` / `total_output_tokens` | Formatted as `k` above 1000 |
| `💵 $N` | `cost.total_cost_usd` | Session total |
| `@$N/h` | cost / (duration_ms / 3600000) | Shown when session > 36s |
| `⌚ Nh` | `cost.total_duration_ms` | Falls back to session JSON files |
| `⏱️ N%` | `rate_limits.five_hour.used_percentage` | 5-hour rolling window |
| `🔄 HH:MM` | `rate_limits.five_hour.resets_at` | Epoch → local time |
| `⏳ N%` | `rate_limits.seven_day.used_percentage` | 7-day rolling window |
| `🔄 dd/mm HH:MM` | `rate_limits.seven_day.resets_at` | Epoch → local date + time |

## Line 2 — Git State

| Segment | Description |
|---------|-------------|
| `📁 dir` | `basename` of the git root |
| `🔒 / 🔓` | Dirty (untracked or modified files) / clean |
| `branch` | Current branch; `no-git` if not in a repo |
| `±A/D` | Lines added/deleted in working tree (from `git diff --numstat`) |
| `⇡N⇣N` | Commits ahead / behind upstream |
| `#hash` | Short commit hash (7 chars) |
| `🕒 Xm/h/d` | Age of last commit (seconds → days) |

## Line 3 — Tools & Handoff

| Segment | States | Description |
|---------|--------|-------------|
| `🔌 gitnexus[stamp]` | `✅ HH:MM` / `⚠ dd/mm` / `⚙️cfg` / `❌` | Index freshness vs HEAD commit |
| `🕸 graphify[stamp]` | `✅ HH:MM` / `⚠ dd/mm` / `❌` | GRAPH_REPORT.md freshness vs HEAD |
| `🏗 L/G` | Numbers | Local skill files / global skill files (SKILL.md) |
| `📋` | `✅` / `⚠` / `∅` | STATE.md session handoff freshness |
| `💾 N% (-Xk)` | Hidden if RTK absent | Today's token savings % + absolute. Falls back to last recorded day |
| `🟢/🔴 label` | Hidden if no config | Custom health check from `CSL_DYNAMIC_PROJECTS` |

### Stamp timestamp format

- Updated **today** → `HH:MM` (time only)
- Updated on a **previous day** → `dd/mm HH:MM`

This keeps the display compact when tools are fresh and informative when they're stale.
