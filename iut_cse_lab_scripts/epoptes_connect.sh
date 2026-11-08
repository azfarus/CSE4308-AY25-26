#!/usr/bin/env bash
# epoptes_connect.sh - fully autonomous epoptes-client configuration on lab PCs
# Assumes all remote hosts use password authentication.

set -o errexit
set -o pipefail

LOGFILE="epoptes_connect.log"
exec > >(tee -a "$LOGFILE") 2>&1

timestamp() { date '+%F %T'; }
log() { echo "[$(timestamp)] $*"; }

# -------- Configurable parameters --------
CONCURRENCY="${1:-30}"                 # Number of parallel SSH sessions
DISCOVER_FILE="${2:-discovered_ips.txt}" 
SSH_USER="${3:-admin}"                 
SSH_PASS="${4:-1ut01ccs3}"             
SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

log "===== Starting epoptes_connect.sh ====="
log "Concurrency: $CONCURRENCY"
log "Discovery file: $DISCOVER_FILE"
log "SSH user: $SSH_USER"

# -------- Ensure sshpass is installed on teacher PC --------
if ! command -v sshpass >/dev/null 2>&1; then
    log "sshpass not found. Installing automatically..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y sshpass
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y sshpass
    else
        log "ERROR: Could not detect package manager. Install sshpass manually."
        exit 1
    fi
    log "sshpass installed successfully."
else
    log "sshpass detected."
fi

# -------- NEW: Ensure current user is in 'epoptes' group --------
log "Checking if user $USER is in 'epoptes' group..."
if ! id -Gn "$USER" | grep -q '\bepoptes\b'; then
    log "User $USER not in 'epoptes' group. Adding with sudo..."
    if sudo usermod -aG epoptes "$USER"; then
        log "Successfully added $USER to 'epoptes' group."
        log "IMPORTANT: You MUST log out and log back in for this group change to take full effect."
    else
        log "ERROR: Failed to add $USER to 'epoptes' group. Please do it manually."
    fi
else
    log "User $USER is already in 'epoptes' group."
fi
# -------- END NEW SECTION --------

# -------- Determine teacher PC IP --------
TEACHER_IP="$(ip -4 -o addr show dev ppp0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 || true)"
if [[ -z "$TEACHE_IP" ]]; then
    TEACHER_IP="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || true)"
fi

if [[ -z "$TEACHER_IP" ]]; then
    log "ERROR: Cannot determine teacher PC IP. Exiting."
    exit 1
fi

log "Teacher PC IP (to be used as SERVER): $TEACHER_IP"

# -------- Run IP discovery --------
if [[ ! -x "./ip_discover.sh" ]]; then
    chmod +x ./ip_discover.sh
fi

log "Running IP discovery..."
./ip_discover.sh "$DISCOVER_FILE"

if [[ ! -s "$DISCOVER_FILE" ]]; then
    log "No active hosts discovered. Exiting."
    exit 0
fi

log "Discovered $(wc -l < "$DISCOVER_FILE") active hosts."

# -------- Prepare remote script --------
log "Preparing remote script payload (v5, 'ps' command)..."
tmp_remote_script="$(mktemp)"
trap 'rm -f "$tmp_remote_script" epoptes_connect_status.tmp' EXIT

# This 'cat' block creates the script that will run on the remote machine.
cat > "$tmp_remote_script" <<EOF
#!/usr/bin/env bash
set -e

# These variables are passed from the main script
SUDO_PASS='${escaped_pass}'
TEACHER_IP='${TEACHER_IP}'

# Backup existing configuration
if [ -f /etc/default/epoptes-client ]; then
    cp -a /etc/default/epoptes-client /tmp/epoptes-client.backup.\$(date +%s)
fi

# Run all privileged operations in a single 'sudo -S' block
echo "\$SUDO_PASS" | sudo -S bash -c '

    set -e # Stop this sub-shell if anything fails
    
    # 1. Update SERVER line
    echo "==> Configuring server IP..."
    if grep -q -E "^#?SERVER=" /etc/default/epoptes-client; then
        sed -i -E "s/^#?SERVER=.*/SERVER=$TEACHER_IP/" /etc/default/epoptes-client
    else
        echo "SERVER=$TEACHER_IP" >> /etc/default/epoptes-client
    fi

    # 2. Run epoptes-client -c to fetch certificate (with 5s timeout)
    echo "==> Fetching certificate (5s timeout)..."
    timeout 5 epoptes-client -c || echo "WARN: epoptes-client -c timed out. This is OK, but check server firewall on port 789."

    # 3. Create autostart file for future reboots
    echo "==> Creating autostart file..."
    tee /etc/xdg/autostart/epoptes-client.desktop > /dev/null << EOT
[Desktop Entry]
Name=Epoptes Client
Exec=epoptes-client
Type=Application
Terminal=false
EOT

    # 4. Start client NOW without rebooting (v5 - Robust "ps" method)
    echo "==> Attempting to start client in active session for user cse..."
    
    # Per your instruction, the username is ALWAYS 'cse'
    USERNAME="cse"
    
    # Get the UID, which we need for the DBUS path
    USER_UID=\$(id -u "\$USERNAME")
    
    # Find the DISPLAY variable by querying the environment of
    # all processes running as $USERNAME. This is the most reliable method.
    DISPLAY=\$(ps e -u "\$USERNAME" | grep -Eo "DISPLAY=:[0-9.]+" | head -n1 | cut -d= -f2)

    if [ -n "\$DISPLAY" ]; then
        echo "Found active graphical user: \$USERNAME on display \$DISPLAY (UID: \$USER_UID)"
        
        # Check that all variables were parsed correctly
        if [ -n "\$USER_UID" ]; then
            
            echo "Killing any old clients for user \$USERNAME..."
            pkill -u "\$USERNAME" -f epoptes-client || true
            sleep 1 # Give pkill a moment
            
            echo "Launching new client for \$USERNAME..."
            sudo -u "\$USERNAME" \
                 DISPLAY="\$DISPLAY" \
                 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/\$USER_UID/bus" \
                 epoptes-client & disown
            
            echo "Client launched for user \$USERNAME."
        else
            echo "ERROR: Could not find UID for user \$USERNAME. User may not exist."
        fi
    else
        echo "No active graphical session found via 'ps' for user \$USERNAME. Client will start on next login."
    fi
'
EOF

chmod +x "$tmp_remote_script"

# -------- Prepare parallel execution --------
rm -f epoptes_connect_status.tmp
touch epoptes_connect_status.tmp

run_for_target() {
    local target="$1"
    timestamp() { date "+%F %T"; }

    # Quick check if port 22 is open
    if ! timeout 4 bash -c ">/dev/tcp/${target}/22" 2>/dev/null; then
        echo "UNREACHABLE $target" >> epoptes_connect_status.tmp
        echo "[$(timestamp)] UNREACHABLE: $target (port 22 closed)"
        return
    fi

    echo "[$(timestamp)] SSH reachable: $target"

    # Attempt SSH using sshpass
    sshpass -p "$SSH_PASS" ssh $SSH_OPTS "${SSH_USER}@${target}" "bash -s" < "$tmp_remote_script" \
        && echo "SUCCESS $target" >> epoptes_connect_status.tmp \
        || { echo "FAIL $target" >> epoptes_connect_status.tmp; echo "[$(timestamp)] FAIL: $target"; }
}

export -f run_for_target
export SSH_USER SSH_PASS SSH_OPTS tmp_remote_script

# -------- Run in parallel --------
log "Starting parallel SSH configuration..."
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
done < epoptes_connect_status.tmp

log "----- Summary -----"
log "SUCCESS: $SUCCESS_COUNT"
log "FAIL: $FAIL_COUNT"
log "UNREACHABLE: $UNREACHABLE_COUNT"
log "Full log: $LOGFILE"
log "===== epoptes_connect.sh completed ====="

# -------- NEW: Launch Epoptes GUI --------
log "Attempting to launch Epoptes application..."
# We check group membership again. If the user was *just* added,
# this check will fail, and we will (correctly) not launch the app.
if id -Gn "$USER" | grep -q '\bepoptes\b'; then
    # Launch in background and detach, sending output to /dev/null
    epoptes >/dev/null 2>&1 &
    log "Epoptes launched in the background. It may take a few seconds to appear."
else
    log "WARNING: User $USER is not currently a member of the 'epoptes' group."
    log "The Epoptes application will not be started."
    log "Please log out and log back in, then run 'epoptes' manually."
fi
# -------- END NEW SECTION --------
