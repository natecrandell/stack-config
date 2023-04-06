# Pi-hole Build Notes

## References

- `https://www.smarthomebeginner.com/pi-hole-setup-guide/`
- Blocklist collections: `https://firebog.net/` (run pihole -g after changing adlists)

## Container Config File

```text
#Main subnet is required for DNS requests from DHCP users.
arch: amd64
cores: 4
hostname: hole-1
memory: 768
mp0: /mnt/pve/cephfs/libraries/config/,mp=/mnt/libraries/config
net0: name=eth1,bridge=vmbr1,firewall=1,hwaddr=86:09:8B:94:EB:21,ip=10.1.1.235/24,ip6=auto,type=veth
net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=FE:93:A8:2D:17:43,ip=10.1.2.235/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
protection: 1
rootfs: local:235/vm-235-disk-1.raw,size=20G
startup: order=1
swap: 0
```

```bash
apt-get update; apt-get dist-upgrade -y; apt-get install vim gnupg2 software-properties-common -y
echo "deb http://repo.saltstack.com/py3/ubuntu/18.04/amd64/latest bionic main" > /etc/apt/sources.list.d/saltstack.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E08A149DE57BFBE; apt-get update; apt-get install salt-minion -y
```

## Configure salt minion and run basic highstate

## Install pi-hole

```bash
curl -sSL https://install.pi-hole.net | bash
```

Yeah that's pretty much it.

### Reset admin pwd

```bash
pihole -a -p
```

### Reign in query DB bloat

```bash
vim /etc/pihole/pihole-FTL.conf
PRIVACYLEVEL=0
MAXLOGAGE=24.0
IGNORE_LOCALHOST=yes
MAXDBDAYS=30
```

## Lograft Config

```bash
ln -s /mnt/libraries/config/stack/$(hostname)/README.md /root/README.md
ln -s /mnt/libraries/config/stack/hole-1/lograft/ /root/lograft
ln -s /tmp/logs/ /mnt/libraries/config/stack/hole-1/lograft/logs
ln -s /mnt/libraries/config/stack/hole-1/lograft.cron /etc/cron.d/lograft
```
