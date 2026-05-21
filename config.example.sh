# claude-statusline-pro — user configuration
# Copy to: ~/.config/claude-statusline/config.sh
# This file is sourced by statusline.sh at runtime. Never commit it.

# ── STATE.md location ─────────────────────────────────────────────────────
# Defaults to STATE.md in the git root of the current project.
# Override here if you keep STATE.md in a fixed location.
# CSL_STATE_FILE="$HOME/dev/my-project/STATE.md"

# ── Dynamic project health checks ─────────────────────────────────────────
# Format: "dirname:health-check-url:label"
# The script checks the URL when the current project folder matches dirname.
# Displayed as 🟢 label (up) or 🔴 label (down) in the 3rd HUD line.
#
# Example:
# CSL_DYNAMIC_PROJECTS=(
#     "my-api:http://localhost:8080/health:api"
#     "frontend:http://localhost:3000:fe"
#     "docs-site:http://localhost:4000:docs"
# )
CSL_DYNAMIC_PROJECTS=()

# ── RTK DB override ───────────────────────────────────────────────────────
# Set if RTK writes its DB to a non-standard location.
# RTK_DB_PATH="$HOME/.local/share/rtk/rtk.db"
