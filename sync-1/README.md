# Build Notes: sync-1

NOTE: This documentation is incomplete. Most of the missing portions can be pulled from salt repos: states & config.

I created an Ubuntu 22.04 CT with these parameters:

```text
arch: amd64
cores: 2
hostname: sync-1
memory: 4092
mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
mp1: /srv/dropbox/,mp=/home/syncadmin/Dropbox
net0: name=eth0,bridge=vmbr0,firewall=1,gw=10.1.1.1,hwaddr=E6:A6:D6:FC:B8:1B,ip=10.1.1.237/24,ip6=auto,type=veth
ostype: ubuntu
rootfs: local:237/vm-237-disk-0.raw,size=6G
swap: 512
```

## Standard System Config

On cl-1:

```bash
mkdir /srv/dropbox
```

Back on sync-1:

```bash
dpkg-reconfigure tzdata

# Configure with salt
ssh root@sync-1
apt update && apt upgrade -y && apt-get install -y salt-minion vim sudo unattended-upgrades curl
echo "master: 10.1.1.231" > /etc/salt/minion
echo "id: sync-1" >> /etc/salt/minion
```

On salt master:

```bash
salt-key -a sync-1
# Ensure pillar/top.sls gives users.syncadmin
salt sync-1 state.sls common.users,common.ssh
# Verify syncadmin user appears in output
```

Configure Zabbix agent

```bash
apt install zabbix-agent
ln -s /mnt/libraries/config/stack/shared/zabbix.crandell.conf /etc/zabbix/zabbix_agentd.conf.d/crandell.conf
service zabbix-agent restart
# Create host on zabbix server
```

## Dropboxd

```bash
ln -s /mnt/libraries/config/stack/sync-1/dropbox.service /lib/systemd/system/dropbox.service
sudo su - syncadmin
# Ensure that host mount is in place at /home/syncadmin/Dropbox BEFORE doing this
# Dropboxd will start. If it can't find auth or its DB it will create them.
wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
# These notes are incomplete
```

## Seaf-cli

Install seaf-cli, clone libraries: backup, homevideos, pictures, config, dropbox, documents.

This section is incomplete.

## Misc Config

### Configure dropbox-cleanup job

```bash
ln -s /mnt/libraries/config/stack/sync-1/dropbox-cleanup.sh /usr/local/bin/dropbox-cleanup.sh
ln -s /mnt/libraries/config/stack/sync-1/dropbox-cleanup.cron /etc/cron.d/dropbox-cleanup
```

### Configure auto-transcode job

```bash
apt install ffmpeg exiftool curl
ln -s /mnt/libraries/config/stack/sync-1/auto-transcode.sh /usr/local/bin/auto-transcode.sh
ln -s /mnt/libraries/config/stack/sync-1/auto-transcode.cron /etc/cron.d/auto-transcode
```

### Configure handling of stack-config repo

```bash
apt install git -y
# Clone stack-config
cd /mnt/libraries/config/
git clone https://gitlab-1.crandell.us/nate/stack-config.git
# The root of the repo needs to be at /mnt/libraries/config/stack/
```

### Misc config: crons, logrotate

```bash
ln -s /mnt/libraries/config/stack/sync-1/zabbix-checks.cron /etc/cron.d/zabbix-checks
ln -s /mnt/libraries/config/stack/shared/clean-cache.cron /etc/cron.d/clean-cache
ln -s /mnt/libraries/config/stack/sync-1/seaf-cli.logrotate /etc/logrotate.d/seaf-cli
ln -s /mnt/libraries/config/stack/sync-1/dropbox.logrotate /etc/logrotate.d/dropbox
ln -s /mnt/libraries/config/stack/sync-1/README.md /root/README.md
```

## Misc Notes

### Locations

```text
/home/syncadmin/Dropbox          Dropbox sync dir
/home/syncadmin/.dropbox         DB, pid file, socket, etc
/home/syncadmin/.dropbox-dist    dropboxd executable
/home/syncadmin/.ccnet           seaf-cli logs, seafile.ini
/root/.ccnet ->                  /home/syncadmin/.ccnet
```
