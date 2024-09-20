# Proxy-1 Build Notes

Nginx reverse proxy on Ubuntu 22.04 (with cert auto-renewal)

## Container Config (Ubuntu 22.04)

```text
arch: amd64
cores: 2
hostname: proxy-1
memory: 512
mp0: /mnt/pve/cephfs/libraries/config/,mp=/mnt/libraries/config
net0: name=eth1,bridge=vmbr1,firewall=1,hwaddr=26:94:EF:52:B3:A7,ip=10.1.1.220/24,ip6=auto,type=veth
net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=2A:6F:F6:88:37:0A,ip=10.1.2.220/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:220/vm-220-disk-0.raw,size=4G
startup: order=2
swap: 0
```

## Salt Config

```bash
ssh root@proxy-1
apt update && apt upgrade && apt-get install -y salt-minion vim sudo gnupg2 unattended-upgrades curl
echo "master: 10.1.2.231" > /etc/salt/minion
echo "id: $(hostname)" >> /etc/salt/minion
service salt-minion restart
```

From salt master

```bash
salt-key -a proxy-1
salt proxy-1 test.ping
salt proxy-1 state.sls common.users,common.ssh
```

## Zabbix Config

```bash
apt install zabbix-agent
ln -s /mnt/libraries/config/stack/shared/zabbix/zabbix.crandell.conf /etc/zabbix/zabbix_agentd.conf.d/crandell.conf
service zabbix-agent restart
```

## SSH

This is required to SSH to gitlab-1 for cert renewal. Gitlab is currently not behind the proxy.

```bash
# copy over /root/.ssh/config|gitlab|gitlab.pub|id_rsa|id_rsa.pub
# test that root user can SSH to gitlab
chmod 600 id_rsa gitlab
ssh gitlab-1.crandell.us
```

## Nginx Config

I'm going to NOT clone the repo, as it appears to have been a temporary fix

```bash
apt install certbot nginx python3-certbot-nginx
rm -rf /etc/nginx/sites-enabled/default
ln -s /mnt/libraries/config/stack/proxy-1/nginx.crandell.us /etc/nginx/sites-enabled/crandell.us

# symlink to letsencrypt config
rm -rf /etc/letsencrypt
ln -s /mnt/libraries/config/stack/proxy-1/letsencrypt /etc/letsencrypt

# test the nginx config
nginx -t
service nginx restart
```

## Certbot Config

```bash
apt install python3-pip -y && pip3 install --upgrade pip && pip3 install certbot-dns-joker
certbot certificates
certbot certonly --dry-run --authenticator dns-joker --dns-joker-credentials /etc/letsencrypt/secrets/crandell.us.ini --dns-joker-propagation-seconds 120 -d *.crandell.us
```

## Misc Config

```bash
dpkg-reconfigure tzdata
ln -s /mnt/libraries/config/stack/proxy-1/cert-check.sh /usr/local/bin/cert-check.sh
ln -s /mnt/libraries/config/stack/shared/clean-cache.cron /etc/cron.d/clean-cache
ln -s /mnt/libraries/config/stack/proxy-1/cert-check.cron /etc/cron.d/cert-check
ln -s /mnt/libraries/config/stack/proxy-1/upgrade.conf /etc/nginx/conf.d/upgrade.conf
mv /etc/cron.d/certbot /etc/cron.d/certbot.disabled
apt clean all
```
