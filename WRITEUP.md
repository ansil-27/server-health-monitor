# AutoOps Monitor — System Design Write-Up
## ASTRA DevOps Engineering Track | Automation & Scripting Module

---

## Overview

AutoOps Monitor is a modular Bash-based automation system that continuously tracks the
health of a Linux server. It checks CPU, memory, disk, and service status against
configurable thresholds, logs every check with a timestamp, and generates a dark-themed
HTML dashboard report — all without any external dependencies beyond standard Linux tools.

---

## Design Decisions

### 1. Modular Script Architecture
Each resource check lives in its own file under `checks/`. This separation of concerns
means you can run, test, or modify a single check (e.g., `cpu.sh`) without touching
the others. `monitor.sh` acts purely as an orchestrator — it sources each check script
and collects their exported results.

### 2. Single Source of Truth: config.cfg
All threshold values and monitored service names are defined once in `config.cfg`. Every
check script sources this file at startup. To change a threshold across the whole system,
you edit exactly one line in one file — no hunting through multiple scripts.

### 3. Export Variables for Aggregation
Each check script exports a pipe-delimited result string (e.g., `CPU|42%|80%|PASS`) into
an environment variable. `monitor.sh` reads these variables to build both the terminal
summary table and the HTML report — avoiding the need to parse log files or use temporary
files for inter-script communication.

### 4. Dual-Snapshot CPU Measurement
CPU usage is measured by reading `/proc/stat` twice, one second apart, and calculating the
ratio of active ticks to total ticks in that window. This is more accurate than a single
snapshot, which only reflects cumulative values since boot.

### 5. Colour-Coded Output (Terminal + HTML)
ANSI escape codes provide immediate visual feedback in the terminal. The HTML report uses
the same green/red semantic colouring with a professional dark-mode design so the report
is readable in a browser without any external CSS framework.

### 6. Persistent Timestamped Logging
Every check appends a fixed-format line to `logs/health.log` using the pattern:
`[YYYY-MM-DD HH:MM:SS] CHECK | value | threshold | STATUS`
This uniform format makes the log easy to parse with `grep`, `awk`, or `sed` for
future extensions such as trend analysis or alerting pipelines.

### 7. Cron Scheduling
Two cron jobs are defined:
- Every 5 minutes: run all checks and append output to `health.log`.
- Every day at 08:00 AM: run `monitor.sh --report` to regenerate `report.html`
  with a fresh snapshot and the latest log entries.

---

## Module Roles

| File | Role |
|---|---|
| `config.cfg` | Central config — thresholds and service list |
| `monitor.sh` | Orchestrator — runs checks, prints summary, calls report generator |
| `checks/cpu.sh` | Reads `/proc/stat` (two snapshots), computes CPU % |
| `checks/memory.sh` | Uses `free -m` to compute used RAM % |
| `checks/disk.sh` | Uses `df -h` to get root partition usage % |
| `checks/services.sh` | Loops over SERVICES, calls `systemctl is-active` for each |
| `logs/health.log` | Persistent timestamped log of every check result |
| `reports/report.html` | Auto-generated HTML dashboard, regenerated each run |

---

