#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
HOOK_NAME='🪝 zzfirewall + certbot: 01-pre hook'
fxHeader "${HOOK_NAME}"
rootCheck
fxConfigLoader


fxTitle "📦 Checking packages...."
if [ -z "$(command -v iptables)" ] || [ -z "$(command -v certbot)" ]; then

  fxWarning "iptables or certbot not installed. Skipping 🦘"
  fxEndFooter
  exit
fi


if ! iptables -S INPUT | grep -q '^-A'; then

  fxWarning "iptables INPUT chain is empty. Skipping 🦘"
  fxEndFooter
  exit
fi


fxTitle "Allow HTTP(s) from all"
iptables -I INPUT -p tcp -m multiport --dports 80,443 -m comment --comment "${HOOK_NAME} (zzfw)" -j ACCEPT


fxTitle "🧱🧱🧱 FINAL FIREWALL STATUS 🧱🧱🧱"
iptables -nL


fxEndFooter
