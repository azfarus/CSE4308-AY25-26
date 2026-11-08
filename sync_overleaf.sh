#!/usr/bin/env bash
#
# sync_overleaf.sh — pull the Overleaf project into this folder (one-way: Overleaf -> local).
#
# Overleaf is the source of truth: edit there. Local copies of synced files are
# overwritten by the Overleaf version on every run.
#
# Usage:
#   ./sync_overleaf.sh           download changed files from Overleaf
#
# Runs automatically every 10 minutes via the systemd user timer
# "overleaf-sync.timer" (see: systemctl --user status overleaf-sync.timer).
#
# One-time setup (log in, opens a browser window):
#   ols login --auth-file ~/.config/overleaf-sync/olauth
#
# Local-only files (build/, every lab's pdf/ folder, these scripts) are never deleted.
# Uses the unofficial "overleaf-sync" tool (installed with: uv tool install overleaf-sync).

set -euo pipefail

# ---------------------------------------------------------------- settings

PROJECT_NAME="[Lab Materials]CSE4308 DBMS Lab"                             # exact Overleaf project name
AUTH_FILE="$HOME/.config/overleaf-sync/olauth"        # saved login, keep it private
OLS="$HOME/.local/bin/ols"

# ---------------------------------------------------------------- main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$PROJECT_NAME" == "CHANGE_ME" ]]; then
    echo "Error: set PROJECT_NAME at the top of $0" >&2
    exit 1
fi

if [[ ! -f "$AUTH_FILE" ]]; then
    echo "Error: not logged in. Run: ols login --auth-file $AUTH_FILE" >&2
    exit 1
fi

# Only one sync at a time (the timer may fire while a manual sync is running).
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/overleaf-sync.lock"
if ! flock -n 9; then
    echo "Another sync is already running, skipping."
    exit 0
fi

echo "$(date '+%F %T')  Syncing Overleaf project \"$PROJECT_NAME\" -> $SCRIPT_DIR"

# ols may ask two kinds of questions; the answers are fed in automatically:
#   "Overwrite it with the version from [remote]? [y/N]"  -> y  (Overleaf wins)
#   "[d]elete, [r]estore or [i]gnore?"                    -> i  (never delete local files)
# ols re-asks after an invalid answer, so an endless "y, i, y, i, ..." stream
# gives every question its right answer within two lines.
answers() { while true; do echo y; echo i; done; }

"$OLS" --remote-only \
       --name "$PROJECT_NAME" \
       --path "$SCRIPT_DIR" \
       --auth-file "$AUTH_FILE" \
       < <(answers)

echo "$(date '+%F %T')  Done"
