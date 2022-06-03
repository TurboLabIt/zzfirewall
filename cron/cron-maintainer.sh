#!/usr/bin/env bash
echo ""
bash "/usr/local/turbolab.it/zzfirewall/generators/generate-list.sh" > "/var/log/zzfirewall_cron-maintainer.log" 2>&1

