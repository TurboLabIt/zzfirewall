#!/usr/bin/env bash

SCRIPT_NAME=zzfirewall
## https://github.com/TurboLabIt/webstackup/blob/master/script/base.sh
source "/usr/local/turbolab.it/webstackup/script/base.sh"
fxHeader "🛡️ Generate Geo+Black+White lists"
rootCheck
fxConfigLoader
showPHPVer

fxTitle "🔧 Checking maintainer keys..."
KEY_NOT_SET_TIP="Set it in sudo nano /etc/turbolab.it/zzfirewall.conf , see https://github.com/TurboLabIt/zzfirewall/blob/main/zzfirewall.default.conf"

if [ -z "${ABUSEIPDB_KEY}" ]; then
  fxCatastrophicError "ABUSEIPDB_KEY is not set! ${KEY_NOT_SET_TIP}"
fi

fxOK "ABUSEIPDB_KEY is set"

if [ -z "${MAXMIND_KEY}" ]; then
  fxCatastrophicError "MAXMIND_KEY is not set! ${KEY_NOT_SET_TIP}"
fi

fxOK "MAXMIND_KEY is set"

fxTitle "↙️ Git pulling..."
git -C "/usr/local/turbolab.it/zzfirewall/" pull


fxTitle "📂 Setting up the vendor directory for composer..."
EXPECTED_USER=$(logname)
VENDOR_DIR=/usr/local/turbolab.it/zzfirewall/generators/vendor/
mkdir -p "${VENDOR_DIR}"
chown $(logname):$(logname) "${VENDOR_DIR}" -R
chmod ugo= "${VENDOR_DIR}" -R
chmod u=rwX "${VENDOR_DIR}" -R
COMPOSER_JSON_FULLPATH=/usr/local/turbolab.it/zzfirewall/generators/composer.json
wsuComposer install


fxTitle "🗺 Generate geolist..."
echo ""
${PHP_CLI} ${SCRIPT_DIR}generate-geolists.php ${MAXMIND_KEY}
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
sed -i 's/\r$//' ${SCRIPT_DIR}../lists/autogen/whitelist.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/whitelist.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/google.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/google-cloud.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/blacklist.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/arab.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/china.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/india.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/korea.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/russia.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/south-america.txt
git -C ${SCRIPT_DIR}../ commit -m"🧱 autogenerated firewall lists update"

fxTitle "☁️ Git pull and push..."
git -C ${SCRIPT_DIR}../ pull --no-edit
git -C ${SCRIPT_DIR}../ push

fxEndFooter
