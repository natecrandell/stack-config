# https://help.ubuntu.com/community/TransmissionHowTo

## Container Config (Ubuntu 22.04)

```text
arch: amd64
cores: 2
hostname: tor-1
memory: 6144
mp0: /var/lib/vz/transmission-config,mp=/home/syncadmin/.config
mp1: /mnt/pve/cephfs/libraries/videos/,mp=/mnt/libraries/videos
mp2: /mnt/pve/cephfs/libraries/config/,mp=/mnt/libraries/config
net1: name=eth2,bridge=vmbr2,gw=10.1.2.1,hwaddr=4A:E9:89:34:05:DE,ip=10.1.2.230/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:230/vm-230-disk-1.raw,size=6G
startup: order=5
swap: 512
```

apt-get install transmission-cli transmission-common transmission-daemon

## Configure settings

service transmission-daemon stop
vim /var/lib/transmission-daemon/info/settings.json

```text
Jul 17 15:12:34 tor-1 transmission-daemon[2648]: [2019-07-17 15:12:34.421] UDP Failed to set receive buffer: requested 419
Jul 17 15:12:34 tor-1 transmission-daemon[2648]: [2019-07-17 15:12:34.421] UDP Failed to set send buffer: requested 104857
```

net.core.rmem_max = 4194304
net.core.wmem_max = 1048576

users:crandell:home: /var/lib/transmission-daemon

/var/lib/transmission-daemon/downloads
/var/lib/transmission-daemon/.config/transmission-daemon/[blocklists|resume|torrents]
/var/lib/transmission-daemon/.config/transmission-daemon/settings.json -> /etc/transmission-daemon/settings.json

root@sync-1:/etc/transmission-daemon# dpkg -l | grep transm
ii  transmission-cli                     2.94-2+deb10u2		amd64        lightweight BitTorrent client (command line programs)
ii  transmission-common                  2.94-2+deb10u2		all          lightweight BitTorrent client (common files)
ii  transmission-daemon                  2.94-2+deb10u2		amd64        lightweight BitTorrent client (daemon)
ii  transmission-gtk                     2.94-2+deb10u2		amd64        lightweight BitTorrent client (GTK+ interface)
ii  transmission-qt                      2.94-2+deb10u2		amd64        lightweight BitTorrent client (Qt interface)
ii  transmission-remote-cli              1.7.0-1			all          ncurses interface for the Transmission BitTorrent daemon
ii  transmission-remote-gtk              1.4.1-1			amd64        GTK+ interface for the Transmission BitTorrent daemon

## On cl-1 as root

```bash
mkdir /var/lib/vz/transmission-config
vim /etc/pve/lxc/230.conf
# add these lines right after memory:
mp0: /var/lib/vz/transmission-config,mp=/home/syncadmin/.config
mp1: /mnt/pve/cephfs/libraries/videos/,mp=/mnt/libraries/videos
```

salt-run cache.clear_git_lock gitfs type=update
[WARNING ] Config option 'gitfs_saltenv_whitelist' with value base has an invalid type of str, a list is required for this option

# Configure container with salt

	ssh root@photoprism-1
	apt update && apt upgrade && apt-get install -y salt-minion vim sudo gnupg2
	rm -rf /etc/salt/minion; vim /etc/salt/minion
		master: 10.1.1.231
		id: photoprism-1

	service salt-minion restart
	# SSH to salt-1, accept key, and test.ping
	# Make sure the pillar for tor-1 has users.syncadmin added
	salt-run git_pillar.update
	salt tor-1 saltutil.refresh_pillar; salt tor-1 pillar.get users
	salt tor-1 state.sls common.users,common.ssh

# Note: from here on run everything as unprivileged user

# Configure Zabbix agent
	sudo apt install zabbix-agent
	sudo vim /etc/zabbix/zabbix_agentd.conf.d/crandell.conf
		LogType=file
		LogFileSize=1
		DebugLevel=3
		AllowKey=system.run[*]
		LogRemoteCommands=1
		Server=10.1.1.217,zabbix-1.crandell.us
		ListenPort=10050
		ServerActive=10.1.1.217
		HostMetadataItem=system.uname
		
	sudo service zabbix-agent restart
	# Create host on zabbix server

# Increase the size of the network send/receive buffers
	# If building transmission as a container, this should be run on the host system, otherwise run on the transmission VM
	# Run as root:
		echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
		echo "net.core.wmem_max = 4194304" >> /etc/sysctl.conf
		sysctl -p

apt install transmission transmission-daemon transmission-remote-gtk
systemctl stop transmission-daemon



"download-dir": "/mnt/videos",
"rpc-password": "{55c2ca1997e326718bcc3a993c02dd61f76488d4WV2AlyCw",
"rpc-username": "ncrandell",
"rpc-whitelist": "*",
"rpc-whitelist-enabled": false,
"seed-queue-size": 6,
"speed-limit-up": 200,
"speed-limit-up-enabled": true,
"umask": 2,

Change the transmission-daemon user to syncadmin:crandell

```bash
vim /lib/systemd/system/transmission-daemon.service
User=syncadmin
Group=crandell

systemctl daemon-reload
systemctl start transmission-daemon
```
	
vim /etc/cron.d/zabbix-checks
MAILTO=""
*/5 * * * * root systemctl status transmission-daemon | grep running; zabbix_sender -z 10.1.1.217 -s tor-1 -k transmission-service-status -o $? > /dev/null

## Misc Config

```bash
# this ensures Zabbix checks for the syncadmin config dir has permissions
usermod -aG syncadmin zabbix
```
