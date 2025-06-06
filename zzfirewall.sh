#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🔥🧱 zzfirewall 🧱🔥"
rootCheck
fxConfigLoader

fxTitle "📦 Checking packages...."
if [ -z "$(command -v curl)" ] || [ -z "$(command -v iptables)" ] || [ -z "$(command -v ipset)" ]; then

  fxMessage "Installing packages..."
  apt update
  apt install iptables ipset curl -y
  
else

  fxMessage "✔ iptables and ipset are already installed"
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


fxTitle "⏬ Downloading combined IP white list..."
IP_WHITELIST_FULLPATH=${DOWNLOADED_LIST_DIR}autogen-whitelist.txt
curl -Lo "${IP_WHITELIST_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/autogen/whitelist.txt
fxExitOnNonZero "$?"
echo "" >> $IP_WHITELIST_FULLPATH

fxTitle "⏬ Appending https://github.com/TurboLabIt/zzfirewall/blob/main/lists/whitelist.txt ..."
curl https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/whitelist.txt >> $IP_WHITELIST_FULLPATH
fxExitOnNonZero "$?"
echo "" >> $IP_WHITELIST_FULLPATH

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

if [ "${ALLOW_GOOGLE_CLOUD}" != 1 ]; then

  fxTitle "⏬ Appending Google Cloud IP list..."
  echo "## https://github.com/TurboLabIt/zzfirewall/blob/main/lists/autogen/google-cloud.txt" >> $IP_BLACKLIST_FULLPATH
  curl https://raw.githubusercontent.com/TurboLabIt/zzfirewall/refs/heads/main/lists/autogen/google-cloud.txt >> $IP_BLACKLIST_FULLPATH
  fxExitOnNonZero "$?"
  echo "" >> $IP_BLACKLIST_FULLPATH
fi

if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_ARAB} != 0 ]; then

  fxTitle "⏬ Downloading 🇦🇪 Arab IP list..."
  IP_BLACKLIST_ARAB_FULLPATH=${DOWNLOADED_LIST_DIR}geos-arab.txt
  curl -Lo "${IP_BLACKLIST_ARAB_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/arab.txt
fi


if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_CHINA} != 0 ]; then

  fxTitle "⏬ Downloading 🇨🇳 China IP list..."
  IP_BLACKLIST_CHINA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-china.txt
  curl -Lo "${IP_BLACKLIST_CHINA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/china.txt
fi


if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_INDIA} != 0 ]; then

  fxTitle "⏬ Downloading 🇮🇳 India IP list..."
  IP_BLACKLIST_INDIA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-india.txt
  curl -Lo "${IP_BLACKLIST_INDIA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/india.txt
fi


if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_KOREA} != 0 ]; then

  fxTitle "⏬ Downloading 🇰🇷 Korea IP list..."
  IP_BLACKLIST_KOREA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-korea.txt
  curl -Lo "${IP_BLACKLIST_KOREA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/korea.txt
fi


if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_RUSSIA} != 0 ]; then

  fxTitle "⏬ Downloading 🇷🇺 Russia IP list..."
  IP_BLACKLIST_RUSSIA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-russia.txt
  curl -Lo "${IP_BLACKLIST_RUSSIA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/russia.txt
fi


if [ "${GEOBLOCK}" != 0 ] && [ ${GEOBLOCK_SOUTH_AMERICA} != 0 ]; then

  fxTitle "⏬ Downloading 🇧🇷 South America IP list..."
  IP_BLACKLIST_SOUTH_AMERICA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-south-america.txt
  curl -Lo "${IP_BLACKLIST_SOUTH_AMERICA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/south-america.txt
fi


bash ${SCRIPT_DIR}zzfirewall-reset.sh


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
      ipset add $1 $line
    fi
  done < "$2"
}


function insertBeforeIpsetRules()
{
  fxTitle "🚪Insert pre-ipset rules"

  MSG="🏡 Allow from loopback"
  fxMessage "$MSG"
  iptables -A INPUT -i lo -j ACCEPT -m comment --comment "$MSG (zzfw)"

  MSG="🎅 Drop XMAS packets"
  fxMessage "$MSG"
  iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP -m comment --comment "$MSG (zzfw)"

  MSG="💩 Drop null packets"
  fxMessage "$MSG"
  iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP -m comment --comment "$MSG (zzfw)"

  if [ "${ALLOW_FROM_LAN}" = 1 ]; then

    MSG="🏡 Allow connections from LAN"
    fxMessage "$MSG"
    iptables -A INPUT -s 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  ## https://serverfault.com/q/1128226/188704
  # Keep this before the blocklists, otherwise the system can't connect out to blocked addresses (e.g.: Google Cloud)
  MSG="📤 Allow EST,REL"
  fxMessage "$MSG"
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "$MSG (zzfw)"
}


function insertAfterIpsetRules()
{
  fxTitle "🚪Insert post-ipset rules"
  
  ## keep this as high as possible, so that we traverse less rules on access
  if [ "${ALLOW_WEBSERVER}" != 0 ]; then
  
    MSG="🌎 Allow HTTP/HTTPS"
    fxMessage "$MSG"
    iptables -A INPUT -p tcp -m multiport --dport 80,443 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  if [ "${ALLOW_WEBSERVER_FROM_WHITELIST}" != 0 ]; then

    MSG="👐 HTTP(s) whitelist ipset"
    fxMessage "$MSG"
    iptables -A INPUT -p tcp -m multiport --dport 80,443 -m set --match-set zzfw_Whitelist src -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  if [ "${ALLOW_SECURE_IMAP}" != 0 ]; then

    MSG="📧 Allow secure IMAP over TLS/SSL"
    fxMessage "$MSG"
    iptables -A INPUT -p tcp -m multiport --dport 993 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  if [ "${ALLOW_SECURE_POP3}" != 0 ]; then

    MSG="📧 Allow secure POP3 over TLS/SSL"
    fxMessage "$MSG"
    iptables -A INPUT -p tcp -m multiport --dport 995 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  MSG="🐧 Allow SSH"
  fxMessage "$MSG"
  iptables -A INPUT -p tcp --dport 22 -j ACCEPT -m comment --comment "$MSG (zzfw)"

  if [ "${ALLOW_FTP}" != 0 ]; then

    MSG="📁 Allow FTP"
    fxMessage "$MSG"
    iptables -A INPUT -p tcp -m multiport --dport 20,21,990,2121:2221 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi

  if [ "${ALLOW_SMTP}" != 0 ]; then
  
    MSG="💌 Allow SMTP"
    fxMessage "$MSG"
    iptables -A INPUT -p tcp --dport 25 -j ACCEPT -m comment --comment "$MSG (zzfw)"
  fi
  
  if [ ! -z "${PRE_DROP_SCRIPT}" ]; then
  
    fxTitle "💨 Running ${PRE_DROP_SCRIPT}..."
    bash "$PRE_DROP_SCRIPT"
  fi
  
  MSG="🏓 Allow ICMP (ping)"
  fxMessage "$MSG"
  iptables -A INPUT -p icmp -j ACCEPT -m comment --comment "$MSG (zzfw)"

  MSG="🛑 Drop everything else"
  fxTitle "$MSG"
  iptables -A INPUT -j DROP -m comment --comment "$MSG (zzfw)"
}


createIpSet zzfw_Whitelist "$IP_WHITELIST_FULLPATH"

## the server must be protected while we build the ipsets
insertBeforeIpsetRules
insertAfterIpsetRules

fxTitle "🧱 Current status"
iptables -nL

createIpSet zzfw_Blacklist "$IP_BLACKLIST_FULLPATH"
createIpSet zzfw_GeoArab "$IP_BLACKLIST_ARAB_FULLPATH"
createIpSet zzfw_GeoChina "$IP_BLACKLIST_CHINA_FULLPATH"
createIpSet zzfw_GeoIndia "$IP_BLACKLIST_INDIA_FULLPATH"
createIpSet zzfw_GeoKorea "$IP_BLACKLIST_KOREA_FULLPATH"
createIpSet zzfw_GeoRussia "$IP_BLACKLIST_RUSSIA_FULLPATH"
createIpSet zzfw_GeoSouthAmerica "$IP_BLACKLIST_SOUTH_AMERICA_FULLPATH"


fxTitle "🧹 Delete the temp folder..."
rm -rf $DOWNLOADED_LIST_DIR

bash ${SCRIPT_DIR}zzfirewall-reset.sh light
insertBeforeIpsetRules


fxTitle "🚪Insert ipset rules"
fxMessage "🛑 Enable ipset zzfw_Blacklist..."
iptables -A INPUT -m set --match-set zzfw_Blacklist src -j DROP

function addDropRule()
{
  if [ "${GEOBLOCK}" = 0 ] || [ "${2}" = 0 ]; then
    return 0
  fi

  fxMessage "🛑 Enable ipset ${1}..."
  iptables -A INPUT -m set --match-set ${1} src -j DROP
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
  
  fxMessage "pure-ftpd found! Updating PassivePortRange..."
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

  fxMessage "pure-ftpd not found. No PassivePortRange update"
fi

fxTitle "ipset zzfw_Blacklist"
ipset list zzfw_Blacklist | head -n 7
echo "...."

function printIpSet()
{
  if [ "${GEOBLOCK}" = 0 ] || [ "${2}" = 0 ]; then
    return 0
  fi

  fxTitle "ipset $1"
  ipset list $1 | head -n 7
  echo "...."
}


printIpSet zzfw_GeoArab "${GEOBLOCK_ARAB}"
printIpSet zzfw_GeoChina "${GEOBLOCK_CHINA}"
printIpSet zzfw_GeoIndia "${GEOBLOCK_INDIA}"
printIpSet zzfw_GeoKorea "${GEOBLOCK_KOREA}"
printIpSet zzfw_GeoRussia "${GEOBLOCK_RUSSIA}"
printIpSet zzfw_GeoSouthAmerica "${GEOBLOCK_SOUTH_AMERICA}"


fxTitle "🧱 Current status"
iptables -nL

fxTitle "Need the log?"
fxMessage "nano ${IP_LOG_FILE}"

fxEndFooter
