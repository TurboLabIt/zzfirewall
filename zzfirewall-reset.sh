#!/usr/bin/env bash
### FACTORY-RESET IPTABLES 
# clear && sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/zzfirewall-reset.sh?$(date +%s) | sudo bash

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready
fxHeader "❤️‍🩹 FIREWALL RESET"
rootCheck

fxTitle "🧹 Removing ufw, iptables-persistent..."
apt purge ufw iptables-persistent -y

fxTitle "🔄 Restoring iptables to default..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

fxTitle "🔄 Restoring iptables6 to default..."
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -t nat -F
ip6tables -t mangle -F
ip6tables -F
ip6tables -X

fxTitle "🧱 Current status"
iptables -nvL

fxEndFooter

