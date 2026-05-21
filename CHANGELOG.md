# Changelog

All notable changes to claude-statusline-pro are documented here.  
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning: [SemVer](https://semver.org/).

## [1.0.0] — 2026-05-22

### Added

- **3-line HUD** with Claude Code status bar integration
- **Line 1 — AI metrics**: model name, context % used, cache hit %, input/output tokens, cost, cost rate ($/h), session duration, 5h/7d rate limits with reset times
- **Line 2 — Git state**: project folder, dirty lock icon, branch, diff stats (±A/D), ahead/behind remote (⇡⇣), short commit hash, time since last commit
- **Line 3 — Tool health**: GitNexus index freshness, Graphify graph freshness, skill count (local/global), STATE.md handoff indicator, RTK token savings
- **Adaptive timestamps**: tool stamps show `HH:MM` when updated today, `dd/mm HH:MM` when stale
- **RTK indicator** (`💾 N% (-Xk)`): savings percentage + absolute tokens saved today; falls back to last available day when no data for today
- **STATE.md indicator** (`📋✅/⚠/∅`): three-state freshness check against last git commit
- **Dynamic project checks** (config-driven): show 🟢/🔴 health status for local dev servers
- **Graceful degradation**: every indicator hides silently when its underlying tool is absent
- `install.sh`: bash 4+ check, OS detection (Linux / macOS / WSL), non-destructive `settings.json` merge via `jq`
- `uninstall.sh`: removes installed files, strips `statusLine` from `settings.json`, preserves user config
- `update-state.sh`: portable STATE.md auto-updater, wired to git `post-commit` hook
- `config.example.sh`: template for `~/.config/claude-statusline/config.sh`
