# Photoprism Build Notes

Install Photoprism (docker-compose method) running on Ubuntu 22 container
`https://docs.photoprism.app/getting-started/docker-compose/`

## References

- `https://docs.photoprism.app/release-notes/`

## Design Decisions

- Photoprism will run on an Ubuntu 22.04 container
- The container storage will run on the Proxmox host's local SSD-backed storage. This is to avoid incurring significant network overhead by using cephfs or an rbd block device.
- Regular backups will be taken of the container's root fs
- The Photoprism data dir will be part of the container's root filesystem.
- An additional mount will be provided by the Proxmox host. It is a connection to photo library.

## Container Config (Ubuntu 22.04)

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
rootfs: local2:236/vm-236-disk-0.raw,size=40G
startup: order=5
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

Note: the docker-compose.yml file if FAR from complete. See `https://docs.photoprism.app/getting-started/config-options/` for additional options.

vim docker-compose.yml
PHOTOPRISM_ADMIN_PASSWORD: "[redacted]"
PHOTOPRISM_SITE_URL: "http://10.1.1.236:2342/"
PHOTOPRISM_WAKEUP_INTERVAL: 86400 # Add this option to prevent heavy IO every 15m
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

## Issues

### Auth

Photoprism's auth handling does not yet have any level of useful maturity. See `https://github.com/photoprism/photoprism/discussions/1678` and `https://docs.photoprism.app/release-notes/#november-2-2022`)

### Maps

The Photoprism project lacks resources to implement maps with reasonable level of detail See `https://github.com/photoprism/photoprism/issues/2998`.
