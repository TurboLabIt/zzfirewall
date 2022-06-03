#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🕛 zzfirewall cron-maintainer"
rootCheck
fxMessage "The output is redirect to logfile, please wait..."

LOG_DIR="/var/log/turbolab.it/"
mkdir -p "${LOG_DIR}"
LOG_FILE=${LOG_DIR}zzfirewall_cron-maintainer.log

git -C "/usr/local/turbolab.it/zzfirewall/" pull > "${LOG_FILE}zzfirewall_cron-maintainer.log" 2>&1
bash "/usr/local/turbolab.it/zzfirewall/generators/generate-lists.sh" >> "${LOG_FILE}zzfirewall_cron-maintainer.log" 2>&1

fxTitle "${LOG_FILE}"
cat ${LOG_FILE}

