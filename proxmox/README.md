# Proxmox Build Notes

Proxmox 7.3 Installation on cl-1 (NUC11) 2023-03

## Partition config

```text
# This node has a single 256G SSD
hdsize: 223
swapsize: 0
maxroot: 223
minfree: 16
maxvz: 0
```

- A positive maxvz setting results in the creation of the local-lvm storage location, which Proxmox only allows to contain disk images and containers. It will not allow backup files, ISO images, or container templates, so I'd just as soon not deal with it.
- The result of the above settings is no local-lvm was created (good), but the local volume is only 71G. The docs say the max acceptable value for maxroot is hddsize/4, but pve-1 has a 250G disk with local volume size of 240G...

Troubleshooting Notes

- If a blank installer screen is encountered, try plugging the monitor in to a different video output.
- If pasting in vim doesn't work, try `:set mouse=-a`

Switch to non-subscription repo. This can now be done within proxmox gui

## Install common packages

```bash
apt install vim sudo exa
```

## User Config

```bash
adduser ncrandell
usermod -a -G sudo ncrandell
mkdir -p /home/ncrandell/.ssh
vim /home/ncrandell/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCvG9a6E4+lZA5ZY7izC0d92JlL3/CaJUSpf+Psn1Cft24SfWCy+0EIVomEyJR0TXeYWAG7pYBmO2jgi7vKi6H+5XPb5rN/fgx8kaSQJXpfKniind/ioQ80kD54LaqD8oxXoV0BYDN39z1QaKksbypgUn0zPKV2zbT5HoaRxe3kkZKbCU0do8O+bWmAXZ/qJoRlK9l+sfa33PpNXnu2phlBo5YVVcdkivS2u3KdhzQWnPPfcEYRNjkTYkZd5bZzQoXygs69kg3C4WZiyPS7U01+4n567jFgnEPppeXnXASQcApENYH3imf78a9kw84Foh4HZ6J4T+TJIdXMuLhC2rz

chmod 600 /home/ncrandell/.ssh/authorized_keys
chmod 700 /home/ncrandell/.ssh
chown -R ncrandell: /home/ncrandell
echo "ncrandell ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ncrandell
```

## Zabbix Config

```bash
ln -s /mnt/pve/cephfs/libraries/config/stack/shared/zabbix.crandell.conf /etc/zabbix/zabbix_agentd.d/crandell.conf
# Ensure ceph mount is in place before starting Zabbix agent
vim /lib/systemd/system/zabbix-agent.service
After=ceph.target
# This checks for Ceph degraded state:
ln -s /mnt/pve/cephfs/libraries/config/stack/proxmox/zabbix-checks.cron /etc/cron.d/zabbix-checks
service zabbix-agent restart
```

## DDNS

```bash
ln -s /mnt/pve/cephfs/libraries/config/stack/proxmox/ddns.cron /etc/cron.d/ddns
```

## Command Reference

```bash
pveversion -v #Versions report
```

### Storage

```bash
pvesm status
```

### Appliance Manager Commands (CT image downloads)

`https://10.1.1.201:8006/pve-docs/chapter-pct.html#pct_configuration`

```bash
pveam update
pveam available
pveam available --section system
pveam list GVOL2
```

### CT Commands (LXC with PCT wrapper)

`https://10.1.1.201:8006/pve-docs/chapter-pct.html#pct_configuration`

```bash
pct list #Shows status of all CTs
pct create 214 GVOL2:vztmpl/ubuntu-18.04-standard_18.04-1_amd64.tar.gz -rootfs local-lvm:6G
pct start 100
pct console 100 #Start a login session via getty
pct enter 100 #Enter the LXC namespace and run a shell as root user
pct config 100 #Display the configuration
pct set 100 -net0 name=eth0,bridge=vmbr0,ip=192.168.15.147/24,gw=192.168.15.1
pct set 100 -memory 512

USAGE: pct <COMMAND> [ARGS] [OPTIONS]
       pct clone <vmid> <newid> [OPTIONS]
       pct create <vmid> <ostemplate> [OPTIONS]
       pct destroy <vmid>
       pct list 
       pct migrate <vmid> <target> [OPTIONS]
       pct move_volume <vmid> <volume> <storage> [OPTIONS]
       pct resize <vmid> <disk> <size> [OPTIONS]
       pct restore <vmid> <ostemplate> [OPTIONS]
       pct template <vmid>

       pct config <vmid>
       pct set <vmid> [OPTIONS]

       pct delsnapshot <vmid> <snapname> [OPTIONS]
       pct listsnapshot <vmid>
       pct rollback <vmid> <snapname>
       pct snapshot <vmid> <snapname> [OPTIONS]

       pct resume <vmid>
       pct shutdown <vmid> [OPTIONS]
       pct start <vmid> [OPTIONS]
       pct stop <vmid> [OPTIONS]
       pct suspend <vmid>

       pct console <vmid>
       pct cpusets 
       pct df <vmid>
       pct enter <vmid>
       pct exec <vmid> [<extra-args>]
       pct fsck <vmid> [OPTIONS]
       pct mount <vmid>
       pct pull <vmid> <path> <destination> [OPTIONS]
       pct push <vmid> <file> <destination> [OPTIONS]
       pct status <vmid> [OPTIONS]
       pct unlock <vmid>
       pct unmount <vmid>

       pct help [<extra-args>] [OPTIONS]
```

### VM Commands (QEMU)

`https://pve.proxmox.com/pve-docs/qm.1.html`

```bash
qm create 102 --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 102 bionic-server-cloudimg-amd64.img local-lvm
qm set 102 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-102-disk-1 --ide2 local-lvm:cloudinit --boot c --bootdisk scsi0 --serial0 socket --vga serial0
qm set 102 --agent 1 --localtime 1 --hotplug 0 --tablet 0 --onboot 1 --ostype l26
qm template 102
qm clone 102 103 --name testvm
qm set 103 --sshkey ~ncrandell/.ssh/authorized_keys --ipconfig0 ip=10.1.1.109/24,gw=10.1.1.1
```

### No quorum (local mode)

```bash
systemctl stop pve-cluster
/usr/bin/pmxcfs -l
```

## Unformatted Notes Dump from Proxmox 8 Rebuild (2025-07-07)

https://pve.proxmox.com/wiki/Roadmap

217 (zabbix-1)
219 (gitlab-1)
220 (proxy-1)
221 (zm-l)
222 (zm-2)
230 (tor-1)
231 (salt-1)
236 (photoprism-1)
237 (sync-1)
218 (seafile-1)

------------------------------------------------------------------------------------------ PREPARATION

# Before shutting down the current pve:
	Take backups:
		seafile-1
		gitlab-1
		zabbix-1

# Make sure the salt master has had the old cl-1 key removed:
	# On salt-1:
	salt-key -d cl-1

##### DON'T FORGET!!!
	the contents of /srv/dropbox need to be copied from the old NVMe to the new one

------------------------------------------------------------------------------------------ SETUP

# Shutdown the current pve, swap the NVMe chips, start the machine again

root/V******688!

# This node has a single 500G SSD
	hdsize: 430 
	swapsize: 0
	maxroot: 430 # Match hdsize
	minfree: 16
	maxvz: 0 # keep this 0

# IP = 10.1.1.111

# Login to the web UI and configure the network interfaces: https://10.1.1.111:8006

# Get the SATA disk mounted
	mkdir /mnt/sda1
	echo "/dev/sda1 /mnt/sda1 ext4 defaults 0 1" >> /etc/fstab
	systemctl daemon-reload
	mount -a
	
# In the proxmos web UI, configure all storage
Storage:
	cephfs
		General:
			monitors: 10.1.1.101
			User name: compute
			Secret Key: AQBkjRRhttINGxAAzCkWlOvnMinU8CetafPOjw==
			Content: VZDump backup file (backups)
		Backup Retention: (empty if not mentioned)
			Keep Last: 1
			Keep Monthly: 2
			Keep Weekly: 2
	local: (NVMe)
		General:
			Directory: /var/lib/vz
			Content: Container
			Enable: yes
			Shared: no
		Backup Retention:
			Keep Last: 3
	localSATA:
		General:
			Directory: /mnt/sda1
			Content: Disk image, Container, Container template
			Enable: no
			Shared: no
		Backup Retention:
			Keep all backups: yes

# restore salt-1 from backup

------------------------------------------------------------------------------------------ CONFIGURE SALT

# Use Proxmox web UI shell to login to cl-1 as root

# Disable unneeded repos, configure proxmox free repo
	cd /etc/apt/sources.list.d
	rm -rf ceph.list pve-enterprise.list
	echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/proxmox.list
	apt-get update && apt-get upgrade
	apt-get install vim sudo exa
	poweroff
	
apt-get install vim sudo exa
	

# Install/configure salt
	# https://github.com/saltstack/salt-bootstrap#installing-via-an-insecure-one-liner
	# On cl-1:
	curl -o bootstrap-salt.sh -L https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh
	chmod +x bootstrap-salt.sh
	./bootstrap-salt.sh -P stable 3006.1
	rm -rf /etc/salt/minion
	vim /etc/salt/minion
		master: 10.1.2.231
		id: cl-1
	systemctl restart salt-minion
		
	# On salt-1:
	salt-key -a cl-1
	salt cl-1 test.ping
	salt cl-1 state.sls common.users,common.ssh

------------------------------------------------------------------------------------------ CONFIGURE PVE

# Special Config (requires cephfs mount at /mnt/pve/cephfs) (required by tor-1 and sync-1)
	# On cl-1:
	mkdir /srv/dropbox /var/lib/vz/transmission-config
	chown -R syncadmin:crandell /var/lib/vz/transmission-config
	chown -R syncadmin:crandell /srv/dropbox
	ln -s /mnt/pve/cephfs/libraries/config/stack/tor-1/transmission.settings.json /var/lib/vz/transmission-config/transmission.settings.json

# Sudoers
	echo "ncrandell ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ncrandell
	
# Verify hostname config
	hostname
	hostname -f
	
vim /etc/resolv.conf
	domain crandell.us
	search crandell.us.
	nameserver 10.1.1.1
	nameserver 8.8.8.8

# Configure my BASH profile	
exit # to session as user ncrandell
mkdir /home/ncrandell/.bashrc.d
vim /home/ncrandell/.bashrc.d/mybash
	HISTSIZE=2000
	HISTFILESIZE=4000

	#alias ll='ls --color=auto -lha'
	alias ls='exa -la'
	alias lst='exa --tree'
	[[ $(whoami) == 'root' ]] && \
	  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ' || \
	  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '


# Zabbix
	# https://www.zabbix.com/download?zabbix=6.0&os_distribution=debian&os_version=12&components=agent&db=&ws=
	sudo -i
	wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_6.0+debian12_all.deb
	dpkg -i zabbix-release_latest_6.0+debian12_all.deb
	rm -rf zabbix-release_latest_6.0+debian12_all.deb
	apt-get update && apt-get install zabbix-agent

	ln -s /mnt/pve/cephfs/libraries/config/stack/shared/zabbix.crandell.conf /etc/zabbix/zabbix_agentd.d/crandell.conf
	# Ensure ceph mount is in place before starting Zabbix agent
	vim /lib/systemd/system/zabbix-agent.service
	After=ceph.target
	systemctl daemon-reload
	echo "Hostname=cl-1" > /etc/zabbix/zabbix_agentd.d/hostname.conf
	service zabbix-agent restart
	
# DDNS
	ln -s /mnt/pve/cephfs/libraries/config/stack/proxmox/ddns.cron /etc/cron.d/ddns

# Configure Backup Jobs

vim /etc/pve/jobs.cfg
vzdump: backup-c61ec56b-d747
        schedule Monday 04:00
        compress zstd
        enabled 1
        mailnotification failure
        mailto nate@crandell.us
        mode stop
        notes-template {{guestname}}
        storage cephfs
        vmid 220,222,231,221,219,217,237,230

vzdump: backup-6b207c6a-6b52
        comment This job only exists because VMs don't like Stop mode
        schedule Monday 03:55
        compress zstd
        enabled 1
        mailnotification failure
        mailto nate@crandell.us
        mode snapshot
        notes-template {{guestname}}
        storage cephfs
        vmid 218

vzdump: backup-c9ec3043-9c48
        comment This job exists solely to thin retention of massive photoprism-1 backup
        schedule Monday 04:30
        compress zstd
        enabled 1
        mailnotification failure
        mailto nate@crandell.us
        mode stop
        notes-template {{guestname}}
        prune-backups keep-last=2
        storage cephfs
        vmid 236

------------------------------------------------------------------------------------------

DATACENTER
Options:
	MAC address prefix: none				# in Proxmox 8 the default is now "BC:24:11"
	Next Free VMID Range: lower=220 , upper=249
CL-1
System - DNS
	server 1: 10.1.1.1
System - Hosts
	10.1.1.111 cl-1.crandell.us cl-1
System - Options
	Start on boot delay: 60s
	
------------------------------------------------------------------------------------------

root@cl-1:/etc/pve# cat storage.cfg
dir: local
        path /var/lib/vz
        content vztmpl,rootdir,images
        shared 0

cephfs: cephfs
        path /mnt/pve/cephfs
        content backup
        fs-name cephfs
        monhost 10.1.1.101
        prune-backups keep-last=1,keep-monthly=2,keep-weekly=2
        username compute

dir: localSATA
        disable
        path /mnt/sda1
        content images,vztmpl,rootdir
        prune-backups keep-all=1
        shared 0

------------------------------------------------------------------------------------------

root@cl-1:/etc/pve# cat datacenter.cfg

keyboard: en-us
next-id: lower=220,upper=249

------------------------------------------------------------------------------------------

root@cl-1:/etc/pve/nodes/cl-1# cat qemu-server/218.conf
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

------------------------------------------------------------------------------------------

root@cl-1:/etc/pve/nodes/cl-1/lxc# grep ^ 2*.conf
217.conf:arch: amd64
217.conf:cores: 3
217.conf:hostname: zabbix-1
217.conf:memory: 2048
217.conf:net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=8A:0A:D3:95:28:F6,ip=10.1.2.217/24,ip6=auto,type=veth
217.conf:net2: name=eth3,bridge=vmbr3,firewall=1,hwaddr=CA:0F:56:C7:45:69,ip=10.1.3.217/24,ip6=auto,type=veth
217.conf:onboot: 1
217.conf:ostype: ubuntu
217.conf:rootfs: local2:217/vm-217-disk-0.raw,size=15G
217.conf:startup: order=3
217.conf:swap: 0
219.conf:#Requires main subnet, as this is not behind proxy.
219.conf:arch: amd64
219.conf:cores: 2
219.conf:hostname: gitlab-1
219.conf:memory: 4096
219.conf:net0: name=eth1,bridge=vmbr1,firewall=1,hwaddr=42:88:E3:92:87:CB,ip=10.1.1.219/24,ip6=auto,type=veth
219.conf:net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=1A:62:05:1F:2E:65,ip=10.1.2.219/24,ip6=auto,type=veth
219.conf:onboot: 1
219.conf:ostype: ubuntu
219.conf:protection: 1
219.conf:rootfs: local2:219/vm-219-disk-0.raw,mountoptions=noatime,size=16G
219.conf:startup: order=4
219.conf:swap: 0
220.conf:arch: amd64
220.conf:cores: 2
220.conf:hostname: proxy-1
220.conf:memory: 512
220.conf:mp0: /mnt/pve/cephfs/libraries/config/,mp=/mnt/libraries/config
220.conf:net0: name=eth1,bridge=vmbr1,firewall=1,hwaddr=26:94:EF:52:B3:A7,ip=10.1.1.220/24,ip6=auto,type=veth
220.conf:net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=2A:6F:F6:88:37:0A,ip=10.1.2.220/24,ip6=auto,type=veth
220.conf:onboot: 1
220.conf:ostype: ubuntu
220.conf:rootfs: local2:220/vm-220-disk-0.raw,size=4G
220.conf:startup: order=2
220.conf:swap: 0
221.conf:arch: amd64
221.conf:cores: 4
221.conf:hostname: zm-1
221.conf:memory: 2048
221.conf:mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
221.conf:net0: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=0A:63:3D:38:B5:06,ip=10.1.2.221/24,ip6=auto,type=veth
221.conf:net1: name=eth3,bridge=vmbr3,hwaddr=02:B4:5B:B0:D1:82,ip=10.1.3.221/24,ip6=auto,type=veth
221.conf:onboot: 1
221.conf:ostype: ubuntu
221.conf:rootfs: local2:221/vm-221-disk-0.raw,size=6G
221.conf:startup: order=4
221.conf:swap: 0
222.conf:arch: amd64
222.conf:cores: 4
222.conf:hostname: zm-2
222.conf:memory: 2048
222.conf:mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
222.conf:net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=2A:6D:BB:EE:01:8A,ip=10.1.2.222/24,ip6=auto,type=veth
222.conf:net2: name=eth3,bridge=vmbr3,hwaddr=86:0E:72:EB:1D:CC,ip=10.1.3.222/24,ip6=auto,type=veth
222.conf:onboot: 1
222.conf:ostype: ubuntu
222.conf:rootfs: local2:222/vm-222-disk-0.raw,size=6G
222.conf:startup: order=4
222.conf:swap: 0
230.conf:arch: amd64
230.conf:cores: 2
230.conf:hostname: tor-1
230.conf:memory: 6144
230.conf:mp0: /var/lib/vz/transmission-config,mp=/home/syncadmin/.config
230.conf:mp1: /mnt/pve/cephfs/libraries/videos/,mp=/mnt/libraries/videos
230.conf:mp2: /mnt/pve/cephfs/libraries/config/,mp=/mnt/libraries/config
230.conf:net1: name=eth2,bridge=vmbr2,gw=10.1.2.1,hwaddr=4A:E9:89:34:05:DE,ip=10.1.2.230/24,ip6=auto,type=veth
230.conf:onboot: 1
230.conf:ostype: ubuntu
230.conf:rootfs: local2:230/vm-230-disk-0.raw,size=6G
230.conf:startup: order=5
230.conf:swap: 512
231.conf:arch: amd64
231.conf:cores: 2
231.conf:hostname: salt-1
231.conf:memory: 1024
231.conf:net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=1E:FC:69:65:2D:E6,ip=10.1.2.231/24,ip6=auto,type=veth
231.conf:onboot: 1
231.conf:ostype: ubuntu
231.conf:rootfs: local2:231/vm-231-disk-0.raw,size=8G
231.conf:startup: order=4
231.conf:swap: 0
236.conf:arch: amd64
236.conf:cores: 3
236.conf:features: nesting=1
236.conf:hostname: photoprism-1
236.conf:memory: 4092
236.conf:mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
236.conf:net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=C2:E3:58:14:7B:38,ip=10.1.2.236/24,ip6=auto,type=veth
236.conf:onboot: 1
236.conf:ostype: ubuntu
236.conf:rootfs: local2:236/vm-236-disk-0.raw,size=40G
236.conf:startup: order=5
236.conf:swap: 4092
237.conf:arch: amd64
237.conf:cores: 2
237.conf:hostname: sync-1
237.conf:memory: 4092
237.conf:mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
237.conf:mp1: /srv/dropbox/,mp=/home/syncadmin/Dropbox
237.conf:mp2: /mnt/sda1/cephfsbackup/,mp=/mnt/cephfsbackup
237.conf:net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=7E:AB:D6:0E:2A:E5,ip=10.1.2.237/24,ip6=auto,type=veth
237.conf:onboot: 1
237.conf:ostype: ubuntu
237.conf:rootfs: local2:237/vm-237-disk-0.raw,size=6G
237.conf:startup: order=4
237.conf:swap: 512

------------------------------------------------------------------------------------------
