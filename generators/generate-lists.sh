#!/usr/bin/env bash

SCRIPT_NAME=zzfirewall
## https://github.com/TurboLabIt/webstackup/blob/master/script/base.sh
source "/usr/local/turbolab.it/webstackup/script/base.sh"
fxHeader "🛡️ Generate Geo+Black+White lists"
rootCheck
fxConfigLoader
showPHPVer

GIT_REPO_SSH_URL=git@github.com:TurboLabIt/zzfirewall.git
GIT_KEY_NOT_OK_TIP="Generate a key with sudo ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 and add /root/.ssh/id_ed25519.pub to https://github.com/TurboLabIt/zzfirewall/settings/keys as a deploy key, with 'Allow write access' ticked"


## it installs jq too, which we need later on for the lists as well
fxSshSetKnownHosts


fxTitle "☁️ Switching the git remote to SSH..."
if [ "$(git -C "${PROJECT_DIR}" remote get-url origin)" = "${GIT_REPO_SSH_URL}" ]; then

  fxOK "The git remote is already ##${GIT_REPO_SSH_URL}##"

else

  git -C "${PROJECT_DIR}" remote set-url origin "${GIT_REPO_SSH_URL}"
  fxOK "The git remote is now ##${GIT_REPO_SSH_URL}##"
fi


fxTitle "🔐 Checking the SSH write access to the repo..."
## --dry-run on a would-be-new branch: it never really creates it and it can't fail
## for non-fast-forward reasons, so a failure here means "no write access", full stop.
## BatchMode + SSH_ASKPASS_REQUIRE: never ever prompt, or the cron run would hang forever
GIT_WRITE_ACCESS_CHECK=$( \
  SSH_ASKPASS_REQUIRE=never GIT_SSH_COMMAND="ssh -o BatchMode=yes" \
  git -C "${PROJECT_DIR}" push --dry-run origin HEAD:refs/heads/zzfirewall-write-access-check 2>&1)

GIT_WRITE_ACCESS_CHECK_RESULT=$?

if [ "${GIT_WRITE_ACCESS_CHECK_RESULT}" != 0 ]; then

  echo "${GIT_WRITE_ACCESS_CHECK}"
  fxCatastrophicError "$(whoami) has no SSH write access to ${GIT_REPO_SSH_URL}! ${GIT_KEY_NOT_OK_TIP}"
fi

fxOK "$(whoami) has SSH write access to ${GIT_REPO_SSH_URL}"


fxTitle "🪪 Setting the git commit identity..."
git -C "${PROJECT_DIR}" config user.name "zzfirewall-maintainer"
git -C "${PROJECT_DIR}" config user.email "zzfirewall@turbolab.it"
fxOK "$(git -C "${PROJECT_DIR}" config user.name) <$(git -C "${PROJECT_DIR}" config user.email)>"


fxTitle "🙈 Ignoring the file mode changes..."
## the chmods around here would otherwise show up as local changes and block the pull
git -C "${PROJECT_DIR}" config core.fileMode false
fxOK "core.fileMode is $(git -C "${PROJECT_DIR}" config core.fileMode)"


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
EXPECTED_USER=$(logname 2>/dev/null)

if [ -z "${EXPECTED_USER}" ]; then
  EXPECTED_USER=root
fi

fxOK "EXPECTED_USER is ##${EXPECTED_USER}##"
VENDOR_DIR=/usr/local/turbolab.it/zzfirewall/generators/vendor/
mkdir -p "${VENDOR_DIR}"
chown ${EXPECTED_USER}:${EXPECTED_USER} "${VENDOR_DIR}" -R
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


fxTitle "🧱 Adding Contabo to the blacklist..."
echo "" >> ${SCRIPT_DIR}../lists/autogen/blacklist.txt
echo "## 🛑 Contabo " >> ${SCRIPT_DIR}../lists/autogen/blacklist.txt
curl -s 'https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS51167' \
| jq -r '.data.prefixes[].prefix' \
| sort -u | grep -v ":" >> ${SCRIPT_DIR}../lists/autogen/blacklist.txt

curl -s 'https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS40021' \
| jq -r '.data.prefixes[].prefix' \
| sort -u | grep -v ":" >> ${SCRIPT_DIR}../lists/autogen/blacklist.txt


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
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/google-search.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/google-cloud.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/claude.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/meta.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/autogen/blacklist.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/arab.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/china.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/india.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/korea.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/russia.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/south-america.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/italy.txt
git -C ${SCRIPT_DIR}../ add ${SCRIPT_DIR}../lists/geos/switzerland.txt
git -C ${SCRIPT_DIR}../ commit -m"🧱 autogenerated firewall lists update"

fxTitle "☁️ Git pulling..."
git -C ${SCRIPT_DIR}../ pull --no-edit

## every run commits a few MB of lists: left alone, the local history piles up forever (~50 MB/year)
fxPushAndShallow "${PROJECT_DIR}"

fxEndFooter
