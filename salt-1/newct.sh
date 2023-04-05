#!/bin/bash

# This script does the following:


# This script works, but needs additional logic added so that a Debian 10 CT will skip adding the salt repo.
# Or perhaps, for extra credit, a functional check could be added to see if a repo is available for the OS/Major.
# Improvement: add function to delete CT, and execute on certain failed steps.
# Improvement: add step to check if zabbix host already exists before trying to create it.
# Improvement: get parameters interactively

# References:
#   https://pve.proxmox.com/wiki/Linux_Container
#   https://pve.proxmox.com/pve-docs/pct.1.html

# Usage:             1      2        3       4      5      6     7         8            9      10 (opt)
#   ./newct-ub.sh [host] [vmid] [hostname] [cpus] [ram] [disk] [os] [osmajorversion] [oscode] [apt|py3]
#   ./newct.sh    pve-2    232    test-1      2   2048    8   debian      10          buster

die()
{
  echo $1
  exit 1
}

#set -x

HOST=${1}
VMID=${2}
HOSTNAME=${3}
CPUS=${4}
RAM=${5}
DISK=${6}
OS=${7}
OSMAJORVERSION=${8}
OSCODE=${9}

# I can't remember in what circumstances py2 is desired.
if [ -n ${10} ]
then
  PY="apt"
else
  PY="py3"
fi


# It would be nice to use 'pveam available' and 'pveam download' if template not found
TEMPLATE_STORAGE="gvol-seaf"
VDISK_STORAGE="ceph-vdisks"
IMAGE=$(ssh ${HOST}.crandell.us "sudo pveam list ${TEMPLATE_STORAGE} | grep ${OS}-${OSMAJORRELEASE} | tail -n1 | cut -d ' ' -f1")

if [ ${OS} = 'debian' ]; then
  PACKAGES='dirmngr sudo'
elif [ ${OS} = 'ubuntu' ]; then
  PACKAGES='gnupg'
  OSMAJORVERSION='${OSMAJORVERSION}.04'
fi

# Clear out any salt-keys for a host with the same name that may be hanging around
salt-key -d ${HOSTNAME} -y


echo "Creating & starting new CT..."
ssh ${HOST}.crandell.us "set -x; sudo pct create ${VMID} ${IMAGE} -hostname ${HOSTNAME} -cores ${CPUS} -memory ${RAM} -swap 512 -rootfs ${VDISK_STORAGE}:${DISK} -ostype ubuntu -onboot 1 -net0 name=eth0,bridge=vmbr0,gw=10.1.1.1,ip=10.1.1.${VMID}/24,ip6=auto,type=veth && sudo pct start ${VMID}"
echo "Done."

echo "Executing salt-minion installation script on new CT..."
# SSH to pve node, copy install script to CT, then run it
# I'll bet I could simplify this whole thing by putting 2 scripts on the salt-master: install-salt-minion-ubuntu.bash and install-salt-minion-debian.bash
ssh ${HOST}.crandell.us "HOSTNAME=${HOSTNAME} && cat > /tmp/install-salt-minion.bash << EOF1
apt-get update && apt-get install -y ${PACKAGES}
wget -O - https://repo.saltstack.com/${PY}/${OS}/${OSMAJORVERSION}/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo "deb http://repo.saltstack.com/${PY}/${OS}/${OSMAJORVERSION}/amd64/latest ${OSCODE} main" > /etc/apt/sources.list.d/saltstack.list
apt-get update && apt-get install salt-minion -y && cat > /etc/salt/minion << EOF2
id: ${HOSTNAME}
master: 10.1.1.231
EOF2
sleep 8s
service salt-minion restart
exit
EOF1
cat /tmp/install-salt-minion.bash | sudo pct enter ${VMID}"

# Wait for salt-minion installation script to execute
sleep 8s
echo "Done."

# Accept key from new minion
salt-key -a ${HOSTNAME} -y && sleep 6s || die "Salt-key acceptance failed."

# Run a highstate
echo "Running highstate..."
salt ${HOSTNAME} state.highstate
sleep 1s

# Create basic zabbix host
salt salt-1 zabbix.host_create ${HOSTNAME} [16,21] interfaces='{type: 1,main: 1,useip: 1,ip: "10.1.1.'${VMID}'",dns: "'${HOSTNAME}'.crandell.us",port: "10050"}' templates='10258'
