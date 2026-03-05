#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🪝 zzfirewall + certbot: 01-pre hook"
source "${SCRIPT_DIR}lets-encrypt-web.sh"


fxTitle "Temporary allow HTTP(s) from all..."
iptables -I ${IPTABLES_COMMAND_ARGUMENTS}


fxTitle "🧱🧱🧱 FINAL FIREWALL STATUS 🧱🧱🧱"
iptables -nL


fxEndFooter
