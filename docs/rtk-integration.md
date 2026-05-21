# RTK Integration

[RTK](https://github.com/andreafinazzi/rtk) intercepts shell commands before Claude reads their output, applies token-efficient filters, and records savings to a SQLite database. The `💾 N% (-Xk)` indicator reads from that database.

## Install RTK

```bash
# From source (requires Rust)
git clone https://github.com/andreafinazzi/rtk.git
cd rtk
cargo install --path .
```

Confirm installation:
```bash
which rtk && rtk --version
```

## Wire the Claude Code Hook

Add to your project's `.claude/settings.json` (or `~/.claude/settings.json` for global):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.local/share/rtk/rtk-rewrite.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

The hook intercepts every Bash tool call, runs `rtk rewrite` on the command, and if a filter exists, rewrites the command to `rtk <cmd>` before execution.

## Verify It Works

Run a filtered command via Claude Code (not directly in terminal):
```bash
git log -10
```

Then check the database:
```bash
python3 -c "
import sqlite3
db = sqlite3.connect('$HOME/.local/share/rtk/rtk.db')
rows = db.execute('SELECT cmd, original_tokens, filtered_tokens, timestamp FROM tracking ORDER BY id DESC LIMIT 5').fetchall()
for r in rows: print(r)
"
```

You should see a new row with `cmd = 'git log'` and `filtered_tokens` significantly lower than `original_tokens`.

## Supported Filters (built-in)

| Command | Typical savings |
|---------|-----------------|
| `git log` | ~80% |
| `git diff` | ~70% |
| `git status` | ~72% |
| `cargo test` | ~90% |
| `cargo build` / `cargo check` | ~85% |

## DB Location

RTK probes in this order:
1. `$RTK_DB_PATH` (env var override)
2. `$HOME/.local/share/rtk/rtk.db`
3. `$HOME/.config/rtk/rtk.db`
4. WSL only: `%APPDATA%/rtk/rtk.db` (Windows path)

Override via `config.sh`:
```bash
RTK_DB_PATH="$HOME/.local/share/rtk/rtk.db"
```
