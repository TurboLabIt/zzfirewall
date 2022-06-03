#!/usr/bin/env bash
echo ""
bash "/usr/local/turbolab.it/zzfirewall/ddns/update.sh" > "/var/log/zzfirewall_cron-ddns-update.log" 2>&1

