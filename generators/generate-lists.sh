#!/usr/bin/env bash

SCRIPT_NAME=zzfirewall
## https://github.com/TurboLabIt/webstackup/blob/master/script/base.sh
source "/usr/local/turbolab.it/webstackup/script/base.sh"
fxHeader "🛡️ Generate Geo+Black+White lists"
rootCheck
fxConfigLoader
showPHPVer

fxTitle "📂 Setting up the vendor directory for composer..."
EXPECTED_USER=zane
VENDOR_DIR=/usr/local/turbolab.it/zzfirewall/generators/vendor/
mkdir -p "${VENDOR_DIR}"
chown zane:zane "${VENDOR_DIR}" -R
chmod ugo= "${VENDOR_DIR}" -R
chmod u=rwX "${VENDOR_DIR}" -R
wsuComposer install

fxTitle "🗺 Generate geolist..."
echo ""
XDEBUG_MODE=off ${PHP_CLI} ${SCRIPT_DIR}generate-geolists.php ${MAXMIND_KEY}
echo ""

fxTitle "🤝 Generate whitelist..."
echo ""
XDEBUG_MODE=off ${PHP_CLI} ${SCRIPT_DIR}generate-whitelist.php
echo ""

fxTitle "🧱 Generate blacklist..."
echo ""
XDEBUG_MODE=off ${PHP_CLI} ${SCRIPT_DIR}generate-blacklist.php
echo ""

fxTitle "🧱 Adding abuseipdb to the blacklist..."
ABUSE_IP=$(curl -G https://api.abuseipdb.com/api/v2/blacklist \
  -d limit=500000 \
  -d confidenceMinimum=70 \
  -d plaintext \
  -H "Key: ${ABUSEIPDB_KEY}" \
  -H "Accept: application/json")

CURL_RESULT=$?

if [[ "$ABUSE_IP" == *"error"* ]] || [ -z "${ABUSE_IP}" ] || [ "${CURL_RESULT}" != 0 ]; then
  fxCatastrophicError "${ABUSE_IP}"
fi

echo "" >> ${SCRIPT_DIR}../lists/autogen/blacklist.txt
echo "## 🛑 AbuseIPDB" >> ${SCRIPT_DIR}../lists/autogen/blacklist.txt
echo "$ABUSE_IP" | grep -v ":" >> ${SCRIPT_DIR}../lists/autogen/blacklist.txt

fxTitle "✔️ Git commit..."
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/whitelist.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/google.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/blacklist.txt
git -C ${SCRIPT_DIR}../ commit -m"🧱 autogenerated firewall lists update"

fxTitle "☁️ Git pull and push..."
git -C ${SCRIPT_DIR}../ pull --no-edit
git -C ${SCRIPT_DIR}../ push

fxEndFooter
