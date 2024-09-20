# Zoneminder Build Notes

## References

- Ubuntu basic install: `https://zoneminder.readthedocs.io/en/latest/installationguide/ubuntu.html`
- Multi-server install: `https://zoneminder.readthedocs.io/en/latest/installationguide/multiserver.html`
- Zoneminder API Docs: `https://zoneminder.readthedocs.io/en/latest/api.html`
- Zoneminder Release Notes: `https://github.com/ZoneMinder/zoneminder/releases`

## Notes

- Go through and build zm-1 first. Then do the exact same process for additional servers, skipping only the database steps.
- 10.1.2.0/24 is used as mgmt network. It has an internet gateway for updates, and the proxy hits the zm nodes on this subnet.
- 10.1.3.0/24 is the camera network. It is unmanaged, has no gateway, and is isolated from all other networks.
- 10.1.1.0/24 is temporarily used on zm-2 until I get rid of the D-Link DCS-932L cameras
- The zm nodes mount to a cephfs share using the pve host's connection. This is intended to be used for video recordings.
- The local events storage is /mnt/libraries/zoneminder/events

## Container Config (Ubuntu 22.04)

```text
arch: amd64
cores: 4
hostname: zm-1
memory: 2048
mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
net0: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=0A:63:3D:38:B5:06,ip=10.1.2.221/24,ip6=auto,type=veth
net1: name=eth3,bridge=vmbr3,hwaddr=02:B4:5B:B0:D1:82,ip=10.1.3.221/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:221/vm-221-disk-0.raw,size=6G
startup: order=4
swap: 0
```

```text
arch: amd64
cores: 4
hostname: zm-2
memory: 2048
mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=2A:6D:BB:EE:01:8A,ip=10.1.2.222/24,ip6=auto,type=veth
net2: name=eth3,bridge=vmbr3,hwaddr=86:0E:72:EB:1D:CC,ip=10.1.3.222/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:222/vm-222-disk-0.raw,size=6G
startup: order=4
swap: 0
```

## Standard System Config

Perform the [standard system config](../shared/standard-config.md).

## Zoneminder Config

`https://zoneminder.readthedocs.io/en/latest/installationguide/ubuntu.html#ubuntu-22-04-jammy`

```bash
apt install -y software-properties-common
add-apt-repository ppa:iconnor/zoneminder-1.36 && apt update && apt install -y zoneminder
a2enmod rewrite; a2enconf zoneminder; systemctl restart apache2

vim /etc/php/8.1/apache2/php.ini
# Uncomment and change date.timezone to your tz. http://php.net/manual/en/timezones.php
date.timezone = America/Denver
```

## MySQL Config (zm-1 only)

```bash
rm /etc/mysql/my.cnf  #(this removes the current symbolic link)
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/my.cnf
vim /etc/mysql/my.cnf
bind-address            = 127.0.0.1,10.1.2.221
systemctl restart mysql

# Setup user/privs for multi-server (perform on zm-1 only)
# repeat this process for all additional servers
mysql -uroot -p
CREATE USER 'zmuser'@'10.1.2.222' IDENTIFIED BY 'zmpass';
GRANT ALL ON zm.* to 'zmuser'@'10.1.2.222';
flush privileges;
\q
```

Reduce disk bloat by reducing MySQL bin logs.

```bash
vim /etc/mysql/my.cnf
binlog_expire_logs_seconds    = 604800
service mysql restart
```

## Event Storage Config

Ensure /mnt/libraries is mounted.

```bash
mkdir -p /mnt/libraries/events
chown -R www-data:crandell /mnt/libraries/zoneminder/
```

## Misc Config

Leave all config files in /etc/zm/ and /etc/zm/conf.d/ as they are. Adding /etc/zm/conf.d/zm-*.conf will override defaults.

```bash
# The following step will have a corresponding file for zm-*
ln -s /mnt/libraries/config/stack/zm/zm-1.conf /etc/zm/conf.d/zm-1.conf

ln -s /mnt/libraries/config/stack/shared/clean-cache.cron /etc/cron.d/clean-cache

systemctl enable --now zoneminder
```

## Cleanup

Remove mysql for nodes that aren't zm-1

```bash
apt remove mysql-server*
apt autoremove
```
