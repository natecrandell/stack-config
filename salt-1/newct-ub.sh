#!/bin/bash

# References:
#   https://pve.proxmox.com/wiki/Linux_Container
#   https://pve.proxmox.com/pve-docs/pct.1.html

# Usage:
#   ./newct-deb.sh [host] [vmid] [hostname] [cpus] [ram] [size]

# Example:
#   ./newct.sh pve-2 232 test-1 2 2048 8

set -x

HOST=${1}
VMID=${2}
HOSTNAME=${3}
CPUS=${4}
RAM=${5}
SIZE=${6}

STORAGE_TEMPLATES="gvol-seaf"                                                                                           STORAGE_VDISKS="ceph-vdisks"

if [ -n ${7} ]
then
  PY="apt"
else
  PY="py3"
fi

IMAGE=$(ssh ${HOST}.crandell.us "sudo pveam list ${STORAGE_TEMPLATES} | grep ubun | tail -n1 | cut -d ' ' -f1")

# Clear out any salt-keys for a host with the same name that may be hanging around
salt-key -d ${HOSTNAME} -y

# SSH to pve node, create CT, then install salt-minion
ssh ${HOST}.crandell.us "set -x; sudo pct create ${VMID} ${IMAGE} -hostname ${HOSTNAME} -cores ${CPUS} -memory ${RAM} -swap 512 -rootfs ${STORAGE_VDISKS}:${SIZE} -ostype ubuntu -onboot 1 -net0 name=eth0,bridge=vmbr0,gw=10.1.1.1,ip=10.1.1.${VMID}/24,ip6=auto,type=veth && sudo pct start ${VMID} && HOSTNAME=${HOSTNAME} && cat > /tmp/install-salt-minion.bash << EOF1

# Install Saltstack repo 
apt-get update && apt-get install -y gnupg
wget -O - https://repo.saltstack.com/${PY}/ubuntu/18.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo "deb http://repo.saltstack.com/${PY}/ubuntu/18.04/amd64/latest bionic main" > /etc/apt/sources.list.d/saltstack.list

# Install salt-minion
apt-get update && apt-get install salt-minion -y && cat > /etc/salt/minion << EOF2
id: ${HOSTNAME}
master: 10.1.1.231
EOF2
sleep 8s
service salt-minion restart
exit
EOF1
cat /tmp/install-salt-minion.bash | sudo pct enter ${VMID}"

sleep 8s
salt-key -a ${HOSTNAME} -y
sleep 6s
salt ${HOSTNAME} state.highstate
sleep 1s
salt salt-1 zabbix.host_create ${HOSTNAME} [16,21] interfaces='{type: 1,main: 1,useip: 1,ip: "10.1.1.'${VMID}'",dns: "'${HOSTNAME}'.crandell.us",port: "10050"}' templates='10258'
