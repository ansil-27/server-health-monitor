#!/bin/bash
# ============================================================
# checks/cpu.sh — CPU Usage Check
# AutoOps Monitor | ASTRA DevOps Project
# ============================================================
# Reads CPU_THRESHOLD from config.cfg.
# Captures current CPU utilisation using /proc/stat (two
# snapshots 1 second apart for an accurate idle delta).
# Prints colour-coded PASS / ALERT and appends to health.log.
# ============================================================

# ── Locate project root (one level up from checks/) ────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ── Load configuration ──────────────────────────────────────
source "$PROJECT_ROOT/config.cfg"

# ── Colour codes ────────────────────────────────────────────
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"   # No Colour / Reset

# ── Capture CPU usage via /proc/stat (two snapshots) ────────
get_cpu_usage() {
    # First snapshot — use awk to reliably parse /proc/stat
    local snap1
    snap1=$(awk '/^cpu / {print $2,$3,$4,$5,$6,$7,$8}' /proc/stat)
    read -r user1 nice1 system1 idle1 iowait1 irq1 softirq1 <<< "$snap1"

    sleep 1   # Wait one second before second snapshot

    # Second snapshot
    local snap2
    snap2=$(awk '/^cpu / {print $2,$3,$4,$5,$6,$7,$8}' /proc/stat)
    read -r user2 nice2 system2 idle2 iowait2 irq2 softirq2 <<< "$snap2"

    # Calculate deltas
    local idle_delta=$(( (idle2 + iowait2) - (idle1 + iowait1) ))
    local total_delta=$(( (user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2) \
                        - (user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1) ))

    # CPU usage % = 100 * (total - idle) / total
    if [[ $total_delta -eq 0 ]]; then
        echo 0
    else
        echo $(( 100 * (total_delta - idle_delta) / total_delta ))
    fi
}

# ── Main logic ───────────────────────────────────────────────
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
CPU_USAGE=$(get_cpu_usage)

# Compare against threshold
if [[ $CPU_USAGE -ge $CPU_THRESHOLD ]]; then
    STATUS="ALERT"
    COLOR=$RED
else
    STATUS="PASS"
    COLOR=$GREEN
fi

# ── Terminal output (colour-coded) ──────────────────────────
echo -e "  [CPU]     Usage: ${COLOR}${CPU_USAGE}%${NC}  |  Threshold: ${CPU_THRESHOLD}%  |  Status: ${COLOR}${STATUS}${NC}"

# ── Append to log file ───────────────────────────────────────
echo "[$TIMESTAMP] CPU     | Usage: ${CPU_USAGE}%  | Threshold: ${CPU_THRESHOLD}% | ${STATUS}" \
    >> "$PROJECT_ROOT/$LOG_FILE"

# ── Export result for monitor.sh to collect ─────────────────
export CPU_RESULT="CPU|${CPU_USAGE}%|${CPU_THRESHOLD}%|${STATUS}"