When the unifi stable repo changes, do this:
	vim /etc/apt/sources.list.d/100-ubnt-unifi.list			# Update the name of the repo
	apt-get clean
	apt-get update -y --allow-releaseinfo-change
	apt-get dist-upgrade

This VM appears to require these packages:
	gnupg
	mongodb-org
	openjdk-8-jdk
	unifi

To update unifi and all other system software, just run:
	salt unifi-1 cmd.run 'apt-get update && apt-get upgrade -y'

