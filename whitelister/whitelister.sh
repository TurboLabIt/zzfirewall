#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🛡️🧱 zzfirewall whitelister 🧱🛡️"
rootCheck
fxConfigLoader


compgen -G "/etc/turbolab.it/zzfirewall-whitelist*" > /dev/null
ONE_WHITELIST_EXISTS=$?

if [ "$ONE_WHITELIST_EXISTS" != 0 ]; then

  fxCatastrophicError "⚠️ No whitelist(s) found"
  fxEndFooter failure
  exit
fi

if [ -z "$(command -v dig)" ]; then

  sudo apt update
  sudo apt install dnsutils -y
fi

fxTitle "Testing domains resolution..."
IP_ADDRESS=$(dig +short @8.8.8.8 google.com | tail -1)

if [ -z "$IP_ADDRESS" ]; then
  fxCatastrophicError "⚠️ DNS resolution failed"
  fxEndFooter failure
  exit
fi


CHAIN_NAME="ZZFIREWALL_WHITELISTER"
CHAIN_REFERENCE_COMMENT="(zzfw)"
MAIN_CHAIN_NAME="ZZFIREWALL"

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
    local TIMESTAMP=$(date +"%F %T")
    local IP_ADDRESS=$(dig +short @8.8.8.8 "$ITEM" | tail -1)

    if [ -z "$IP_ADDRESS" ]; then
      fxCatastrophicError "⚠️ Failed" "proceed"
      return 255
    fi
   
    local RULE_COMMENT="🪪 $ITEM || $TIMESTAMP"
  
  else
  
    local IP_ADDRESS=$ITEM
    local RULE_COMMENT="🧭 $ITEM"
  fi
 

  echo "Adding $IP_ADDRESS to the chain..."
  iptables -A "$CHAIN_NAME" -s "$IP_ADDRESS" -j ACCEPT -m comment --comment "$RULE_COMMENT (zzfw)"
}


for WHITELIST_FILE in /etc/turbolab.it/zzfirewall-whitelist*
  do

    fxTitle "📋 ${WHITELIST_FILE}"
    
    while read -r line || [[ -n "$line" ]]; do
    
      FIRSTCHAR="${line:0:1}"
      if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then
        addItem $line
        echo ""
      fi
      
    done < "$WHITELIST_FILE"
    
  done


fxIptablesCheckEmptyChain "$CHAIN_NAME"
EMPTY_WHITELISTER=$?

if [ "$EMPTY_WHITELISTER" != 0 ]; then
  fxCatastrophicError "⚠️⚠️ No whitelisted clients were added!"
fi

if [ "$EMPTY_WHITELISTER" != 0 ] && [ "$LIMIT_SSH_TO_WHITELISTED" = 1 ]; then

  fxCatastrophicError "☠️ CANNOT RESTRICT SSH ACCESS BY ORIGIN! ☠️"
  
elif [ "$EMPTY_WHITELISTER" = 0 ] && [ "$LIMIT_SSH_TO_WHITELISTED" = 1 ] ; then

  fxTitle "🛡️ Limiting SSH to whitelisted origins..."
  MSG="🐧 Allow SSH"
  iptables -C "$MAIN_CHAIN_NAME" -p tcp --dport 22 -j ACCEPT -m comment --comment "$MSG (zzfw)" >/dev/null 2>&1
  ALLOW_SSH_RULE_EXISTS=$?

  if [ "$ALLOW_SSH_RULE_EXISTS" = 0 ]; then

    iptables -D "$MAIN_CHAIN_NAME" -p tcp --dport 22 -j ACCEPT -m comment --comment "$MSG (zzfw)"
    fxMessage "🔒 Global \"$MSG\" rule removed"
  else

    fxMessage "✔️ Already limited: no global \"$MSG\" rule in $MAIN_CHAIN_NAME"
  fi
  
elif [ "$EMPTY_WHITELISTER" = 0 ] && [ "$LIMIT_SSH_TO_WHITELISTED" = 0 ] ; then

  fxTitle "❔ No SSH limit by origin requested via config"
  
fi


fxTitle "🛡️ Current status"
iptables -nL

fxEndFooter

