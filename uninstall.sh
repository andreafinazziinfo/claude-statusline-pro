#!/usr/bin/env bash
# uninstall.sh — removes claude-statusline-pro installed files
set -euo pipefail

_CLAUDE_DIR="$HOME/.claude"
_DEST_STATUSLINE="$_CLAUDE_DIR/statusline-command.sh"
_DEST_UPDATE="$HOME/.local/bin/claude-update-state"
_SETTINGS="$_CLAUDE_DIR/settings.json"

echo "claude-statusline-pro — uninstaller"
echo ""

# Remove statusline script
if [ -f "$_DEST_STATUSLINE" ]; then
    rm "$_DEST_STATUSLINE"
    echo "✓ Removed $_DEST_STATUSLINE"
else
    echo "  $_DEST_STATUSLINE not found — skipping"
fi

# Remove update-state helper
if [ -f "$_DEST_UPDATE" ]; then
    rm "$_DEST_UPDATE"
    echo "✓ Removed $_DEST_UPDATE"
else
    echo "  $_DEST_UPDATE not found — skipping"
fi

# Remove statusLine key from settings.json (preserve rest of file)
if [ -f "$_SETTINGS" ] && jq -e '.statusLine' "$_SETTINGS" &>/dev/null; then
    _tmp=$(mktemp)
    jq 'del(.statusLine)' "$_SETTINGS" > "$_tmp" && mv "$_tmp" "$_SETTINGS"
    echo "✓ Removed statusLine from $_SETTINGS"
fi

# Note: config.sh and post-commit hook left intentionally
echo ""
echo "Done. config.sh and git hooks were not removed — delete manually if needed."
echo "Restart Claude Code to deactivate."
