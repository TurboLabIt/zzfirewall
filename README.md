# 🔥🧱 zzfirewall 🧱🔥

iptables rules to shut off undesired connections and clients from certain geos


# Install

Just execute:

````bash
sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/zzfirewall/master/setup.sh?$(date +%s) | sudo bash

````

Now copy the provided sample configuration file (`zzfirewall.default.conf`) to your own `zzfirewall.conf` and set your preference:

````bash
sudo cp /usr/local/turbolab.it/zzfirewall/zzfirewall.default.conf /etc/turbolab.it/zzfirewall.conf && sudo nano /etc/turbolab.it/zzfirewall.conf

````


# Shields Up!

````bash
sudo zzfirewall
````

Need a factory-reset?

````bash
sudo zzfirewall-reset
````


# For the maintainers: update the lists

````bash
sudo zzfirewall-generate
````

