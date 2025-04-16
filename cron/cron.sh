#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🕛 zzfirewall cron"
rootCheck
fxMessage "The output is redirect to logfile, please wait..."

LOG_DIR="/var/log/turbolab.it/"
mkdir -p "${LOG_DIR}"
LOG_FILE=${LOG_DIR}zzfirewall_cron.log

bash "/usr/local/turbolab.it/zzfirewall/zzfirewall.sh" > "${LOG_FILE}" 2>&1

fxTitle "${LOG_FILE}"
cat ${LOG_FILE}
