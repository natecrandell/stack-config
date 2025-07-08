
# tor-1

>>> [!note]
On the next rebuild:

- Change the design. Instead of requiring the snowflakey mount point on the host for the transmission config file, just symlink to the files in the libraries mount.
- The current iteration of tor-1 seems to have duplicated files in various places. Figure this out and clean it up.

>>>

## References

- `https://help.ubuntu.com/community/TransmissionHowTo`

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

## Prerequisites

Host config:

```bash
# On cl-1:
# Expose the transmission config file, which is in version control
mkdir /var/lib/vz/transmission-config
chown -R syncadmin:crandell /var/lib/vz/transmission-config
ln -s /mnt/pve/cephfs/libraries/config/stack/tor-1/transmission.settings.json /var/lib/vz/transmission-config/transmission.settings.json

# Increase the size of the network send/receive buffers
echo "# Send/rcv buffers for tor-1" >> /etc/sysctl.conf
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 4194304" >> /etc/sysctl.conf
sysctl -p
```

The sysctl config mitigates these errors when starting the transmission-daemon:

```text
Jul 17 15:12:34 tor-1 transmission-daemon[2648]: [2019-07-17 15:12:34.421] UDP Failed to set receive buffer: requested 419
Jul 17 15:12:34 tor-1 transmission-daemon[2648]: [2019-07-17 15:12:34.421] UDP Failed to set send buffer: requested 104857
```

## Build Notes

### First Steps

1. Create the container without the mount points
1. Run the salt states to configure common users
1. Shutdown the container
1. Edit the container conf file on the host to include the mount points
1. Start the container

> [!important]
> Follow the [steps outlined here](../shared/standard-config.md) for salt (user/ssh config) and zabbix config.

Ensure appropriate permissions for the zabbix checks against the syncadmin config dir:

```bash
usermod -aG syncadmin zabbix
```

```bash
apt-get update && apt-get install transmission-cli transmission-common transmission-daemon
# or is it `apt install transmission transmission-daemon transmission-remote-gtk`?
systemctl stop transmission-daemon
rm -rf /lib/systemd/system/transmission-daemon.service
ln -s /mnt/libraries/config/stack/tor-1/transmission-daemon.service /lib/systemd/system/transmission-daemon.service # Verify me!
systemctl daemon-reload
systemctl start transmission-daemon
```

> [!note]
> The transmission-daemon's default service file has been altered to be run by `syncadmin:crandell`.

## Locations

- /lib/systemd/system/transmission-daemon.service
- ~syncadmin/.config/transmission.settings.json				Transmission config file (How does this differ from /home/syncadmin/.config/transmission-daemon/settings.json?)
- ~syncadmin/.config/transmission-daemon/[blocklists|resume|torrents]		Torrent file storage, blocklists
- /var/lib/transmission-daemon												Unsure. Looks like an unneeded dupe of /home/syncadmin/.config/transmission-daemon/. Need clarification.
- /etc/transmission-daemon/														Same as^^. Figure this shit out on the next rebuild.
