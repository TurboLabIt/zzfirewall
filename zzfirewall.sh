#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🔥🧱 zzfirewall 🧱🔥"
rootCheck
fxConfigLoader

## exported so that PRE_DROP_SCRIPT can add its custom rules to the zzfirewall chain
export ZZFW_CHAIN=ZZFIREWALL

fxTitle "📦 Checking packages...."
if [ -z "$(command -v curl)" ] || [ -z "$(command -v iptables)" ] || [ -z "$(command -v ipset)" ]; then

  fxInfo "Installing packages..."
  apt update
  apt install iptables ipset curl -y

else

  fxOK "iptables and ipset are already installed"
fi

fxTitle "🧹 Removing ufw, iptables-persistent..."
if dpkg -s ufw >/dev/null 2>&1 || dpkg -s iptables-persistent >/dev/null 2>&1; then
  apt purge ufw iptables-persistent -y
else
  fxInfo "Not installed, skipping"
fi


fxTitle "🧹 Clear the log file..."
LOG_DIR="/var/log/turbolab.it/"
mkdir -p "${LOG_DIR}"
IP_LOG_FILE=${LOG_DIR}zzfirewall.log
date +"%Y-%m-%d %T" > "${IP_LOG_FILE}"


fxTitle "📂 Creating a temp folder to download into..."
DOWNLOADED_LIST_DIR=/tmp/zzfirewall/
rm -rf $DOWNLOADED_LIST_DIR
mkdir -p $DOWNLOADED_LIST_DIR


fxTitle "🤝 Disable nf_conntrack_tcp_loose"
## https://serverfault.com/a/1128235
if [ "${DISABLE_TCP_LOOSE_CONN}" != 0 ]; then
  sysctl -w net.netfilter.nf_conntrack_tcp_loose=0
else
  fxInfo "Disabled in config, skipping"
fi


###################
# 🟢 WHITELISTS 🟢 #
###################
fxTitle "⏬ Downloading combined IP white list..."
IP_WHITELIST_FULLPATH=${DOWNLOADED_LIST_DIR}autogen-whitelist.txt
curl -Lo "${IP_WHITELIST_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/autogen/whitelist.txt
fxExitOnNonZero "$?"
echo "" >> $IP_WHITELIST_FULLPATH

fxTitle "⏬ Appending https://github.com/TurboLabIt/zzfirewall/blob/main/lists/whitelist.txt ..."
curl https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/whitelist.txt >> $IP_WHITELIST_FULLPATH
fxExitOnNonZero "$?"
echo "" >> $IP_WHITELIST_FULLPATH

fxTitle "⏬ Downloading Google IP list (complete)..."
DOWNLOADED_FILE_IPLIST_GOOGLE_ALL=${DOWNLOADED_LIST_DIR}google.txt
curl -Lo "${DOWNLOADED_FILE_IPLIST_GOOGLE_ALL}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/refs/heads/main/lists/autogen/google.txt

IFS=',' read -ra GEOALLOW_WEB_COUNTRIES_ARRAY <<< "$GEOALLOW_WEB_COUNTRIES"
for GEOALLOW_COUNTRY in "${GEOALLOW_WEB_COUNTRIES_ARRAY[@]}"; do

  GEOALLOW_COUNTRY=$(echo "$GEOALLOW_COUNTRY" | xargs)
  if [ -n "$GEOALLOW_COUNTRY" ]; then
    fxTitle "⏬ Downloading ${GEOALLOW_COUNTRY} IP list for geo-allow..."
    curl -Lo "${DOWNLOADED_LIST_DIR}geoallow-${GEOALLOW_COUNTRY}.txt" "https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/${GEOALLOW_COUNTRY}.txt"
  fi
done


####################
# 🔴 BLACKLISTS 🔴 #
####################
fxTitle "⏬ Downloading combined IP blacklist..."
IP_BLACKLIST_FULLPATH=${DOWNLOADED_LIST_DIR}autogen-blacklist.txt
curl -Lo "${IP_BLACKLIST_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/autogen/blacklist.txt
fxExitOnNonZero "$?"
echo "" >> $IP_BLACKLIST_FULLPATH

fxTitle "⏬ Appending https://github.com/TurboLabIt/zzfirewall/blob/main/lists/blacklist.txt ..."
echo "## https://github.com/TurboLabIt/zzfirewall/blob/main/lists/blacklist.txt" >> $IP_BLACKLIST_FULLPATH
curl https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/blacklist.txt >> $IP_BLACKLIST_FULLPATH
fxExitOnNonZero "$?"
echo "" >> $IP_BLACKLIST_FULLPATH

fxTitle "⏬ Appending http://iplists.firehol.org/ ..."
echo "## http://iplists.firehol.org/" >> $IP_BLACKLIST_FULLPATH
curl https://raw.githubusercontent.com/ktsaou/blocklist-ipsets/master/firehol_level1.netset >> $IP_BLACKLIST_FULLPATH
fxExitOnNonZero "$?"
echo "" >> $IP_BLACKLIST_FULLPATH

fxTitle "⏬ Appending https://github.com/stamparm/ipsum ..."
echo "## https://github.com/stamparm/ipsum" >> $IP_BLACKLIST_FULLPATH
curl --compressed https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1 >> $IP_BLACKLIST_FULLPATH

DOWNLOADED_FILE_IPLIST_GOOGLE_CLOUD=${DOWNLOADED_LIST_DIR}google-cloud.txt
if [ "${ALLOW_GOOGLE_CLOUD}" != 1 ]; then

  fxTitle "⏬ Downloading Google Cloud IP list..."
  curl -Lo "${DOWNLOADED_FILE_IPLIST_GOOGLE_CLOUD}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/refs/heads/main/lists/autogen/google-cloud.txt
fi

## always downloaded: the zzfw_Claude ipset is used both by ALLOW_CLAUDE=1 (ACCEPT) and ALLOW_CLAUDE=0 (DROP)
fxTitle "⏬ Downloading Claude (Anthropic) IP list..."
DOWNLOADED_FILE_IPLIST_CLAUDE=${DOWNLOADED_LIST_DIR}claude.txt
curl -Lo "${DOWNLOADED_FILE_IPLIST_CLAUDE}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/refs/heads/main/lists/autogen/claude.txt


##################
# 🔴 GEOBLOCK 🔴 #
##################
DOWNLOADED_FILE_IPLIST_GEO_ARAB=${DOWNLOADED_LIST_DIR}geos-arab.txt
if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_ARAB} != 0 ]; then

  fxTitle "⏬ Downloading 🇦🇪 Arab IP list..."
  curl -Lo "${DOWNLOADED_FILE_IPLIST_GEO_ARAB}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/arab.txt
fi

DOWNLOADED_FILE_IPLIST_GEO_CHINA=${DOWNLOADED_LIST_DIR}geos-china.txt
if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_CHINA} != 0 ]; then

  fxTitle "⏬ Downloading 🇨🇳 China IP list..."
  curl -Lo "${DOWNLOADED_FILE_IPLIST_GEO_CHINA}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/china.txt
fi

DOWNLOADED_FILE_IPLIST_GEO_INDIA=${DOWNLOADED_LIST_DIR}geos-india.txt
if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_INDIA} != 0 ]; then

  fxTitle "⏬ Downloading 🇮🇳 India IP list..."
  curl -Lo "${DOWNLOADED_FILE_IPLIST_GEO_INDIA}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/india.txt
fi

DOWNLOADED_FILE_IPLIST_GEO_KOREA=${DOWNLOADED_LIST_DIR}geos-korea.txt
if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_KOREA} != 0 ]; then

  fxTitle "⏬ Downloading 🇰🇷 Korea IP list..."
  curl -Lo "${DOWNLOADED_FILE_IPLIST_GEO_KOREA}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/korea.txt
fi

DOWNLOADED_FILE_IPLIST_GEO_RUSSIA=${DOWNLOADED_LIST_DIR}geos-russia.txt
if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_RUSSIA} != 0 ]; then

  fxTitle "⏬ Downloading 🇷🇺 Russia IP list..."
  curl -Lo "${DOWNLOADED_FILE_IPLIST_GEO_RUSSIA}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/russia.txt
fi

DOWNLOADED_FILE_IPLIST_GEO_SOUTH_AMERICA=${DOWNLOADED_LIST_DIR}geos-south-america.txt
if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_SOUTH_AMERICA} != 0 ]; then

  fxTitle "⏬ Downloading 🇧🇷 South America IP list..."
  curl -Lo "${DOWNLOADED_FILE_IPLIST_GEO_SOUTH_AMERICA}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/south-america.txt
fi


function zzfwReset()
{
  fxTitle "❤️‍🩹 Reset the ${ZZFW_CHAIN} chain..."

  fxIptablesCreateChainIfNotExists "$ZZFW_CHAIN" silent

  iptables -C INPUT -j "$ZZFW_CHAIN" -m comment --comment "(zzfw)" >/dev/null 2>&1
  INPUT_CHAIN_CONTAINS=$?

  if [ "$INPUT_CHAIN_CONTAINS" != 0 ]; then

    fxInfo "🔗 Hooking ${ZZFW_CHAIN} to INPUT"
    iptables -A INPUT -j "$ZZFW_CHAIN" -m comment --comment "(zzfw)"
  fi

  iptables -P INPUT ACCEPT
  iptables -F "$ZZFW_CHAIN"
}


function zzfwFlushIpsets()
{
  fxTitle "🧹 Flush every zzfw_* ipset..."

  local SET_NAME
  for SET_NAME in $(ipset list -n | grep '^zzfw_'); do
    fxInfo "🧹 ${SET_NAME}"
    ipset flush "$SET_NAME"
  done
}


zzfwReset
zzfwFlushIpsets


function createIpSet()
{
  if [ ! -f "$2" ]; then
    return 0
  fi

  fxTitle "🧱 Building ipset $1 from file..."
  ipset create $1 nethash -exist hashsize 65536 maxelem 200000
  while read -r line || [[ -n "$line" ]]; do
    local FIRSTCHAR="${line:0:1}"
    if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then
      echo "Add: $line" >> "${IP_LOG_FILE}"
      ipset add $1 $line -exist
    fi
  done < "$2"
}


function insertBeforeIpsetRules()
{
  fxTitle "🚪Insert pre-ipset rules"

  MSG="🏡 Allow from loopback"
  echo "$MSG"
  iptables -A "$ZZFW_CHAIN" -i lo -j ACCEPT -m comment --comment "$MSG (zzfw)"

  MSG="🎅 Drop XMAS packets"
  echo "$MSG"
  iptables -A "$ZZFW_CHAIN" -p tcp --tcp-flags ALL ALL -j DROP -m comment --comment "$MSG (zzfw)"

  MSG="💩 Drop null packets"
  echo "$MSG"
  iptables -A "$ZZFW_CHAIN" -p tcp --tcp-flags ALL NONE -j DROP -m comment --comment "$MSG (zzfw)"

  if [ "${ALLOW_FROM_LAN}" = 1 ]; then

    MSG="🏡 Allow connections from LAN"
    echo "$MSG"
    iptables -A "$ZZFW_CHAIN" -s 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  ## https://serverfault.com/q/1128226/188704
  # Keep this before the blocklists, otherwise the system can't connect out to blocked addresses (e.g.: Google Cloud)
  MSG="📤 Allow EST,REL"
  echo "$MSG"
  iptables -A "$ZZFW_CHAIN" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "$MSG (zzfw)"

  if [ "${ALLOW_WEBSERVER_FROM_WHITELIST}" != 0 ]; then

    MSG="👐 HTTP(s) whitelist ipset"
    echo "$MSG"
    iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 80,443 -m set --match-set zzfw_Whitelist src -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi
}


function insertAfterIpsetRules()
{
  fxTitle "🚪Insert post-ipset rules"
  
  ## keep this as high as possible, so that we traverse less rules on access
  if [ "${ALLOW_WEBSERVER}" != 0 ]; then

    MSG="🌎 Allow HTTP/HTTPS"
    echo "$MSG"
    iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 80,443 -j ACCEPT -m comment --comment "$MSG (zzfw)"

  else

    ## allow access from specific countries even when ALLOW_WEBSERVER=0
    for GEOALLOW_COUNTRY in "${GEOALLOW_WEB_COUNTRIES_ARRAY[@]}"; do
      GEOALLOW_COUNTRY=$(echo "$GEOALLOW_COUNTRY" | xargs)
      if [ -n "$GEOALLOW_COUNTRY" ]; then
        MSG="🌍 Allow HTTP/HTTPS from ${GEOALLOW_COUNTRY}"
        echo "$MSG"
        iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 80,443 -m set --match-set "zzfw_GeoAllow_${GEOALLOW_COUNTRY}" src -j ACCEPT -m comment --comment "$MSG (zzfw)"
      fi
    done
  fi

  if [ "${ALLOW_SECURE_IMAP}" != 0 ]; then

    MSG="📧 Allow secure IMAP over TLS/SSL"
    echo "$MSG"
    iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 993 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  if [ "${ALLOW_SECURE_POP3}" != 0 ]; then

    MSG="📧 Allow secure POP3 over TLS/SSL"
    echo "$MSG"
    iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 995 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  MSG="🐧 Allow SSH"
  echo "$MSG"
  iptables -A "$ZZFW_CHAIN" -p tcp --dport 22 -j ACCEPT -m comment --comment "$MSG (zzfw)"

  if [ "${ALLOW_FTP}" != 0 ]; then

    MSG="📁 Allow FTP"
    echo "$MSG"
    iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 20,21,990,2121:2221 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  if [ "${ALLOW_SMTP}" != 0 ]; then
  
    MSG="💌 Allow SMTP"
    echo "$MSG"
    iptables -A "$ZZFW_CHAIN" -p tcp --dport 25 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi
  
  if [ ! -z "${PRE_DROP_SCRIPT}" ]; then
  
    fxTitle "💨 Running ${PRE_DROP_SCRIPT}..."
    ## custom rules must target the exported $ZZFW_CHAIN: rules appended to INPUT would sit below the jump, never reached
    bash "$PRE_DROP_SCRIPT"
  fi
  
  MSG="🏓 Allow ICMP (ping)"
  echo "$MSG"
  iptables -A "$ZZFW_CHAIN" -p icmp -j ACCEPT -m comment --comment "$MSG (zzfw)"

  MSG="🛑 Drop everything else"
  fxTitle "$MSG"
  iptables -A "$ZZFW_CHAIN" -j DROP -m comment --comment "$MSG (zzfw)"
}


createIpSet zzfw_Whitelist "$IP_WHITELIST_FULLPATH"
## the server must be protected while we build the ipsets
insertBeforeIpsetRules
for GEOALLOW_COUNTRY in "${GEOALLOW_WEB_COUNTRIES_ARRAY[@]}"; do
  GEOALLOW_COUNTRY=$(echo "$GEOALLOW_COUNTRY" | xargs)
  if [ -n "$GEOALLOW_COUNTRY" ]; then
    createIpSet "zzfw_GeoAllow_${GEOALLOW_COUNTRY}" "${DOWNLOADED_LIST_DIR}geoallow-${GEOALLOW_COUNTRY}.txt"
  fi
done
insertAfterIpsetRules

fxTitle "🧱 Intermediate status alpha"
iptables -nL


createIpSet zzfw_Blacklist "$IP_BLACKLIST_FULLPATH"
createIpSet zzfw_GoogleCloud "$DOWNLOADED_FILE_IPLIST_GOOGLE_CLOUD"
createIpSet zzfw_GoogleAll "$DOWNLOADED_FILE_IPLIST_GOOGLE_ALL"
createIpSet zzfw_Claude "$DOWNLOADED_FILE_IPLIST_CLAUDE"

createIpSet zzfw_GeoArab "$DOWNLOADED_FILE_IPLIST_GEO_ARAB"
createIpSet zzfw_GeoChina "$DOWNLOADED_FILE_IPLIST_GEO_CHINA"
createIpSet zzfw_GeoIndia "$DOWNLOADED_FILE_IPLIST_GEO_INDIA"
createIpSet zzfw_GeoKorea "$DOWNLOADED_FILE_IPLIST_GEO_KOREA"
createIpSet zzfw_GeoRussia "$DOWNLOADED_FILE_IPLIST_GEO_RUSSIA"
createIpSet zzfw_GeoSouthAmerica "$DOWNLOADED_FILE_IPLIST_GEO_SOUTH_AMERICA"


fxTitle "🧹 Delete the temp folder..."
rm -rf $DOWNLOADED_LIST_DIR

zzfwReset
insertBeforeIpsetRules


## keep zzfw_Claude before zzfw_Blacklist (ALLOW_CLAUDE=1 must win even if a Claude IP gets blacklisted)
## and before the Google rules (most Claude IPs fall inside Google Cloud ranges, so a later rule
## would be shadowed by zzfw_GoogleCloud (DROP) / zzfw_GoogleAll (ACCEPT))
if [ "${ALLOW_CLAUDE}" = 1 ]; then

  CLAUDE_BURST=$(( CLAUDE_MAX_CONN_PER_SEC * 2 ))

  fxTitle "🟢 Enable ipset zzfw_Claude (HTTP/HTTPS only, ${CLAUDE_MAX_CONN_PER_SEC} new conn/s, ${CLAUDE_BURST} concurrent)..."

  ## both limits are aggregate: they apply to all the Claude IPs combined, not to each IP
  iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 80,443 -m set --match-set zzfw_Claude src \
    -m conntrack --ctstate NEW -m connlimit --connlimit-above ${CLAUDE_BURST} --connlimit-mask 0 \
    -j DROP -m comment --comment "🛑 Claude, ${CLAUDE_BURST}+ concurrent conn (zzfw)"

  ## --ctstate NEW: only new connections count against the limit (established traffic is accepted earlier in the chain)
  iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 80,443 -m set --match-set zzfw_Claude src \
    -m conntrack --ctstate NEW -m limit --limit ${CLAUDE_MAX_CONN_PER_SEC}/second --limit-burst ${CLAUDE_BURST} \
    -j ACCEPT -m comment --comment "🟢 Claude, max ${CLAUDE_MAX_CONN_PER_SEC} conn/s (zzfw)"

  ## over-limit traffic must be dropped here: if it fell through, 216.73.216.0/22 (not a Google Cloud IP)
  ## would reach the ALLOW_WEBSERVER ACCEPT, defeating the limits
  iptables -A "$ZZFW_CHAIN" -m set --match-set zzfw_Claude src -j DROP -m comment --comment "🛑 Claude, over-limit (zzfw)"

else

  fxTitle "🛑 Enable ipset zzfw_Claude..."
  iptables -A "$ZZFW_CHAIN" -m set --match-set zzfw_Claude src -j DROP -m comment --comment "🛑 Claude (zzfw)"
fi

fxTitle "🛑 Enable ipset zzfw_Blacklist..."
iptables -A "$ZZFW_CHAIN" -m set --match-set zzfw_Blacklist src -j DROP -m comment --comment "🛑 Blacklist (zzfw)"

if [ "${ALLOW_GOOGLE_CLOUD}" != 1 ]; then

  fxTitle "🛑 Enable ipset zzfw_GoogleCloud..."
  iptables -A "$ZZFW_CHAIN" -m set --match-set zzfw_GoogleCloud src -j DROP -m comment --comment "🛑 Google Cloud (zzfw)"
fi

fxTitle "🟢 Enable ipset zzfw_Google..."
iptables -A "$ZZFW_CHAIN" -p tcp -m multiport --dport 80,443 -m set --match-set zzfw_GoogleAll src -j ACCEPT -m comment --comment "🟢 Google (zzfw)"


function addDropRule()
{
  if [ "${GEOBLOCK}" = 0 ] || [ "${2}" = 0 ]; then
    return 0
  fi

  echo "🛑 Enable ipset ${1}..."
  iptables -A "$ZZFW_CHAIN" -m set --match-set ${1} src -j DROP -m comment --comment "🛑 ${1} (zzfw)"
}

addDropRule zzfw_GeoArab "${GEOBLOCK_ARAB}"
addDropRule zzfw_GeoChina "${GEOBLOCK_CHINA}"
addDropRule zzfw_GeoIndia "${GEOBLOCK_INDIA}"
addDropRule zzfw_GeoKorea "${GEOBLOCK_KOREA}"
addDropRule zzfw_GeoRussia "${GEOBLOCK_RUSSIA}"
addDropRule zzfw_GeoSouthAmerica "${GEOBLOCK_SOUTH_AMERICA}"

insertAfterIpsetRules

bash "${SCRIPT_DIR}whitelister/whitelister.sh"


fxTitle "🍃 Looking for pure-ftpd..."
if [ -d /etc/pure-ftpd/conf/ ]; then
  
  fxOK "pure-ftpd found! Updating PassivePortRange..."
  rm -f /etc/pure-ftpd/conf/PassivePortRange
  
  if [ -f "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PassivePortRange" ]; then
  
    ln -s "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PassivePortRange" "/etc/pure-ftpd/conf/PassivePortRange"

  else
  
    curl -o "/etc/pure-ftpd/conf/PassivePortRange" https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/pure-ftpd/PassivePortRange
  fi
  
  ls -la /etc/pure-ftpd/conf/
  cat /etc/pure-ftpd/conf/PassivePortRange
  service pure-ftpd restart
  
else

  fxInfo "pure-ftpd not found. No PassivePortRange update"
fi


fxTitle "🧱🧱🧱 FINAL FIREWALL STATUS 🧱🧱🧱"
iptables -nL

fxTitle "Need the log?"
fxMessage "nano ${IP_LOG_FILE}"

fxEndFooter
