#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🛡️🧱 zzfirewall DDNS update 🧱🛡️"
rootCheck

#SCRIPT_DIR=${SCRIPT_DIR}../
#source "${BASHFX_INSTALL_DIR}scripts/config-loader.sh"

function addItem()
{
  local ITEM=$1
  fxMessage "👔 $ITEM"
}


for DDNS_FILE in /etc/turbolab.it/zzfirewall-ddns*
  do

    fxTitle "📋 ${DDNS_FILE}"
    
    while read -r line || [[ -n "$line" ]]; do
    
      FIRSTCHAR="${line:0:1}"
      if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then
        addItem $line
      fi
      
    done < "$DDNS_FILE"
    
  done


fxEndFooter

