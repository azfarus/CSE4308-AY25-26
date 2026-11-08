#!/usr/bin/env bash
# lab_cleanup.sh - safely cleans the 'cse' user's home directory.
# Deletes common user files, but preserves configuration (dotfiles).

set -o errexit
set -o pipefail

LOGFILE="lab_cleanup.log"
exec > >(tee -a "$LOGFILE") 2>&1

timestamp() { date '+%F %T'; }
log() { echo "[$(timestamp)] $*"; }

# -------- Configurable parameters --------
CONCURRENCY="${1:-30}"
DISCOVER_FILE="${2:-discovered_ips.txt}"
SSH_USER="${3:-admin}"
SSH_PASS="${4:-1ut01ccs3}"
SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
STUDENT_USER="cse" # The user to clean

log "===== Starting lab_cleanup.sh for user: $STUDENT_USER ====="
log "Concurrency: $CONCURRENCY"
log "Discovery file: $DISCOVER_FILE"

# -------- Ensure sshpass is installed --------
if ! command -v sshpass >/dev/null 2>&1; then
    log "sshpass not found. Please install it."
    exit 1
fi
log "sshpass detected."

# -------- Ensure discovery file exists --------
if [[ ! -s "$DISCOVER_FILE" ]]; then
    log "No active hosts found in $DISCOVER_FILE. Exiting."
    exit 0
fi

log "Found $(wc -l < "$DISCOVER_FILE") hosts to clean."

# -------- Prepare remote script payload (FIXED v3) --------
tmp_remote_script="$(mktemp)"
trap 'rm -f "$tmp_remote_script" lab_cleanup_status.tmp' EXIT

escaped_pass=$(printf '%s' "$SSH_PASS" | sed "s/'/'\\\\''/g")

# This 'cat' block creates the script that will run on the remote machine.
cat > "$tmp_remote_script" <<EOF
#!/usr/bin/env bash
set -e

SUDO_PASS='${escaped_pass}'
USERNAME='${STUDENT_USER}'
HOME_DIR="/home/\$USERNAME"

# We do NOT use 'export'.
# We will pass \$HOME_DIR and \$USERNAME as arguments to the sudo bash shell.

# Run all privileged operations
echo "\$SUDO_PASS" | sudo -S bash -c '
    set -e # Stop this sub-shell if anything fails
    
    # Read variables passed in as arguments
    # \$0 is "bash", \$1 is the first arg, \$2 is the second
    HOME_DIR_SUDO="\$1"
    USERNAME_SUDO="\$2"

    # Check if variables are empty (safety check)
    if [ -z "\$HOME_DIR_SUDO" ] || [ -z "\$USERNAME_SUDO" ]; then
        echo "ERROR: Received empty variables inside sudo."
        exit 1
    fi
    
    echo "==> Cleaning \$HOME_DIR_SUDO for user \$USERNAME_SUDO..."

    # 1. Delete all NON-HIDDEN files from the root of home
    find "\$HOME_DIR_SUDO" -maxdepth 1 -type f -delete

    # 2. Empty all standard XDG user directories
    xdg_dirs=( "Desktop" "Documents" "Downloads" "Music" "Pictures" "Public" "Templates" "Videos" )
    for dir in "\${xdg_dirs[@]}"; do
        if [ -d "\$HOME_DIR_SUDO/\$dir" ]; then
            echo "Cleaning \$HOME_DIR_SUDO/\$dir..."
            find "\$HOME_DIR_SUDO/\$dir" -mindepth 1 -delete
        fi
    done

    # 3. Clean all caches (very safe to do)
    if [ -d "\$HOME_DIR_SUDO/.cache" ]; then
        echo "Cleaning cache..."
        find "\$HOME_DIR_SUDO/.cache" -mindepth 1 -delete
    fi

    # 4. Clean trash
    if [ -d "\$HOME_DIR_SUDO/.local/share/Trash" ]; then
        echo "Emptying trash..."
        find "\$HOME_DIR_SUDO/.local/share/Trash" -mindepth 1 -delete
    fi
    
    echo "==> Cleanup complete for \$USERNAME_SUDO."
' bash "\$HOME_DIR" "\$USERNAME" # <-- THIS IS THE FIX
EOF

chmod +x "$tmp_remote_script"

# -------- Prepare parallel execution --------
# (This part is unchanged and correct)
rm -f lab_cleanup_status.tmp
touch lab_cleanup_status.tmp

run_for_target() {
    local target="$1"
    timestamp() { date "+%F %T"; }

    if ! timeout 4 bash -c ">/dev/tcp/${target}/22" 2>/dev/null; then
        echo "UNREACHABLE $target" >> lab_cleanup_status.tmp
        echo "[$(timestamp)] UNREACHABLE: $target (port 22 closed)"
        return
    fi

    sshpass -p "$SSH_PASS" ssh $SSH_OPTS "${SSH_USER}@${target}" "bash -s" < "$tmp_remote_script" \
        && echo "SUCCESS $target" >> lab_cleanup_status.tmp \
        || { echo "FAIL $target" >> lab_cleanup_status.tmp; echo "[$(timestamp)] FAIL: $target"; }
}

export -f run_for_target
export SSH_USER SSH_PASS SSH_OPTS tmp_remote_script STUDENT_USER

# -------- Run in parallel --------
# (This part is unchanged and correct)
log "Starting parallel cleanup..."
xargs -a "$DISCOVER_FILE" -n1 -P "$CONCURRENCY" -I{} bash -c 'run_for_target "$@"' _ {}

# -------- Summarize results --------
# (This part is unchanged and correct)
SUCCESS_COUNT=0
FAIL_COUNT=0
UNREACHABLE_COUNT=0

while read -r line; do
    case "$line" in
        SUCCESS*) ((SUCCESS_COUNT++)) ;;
        FAIL*) ((FAIL_COUNT++)) ;;
        UNREACHABLE*) ((UNREACHABLE_COUNT++)) ;;
    esac
done < lab_cleanup_status.tmp


log "----- Summary -----"
log "SUCCESS: $SUCCESS_COUNT"
log "FAIL: $FAIL_COUNT"
log "UNREACHABLE: $UNREACHABLE_COUNT"
log "Full log: $LOGFILE"
log "===== lab_cleanup.sh completed ====="