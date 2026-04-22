#!/bin/bash
# ============================================================
# checks/services.sh — Service Status Check
# AutoOps Monitor | ASTRA DevOps Project
# ============================================================
# Reads the SERVICES list from config.cfg.
# Uses `systemctl is-active` to verify each service is running.
# Prints colour-coded PASS / ALERT per service.
# Appends a summary entry to health.log.
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

# ── Check each service ───────────────────────────────────────
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
ALL_PASS=true          # Track overall status
SERVICE_SUMMARY=""     # Build a pipe-delimited summary string

for SERVICE in $SERVICES; do
    # systemctl is-active returns "active" if running, else "inactive" / "failed"
    STATE=$(systemctl is-active "$SERVICE" 2>/dev/null)

    if [[ "$STATE" == "active" ]]; then
        STATUS="PASS"
        COLOR=$GREEN
    else
        STATUS="ALERT"
        COLOR=$RED
        ALL_PASS=false
        STATE="inactive/failed"
    fi

    # Terminal output per service
    echo -e "  [SERVICE] ${SERVICE}: ${COLOR}${STATE}${NC}  |  Status: ${COLOR}${STATUS}${NC}"

    # Append per-service log entry
    echo "[$TIMESTAMP] SERVICE | ${SERVICE}: ${STATE} | ${STATUS}" \
        >> "$PROJECT_ROOT/$LOG_FILE"

    # Build summary for HTML report (format: name:status)
    SERVICE_SUMMARY="${SERVICE_SUMMARY}${SERVICE}:${STATUS},"
done

# ── Overall service status ───────────────────────────────────
if $ALL_PASS; then
    OVERALL="PASS"
else
    OVERALL="ALERT"
fi

# ── Export result for monitor.sh / HTML report ──────────────
# Format: "Services|<service1:STATUS,service2:STATUS,...>|N/A|OVERALL"
export SVC_RESULT="Services|${SERVICE_SUMMARY%,}|N/A|${OVERALL}"