#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🪝 zzfirewall + certbot: 90-post hook"
source "${SCRIPT_DIR}lets-encrypt-web.sh"


fxTitle "Remove the temp. Allow HTTP(s) from all rule..."
while iptables -D "${IPTABLES_COMMAND_ARGUMENTS[@]}" 2>/dev/null; do
  fxOK "Removed a matching rule..."
done


fxTitle "🧱🧱🧱 FINAL FIREWALL STATUS 🧱🧱🧱"
iptables -nL


fxEndFooter

