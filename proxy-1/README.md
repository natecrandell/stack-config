# Nginx reverse proxy on Ubuntu 22.04 (with cert auto-renewal)

root@cl-1:/etc/pve/lxc# cat 220.conf
	arch: amd64
	cores: 2
	hostname: proxy-1
	memory: 512
	mp0: /mnt/pve/cephfs/libraries/config/,mp=/mnt/libraries/config
	net0: name=eth1,bridge=vmbr1,firewall=1,hwaddr=5A:43:E8:8E:42:BE,ip=10.1.1.220/24,ip6=auto,type=veth
	net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=76:B6:D9:A0:06:AB,ip=10.1.2.220/24,ip6=auto,type=veth
	onboot: 1
	ostype: ubuntu
	rootfs: local:220/vm-220-disk-0.raw,size=4G
	startup: order=2
	swap: 0


# Configure container with salt
	ssh root@proxy-1
	apt update && apt upgrade -y && apt-get install -y salt-minion vim sudo unattended-upgrades curl
	rm -rf /etc/salt/minion; vim /etc/salt/minion
		master: 10.1.1.231
		id: proxy-1

	service salt-minion restart
	# SSH to salt-1, accept key, and test.ping
	salt proxy-1 state.sls common.users,common.ssh

# Configure Zabbix agent
	apt install zabbix-agent
	ln -s /mnt/libraries/config/stack/shared/zabbix.crandell.conf /etc/zabbix/zabbix_agentd.conf.d/crandell.conf
	service zabbix-agent restart
	# Create host on zabbix server

# SSH credentials
	# copy over /root/.ssh/config|gitlab|gitlab.pub|id_rsa|id_rsa.pub
	# test that root user can SSH to gitlab
		chmod 600 id_rsa gitlab
		ssh gitlab-1.crandell.us

# Install and configure Nginx
	# I'm going to NOT clone the repo, as it appears to have been a temporary fix
	apt install certbot nginx python3-certbot-nginx
	rm -rf /etc/nginx/sites-enabled/default
	ln -s /mnt/libraries/config/stack/proxy-1/nginx.crandell.us /etc/nginx/sites-enabled/crandell.us
	
	# symlink to letsencrypt config
		rm -rf /etc/letsencrypt
		ln -s /mnt/libraries/config/stack/proxy-1/letsencrypt /etc/letsencrypt
		
	# test the nginx config
		nginx -t
		service nginx restart
	
# Configure and test certbot		
	apt install python3-pip -y && pip3 install --upgrade pip && pip3 install certbot-dns-joker
	certbot certificates
	certbot certonly --dry-run --authenticator dns-joker --dns-joker-credentials /etc/letsencrypt/secrets/crandell.us.ini --dns-joker-propagation-seconds 120 -d *.crandell.us

# Misc
	dpkg-reconfigure tzdata
	ln -s /mnt/libraries/config/stack/proxy-1/cert-check.sh /usr/local/bin/cert-check.sh
	ln -s /mnt/libraries/config/stack/shared/clean-cache.cron /etc/cron.d/clean-cache
	ln -s /mnt/libraries/config/stack/proxy-1/cert-check.cron /etc/cron.d/cert-check
	mv /etc/cron.d/certbot /etc/cron.d/certbot.disabled
	
	apt clean allcd