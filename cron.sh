#!/usr/bin/env bash
echo ""

## Script name
SCRIPT_NAME="zzfirewall"

source "/usr/local/turbolab.it/zzfirewall/base.sh"
bash "/usr/local/turbolab.it/zzfirewall/zzfirewall.sh" > "/var/log/zzfirewall_cron.log" 2>&1

