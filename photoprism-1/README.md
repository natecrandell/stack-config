# Photoprism Build Notes

Install Photoprism (docker-compose method) running on Ubuntu 22 container
`https://docs.photoprism.app/getting-started/docker-compose/`

Design decisions:

- Photoprism will run on an Ubuntu 22.04 container
- The container storage will run on the Proxmox host's local SSD-backed storage. This is to avoid incurring significant network overhead by using cephfs or an rbd block device.
- Regular backups will be taken of the container's root fs
- The Photoprism data dir will be part of the container's root filesystem.
- An additional mount will be provided by the Proxmox host. It is a connection to photo library.

Download latest Ubuntu 22.04 container template in Proxmox

## Container Config

```text
arch: amd64
cores: 3
features: nesting=1
hostname: photoprism-1
memory: 4092
mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=C2:E3:58:14:7B:38,ip=10.1.2.236/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:236/vm-236-disk-0.raw,size=40G
startup: order=4
swap: 4092
```

- Photoprism recommends at least 4G swap to prevent indexing from causing restarts
- Ensure nesting=1 (docker requirement)

Note: from here on run everything as unprivileged user

## Docker Config

```bash
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker ${USER}
groups ${USER}

# Verify
sudo dpkg -l | grep "dock\|contain"
sudo systemctl status docker
sudo docker ps
```

## Photoprism Config

`https://docs.photoprism.app/getting-started/docker-compose/`

```bash
sudo mkdir /data

# Download the official docker-compose.yml
wget https://dl.photoprism.app/docker/docker-compose.yml

vim docker-compose.yml
PHOTOPRISM_ADMIN_PASSWORD: "[redacted]"
PHOTOPRISM_SITE_URL: "http://10.1.1.236:2342/"
user: "1111:1111"
volumes:
  - "/mnt/libraries/pictures:/photoprism/originals"
  - "/mnt/libraries/homevideos:/photoprism/originals/homevideos"
  - "/data:/photoprism/storage"
```

```bash
sudo docker compose up -d
```

## Command Reference

`https://docs.photoprism.app/getting-started/docker-compose/#examples`

```bash
sudo docker compose pull #update
sudo docker compose exec photoprism photoprism users add
```

Note: I created user: guest, password: password
