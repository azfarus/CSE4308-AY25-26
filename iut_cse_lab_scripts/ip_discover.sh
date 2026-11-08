#!/usr/bin/env bash
# ip_discover.sh
# Discover active IPs across relevant local subnets.
# Writes active IPs (one per line) to ./discovered_ips.txt (or file given as first arg)
# Skips .0 .1 .255 addresses to avoid gateways/broadcasts.

set -o errexit
set -o pipefail

OUTFILE="${1:-discovered_ips.txt}"
CONCURRENCY=$(( $(nproc 2>/dev/null || echo 1) * 6 ))
PING_TIMEOUT=${PING_TIMEOUT:-1}
PING_COUNT=${PING_COUNT:-1}

timestamp() { date '+%F %T'; }
log() { echo "[$(timestamp)] $*"; }

first3() { IFS='.' read -r a b c d <<< "$1"; echo "${a}.${b}.${c}"; }

log "Starting IP discovery..."

# 1) local global IPv4s
mapfile -t local_addrs < <(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 || true)

if [[ ${#local_addrs[@]} -eq 0 ]]; then
  log "WARN: no scope global IPv4 addresses found."
fi

# 2) collect subnets (deduplicated)
declare -A subnets

# from local addresses (if private)
for ip in "${local_addrs[@]}"; do
  if [[ "$ip" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
    base=$(first3 "$ip")
    subnets["$base"]=1
    log "Local IP $ip -> adding inferred subnet ${base}.0/24"
  fi
done

# from ip route (private CIDRs only)
while read -r cidr; do
  ippart="${cidr%%/*}"
  if [[ "$ippart" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
    base=$(first3 "$ippart")
    subnets["$base"]=1
    log "Route $cidr -> adding subnet ${base}.0/24"
  fi
done < <(ip route show | grep -Eo '([0-9]+\.){3}[0-9]+/[0-9]+' || true)

# from ARP table (handles PPP /32 neighbours)
mapfile -t arp_ips < <(arp -n 2>/dev/null | awk '/^[0-9]+\./ {print $1}' || true)
for ip in "${arp_ips[@]}"; do
  if [[ "$ip" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
    base=$(first3 "$ip")
    subnets["$base"]=1
    log "ARP entry $ip -> adding subnet ${base}.0/24"
  fi
done

# fallback: if no subnets detected, use first local addr's /24
if [[ ${#subnets[@]} -eq 0 && ${#local_addrs[@]} -gt 0 ]]; then
  base=$(first3 "${local_addrs[0]}")
  subnets["$base"]=1
  log "Fallback: added ${base}.0/24 from local IP ${local_addrs[0]}"
fi

# build targets (skip .0 .1 .255 and remove our own IPs)
tmp_targets="$(mktemp)"
trap 'rm -f "$tmp_targets"' EXIT

for base in "${!subnets[@]}"; do
  for i in $(seq 1 254); do
    # skip .1 (common gateway), .0 (network), .255 (broadcast)
    if [[ "$i" == "1" || "$i" == "0" || "$i" == "255" ]]; then
      continue
    fi
    echo "${base}.${i}" >> "$tmp_targets"
  done
done

# remove our own IP(s) from scan
for ip in "${local_addrs[@]}"; do
  [[ -z "$ip" ]] && continue
  sed -i "/^${ip//./\\.}$/d" "$tmp_targets" || true
done

# uniq & sort
sort -u "$tmp_targets" -o "$tmp_targets"

if [[ ! -s "$tmp_targets" ]]; then
  log "No targets to scan. Writing empty ${OUTFILE} and exiting."
  : > "$OUTFILE"
  exit 0
fi

log "Scanning $(wc -l < "$tmp_targets" | tr -d ' ') targets with concurrency=$CONCURRENCY..."

probe_and_print() {
  ip="$1"
  # ping with timeout; try -W then -w fallback (some busybox)
  if timeout "$PING_TIMEOUT" ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$ip" >/dev/null 2>&1; then
    printf "%s\n" "$ip"
    return
  fi
  if timeout "$PING_TIMEOUT" ping -c "$PING_COUNT" -w "$PING_TIMEOUT" "$ip" >/dev/null 2>&1; then
    printf "%s\n" "$ip"
    return
  fi
}

export -f probe_and_print
export PING_TIMEOUT PING_COUNT

xargs -a "$tmp_targets" -n1 -P "$CONCURRENCY" -I{} bash -c 'probe_and_print "$@"' _ {} \
  | sort -u > "$OUTFILE"

log "Discovery finished. Active IPs written to $OUTFILE"
log "Active hosts:"
if [[ -s "$OUTFILE" ]]; then
  sed -n '1,200p' "$OUTFILE"
else
  log "  (none)"
fi

exit 0
