#!/bin/bash
# ============================================================
# monitor.sh — Main Runner / Orchestrator
# AutoOps Monitor | ASTRA DevOps Project
# ============================================================
# Usage:
#   ./monitor.sh           — Run all checks + generate report
#   ./monitor.sh --report  — Same (used by 8 AM cron job)
#
# Flow:
#   1. Source config.cfg
#   2. Run all 4 check scripts in sequence
#   3. Print formatted summary to terminal
#   4. Call generate_report() to create reports/report.html
# ============================================================

# ── Resolve absolute project root ───────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load configuration ──────────────────────────────────────
source "$PROJECT_ROOT/config.cfg"

# ── Colour codes ────────────────────────────────────────────
CYAN="\033[0;36m"
BOLD="\033[1m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

# ── Ensure log and report directories exist ─────────────────
mkdir -p "$PROJECT_ROOT/logs"
mkdir -p "$PROJECT_ROOT/reports"

# ── Print banner ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}============================================${NC}"
echo -e "${CYAN}${BOLD}   AutoOps Monitor — Server Health Check    ${NC}"
echo -e "${CYAN}${BOLD}============================================${NC}"
echo -e "  Run time : $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  Host     : $(hostname)"
echo -e "  Uptime   : $(uptime -p 2>/dev/null || uptime)"
echo -e "${CYAN}--------------------------------------------${NC}"
echo ""

# ── Run individual check scripts ─────────────────────────────
# Each script exports its result in the variable named below.

echo -e "${BOLD}[1/4] CPU Check${NC}"
source "$PROJECT_ROOT/checks/cpu.sh"

echo ""
echo -e "${BOLD}[2/4] Memory Check${NC}"
source "$PROJECT_ROOT/checks/memory.sh"

echo ""
echo -e "${BOLD}[3/4] Disk Check${NC}"
source "$PROJECT_ROOT/checks/disk.sh"

echo ""
echo -e "${BOLD}[4/4] Services Check${NC}"
source "$PROJECT_ROOT/checks/services.sh"

# ── Collect all results into an array ───────────────────────
# Each result is a pipe-delimited string: Name|Value|Threshold|Status
RESULTS=("$CPU_RESULT" "$MEM_RESULT" "$DISK_RESULT" "$SVC_RESULT")

# ── Print summary table to terminal ─────────────────────────
echo ""
echo -e "${CYAN}${BOLD}============================================${NC}"
echo -e "${CYAN}${BOLD}              SUMMARY                       ${NC}"
echo -e "${CYAN}${BOLD}============================================${NC}"
printf "  %-12s %-12s %-12s %-8s\n" "CHECK" "VALUE" "THRESHOLD" "STATUS"
echo -e "  ------------------------------------------"

for RESULT in "${RESULTS[@]}"; do
    IFS='|' read -r NAME VALUE THRESHOLD STATUS <<< "$RESULT"
    if [[ "$STATUS" == "PASS" ]]; then
        STATUS_COLOR=$GREEN
    else
        STATUS_COLOR=$RED
    fi
    printf "  %-12s %-12s %-12s " "$NAME" "$VALUE" "$THRESHOLD"
    echo -e "${STATUS_COLOR}${STATUS}${NC}"
done

echo -e "${CYAN}============================================${NC}"
echo ""

# ── HTML Report Generator ────────────────────────────────────
generate_report() {
    REPORT_PATH="$PROJECT_ROOT/$REPORT_FILE"
    TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

    # Retrieve last 10 log entries
    LAST_LOGS=$(tail -n 10 "$PROJECT_ROOT/$LOG_FILE" 2>/dev/null \
        || echo "No log entries yet.")

    # Build HTML rows for each result
    ROWS_HTML=""
    for RESULT in "${RESULTS[@]}"; do
        IFS='|' read -r NAME VALUE THRESHOLD STATUS <<< "$RESULT"
        if [[ "$STATUS" == "PASS" ]]; then
            ROW_CLASS="pass"
            BADGE="&#10003; PASS"
        else
            ROW_CLASS="alert"
            BADGE="&#9888; ALERT"
        fi
        ROWS_HTML+="<tr class=\"${ROW_CLASS}\">
            <td>${NAME}</td>
            <td>${VALUE}</td>
            <td>${THRESHOLD}</td>
            <td><span class=\"badge ${ROW_CLASS}\">${BADGE}</span></td>
        </tr>"
    done

    # Convert log lines to HTML (escape < and >)
    LOG_HTML=$(echo "$LAST_LOGS" | sed 's/</\&lt;/g; s/>/\&gt;/g' \
        | while IFS= read -r line; do echo "<div class=\"log-line\">${line}</div>"; done)

    # Write the full HTML file
    cat > "$REPORT_PATH" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>AutoOps Monitor — Health Report</title>
  <style>
    /* ── Reset & base ── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      background: #0d1117;
      color: #c9d1d9;
      min-height: 100vh;
      padding: 30px 20px;
    }

    /* ── Header ── */
    header {
      background: linear-gradient(135deg, #1f2937, #111827);
      border: 1px solid #30363d;
      border-radius: 12px;
      padding: 28px 32px;
      margin-bottom: 28px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
    }
    header h1 { font-size: 1.8rem; color: #58a6ff; letter-spacing: 1px; }
    header h1 span { color: #f0f6fc; }
    .meta { font-size: 0.85rem; color: #8b949e; text-align: right; }
    .meta strong { color: #c9d1d9; }

    /* ── Section card ── */
    .card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 10px;
      padding: 24px 28px;
      margin-bottom: 24px;
    }
    .card h2 {
      font-size: 1rem;
      color: #8b949e;
      text-transform: uppercase;
      letter-spacing: 2px;
      margin-bottom: 18px;
      border-bottom: 1px solid #30363d;
      padding-bottom: 10px;
    }

    /* ── Results table ── */
    table { width: 100%; border-collapse: collapse; }
    th {
      background: #0d1117;
      color: #8b949e;
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      padding: 12px 16px;
      text-align: left;
      border-bottom: 2px solid #30363d;
    }
    td { padding: 14px 16px; border-bottom: 1px solid #21262d; font-size: 0.95rem; }
    tr:last-child td { border-bottom: none; }

    /* ── Row colouring ── */
    tr.pass  td:first-child { border-left: 4px solid #3fb950; }
    tr.alert td:first-child { border-left: 4px solid #f85149; }
    tr.pass  { background: rgba(63,185,80,0.05); }
    tr.alert { background: rgba(248,81,73,0.07); }
    tr:hover { background: rgba(255,255,255,0.04); }

    /* ── Status badges ── */
    .badge {
      display: inline-block;
      padding: 4px 14px;
      border-radius: 20px;
      font-size: 0.8rem;
      font-weight: 700;
      letter-spacing: 0.5px;
    }
    .badge.pass  { background: #1a4731; color: #3fb950; border: 1px solid #3fb950; }
    .badge.alert { background: #4a1515; color: #f85149; border: 1px solid #f85149; }

    /* ── Log section ── */
    .log-box {
      background: #0d1117;
      border: 1px solid #30363d;
      border-radius: 8px;
      padding: 16px 18px;
      font-family: 'Courier New', monospace;
      font-size: 0.82rem;
      max-height: 300px;
      overflow-y: auto;
    }
    .log-line {
      padding: 4px 0;
      border-bottom: 1px solid #1c2128;
      color: #8b949e;
    }
    .log-line:last-child { border-bottom: none; }

    /* ── Footer ── */
    footer {
      text-align: center;
      color: #484f58;
      font-size: 0.78rem;
      margin-top: 10px;
    }
  </style>
</head>
<body>

  <header>
    <div>
      <h1>AutoOps <span>Monitor</span></h1>
      <p style="color:#8b949e; font-size:0.85rem; margin-top:4px;">
        Automated Server Health Report — ASTRA DevOps Track
      </p>
    </div>
    <div class="meta">
      <div>Generated: <strong>${TIMESTAMP}</strong></div>
      <div>Host: <strong>$(hostname)</strong></div>
    </div>
  </header>

  <!-- ── Results Table ── -->
  <div class="card">
    <h2>&#128200; Health Check Results</h2>
    <table>
      <thead>
        <tr>
          <th>Check</th>
          <th>Current Value</th>
          <th>Threshold</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        ${ROWS_HTML}
      </tbody>
    </table>
  </div>

  <!-- ── Log Entries ── -->
  <div class="card">
    <h2>&#128196; Last 10 Log Entries</h2>
    <div class="log-box">
      ${LOG_HTML}
    </div>
  </div>

  <footer>
    AutoOps Monitor &nbsp;|&nbsp; ASTRA DevOps Engineering Track
    &nbsp;|&nbsp; Report auto-generated by monitor.sh
  </footer>

</body>
</html>
HTML

    echo -e "${GREEN}  ✔ HTML report saved → ${REPORT_PATH}${NC}"
}

# ── Generate report ──────────────────────────────────────────
echo -e "${YELLOW}Generating HTML report...${NC}"
generate_report

echo ""
echo -e "${CYAN}${BOLD}All checks complete. Report: ${PROJECT_ROOT}/reports/report.html${NC}"
echo ""