# 🔥🧱 zzfirewall 🧱🔥

iptables rules to stop undesired connections.


## Install

Just execute:

````bash
sudo apt install curl -y && \
  curl -s https://raw.githubusercontent.com/TurboLabIt/zzfirewall/master/setup.sh | sudo bash
````

Now copy the provided sample configuration file (`zzfirewall.default.conf`) to your own `zzfirewall.conf` and set your preference:

````bash
sudo cp /usr/local/turbolab.it/zzfirewall/zzfirewall.default.conf /etc/turbolab.it/zzfirewall.conf && \
  sudo nano /etc/turbolab.it/zzfirewall.conf
````


## Shields Up!

````bash
sudo zzfirewall
````


## Restrict SSH access

If you want to limit SSH access to pre-approved hosts, create a file and add your IPs/DDNS (one per line):

````bash
sudo nano /etc/turbolab.it/zzfirewall-whitelist.conf && \
  sudo zzfirewall-whitelist-update
````


## Geo-allow web access

To allow HTTP(S) traffic from specific countries only, do this:

````bash
## Allow web traffic from specific countries only
ALLOW_WEBSERVER=0
GEOALLOW_WEB_COUNTRIES=italy,switzerland
````


## How to Cloudflare

Just set:

````bash
## Allow web traffic from Cloudflare only
ALLOW_WEBSERVER=0
````

All web traffic will be accepted through Cloudflare only.


## On-the-fly IP whitelist

````bash
sudo iptables -I "INPUT" -s "TRUSTED_IP_ADDRESS" -j ACCEPT
````


## Database-only, LAN-only server 

````bash
## Database-only, LAN-only server
ALLOW_WEBSERVER=0
ALLOW_WEBSERVER_FROM_WHITELIST=0
ALLOW_FTP=0
GEOBLOCK=0
````


## Which lists are loaded

The sources are listed, one URL per line, in
[lists/blocklists.txt](lists/blocklists.txt) and [lists/whitelists.txt](lists/whitelists.txt).

A source is fetched and merged as-is: if it needs filtering, parsing or an API key, it does **not**
go in the index. It goes into `generators/generate-lists.sh`, which runs on the maintainer box only
and commits its result to `lists/autogen/blacklist.txt` (that is how AbuseIPDB, firehol_level1,
stamparm/ipsum and the Contabo ranges get in). An index full of shell pipelines would mean every
box running internet-fetched code as root.

If a single source is unreachable the others are still applied; if all of them are, the running
ipsets are left untouched and the box keeps being protected by the previous content.


## Emergency firewall reset

````bash
sudo zzfirewall-reset
````

It wipes every iptables rule and every ipset on the box. If Docker is installed and running, it gets restarted automatically so it can rebuild its own iptables rules.


----

### For the maintainers: update the lists

````bash
sudo zzfirewall-generate
````
