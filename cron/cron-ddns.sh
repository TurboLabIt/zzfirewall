#!/usr/bin/env bash
echo ""

LOG_DIR="/var/log/turbolab.it/"
mkdir -p "${LOG_DIR}"

bash "/usr/local/turbolab.it/zzfirewall/ddns/update.sh" > "${LOG_DIR}zzfirewall_cron-ddns-update.log" 2>&1

