#!/usr/bin/env bash
# ==============================================================================
# claude-statusline-pro — 3-line HUD status line for Claude Code
# Description : Displays AI metrics, git state, tool freshness, and token
#               savings at a glance inside the Claude Code status bar.
# Author      : Andrea Finazzi
# License     : MIT
# Repository  : https://github.com/andreafinazzi/claude-statusline-pro
# ==============================================================================

VERSION="1.0.0"

# ── Optional user config ──────────────────────────────────────────────────────
# Create ~/.config/claude-statusline/config.sh to override defaults.
# See config.example.sh for available variables.
_CSL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/claude-statusline/config.sh"
# shellcheck source=/dev/null
[ -f "$_CSL_CONFIG" ] && source "$_CSL_CONFIG"

# ── Platform detection ────────────────────────────────────────────────────────
_IS_WSL=false
{ [ -n "${WSL_DISTRO_NAME:-}" ] || { [ -f /proc/version ] && grep -qi microsoft /proc/version; }; } \
    && _IS_WSL=true

PAYLOAD=$(cat)

# ── AI Metrics ─────────────────────────────────────────────────────────────
MODEL=$(echo "$PAYLOAD" | jq -r '(.model.display_name? // .model) // "–"' 2>/dev/null)
COST=$(echo "$PAYLOAD"  | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)

CTX_PCT=$(echo "$PAYLOAD" | jq -r '
  if .context_window.used_percentage != null then (.context_window.used_percentage | round)
  elif (.context_window.context_window_size // 0) > 0 then
    ((.context_window.total_input_tokens // 0) / .context_window.context_window_size * 100 | round)
  else 0 end' 2>/dev/null)
CTX_PCT="${CTX_PCT:-0}"

LIMIT_5H=$(echo "$PAYLOAD" | jq -r '(.rate_limits.five_hour.used_percentage  // 0) | round' 2>/dev/null)
LIMIT_7D=$(echo "$PAYLOAD" | jq -r '(.rate_limits.seven_day.used_percentage   // 0) | round' 2>/dev/null)
LIMIT_5H="${LIMIT_5H:-0}"; LIMIT_7D="${LIMIT_7D:-0}"

# ── Reset timestamps ───────────────────────────────────────────────────────
RESET_5H_EPOCH=$(echo "$PAYLOAD" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
RESET_7D_EPOCH=$(echo "$PAYLOAD" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)

epoch_to_time() {
    local epoch="${1:-}" fmt="${2:-%H:%M}"
    [[ "$epoch" =~ ^[0-9]+$ ]] || { echo "–"; return; }
    [ "${#epoch}" -gt 10 ] && epoch=$((epoch / 1000))
    date -d "@$epoch" "+${fmt}" 2>/dev/null || date -r "$epoch" "+${fmt}" 2>/dev/null || echo "–"
}

epoch_to_stamp() {
    local epoch="${1:-}"
    [[ "$epoch" =~ ^[0-9]+$ ]] || { echo "–"; return; }
    [ "${#epoch}" -gt 10 ] && epoch=$((epoch / 1000))
    local today day
    today=$(date +%Y-%m-%d)
    day=$(date -d "@$epoch" "+%Y-%m-%d" 2>/dev/null || date -r "$epoch" "+%Y-%m-%d" 2>/dev/null)
    if [ "$day" = "$today" ]; then
        date -d "@$epoch" "+%H:%M" 2>/dev/null || date -r "$epoch" "+%H:%M" 2>/dev/null || echo "–"
    else
        date -d "@$epoch" "+%d/%m %H:%M" 2>/dev/null || date -r "$epoch" "+%d/%m %H:%M" 2>/dev/null || echo "–"
    fi
}

RESET_5H=$(epoch_to_time "$RESET_5H_EPOCH" '%H:%M')
RESET_7D=$(epoch_to_time "$RESET_7D_EPOCH" '%d/%m %H:%M')

# ── Tokens + Cache efficiency ──────────────────────────────────────────────
TOK_IN=$(echo  "$PAYLOAD" | jq -r '.context_window.total_input_tokens  // .tokens.input  // .usage.input_tokens  // 0' 2>/dev/null)
TOK_OUT=$(echo "$PAYLOAD" | jq -r '.context_window.total_output_tokens // .tokens.output // .usage.output_tokens // 0' 2>/dev/null)
CACHE_READ=$(echo "$PAYLOAD" | jq -r '
  (.context_window.current_usage.cache_read_input_tokens     // 0) +
  (.context_window.current_usage.cache_creation_input_tokens // 0)' 2>/dev/null)
CACHE_READ="${CACHE_READ:-0}"

if [[ "$TOK_IN" =~ ^[0-9]+$ ]] && [ "$TOK_IN" -gt 0 ]; then
    CACHE_PCT=$(awk -v cr="${CACHE_READ:-0}" -v ti="$TOK_IN" 'BEGIN{printf "%d", cr/ti*100}')
else
    CACHE_PCT=0
fi

format_k() {
    local n="${1:-0}"; [[ "$n" =~ ^[0-9]+$ ]] || n=0
    [ "$n" -ge 1000 ] && awk -v n="$n" 'BEGIN{printf "%.1fk",n/1000}' || echo "$n"
}
IN_FMT=$(format_k "$TOK_IN")
OUT_FMT=$(format_k "$TOK_OUT")
COST_FMT=$(awk "BEGIN{printf \"%.2f\",${COST:-0}}")

# ── Dir & Git ──────────────────────────────────────────────────────────────
DIR_RAW=$(echo "$PAYLOAD" | jq -r '.workspace.current_dir // ""' 2>/dev/null)
[ -z "$DIR_RAW" ] && DIR_RAW="$PWD"
GIT_ROOT=$(git --no-optional-locks -C "$DIR_RAW" rev-parse --show-toplevel 2>/dev/null)
[ -n "$GIT_ROOT" ] && DIR_RAW="$GIT_ROOT"
DIR_NAME=$(basename "$DIR_RAW")

BRANCH=$(git --no-optional-locks -C "$DIR_RAW" branch --show-current 2>/dev/null)
[ -z "$BRANCH" ] && BRANCH="no-git"
GIT_HASH=$(git --no-optional-locks -C "$DIR_RAW" rev-parse --short HEAD 2>/dev/null)

GIT_PORCELAIN=$(git --no-optional-locks -C "$DIR_RAW" status --porcelain 2>/dev/null)
if [ -z "$GIT_PORCELAIN" ]; then
    LOCK="🔓"; DIRTY_SIZE=""
else
    LOCK="🔒"
    read ADD DEL < <(git --no-optional-locks -C "$DIR_RAW" diff --numstat 2>/dev/null \
        | awk 'NF{a+=$1; d+=$2} END{print a+0, d+0}')
    [ "$ADD" -gt 0 ] || [ "$DEL" -gt 0 ] && DIRTY_SIZE="±${ADD}/${DEL}" || DIRTY_SIZE="±0/0"
fi

LAST_COMMIT_EPOCH=$(git --no-optional-locks -C "$DIR_RAW" log -1 --format='%ct' 2>/dev/null)
LAST_COMMIT_EPOCH="${LAST_COMMIT_EPOCH:-0}"
if [[ "$LAST_COMMIT_EPOCH" =~ ^[0-9]+$ ]] && [ "$LAST_COMMIT_EPOCH" -gt 0 ]; then
    _age=$(( $(date +%s) - LAST_COMMIT_EPOCH ))
    LAST_COMMIT_TIME=$(awk -v s="$_age" 'BEGIN{
        if(s<60)         printf "%ds",s
        else if(s<3600)  printf "%dm",int(s/60)
        else if(s<86400) printf "%dh",int(s/3600)
        else             printf "%dd",int(s/86400) }')
else
    LAST_COMMIT_TIME="–"
fi

# ── Git ahead/behind remote ────────────────────────────────────────────────
AB=$(git --no-optional-locks -C "$DIR_RAW" rev-list --count --left-right \
     '@{upstream}...HEAD' 2>/dev/null)
if [ -n "$AB" ]; then
    BEHIND=$(echo "$AB" | awk '{print $1}')
    AHEAD=$(echo  "$AB" | awk '{print $2}')
    AHEAD_BEHIND="⇡${AHEAD}⇣${BEHIND}"
else
    AHEAD_BEHIND=""
fi

# ── Session duration ───────────────────────────────────────────────────────
SESSION_MS=$(echo "$PAYLOAD" | jq -r '.cost.total_duration_ms // empty' 2>/dev/null)
SESSION_DUR=""
if [[ "$SESSION_MS" =~ ^[0-9]+$ ]] && [ "$SESSION_MS" -gt 0 ]; then
    SESSION_DUR=$(awk -v ms="$SESSION_MS" 'BEGIN{
        s=int(ms/1000); m=int(s/60); h=int(m/60); m=m%60
        if(h>0) printf "%dh%dm",h,m; else printf "%dm",m }')
else
    # Fallback: scan recent session JSON files, match by cwd
    _sessions_dir="$HOME/.claude/sessions"
    while IFS= read -r _sf; do
        _cwd=$(jq -r '.cwd // empty' "$_sf" 2>/dev/null)
        [ "$_cwd" = "$DIR_RAW" ] || continue
        _start=$(jq -r '.startedAt // 0' "$_sf" 2>/dev/null)
        [[ "$_start" =~ ^[0-9]+$ ]] && [ "$_start" -gt 0 ] || continue
        _start_s=$(( _start / 1000 ))
        _elapsed=$(( $(date +%s) - _start_s ))
        SESSION_DUR=$(awk -v s="$_elapsed" 'BEGIN{
            m=int(s/60); h=int(m/60); m=m%60
            if(h>0) printf "%dh%dm",h,m; else printf "%dm",m }')
        break
    done < <(find "$_sessions_dir" -maxdepth 1 -name "*.json" 2>/dev/null | head -5)
fi

COST_RATE=""
if [[ "$SESSION_MS" =~ ^[0-9]+$ ]] && [ "$SESSION_MS" -gt 0 ]; then
    COST_RATE=$(awk -v cost="${COST:-0}" -v ms="$SESSION_MS" \
        'BEGIN{ h=ms/3600000; if(h>0.01) printf "%.2f/h", cost/h }')
fi

# ── Skill count (SKILL.md = canonical skill definitions) ──────────────────
SKILLS_GLOBAL=$(find "$HOME/.claude/skills" -type f -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
SKILLS_LOCAL=$(( \
    $(find "${DIR_RAW}/.claude/skills"  -type f -name "SKILL.md" 2>/dev/null | wc -l) + \
    $(find "${DIR_RAW}/.agents/skills"  -type f -name "SKILL.md" 2>/dev/null | wc -l) \
))
SKILLS_FMT="${SKILLS_LOCAL}/${SKILLS_GLOBAL}"

# ── RTK savings (silent if RTK not installed) ──────────────────────────────
RTK_FMT=""
RTK_DB="${RTK_DB_PATH:-}"
if [ -z "$RTK_DB" ]; then
    for _p in \
        "$HOME/.local/share/rtk/rtk.db" \
        "$HOME/.config/rtk/rtk.db"; do
        [ -f "$_p" ] && { RTK_DB="$_p"; break; }
    done
fi
# WSL: also probe Windows AppData path
if [ -z "$RTK_DB" ] && $_IS_WSL; then
    _win_appdata=$(cmd.exe /c 'echo %APPDATA%' 2>/dev/null | tr -d '\r\n')
    if [ -n "$_win_appdata" ]; then
        _win_rtk=$(wslpath "$_win_appdata" 2>/dev/null)/rtk/rtk.db
        [ -f "${_win_rtk:-}" ] && RTK_DB="$_win_rtk"
    fi
fi
if [ -n "$RTK_DB" ]; then
    read _orig _filt _label < <(python3 -c "
import sqlite3
try:
    db = sqlite3.connect('$RTK_DB')
    r = db.execute(\"SELECT SUM(original_tokens), SUM(filtered_tokens) FROM tracking WHERE date(timestamp) = date('now')\").fetchone()
    if r[0]:
        print(int(r[0]), int(r[1] or 0), 'today')
    else:
        r2 = db.execute(\"SELECT SUM(original_tokens), SUM(filtered_tokens), date(timestamp) FROM tracking GROUP BY date(timestamp) ORDER BY date(timestamp) DESC LIMIT 1\").fetchone()
        if r2 and r2[0]: print(int(r2[0]), int(r2[1] or 0), r2[2])
        else: print(0, 0, '')
except: print(0, 0, '')
" 2>/dev/null)
    if [ "${_orig:-0}" -gt 0 ]; then
        _pct=$(awk -v o="$_orig" -v f="$_filt" 'BEGIN{printf "%d",(o-f)/o*100}')
        _saved=$(( _orig - _filt ))
        _saved_fmt=$(awk -v s="$_saved" 'BEGIN{ if(s>=1000) printf "%.1fk",s/1000; else printf "%d",s }')
        [ "$_label" = "today" ] \
            && RTK_FMT="💾 ${_pct}% (-${_saved_fmt})" \
            || RTK_FMT="💾 ${_pct}% (-${_saved_fmt}) (${_label})"
    fi
fi

# ── STATE.md freshness (📋✅ fresh | 📋⚠ stale | 📋∅ template/missing) ────
STATE_FMT="📋∅"
_STATE_FILE="${CSL_STATE_FILE:-${DIR_RAW}/STATE.md}"
if [ -f "$_STATE_FILE" ]; then
    if grep -qE '\{data ISO\}|\{repo attivo\}' "$_STATE_FILE" 2>/dev/null; then
        STATE_FMT="📋∅"
    else
        _state_mtime=$(stat -c %Y "$_STATE_FILE" 2>/dev/null || stat -f %m "$_STATE_FILE" 2>/dev/null || echo 0)
        _git_mtime=$(git -C "$DIR_RAW" log -1 --format='%ct' 2>/dev/null || echo 0)
        if [ "${_state_mtime:-0}" -ge "${_git_mtime:-0}" ]; then
            STATE_FMT="📋✅"
        else
            STATE_FMT="📋⚠"
        fi
    fi
fi

# ── Tool alignment: GitNexus ───────────────────────────────────────────────
PROJECT_SETTINGS="${DIR_RAW}/.claude/settings.json"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"
CURSOR_MCP="$HOME/.cursor/mcp.json"

GN_CONFIGURED=false
for _cfg in "$PROJECT_SETTINGS" "$GLOBAL_SETTINGS" "$CURSOR_MCP"; do
    jq -r '.mcpServers | keys | join(",")' "$_cfg" 2>/dev/null \
        | grep -qi "gitnexus" && { GN_CONFIGURED=true; break; }
done

GN_DB=$(find "$DIR_RAW" -maxdepth 2 \( -name ".gitnexus.db" -o -name "gitnexus.db" \) \
         2>/dev/null | head -1)
[ -z "$GN_DB" ] && [ -f "${DIR_RAW}/.gitnexus/lbug" ] && GN_DB="${DIR_RAW}/.gitnexus/lbug"
[ -z "$GN_DB" ] && \
    GN_DB=$(find "$HOME/.local/share/gitnexus" -name "*.db" 2>/dev/null | head -1)

if [ -n "$GN_DB" ]; then
    GN_EPOCH=$(stat -c %Y "$GN_DB" 2>/dev/null || stat -f %m "$GN_DB" 2>/dev/null)
    if [[ "$GN_EPOCH" =~ ^[0-9]+$ ]] && [ "$GN_EPOCH" -ge "$LAST_COMMIT_EPOCH" ]; then
        GN_STAMP="✅  $(epoch_to_stamp "$GN_EPOCH")"
    else
        GN_STAMP="⚠  $(epoch_to_stamp "$GN_EPOCH")"
    fi
elif $GN_CONFIGURED; then
    GN_STAMP="⚙️cfg"
else
    GN_STAMP="❌"
fi

# ── Tool alignment: Graphify ───────────────────────────────────────────────
GRAPH_FILE=$(find "$DIR_RAW" -maxdepth 2 \
    \( -name "GRAPH_REPORT.md" -o -name ".graphify" \) 2>/dev/null | head -1)
if [ -n "$GRAPH_FILE" ]; then
    GR_EPOCH=$(stat -c %Y "$GRAPH_FILE" 2>/dev/null || stat -f %m "$GRAPH_FILE" 2>/dev/null)
    if [[ "$GR_EPOCH" =~ ^[0-9]+$ ]] && [ "$GR_EPOCH" -ge "$LAST_COMMIT_EPOCH" ]; then
        GRAPH_STAMP="✅  $(epoch_to_stamp "$GR_EPOCH")"
    else
        GRAPH_STAMP="⚠  $(epoch_to_stamp "$GR_EPOCH")"
    fi
else
    GRAPH_STAMP="❌"
fi

# ── Dynamic project tools (config-driven via CSL_DYNAMIC_PROJECTS) ─────────
# Define in config.sh: CSL_DYNAMIC_PROJECTS=("dirname:url:label" ...)
DYNAMIC_TOOLS=""
if declare -p CSL_DYNAMIC_PROJECTS &>/dev/null; then
    for _entry in "${CSL_DYNAMIC_PROJECTS[@]}"; do
        IFS=: read -r _dname _url _label <<< "$_entry"
        [ "$DIR_NAME" = "$_dname" ] || continue
        if curl -s -m 0.5 "$_url" 2>/dev/null | grep -q .; then
            DYNAMIC_TOOLS="🟢 ${_label}"
        else
            DYNAMIC_TOOLS="🔴 ${_label}"
        fi
        break
    done
fi

# ── Colors ─────────────────────────────────────────────────────────────────
R="\033[0m"; BOLD="\033[1m"
PUR="\033[0;35m"; CYA="\033[0;36m"; GRN="\033[0;32m"
WHT="\033[1;37m"; BYEL="\033[1;33m"; BCYA="\033[1;36m"; BGRN="\033[1;32m"

case "$GN_STAMP"    in ✅*) GN_COLOR="$BGRN" ;; ⚠*) GN_COLOR="$BYEL" ;; *) GN_COLOR="$BCYA" ;; esac
case "$GRAPH_STAMP" in ✅*) GR_COLOR="$BGRN" ;; ⚠*) GR_COLOR="$BYEL" ;; *) GR_COLOR="$BCYA" ;; esac

if   [ "$CTX_PCT" -le 50 ]; then CTX_COLOR="\033[1;32m"
elif [ "$CTX_PCT" -le 80 ]; then CTX_COLOR="\033[1;33m"
else                              CTX_COLOR="\033[1;31m"
fi

# ── 3-line HUD ─────────────────────────────────────────────────────────────
echo -e "${BOLD}╭─${R} ${PUR}👾 ${MODEL}${R} │ ${CTX_COLOR}🧠 ${CTX_PCT}% ⚡ ${CACHE_PCT}%${R} │ ${CYA}↓ ${IN_FMT} ↑ ${OUT_FMT}${R} │ ${BYEL}💵 \$${COST_FMT}${COST_RATE:+ @\$${COST_RATE}}${SESSION_DUR:+ ⌚ ${SESSION_DUR}}${R} │ ${WHT}⏱️ ${LIMIT_5H}% 🔄 ${RESET_5H} ⏳ ${LIMIT_7D}% 🔄 ${RESET_7D}${R}"
echo -e "${BOLD}├─${R} ${BCYA}📁 ${DIR_NAME}${R} │ ${LOCK} ${GRN}${BRANCH}${R}${DIRTY_SIZE:+ ${BYEL}${DIRTY_SIZE}${R}}${AHEAD_BEHIND:+ ${AHEAD_BEHIND}}${GIT_HASH:+ ${WHT}#${GIT_HASH}${R}} │ ${WHT}🕒 ${LAST_COMMIT_TIME}${R}"
echo -e "${BOLD}╰─${R} 🛠  ${GN_COLOR}🔌 gitnexus[${GN_STAMP}]${R} │ ${GR_COLOR}🕸  graphify[${GRAPH_STAMP}]${R} │ 🏗  ${SKILLS_FMT} │ ${STATE_FMT}${RTK_FMT:+ │ ${RTK_FMT}}${DYNAMIC_TOOLS:+ │ ${DYNAMIC_TOOLS}}"
