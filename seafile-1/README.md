# Seafile Build Notes

## Qemu Config

```text
agent: 1
balloon: 0
boot: c
bootdisk: virtio0
cores: 4
cpuunits: 1000
hotplug: 0
memory: 8192
name: seafile-1
net1: virtio=BE:6B:C4:07:6A:EE,bridge=vmbr2,firewall=1
numa: 0
onboot: 1
ostype: l26
scsihw: virtio-scsi-single
smbios1: uuid=43b2b5a9-6d9a-4578-983a-2c841fcc76ae
sockets: 1
startup: order=3
tablet: 0
virtio0: local2:218/vm-218-disk-0.raw,iothread=1,replicate=0,size=12G
vmgenid: 9136957a-3722-45fb-956b-dd1ed3598056
```

## Misc Config

```bash
ln -s /mnt/cephfs/libraries/ /mnt/libraries
ln -s /mnt/libraries/config/stack/$(hostname)/README.md /root/README.md
ln -s /mnt/libraries/config/stack/seafile-1/seaf-gc.cron /etc/cron.d/seaf-gc
```

## 2017-12-13 New Seafile Installation

`https://linode.com/docs/applications/cloud-storage/install-seafile-with-nginx-on-ubuntu-1604/`

```bash
adduser sfadmin
gpasswd -a sfadmin sudo
sudo su - sfadmin
wget https://download.seadrive.org/seafile-server_6.2.5_x86-64.tar.gz
tar -xzvf seafile-server*.tar.gz
mkdir installed && mv seafile-server*.tar.gz installed
sudo apt install python2.7 libpython2.7 python-setuptools python-pil python-ldap python-mysqldb python-memcache python-urllib3

mysql_secure_installation
cd seafile-server-* && ./setup-seafile-mysql.sh

ln -s /home/sfadmin/seafile-server-6.2.5 /home/sfadmin/seafile-server-latest
```

```text
---------------------------------
This is your configuration
---------------------------------

    server name:            CrandellCloud
    server ip/domain:       cloud.crandell.us, 10.1.1.13

    seafile data dir:       /home/sfadmin/seafile-data
    fileserver port:        8082

    database:               create new
    ccnet database:         ccnet-db
    seafile database:       seafile-db
    seahub database:        seahub-db
    database user:          seafile
pwd for sfadmin and dbs: sfadminpass

-----------------------------------------------------------------
Your seafile server configuration has been finished successfully.
-----------------------------------------------------------------

run seafile server:     ./seafile.sh { start | stop | restart }
run seahub  server:     ./seahub.sh  { start <port> | stop | restart <port> }

-----------------------------------------------------------------
If you are behind a firewall, remember to allow input/output of these tcp ports:
-----------------------------------------------------------------

port of seafile fileserver:   8082
port of seahub:               8000
```

```bash
./home/sfadmin/seafile-server-latest/seafile.sh
```

### Boot

```bash
vim /etc/systemd/system/seafile.service
[Unit]
Description=Seafile Server
After=network.target

[Service]
Type=oneshot
ExecStart=/home/sfadmin/seafile-server-latest/seafile.sh start
ExecStop=/home/sfadmin/seafile-server-latest/seafile.sh stop
RemainAfterExit=yes
User=sfadmin
Group=sfadmin

[Install]
WantedBy=multi-user.target
```

```bash
vim /etc/systemd/system/seahub.service
[Unit]
Description=Seafile Hub
After=network.target seafile.service

[Service]
Type=oneshot
ExecStart=/home/sfadmin/seafile-server-latest/seahub.sh start-fastcgi
ExecStop=/home/sfadmin/seafile-server-latest/seahub.sh stop
RemainAfterExit=yes
User=sfadmin
Group=sfadmin

[Install]
WantedBy=multi-user.target
```

### Configure Seafile email

`https://manual.seafile.com/config/sending_email.html`

Set path and verify

```bash
echo $PATH
export PATH=/home/sfadmin/seafile-server-latest:$PATH
echo $PATH
```

## Troubleshooting Notes

- Seafile won't start (2016-08-16) - Seafile wouldn't start because Mysql (MariaDB) wouldn't start because the system time was wrong.
- Seahub won't start (2018-02-04) - Turns out ~sfadmin/conf/seahub_settings.py somehow had `seafile` as the value for DEFAULT_FROM_EMAIL and SERVER_EMAIL. Resolved after setting them both to EMAIL_HOST_USER.

## Minor version upgrade (like from 5.0.x to 5.1.y)

`https://manual.seafile.com/deploy/upgrade.html`

```bash
cd /root/seafile/seafile-server-6.0.6
./seahub.sh stop
./seafile.sh stop

cd /root/seafile
wget https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_6.1.0_x86-64.tar.gz
tar -xzf seafile-server_6.1.0_x86-64.tar.gz
rm seafile-server_6.1.0_x86-64.tar.gz

ls upgrade/upgrade_*
./upgrade/upgrade_6.0_6.1.sh

cd /root/seafile/seafile-server-6.1.0
./seahub.sh start
./seafile.sh start

#If new version works, delete the old one.
rm -rf /root/seafile/seafile-server-6.0.6

# Note: don't forget to update the symlink in ~sfadmin, or Seafile won't start at boot
ls -s seafile-server-6.2.3 /home/seafile-server-latest
```

## Seafile Garbage Collection Notes

`https://manual.seafile.com/maintain/seafile_gc.html`

Note: Run as root

```bash
cd ~sfadmin/seafile-server-latest && ./seafile.sh stop && sleep 5 && ./seaf-gc.sh && ./seafile.sh start
```

## Newest iteration of seafile server

Container Config:

```text
arch: amd64
cores: 2
hostname: seafile-1
memory: 12288
mp0: /mnt/gvol1B/data/seafile,mp=/home/sfadmin
net0: name=eth0,bridge=vmbr0,gw=10.1.1.1,hwaddr=D2:11:E1:F3:20:45,ip=10.1.1.213/24,ip6=auto,type=veth
ostype: ubuntu
protection: 1
rootfs: local-lvm:vm-213-disk-1,acl=0,replicate=0,size=8G
swap: 1536
```

### Install Prerequisites

```bash
apt install python2.7 libpython2.7 python-setuptools python-imaging python-ldap python-mysqldb python-memcache python-urllib3 python-pil python-requests ffmpeg python-pip mysql-server
mysql_secure_installation
```

Say no to the first question (can't remember what it was)

### Setup sfadmin environment

```bash
adduser sfadmin
mkdir ~sfadmin/seafile-server-latest
```

### Install Seafile

```bash
cd ~sfadmin
wget https://download.seadrive.org/seafile-server_6.2.5_x86-64.tar.gz
tar -xzvf seafile-server*.tar.gz
mkdir installed && mv seafile-server*.tar.gz installed
cd seafile-server-* && ./setup-seafile-mysql.sh
# Remember: SERVICE_URL = http://10.1.1.213:8000
# This setup can configure MySQL automatically with the mysql root pwd


ln -s /home/sfadmin/seafile-server-6.2.5 /home/sfadmin/seafile-server-latest

# Run seafile at startup with systemd
# https://manual.seafile.com/deploy/start_seafile_at_system_bootup.html

vim /etc/systemd/system/seafile.service
[Unit]
Description=Seafile Server
After=network.target mysql.service

[Service]
Type=forking
ExecStart=/home/sfadmin/seafile-server-latest/seafile.sh start
ExecStop=/home/sfadmin/seafile-server-latest/seafile.sh stop
User=sfadmin
Group=sfadmin

[Install]
WantedBy=multi-user.target
```

### Run seahub at startup with systemd

```bash
vim /etc/systemd/system/seahub.service
[Unit]
Description=Seafile hub
After=network.target mysql.service seafile.service

[Service]
Type=forking
ExecStart=/home/sfadmin/seafile-server-latest/seahub.sh start
ExecStop=/home/sfadmin/seafile-server-latest/seahub.sh stop
User=sfadmin
Group=sfadmin

[Install]
WantedBy=multi-user.target
```

systemctl enable seafile
systemctl enable seahub

```bash
vim /home/sfadmin/conf/seahub_settings.py
# -*- coding: utf-8 -*-
SECRET_KEY = "=(*(zsy51go-2wa4!2z_@y3k)@ee8(%g-xm&344^p7gvyr3j2!"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'seahub-db',
        'USER': 'seafile',
        'PASSWORD': 'redacted',
        'HOST': '127.0.0.1',
        'PORT': '3306'
    }
}
EMAIL_USE_TLS = True
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_HOST_USER = 'nate@crandell.us'
EMAIL_HOST_PASSWORD = 'redacted'
EMAIL_PORT = 587
DEFAULT_FROM_EMAIL = EMAIL_HOST_USER
SERVER_EMAIL = EMAIL_HOST_USER
```

```bash
vim /home/sfadmin/conf/ccnet.conf
[General]
USER_NAME = CrandellCloud
ID = 98b8c8b1781a7e40f020e1077194836b39a96990
NAME = CrandellCloud
SERVICE_URL = http://10.1.1.213:8000

[Client]
PORT = 13419

[Database]
ENGINE = mysql
HOST = 127.0.0.1
PORT = 3306
USER = seafile
PASSWD = redacted
DB = ccnet-db
CONNECTION_CHARSET = utf8
```
