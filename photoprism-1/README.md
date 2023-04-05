# Install Photoprism (docker-compose method) running on Ubuntu 22 container
# https://docs.photoprism.app/getting-started/docker-compose/

# Design decisions:
	- Photoprism will run on an Ubuntu 22.04 container
	- The container storage will run on the Proxmox host's local SSD-backed storage. This is to avoid incurring significant network overhead by using cephfs or an rbd block device.
	- Regular backups will be taken of the container's root fs
	- The Photoprism data dir will be part of the container's root filesystem.
	- An additional mount will be provided by the Proxmox host. It is a connection to photo library.


# Download latest Ubuntu 22.04 container template in Proxmox

# Create CT photoprism-1 with 20G root disk (local), 6G RAM, 4G swap**, 2 cores, CT 236, 10.1.1.236
	# *Photoprism recommends at least 4G swap to prevent indexing from causing restarts
	# After creating container, go to Options -> Features -> Edit -> Nesting: 1 -> Ok (docker requirement)
	# Add photoprism-1 to Proxmox backup job
	
	# Add mount to the photos library. The Proxmox UI doesn't allow this, so will need to do manually from cl-1:
		vim /etc/pve/lxc/236.conf
		# Add this line right after the memory line:
		mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
	
	# start container

# Add DNS A record

# Configure container with salt
	ssh root@photoprism-1
	apt update && apt upgrade && apt-get install -y salt-minion vim sudo gnupg2 unattended-upgrades
	rm -rf /etc/salt/minion; vim /etc/salt/minion
		master: 10.1.1.231
		id: photoprism-1

	service salt-minion restart
	# SSH to salt-1, accept key, and test.ping
	salt photoprism-1 state.sls common.users,common.ssh

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
	
	dpkg-reconfigure tzdata
	
# Install Docker
	sudo apt install curl
	curl -sSL https://get.docker.com | sh
	sudo usermod -aG docker ${USER}
	groups ${USER}
	
	# Verify
	sudo dpkg -l | grep "dock\|contain"
	sudo systemctl status docker
	sudo docker ps
	
# Install and configure Photoprism
	sudo mkdir /data
	# https://docs.photoprism.app/getting-started/docker-compose/
	
	# Download the official docker-compose.yml
	wget https://dl.photoprism.app/docker/docker-compose.yml
	
	PHOTOPRISM_ADMIN_PASSWORD: "[redacted]"
	PHOTOPRISM_SITE_URL: "http://10.1.1.236:2342/"
	user: "1111:1111"
	volumes:
	  - "/mnt/libraries/pictures:/photoprism/originals"
	  - "/mnt/libraries/homevideos:/photoprism/originals/homevideos"
	  - "/data:/photoprism/storage"
	
sudo docker compose up -d


# Other commands
	# https://docs.photoprism.app/getting-started/docker-compose/#examples
	sudo docker compose pull		# update
	sudo docker compose exec photoprism photoprism users add
	
	# I created user: guest, password: password