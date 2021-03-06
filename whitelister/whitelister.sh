#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzfirewall
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "๐ก๏ธ๐งฑ zzfirewall whitelister ๐งฑ๐ก๏ธ"
rootCheck


compgen -G "/etc/turbolab.it/zzfirewall-whitelist*" > /dev/null
ONE_WHITELIST_EXISTS=$?

if [ "$ONE_WHITELIST_EXISTS" != 0 ]; then

  fxCatastrophicError "โ ๏ธ No whitelist(s) found"
  fxEndFooter failure
  exit
fi

if [ -z "$(command -v dig)" ]; then
  sudo apt update && sudo apt install dnsutils -y
fi

fxTitle "Testing domains resolution..."
IP_ADDRESS=$(dig +short @8.8.8.8 google.com | tail -1)

if [ -z "$IP_ADDRESS" ]; then
  fxCatastrophicError "โ ๏ธ DNS resolution failed"
  fxEndFooter failure
  exit
fi


CHAIN_NAME="๐_ZZFW_WHITELISTER"
CHAIN_REFERENCE_COMMENT="(zzfw)"

fxIptablesCreateChainIfNotExists "$CHAIN_NAME"

fxTitle "๐ Checking if the iptables chain INPUT refrences $CHAIN_NAME..."
iptables -C INPUT -t filter -j "$CHAIN_NAME" -m comment --comment "$CHAIN_REFERENCE_COMMENT" >/dev/null 2>&1
INPUT_CHAIN_CONTAINS=$?

if [ "$INPUT_CHAIN_CONTAINS" != 0 ]; then

  fxMessage "๐ณ๏ธ No references found. Referencing it now"
  iptables -t filter -I INPUT -j "$CHAIN_NAME" -m comment --comment "$CHAIN_REFERENCE_COMMENT"
  iptables -nL INPUT
else

  fxMessage "โ๏ธ Reference found"
fi


fxTitle "๐งน Clear the $CHAIN_NAME chain..."
iptables -F "$CHAIN_NAME"


function addItem()
{
  local ITEM=$1
  fxMessage "๐ $ITEM"
  
  if [[ "$ITEM" =~ [^0-9\.\/] ]]; then
    
    echo "Resolving..."
    local TIMESTAMP=$(date +"%F %T")
    local IP_ADDRESS=$(dig +short @8.8.8.8 "$ITEM" | tail -1)

    if [ -z "$IP_ADDRESS" ]; then
      fxCatastrophicError "โ ๏ธ Failed"
      return 255
    fi
   
    local RULE_COMMENT="๐ชช $ITEM || $TIMESTAMP"
  
  else
  
    local IP_ADDRESS=$ITEM
    local RULE_COMMENT="๐งญ $ITEM"
  fi
 

  echo "Adding $IP_ADDRESS to the chain..."
  iptables -A "$CHAIN_NAME" -s "$IP_ADDRESS" -j ACCEPT -m comment --comment "$RULE_COMMENT (zzfw)"
}


for WHITELIST_FILE in /etc/turbolab.it/zzfirewall-whitelist*
  do

    fxTitle "๐ ${WHITELIST_FILE}"
    
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
LIMIT_SSH_TO_WHITELISTED=1

if [ "$EMPTY_WHITELISTER" != 0 ]; then
  fxCatastrophicError "โ ๏ธโ ๏ธ No whitelisted clients were added!"
fi

if [ "$EMPTY_WHITELISTER" != 0 ] && [ "$LIMIT_SSH_TO_WHITELISTED" = 1 ]; then

  fxCatastrophicError "โ ๏ธ CANNOT RESTRICT SSH ACCESS BY ORIGIN! โ ๏ธ"
  
elif [ "$EMPTY_WHITELISTER" = 0 ] && [ "$LIMIT_SSH_TO_WHITELISTED" = 1 ] ; then

  fxTitle "๐ก๏ธ Limiting SSH to whitelisted origins..."
  MSG="๐ง Allow SSH"
  iptables -D INPUT -p tcp --dport 22 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  
elif [ "$EMPTY_WHITELISTER" = 0 ] && [ "$LIMIT_SSH_TO_WHITELISTED" = 0 ] ; then

  fxTitle "โ No SSH limit by origin requested via config"
  
fi


fxTitle "๐ก๏ธ Current status"
iptables -nL

fxEndFooter

