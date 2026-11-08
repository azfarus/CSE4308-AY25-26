#!/usr/bin/env bash
# lab_postgres_fix.sh - Updates pg_hba.conf and resets cse DB password.

set -o errexit
set -o pipefail

LOGFILE="lab_postgres_fix.log"
exec > >(tee -a "$LOGFILE") 2>&1

timestamp() { date '+%F %T'; }
log() { echo "[$(timestamp)] $*"; }

# -------- Configurable parameters --------
CONCURRENCY="${1:-30}"
DISCOVER_FILE="${2:-discovered_ips.txt}"
SSH_USER="${3:-admin}"
SSH_PASS="${4:-1ut01ccs3}"
SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

log "===== Starting PostgreSQL update for lab ====="
log "Concurrency: $CONCURRENCY"
log "Discovery file: $DISCOVER_FILE"

# -------- Ensure sshpass is installed --------
if ! command -v sshpass >/dev/null 2>&1; then
    log "sshpass not found. Please install it."
    exit 1
fi

# -------- Ensure discovery file exists --------
if [[ ! -s "$DISCOVER_FILE" ]]; then
    log "No active hosts found in $DISCOVER_FILE. Exiting."
    exit 0
fi

log "Found $(wc -l < "$DISCOVER_FILE") hosts to update."

# -------- Prepare remote script payload (FIXED QUOTING) --------
tmp_remote_script="$(mktemp)"
trap 'rm -f "$tmp_remote_script" lab_cleanup_status.tmp' EXIT

escaped_pass=$(printf '%s' "$SSH_PASS" | sed "s/'/'\\\\''/g")

# We write a script that creates ANOTHER script on the remote machine.
# This avoids the "bash -c '...'" quoting complexity.
cat > "$tmp_remote_script" <<EOF
#!/usr/bin/env bash
set -e

# 1. Write the ROOT logic to a temporary file on the remote machine
cat > /tmp/lab_root_fix.sh <<'ROOT_EOF'
#!/bin/bash
set -e
TARGET_FILE="/etc/postgresql/14/main/pg_hba.conf"

# --- PART 1: Modify pg_hba.conf ---
if [ -f "\$TARGET_FILE" ]; then
    if grep -qE "^local[[:space:]]+all[[:space:]]+all[[:space:]]+peer" "\$TARGET_FILE"; then
        echo "MODIFY: Found peer auth. Switching to md5..."
        cp "\$TARGET_FILE" "\$TARGET_FILE.bak"
        sed -i -E "s/^local[[:space:]]+all[[:space:]]+all[[:space:]]+peer/local   all             all                                     md5/" "\$TARGET_FILE"
        
        if systemctl is-active --quiet postgresql; then
            echo "RELOAD: Reloading PostgreSQL service..."
            systemctl reload postgresql
            sleep 2
        fi
        echo "CONFIG: Updated to md5."
    else
        echo "CONFIG: Already md5 or peer line not found."
    fi
else
    echo "SKIP: \$TARGET_FILE not found."
fi

# --- PART 2: Update SQL Password ---
if systemctl is-active --quiet postgresql; then
    echo "SQL: Updating password for role cse..."
    # Because this file runs as root, we sudo DOWN to postgres user
    if sudo -u postgres psql -c "ALTER ROLE cse WITH PASSWORD '123';" 2>&1; then
         echo "SUCCESS: SQL password updated."
    else
         echo "FAIL: SQL command failed."
         exit 1
    fi
else
    echo "FAIL: PostgreSQL not running. Cannot update SQL password."
    exit 1
fi
ROOT_EOF

# 2. Make the root script executable
chmod +x /tmp/lab_root_fix.sh

# 3. Run the root script using sudo (reading pass from echo)
echo '${escaped_pass}' | sudo -S /tmp/lab_root_fix.sh

# 4. Cleanup
rm -f /tmp/lab_root_fix.sh
EOF

chmod +x "$tmp_remote_script"

# -------- Prepare parallel execution --------
rm -f lab_cleanup_status.tmp
touch lab_cleanup_status.tmp

run_for_target() {
    local target="$1"
    timestamp() { date "+%F %T"; }

    if ! timeout 4 bash -c ">/dev/tcp/${target}/22" 2>/dev/null; then
        echo "UNREACHABLE $target" >> lab_cleanup_status.tmp
        echo "[$(timestamp)] UNREACHABLE: $target"
        return
    fi

    sshpass -p "$SSH_PASS" ssh $SSH_OPTS "${SSH_USER}@${target}" "bash -s" < "$tmp_remote_script" \
        && echo "SUCCESS $target" >> lab_cleanup_status.tmp \
        || { echo "FAIL $target" >> lab_cleanup_status.tmp; echo "[$(timestamp)] FAIL: $target"; }
}

export -f run_for_target
export SSH_USER SSH_PASS SSH_OPTS tmp_remote_script

# -------- Run in parallel --------
log "Starting parallel execution..."
xargs -a "$DISCOVER_FILE" -n1 -P "$CONCURRENCY" -I{} bash -c 'run_for_target "$@"' _ {}

# -------- Summarize results --------
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
log "===== Update completed ====="