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

## Symlink (globally-available zzfirewall command)
if [ ! -f "/usr/local/bin/${SCRIPT_NAME}" ]; then
  ln -s ${INSTALL_DIR}${SCRIPT_NAME}.sh /usr/local/bin/${SCRIPT_NAME}
fi

if [ ! -f "/usr/local/bin/${SCRIPT_NAME}-reset" ]; then
  ln -s ${INSTALL_DIR}${SCRIPT_NAME}-reset.sh /usr/local/bin/${SCRIPT_NAME}-reset
fi

if [ ! -f "/usr/local/bin/${SCRIPT_NAME}-generate" ]; then
  ln -s ${INSTALL_DIR}generators/generate-lists.sh /usr/local/bin/${SCRIPT_NAME}-generate
fi

## Copy the cron job
if [ ! -f "/etc/cron.d/zzfirewall" ]; then
  cp "${INSTALL_DIR}cron/cron" "/etc/cron.d/zzfirewall"
fi

if [ "$(hostname)" = "zane-boraso" ]; then
  cp "${INSTALL_DIR}cron/cron-maintainer" "/etc/cron.d/zzfirewall_maintainer"
fi

sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}

