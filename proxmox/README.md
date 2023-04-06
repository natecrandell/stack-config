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
