#!/usr/bin/env bash
# update-state.sh — updates structural fields in STATE.md
# Cross-platform (Linux + macOS). Safe to run multiple times (idempotent).
# Leaves narrative sections (Decisions, Open items, Next action) untouched.

REPO=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO" ] && REPO="$(cd "$(dirname "$0")/.." && pwd)"

STATE_FILE="${CSL_STATE_FILE:-${REPO}/STATE.md}"
[ -f "$STATE_FILE" ] || exit 0

DATE_NOW=$(date '+%Y-%m-%d %H:%M')
REPO_NAME=$(basename "$REPO")
BRANCH=$(git -C "$REPO" branch --show-current 2>/dev/null || echo "no-git")

PORCELAIN=$(git -C "$REPO" status --porcelain 2>/dev/null)
if [ -z "$PORCELAIN" ]; then
    DIRTY="no"
else
    COUNT=$(echo "$PORCELAIN" | wc -l | tr -d ' ')
    FILES=$(echo "$PORCELAIN" | awk '{print $2}' | head -3 | paste -sd ',' -)
    DIRTY="yes — ${COUNT} file(s) (${FILES})"
fi

# Use tempfile to avoid sed -i portability issues (GNU vs BSD/macOS)
_tmp=$(mktemp)
sed \
    -e "s|^## SESSION STATE — .*|## SESSION STATE — ${DATE_NOW}|" \
    -e "s|^- repo: .*|- repo: ${REPO_NAME}|" \
    -e "s|^- branch: .*|- branch: ${BRANCH}|" \
    -e "s|^- dirty: .*|- dirty: ${DIRTY}|" \
    "$STATE_FILE" > "$_tmp" && mv "$_tmp" "$STATE_FILE"
