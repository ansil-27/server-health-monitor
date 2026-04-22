#!/bin/bash
# ============================================================
# checks/disk.sh — Disk Usage Check
# AutoOps Monitor | ASTRA DevOps Project
# ============================================================
# Reads DISK_THRESHOLD from config.cfg.
# Uses `df -h` to check usage % on the root partition /.
# Prints colour-coded PASS / ALERT and appends to health.log.
# ============================================================

# ── Locate project root ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ── Load configuration ──────────────────────────────────────
source "$PROJECT_ROOT/config.cfg"

# ── Colour codes ────────────────────────────────────────────
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

# ── Capture disk usage on root partition / ──────────────────
# `df -h /` sample output (line 2):
#   /dev/sda1   50G   20G   30G   40%   /
# We extract the percentage number, stripping the % sign.
get_disk_usage() {
    df -h / | awk 'NR==2 {gsub(/%/,""); print $5}'
}

# ── Main logic ───────────────────────────────────────────────
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
DISK_USAGE=$(get_disk_usage)

# Compare against threshold
if [[ $DISK_USAGE -ge $DISK_THRESHOLD ]]; then
    STATUS="ALERT"
    COLOR=$RED
else
    STATUS="PASS"
    COLOR=$GREEN
fi

# ── Terminal output (colour-coded) ──────────────────────────
echo -e "  [DISK]    Usage: ${COLOR}${DISK_USAGE}%${NC}  |  Threshold: ${DISK_THRESHOLD}%  |  Status: ${COLOR}${STATUS}${NC}"

# ── Append to log file ───────────────────────────────────────
echo "[$TIMESTAMP] DISK    | Usage: ${DISK_USAGE}%  | Threshold: ${DISK_THRESHOLD}% | ${STATUS}" \
    >> "$PROJECT_ROOT/$LOG_FILE"

# ── Export result for monitor.sh to collect ─────────────────
export DISK_RESULT="Disk|${DISK_USAGE}%|${DISK_THRESHOLD}%|${STATUS}"