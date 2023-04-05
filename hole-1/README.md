# Pi-hole container
	# https://www.smarthomebeginner.com/pi-hole-setup-guide/
	
	# Other resources:
		Blocklist collections: https://firebog.net/ (run pihole -g after changing adlists)
		


apt-get update; apt-get dist-upgrade -y; apt-get install vim gnupg2 software-properties-common -y
echo "deb http://repo.saltstack.com/py3/ubuntu/18.04/amd64/latest bionic main" > /etc/apt/sources.list.d/saltstack.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E08A149DE57BFBE; apt-get update; apt-get install salt-minion -y

# Configure salt minion and run basic highstate

# Install pi-hole
curl -sSL https://install.pi-hole.net | bash

Yeah that's pretty much it.

# Reset admin pwd
pihole -a -p

# Reign in query DB bloat
vim /etc/pihole/pihole-FTL.conf
PRIVACYLEVEL=0
MAXLOGAGE=24.0
IGNORE_LOCALHOST=yes
MAXDBDAYS=30

