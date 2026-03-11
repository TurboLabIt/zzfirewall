#!/usr/bin/env bash
### FACTORY-RESET IPTABLES 
# clear && sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/zzfirewall-reset.sh | sudo bash

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "❤️‍🩹 FIREWALL RESET"
rootCheck

if [ "$1" = "light" ]; then
  LIGHT_MODE=1
else
  LIGHT_MODE=0
fi

if [ "$LIGHT_MODE" = 0 ]; then
  fxTitle "🧹 Removing ufw, iptables-persistent..."
  apt purge ufw iptables-persistent -y
fi

fxTitle "🔄 Restoring iptables to default..."
iptables-save | awk '/^[*]/ { print $1 } 
                     /^:[A-Z]+ [^-]/ { print $1 " ACCEPT" ; }
                     /COMMIT/ { print $0; }' | iptables-restore


if [ "$LIGHT_MODE" = 0 ] && [ ! -z "$(command -v ipset)" ]; then

  fxTitle "🧹 Remove all ipsets..."
  ipset flush

  ## Set cannot be destroyed: it is in use by a kernel component
  # https://github.com/weaveworks/weave/issues/3847
  sleep 2
  ipset destroy
  
  if [ $? -ne 0 ]; then
    fxMessage "Failed - retrying..."
    sleep 3
    ipset destroy
  fi
 
fi

fxTitle "🧱 Current status"
iptables -nL

if [ "$LIGHT_MODE" = 0 ] && [ ! -z "$(command -v ipset)" ]; then
  echo ""
  ipset list
fi

fxEndFooter
