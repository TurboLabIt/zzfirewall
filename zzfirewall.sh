#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🛡️🧱 zzfirewall 🧱🛡️"
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


fxTitle "⏬ Downloading combined IP white list..."
IP_WHITELIST_FULLPATH=${DOWNLOADED_LIST_DIR}autogen-whitelist.txt
curl -Lo "${IP_WHITELIST_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/autogen/whitelist.txt?$(date +%s)
fxExitOnNonZero "$?"
echo "" >> $IP_WHITELIST_FULLPATH

fxTitle "⏬ Appending https://github.com/TurboLabIt/zzfirewall/blob/main/lists/whitelist.txt ..."
curl https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/whitelist.txt?$(date +%s) >> $IP_WHITELIST_FULLPATH
fxExitOnNonZero "$?"
echo "" >> $IP_WHITELIST_FULLPATH

fxTitle "⏬ Downloading combined IP black list..."
IP_BLACKLIST_FULLPATH=${DOWNLOADED_LIST_DIR}autogen-blacklist.txt
curl -Lo "${IP_BLACKLIST_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/autogen/blacklist.txt?$(date +%s)
fxExitOnNonZero "$?"
echo "" >> $IP_BLACKLIST_FULLPATH

fxTitle "⏬ Appending https://github.com/TurboLabIt/zzfirewall/blob/main/lists/blacklist.txt ..."
echo "## https://github.com/TurboLabIt/zzfirewall/blob/main/lists/blacklist.txt" >> $IP_BLACKLIST_FULLPATH
curl https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/blacklist.txt?$(date +%s) >> $IP_BLACKLIST_FULLPATH
fxExitOnNonZero "$?"
echo "" >> $IP_BLACKLIST_FULLPATH

fxTitle "⏬ Appending http://iplists.firehol.org/ ..."
echo "## http://iplists.firehol.org/" >> $IP_BLACKLIST_FULLPATH
curl https://raw.githubusercontent.com/ktsaou/blocklist-ipsets/master/firehol_level1.netset?$(date +%s) >> $IP_BLACKLIST_FULLPATH
fxExitOnNonZero "$?"
echo "" >> $IP_BLACKLIST_FULLPATH

fxTitle "⏬ Appending https://github.com/stamparm/ipsum ..."
echo "## https://github.com/stamparm/ipsum" >> $IP_BLACKLIST_FULLPATH
curl --compressed https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt?$(date +%s) 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1 >> $IP_BLACKLIST_FULLPATH


fxTitle "⏬ Downloading Arab IP list..."
IP_BLACKLIST_ARAB_FULLPATH=${DOWNLOADED_LIST_DIR}geos-arab.txt
curl -Lo "${IP_BLACKLIST_ARAB_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/arab.txt?$(date +%s)

fxTitle "⏬ Downloading China IP list..."
IP_BLACKLIST_CHINA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-china.txt
curl -Lo "${IP_BLACKLIST_CHINA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/china.txt?$(date +%s)

fxTitle "⏬ Downloading India IP list..."
IP_BLACKLIST_INDIA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-india.txt
curl -Lo "${IP_BLACKLIST_INDIA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/india.txt?$(date +%s)

fxTitle "⏬ Downloading Korea IP list..."
IP_BLACKLIST_KOREA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-korea.txt
curl -Lo "${IP_BLACKLIST_KOREA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/korea.txt?$(date +%s)

fxTitle "⏬ Downloading Russia IP list..."
IP_BLACKLIST_RUSSIA_FULLPATH=${DOWNLOADED_LIST_DIR}geos-russia.txt
curl -Lo "${IP_BLACKLIST_RUSSIA_FULLPATH}" https://raw.githubusercontent.com/TurboLabIt/zzfirewall/main/lists/geos/russia.txt?$(date +%s)

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

  MSG="📤 Allow EST,REL"
  fxMessage "$MSG"
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "$MSG (zzfw)"

  MSG="🏡 Allow connections from LAN"
  fxMessage "$MSG"
  iptables -A INPUT -s 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j ACCEPT -m comment --comment "$MSG (zzfw)"
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
    echo "$PRE_DROP_SCRIPT"
  fi

  MSG="🛑 Drop everything else"
  fxMessage "$MSG"
  iptables -A INPUT -j DROP -m comment --comment "$MSG (zzfw)"
}


bash ${SCRIPT_DIR}zzfirewall-reset.sh

## the server must be protected while we build the ipsets
insertBeforeIpsetRules
insertAfterIpsetRules


function createIpSet()
{
  fxTitle "🧱 Building ipset $1 from file..."
  ipset create $1 nethash -exist
  while read -r line || [[ -n "$line" ]]; do
    local FIRSTCHAR="${line:0:1}"
    if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then
      echo "Add: $line" >> "${IP_LOG_FILE}"
      ipset add $1 $line
    fi  
  done < "$2"
}

createIpSet zzfw_Whitelist "$IP_WHITELIST_FULLPATH"
createIpSet zzfw_Blacklist "$IP_BLACKLIST_FULLPATH"
createIpSet zzfw_GeoArab "$IP_BLACKLIST_ARAB_FULLPATH"
createIpSet zzfw_GeoChina "$IP_BLACKLIST_CHINA_FULLPATH"
createIpSet zzfw_GeoIndia "$IP_BLACKLIST_INDIA_FULLPATH"
createIpSet zzfw_GeoKorea "$IP_BLACKLIST_KOREA_FULLPATH"
createIpSet zzfw_GeoRussia "$IP_BLACKLIST_RUSSIA_FULLPATH"

fxTitle "🧹 Delete the temp folder..."
rm -rf $DOWNLOADED_LIST_DIR


function addDropRule()
{
  fxMessage "🛑 Enable ipset ${1}..."
  iptables -A INPUT -m set --match-set ${1} src -j DROP
}


bash ${SCRIPT_DIR}zzfirewall-reset.sh light

insertBeforeIpsetRules

if [ "${ALLOW_WEBSERVER}" != 0 ]; then

  MSG="👐 whitelist ipset"
  fxTitle "$MSG"
  iptables -A INPUT -p tcp -m multiport --dport 80,443 -m set --match-set zzfw_Whitelist src -j ACCEPT
fi

fxTitle "🚪Insert ipset rules"
addDropRule zzfw_Blacklist
addDropRule zzfw_GeoArab
addDropRule zzfw_GeoChina
addDropRule zzfw_GeoIndia
addDropRule zzfw_GeoKorea
addDropRule zzfw_GeoRussia

insertAfterIpsetRules

bash "${SCRIPT_DIR}whitelister/whitelister.sh"


fxTitle "🍃 Looking for pure-ftpd..."
if [ -d /etc/pure-ftpd/conf/ ]; then
  
  fxMessage "pure-ftpd found! Updating PassivePortRange..."
  rm -f /etc/pure-ftpd/conf/PassivePortRange
  
  if [ -f "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PassivePortRange" ]; then
  
    ln -s "/usr/local/turbolab.it/webstackup/config/pure-ftpd/PassivePortRange" "/etc/pure-ftpd/conf/PassivePortRange"

  else
  
    curl -o "/etc/pure-ftpd/conf/PassivePortRange" https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/pure-ftpd/PassivePortRange?$(date +%s)
    
  fi
  
  ls -la /etc/pure-ftpd/conf/
  cat /etc/pure-ftpd/conf/PassivePortRange
  service pure-ftpd restart
  
else

  fxMessage "pure-ftpd not found. No PassivePortRange update"
fi

function printIpSet()
{
  fxTitle "ipset $1"
  ipset list $1 | head -n 7
  echo "...."
}

printIpSet zzfw_Blacklist
printIpSet zzfw_GeoArab
printIpSet zzfw_GeoChina
printIpSet zzfw_GeoIndia
printIpSet zzfw_GeoKorea
printIpSet zzfw_GeoRussia

fxTitle "🧱 Current status"
iptables -nL

fxTitle "Need the log?"
fxMessage "nano ${IP_LOG_FILE}"

fxEndFooter
