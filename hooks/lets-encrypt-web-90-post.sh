#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🪝 zzfirewall + certbot: 90-post hook"
source "${SCRIPT_DIR}lets-encrypt-web.sh"


fxTitle "Remove temp. HTTP(s) from all rule..."
iptables -D ${IPTABLES_COMMAND_ARGUMENTS}


fxTitle "🧱🧱🧱 FINAL FIREWALL STATUS 🧱🧱🧱"
iptables -nL


fxEndFooter

