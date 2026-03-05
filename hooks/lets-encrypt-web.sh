rootCheck
fxConfigLoader
HOOK_NAME='⚠️ TEMP! zzfirewall + certbot: 01-pre hook'
IPTABLES_COMMAND_ARGUMENTS="INPUT -p tcp -m multiport --dports 80,443 -m comment --comment \"${HOOK_NAME} (zzfw)\" -j ACCEPT"


fxTitle "📦 Checking packages...."
if [ -z "$(command -v iptables)" ] || [ -z "$(command -v certbot)" ]; then

  fxWarning "iptables or certbot not installed. Skipping 🦘"
  fxEndFooter
  exit
fi


if ! iptables -S INPUT | grep -q '^-A'; then

  fxWarning "iptables INPUT chain is empty. Skipping 🦘"
  fxEndFooter
  exit
fi
