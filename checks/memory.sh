#!/bin/bash
# ============================================================
# checks/memory.sh — Memory Usage Check
# AutoOps Monitor | ASTRA DevOps Project
# ============================================================
# Reads MEMORY_THRESHOLD from config.cfg.
# Uses `free -m` to calculate used RAM as a % of total.
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

# ── Capture memory usage using `free -m` ────────────────────
# `free -m` output (line 2):
#   Mem:   total   used   free   shared  buff/cache   available
get_memory_usage() {
    # Extract total and used values (in MB)
    local mem_total mem_used
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    mem_used=$(free -m  | awk '/^Mem:/ {print $3}')

    # Calculate percentage
    if [[ $mem_total -eq 0 ]]; then
        echo 0
    else
        echo $(( 100 * mem_used / mem_total ))
    fi
}

# ── Main logic ───────────────────────────────────────────────
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
MEM_USAGE=$(get_memory_usage)

# Compare against threshold
if [[ $MEM_USAGE -ge $MEMORY_THRESHOLD ]]; then
    STATUS="ALERT"
    COLOR=$RED
else
    STATUS="PASS"
    COLOR=$GREEN
fi

# ── Terminal output (colour-coded) ──────────────────────────
echo -e "  [MEMORY]  Usage: ${COLOR}${MEM_USAGE}%${NC}  |  Threshold: ${MEMORY_THRESHOLD}%  |  Status: ${COLOR}${STATUS}${NC}"

# ── Append to log file ───────────────────────────────────────
echo "[$TIMESTAMP] MEMORY  | Usage: ${MEM_USAGE}%  | Threshold: ${MEMORY_THRESHOLD}% | ${STATUS}" \
    >> "$PROJECT_ROOT/$LOG_FILE"

# ── Export result for monitor.sh to collect ─────────────────
export MEM_RESULT="Memory|${MEM_USAGE}%|${MEMORY_THRESHOLD}%|${STATUS}"