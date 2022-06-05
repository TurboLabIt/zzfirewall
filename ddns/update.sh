#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🛡️🧱 zzfirewall DDNS update 🧱🛡️"
rootCheck

CHAIN_NAME="👔_ZZFW_LOCAL_WHITELIST"
CHAIN_REFERENCE_COMMENT="👔 (zzfw)"

fxIptablesCreateChainIfNotExists "$CHAIN_NAME"

fxTitle "🔗 Checking if the iptables chain INPUT refrences $CHAIN_NAME..."
iptables -C INPUT -t filter -j "$CHAIN_NAME" -m comment --comment "$CHAIN_REFERENCE_COMMENT" >/dev/null 2>&1
INPUT_CHAIN_CONTAINS=$?

if [ "$INPUT_CHAIN_CONTAINS" != 0 ]; then

  fxMessage "🕳️ No references found. Referencing it now"
  iptables -t filter -I INPUT -j "$CHAIN_NAME" -m comment --comment "$CHAIN_REFERENCE_COMMENT"
  iptables -nL INPUT
else

  fxMessage "✔️ Reference found"
fi


fxTitle "🧹 Clear the $CHAIN_NAME chain..."
iptables -F "$CHAIN_NAME"


function addItem()
{
  local ITEM=$1
  fxMessage "👔 $ITEM"
  
  if [[ "$ITEM" =~ [^0-9\.\/] ]]; then
    
    echo "Resolving..."
    IP_ADDRESS=$(getent hosts $ITEM | awk '{ print $1 }')
    if [ -z "$IP_ADDRESS" ]; then
      fxCatastrophicError "⚠️ Failed"
      return 255
    fi
  
  else
  
    IP_ADDRESS=$ITEM
  fi
 
 echo "Adding $IP_ADDRESS to the chain..." 
 iptables -I "$CHAIN_NAME" -s "$IP_ADDRESS" -j ACCEPT -m comment --comment "👔 $ITEM (zzfw)"
}


for DDNS_FILE in /etc/turbolab.it/zzfirewall-ddns*
  do

    fxTitle "📋 ${DDNS_FILE}"
    
    while read -r line || [[ -n "$line" ]]; do
    
      FIRSTCHAR="${line:0:1}"
      if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then
        addItem $line
        echo ""
      fi
      
    done < "$DDNS_FILE"
    
  done


fxTitle "🛡️ Current status"
iptables -nL

fxEndFooter

