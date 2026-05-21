#!/usr/bin/env bash
# install.sh — claude-statusline-pro installer
# Supports: Linux, macOS, WSL
set -euo pipefail

# ── Bash version guard ─────────────────────────────────────────────────────
if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
    echo "Error: bash 4+ required (found ${BASH_VERSION:-unknown})" >&2
    echo "  macOS users: brew install bash" >&2
    exit 1
fi

# ── OS detection ───────────────────────────────────────────────────────────
_os="linux"
case "$(uname -s)" in
    Darwin) _os="macos" ;;
    Linux)
        if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
            _os="wsl"
        fi
        ;;
esac

echo "claude-statusline-pro v$(grep '^VERSION=' statusline.sh | cut -d'"' -f2) — installer"
echo "Platform: ${_os}"
echo ""

# ── Dependency check ───────────────────────────────────────────────────────
_missing=()
for _dep in jq git python3; do
    command -v "$_dep" &>/dev/null || _missing+=("$_dep")
done
if [ "${#_missing[@]}" -gt 0 ]; then
    echo "Error: missing required dependencies: ${_missing[*]}" >&2
    echo "  Install them and re-run." >&2
    exit 1
fi

# ── Destination paths ──────────────────────────────────────────────────────
_CLAUDE_DIR="$HOME/.claude"
_DEST_STATUSLINE="$_CLAUDE_DIR/statusline-command.sh"
_DEST_UPDATE="$HOME/.local/bin/claude-update-state"
_SETTINGS="$_CLAUDE_DIR/settings.json"
_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-statusline"
_CONFIG_EXAMPLE="$_CONFIG_DIR/config.sh"

mkdir -p "$_CLAUDE_DIR" "$HOME/.local/bin" "$_CONFIG_DIR"

# ── Copy statusline.sh ─────────────────────────────────────────────────────
cp statusline.sh "$_DEST_STATUSLINE"
chmod +x "$_DEST_STATUSLINE"
echo "✓ statusline.sh → $_DEST_STATUSLINE"

# ── Copy update-state.sh ───────────────────────────────────────────────────
cp update-state.sh "$_DEST_UPDATE"
chmod +x "$_DEST_UPDATE"
echo "✓ update-state.sh → $_DEST_UPDATE"

# ── Copy config example (non-destructive) ─────────────────────────────────
if [ ! -f "$_CONFIG_EXAMPLE" ]; then
    cp config.example.sh "$_CONFIG_EXAMPLE"
    echo "✓ config.example.sh → $_CONFIG_EXAMPLE (edit to customize)"
else
    echo "  config.sh already exists — skipping (not overwritten)"
fi

# ── Merge settings.json (never overwrite, only add statusLine key) ─────────
_STATUS_CMD="bash ${_DEST_STATUSLINE}"
if [ -f "$_SETTINGS" ]; then
    _tmp=$(mktemp)
    jq --arg cmd "$_STATUS_CMD" \
       '.statusLine = {"type":"command","command":$cmd}' \
       "$_SETTINGS" > "$_tmp" && mv "$_tmp" "$_SETTINGS"
    echo "✓ Merged statusLine into existing $_SETTINGS"
else
    jq -n --arg cmd "$_STATUS_CMD" \
       '{"statusLine":{"type":"command","command":$cmd}}' > "$_SETTINGS"
    echo "✓ Created $_SETTINGS with statusLine"
fi

# ── Optional: git post-commit hook for STATE.md auto-update ───────────────
_GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$_GIT_ROOT" ]; then
    _HOOK_FILE="$_GIT_ROOT/.git/hooks/post-commit"
    _HOOK_LINE="claude-update-state"
    if [ ! -f "$_HOOK_FILE" ]; then
        printf '#!/bin/sh\n%s\n' "$_HOOK_LINE" > "$_HOOK_FILE"
        chmod +x "$_HOOK_FILE"
        echo "✓ Created post-commit hook → $_HOOK_FILE"
    elif ! grep -q "$_HOOK_LINE" "$_HOOK_FILE" 2>/dev/null; then
        echo "$_HOOK_LINE" >> "$_HOOK_FILE"
        echo "✓ Appended claude-update-state to existing post-commit hook"
    else
        echo "  post-commit hook already contains claude-update-state — skipping"
    fi
fi

# ── Success ────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation complete!"
echo ""
echo "  Restart Claude Code to activate the status line."
echo ""
echo "  Status line preview:"
echo "  ╭─ 👾 claude-sonnet-4-x │ 🧠 42% ⚡ 78% │ ↓ 12.4k ↑ 2.1k │ 💵 \$0.23 @\$0.18/h ⌚ 1h12m │ ⏱️ 5% 🔄 14:30 ⏳ 12% 🔄 22/05 09:00"
echo "  ├─ 📁 my-project │ 🔒 main ±3/1 ⇡2⇣0 #a1b2c3 │ 🕒 45m"
echo "  ╰─ 🛠  🔌 gitnexus[✅ 14:22] │ 🕸  graphify[⚠ 21/05 23:36] │ 🏗  2/42 │ 📋✅ │ 💾 72% (-1.2k)"
echo ""
echo "  Optional: edit $_CONFIG_EXAMPLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
