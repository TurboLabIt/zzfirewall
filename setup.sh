#!/usr/bin/env bash
echo ""
SCRIPT_NAME=zzfirewall

## bash-fx
if [ -z "$(command -v curl)" ]; then
  sudo apt update && sudo apt install curl -y
fi
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

sudo bash /usr/local/turbolab.it/bash-fx/setup/start.sh ${SCRIPT_NAME}
fxLinkBin ${INSTALL_DIR}${SCRIPT_NAME}.sh
fxLinkBin ${INSTALL_DIR}${SCRIPT_NAME}-reset.sh
fxLinkBin ${INSTALL_DIR}whitelister/whitelister.sh ${SCRIPT_NAME}-whitelist-update

## Copy the cron job
if [ ! -f "/etc/cron.d/zzfirewall" ]; then
  cp "${INSTALL_DIR}cron/cron" "/etc/cron.d/zzfirewall"
fi

if [ ! -f "/usr/local/bin/${SCRIPT_NAME}-whitelist-update" ]; then
  ln -s ${INSTALL_DIR}whitelister/whitelister.sh /usr/local/bin/${SCRIPT_NAME}-whitelist-update
fi

## maintainer stuff
if [ "$(hostname)" = "zane-boraso" ]; then
  fxLinkBin ${INSTALL_DIR}generators/generate-lists.sh ${SCRIPT_NAME}-generate
  cp "${INSTALL_DIR}generators/cron-maintainer" "/etc/cron.d/zzfirewall_maintainer"
fi

sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}
