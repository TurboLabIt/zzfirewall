#!/usr/bin/env bash
echo ""

LOG_DIR="/var/log/turbolab.it/"
mkdir -p "${LOG_DIR}"

bash "/usr/local/turbolab.it/zzfirewall/zzfirewall.sh" > "${LOG_DIR}zzfirewall_cron.log" 2>&1

