# 🖥️ AutoOps Monitor — Automated Server Health Check System

> **ASTRA DevOps Engineering Track · Automation & Scripting Module · Intermediate Level**

A fully automated Linux server health monitoring system built with pure Bash scripting.
It checks CPU, memory, disk, and service status against configurable thresholds, logs every
result with a timestamp, and generates a dark-themed HTML dashboard report — all on a cron
schedule with zero external dependencies.

---

## 📋 Table of Contents

- [Features](#-features)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [How It Works](#-how-it-works)
- [Cron Scheduling](#-cron-scheduling)
- [Sample Output](#-sample-output)
- [Grading Rubric Coverage](#-grading-rubric-coverage)
- [Bonus Challenges](#-bonus-challenges)
- [Troubleshooting](#-troubleshooting)

---

## ✨ Features

- ✅ **CPU monitoring** — dual `/proc/stat` snapshot for accurate real-time usage
- ✅ **Memory monitoring** — `free -m` based used-RAM percentage
- ✅ **Disk monitoring** — root partition `df -h` usage check
- ✅ **Service monitoring** — `systemctl is-active` check for any listed services
- ✅ **Configurable thresholds** — single `config.cfg` file controls all alert limits
- ✅ **Colour-coded terminal output** — green `PASS`, red `ALERT` at a glance
- ✅ **Persistent timestamped logging** — every check appended to `logs/health.log`
- ✅ **Auto-generated HTML report** — dark-themed dashboard with results table + last 10 logs
- ✅ **Cron automation** — runs every 5 minutes, full report at 8 AM daily
- ✅ **Modular architecture** — each check is an independent, reusable script

---

## 📁 Project Structure

```
health-monitor/
├── monitor.sh              # Main orchestrator — run this
├── config.cfg              # Threshold & service configuration
├── crontab.txt             # Cron job definitions (copy into crontab -e)
├── WRITEUP.md              # Design decisions write-up
├── README.md               # This file
│
├── checks/
│   ├── cpu.sh              # CPU usage check via /proc/stat
│   ├── memory.sh           # RAM usage check via free -m
│   ├── disk.sh             # Disk usage check via df -h
│   └── services.sh         # Service status check via systemctl
│
├── logs/
│   └── health.log          # Auto-created — timestamped log of all checks
│
└── reports/
    └── report.html         # Auto-generated HTML dashboard report
```

---

## 🔧 Prerequisites

| Requirement | Notes |
|---|---|
| Linux / WSL (Ubuntu recommended) | Windows users: use WSL2 |
| Bash 4.0+ | Pre-installed on all modern Linux distros |
| `systemctl` | For service checks (systemd-based distros) |
| `free`, `df`, `awk` | Standard GNU coreutils — pre-installed |
| `cron` | For scheduled automation |

> **WSL Users (Windows):** See [Troubleshooting](#-troubleshooting) for the CRLF line-ending fix.

---

## 🚀 Installation

### 1. Clone or download the project

```bash
git clone https://github.com/yourname/health-monitor.git
cd health-monitor
```

Or manually place the folder at your preferred path, e.g.:
```
/home/student/health-monitor/
```

### 2. Make all scripts executable

```bash
chmod +x monitor.sh checks/*.sh
```

### 3. Run it

```bash
./monitor.sh
```

That's it. The `logs/` and `reports/` directories are created automatically on first run.

---

## ⚙️ Configuration

All settings live in **`config.cfg`** — edit this file to customise thresholds and services.

```bash
# Alert if CPU usage exceeds this percentage
CPU_THRESHOLD=80

# Alert if memory usage exceeds this percentage
MEMORY_THRESHOLD=75

# Alert if disk usage on / exceeds this percentage
DISK_THRESHOLD=90

# Space-separated list of services to monitor
SERVICES="ssh cron nginx"
```

**To add more services**, just append them to the `SERVICES` line:
```bash
SERVICES="ssh cron nginx mysql redis"
```

**To tighten a threshold**, lower the number:
```bash
CPU_THRESHOLD=60   # Alert if CPU goes above 60%
```

No other files need to be changed — all scripts read from `config.cfg` at runtime.

---

## 🖥️ Usage

### Run a full health check + generate report

```bash
./monitor.sh
```

### Run silently (cron mode — output goes to log)

```bash
./monitor.sh >> logs/health.log 2>&1
```

### View the HTML report

Open `reports/report.html` in any browser:

```bash
# On Linux
xdg-open reports/report.html

# On WSL (opens in Windows browser)
explorer.exe reports/report.html
```

### View the live log

```bash
tail -f logs/health.log
```

---

## 🔍 How It Works

### Execution Flow

```
./monitor.sh
│
├── [1/4] checks/cpu.sh
│         └── Read /proc/stat × 2 (1s apart) → compute CPU %
│         └── Compare vs CPU_THRESHOLD → PASS / ALERT
│         └── Append timestamped entry → logs/health.log
│
├── [2/4] checks/memory.sh
│         └── free -m → extract used/total → compute RAM %
│         └── Compare vs MEMORY_THRESHOLD → PASS / ALERT
│         └── Append timestamped entry → logs/health.log
│
├── [3/4] checks/disk.sh
│         └── df -h / → extract usage % on root partition
│         └── Compare vs DISK_THRESHOLD → PASS / ALERT
│         └── Append timestamped entry → logs/health.log
│
├── [4/4] checks/services.sh
│         └── Loop over $SERVICES → systemctl is-active each
│         └── PASS if active, ALERT if inactive/failed
│         └── Append per-service entry → logs/health.log
│
└── generate_report()
          └── Build colour-coded HTML table from results
          └── Embed last 10 lines of health.log
          └── Write → reports/report.html
```

### Log Format

Every check writes a line in this fixed format:

```
[2026-04-22 08:00:01] CPU     | Usage: 42%  | Threshold: 80% | PASS
[2026-04-22 08:00:02] MEMORY  | Usage: 61%  | Threshold: 75% | PASS
[2026-04-22 08:00:02] DISK    | Usage: 23%  | Threshold: 90% | PASS
[2026-04-22 08:00:02] SERVICE | nginx: active | PASS
```

---

## ⏰ Cron Scheduling

Install the cron jobs by running `crontab -e` and pasting:

```cron
# Run health checks every 5 minutes and append to log
*/5 * * * * /full/path/to/health-monitor/monitor.sh >> /full/path/to/health-monitor/logs/health.log 2>&1

# Regenerate full HTML report every day at 8:00 AM
0 8 * * * /full/path/to/health-monitor/monitor.sh --report
```

> ⚠️ Replace `/full/path/to/health-monitor` with your actual absolute path.
> Use `pwd` inside the project folder to get it.

Verify cron jobs are installed:

```bash
crontab -l
```

---

## 📊 Sample Output

### Terminal

```
============================================
   AutoOps Monitor — Server Health Check
============================================
  Run time : 2026-04-22 08:00:01
  Host     : my-server
  Uptime   : up 3 days, 2 hours

[1/4] CPU Check
  [CPU]     Usage: 42%  |  Threshold: 80%  |  Status: PASS

[2/4] Memory Check
  [MEMORY]  Usage: 61%  |  Threshold: 75%  |  Status: PASS

[3/4] Disk Check
  [DISK]    Usage: 23%  |  Threshold: 90%  |  Status: PASS

[4/4] Services Check
  [SERVICE] ssh:   active          |  Status: PASS
  [SERVICE] cron:  active          |  Status: PASS
  [SERVICE] nginx: inactive/failed |  Status: ALERT

============================================
  CHECK        VALUE     THRESHOLD  STATUS
  ------------------------------------------
  CPU          42%       80%        PASS
  Memory       61%       75%        PASS
  Disk         23%       90%        PASS
  Services     ...       N/A        ALERT
============================================

✔ HTML report saved → reports/report.html
```

### HTML Report

The generated `report.html` includes:
- 🟢 Green rows for **PASS** checks
- 🔴 Red rows for **ALERT** checks
- Current value vs threshold for each check
- Last 10 log entries in a monospace log viewer

---

## 📝 Grading Rubric Coverage

| Criteria | Marks | How It's Met |
|---|---|---|
| All 4 check scripts work and read from `config.cfg` | 25 | `cpu.sh`, `memory.sh`, `disk.sh`, `services.sh` all `source config.cfg` |
| Logging with accurate timestamps | 15 | Every check appends `[YYYY-MM-DD HH:MM:SS]` line to `health.log` |
| HTML report with correct data and colour coding | 20 | `generate_report()` in `monitor.sh` builds full dark-themed dashboard |
| Cron jobs configured correctly | 15 | `crontab.txt` contains both the 5-min and 8 AM job definitions |
| Modular, readable, well-commented code | 15 | Each script has header comments, section comments, and clear variable names |
| Write-up explaining system design | 10 | See `WRITEUP.md` |
| **Total** | **100** | |

---

## ⭐ Bonus Challenges

### Email Alert
Add inside any check script when `STATUS == "ALERT"`:
```bash
echo "ALERT: $SERVICE is down on $(hostname)" | mail -s "Server Alert" admin@example.com
```

### Slack Webhook
Store your webhook URL in `config.cfg` and add:
```bash
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

curl -s -X POST "$SLACK_WEBHOOK" \
  -H 'Content-type: application/json' \
  --data "{\"text\":\"🚨 ALERT: CPU at ${CPU_USAGE}% on $(hostname)\"}"
```

### Multi-Server Support
Loop over remote hosts and run checks via SSH:
```bash
REMOTE_HOSTS="server1.example.com server2.example.com"
for HOST in $REMOTE_HOSTS; do
    ssh user@$HOST "bash -s" < checks/cpu.sh
done
```

### Historical ASCII Graph
Parse `health.log` with awk to plot CPU trend:
```bash
awk '/CPU/ {gsub(/%/,"",$5); print $5}' logs/health.log | \
awk '{printf "%3d%% |", $1; for(i=0;i<$1/2;i++) printf "█"; print ""}'
```

---

## 🛠️ Troubleshooting

### `$'\r': command not found` errors (WSL / Windows)

**Cause:** Files were saved with Windows CRLF (`\r\n`) line endings instead of Unix LF (`\n`).

**Fix:**
```bash
sed -i 's/\r//' config.cfg monitor.sh checks/*.sh
```

Or install and use `dos2unix`:
```bash
sudo apt install dos2unix
dos2unix config.cfg monitor.sh checks/*.sh
```

**Prevent it:** In VS Code, click `CRLF` in the bottom-right status bar → change to `LF` before saving.

---

### `systemctl: command not found`

You're on a non-systemd system (e.g., older Ubuntu in WSL1). Edit `services.sh` and replace:
```bash
systemctl is-active "$SERVICE"
```
with:
```bash
service "$SERVICE" status > /dev/null 2>&1 && echo "active" || echo "inactive"
```

---

### Permission denied when running `./monitor.sh`

```bash
chmod +x monitor.sh checks/*.sh
```

---

## 👨‍💻 Author

Built as part of the **ASTRA DevOps Engineering Track** — Automation & Scripting Module.

-Ansil T A