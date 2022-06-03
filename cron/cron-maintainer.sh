#!/usr/bin/env bash
echo ""

LOG_DIR="/var/log/turbolab.it/"
mkdir -p "${LOG_DIR}"

bash "/usr/local/turbolab.it/zzfirewall/generators/generate-lists.sh" > "${LOG_DIR}zzfirewall_cron-maintainer.log" 2>&1

