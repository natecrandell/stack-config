# Frigate Build Notes

References

- `https://github.com/blakeblackshear/frigate`
- `https://docs.frigate.video/frigate/installation`
- `https://github.com/blakeblackshear/frigate/discussions/1111`

## Container Config

```text
arch: amd64
cores: 4
features: nesting=1
hostname: frigate-1
memory: 8192
mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
net0: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=6A:F9:91:A5:2D:AA,ip=10.1.2.224/24,ip6=auto,type=veth
net1: name=eth3,bridge=vmbr3,firewall=1,hwaddr=A6:51:52:62:03:14,ip=10.1.3.224/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:224/vm-224-disk-0.raw,size=6G
startup: order=3
swap: 1024
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.cgroup2.devices.allow: c 29:0 rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.apparmor.profile: unconfined
lxc.cgroup2.devices.allow: a
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file 0, 0
lxc.mount.entry: /dev/bus/usb/004 dev/bus/usb/004 none bind,optional,create=dir 0, 0
lxc.cap.drop:
lxc.mount.auto: cgroup:rw
```

- rootfs sizes smaller than 10G fail to successfully pull Docker image
- Ensure nesting=1 (docker requirement)
- The LXC container config is intended to pass through the Coral TPM USB accelerator. I pulled it from `https://github.com/blakeblackshear/frigate/issues/1807#issuecomment-922497052`.

## Standard System Config

Perform the [standard system config](../shared/standard-config.md).

## Docker Config

Note: from here on run everything as unprivileged user

```bash
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker ${USER}
groups ${USER}

# Verify
sudo dpkg -l | grep "dock\|contain"
sudo systemctl status docker
sudo docker ps
```

I originally got the docker-compose.yml file from `https://docs.frigate.video/frigate/installation#docker`.

```bash
ln -s /mnt/libraries/config/stack/frigate-1/docker-compose.yml /home/ncrandell/docker-compose.yml
ln -s /mnt/libraries/config/stack/frigate-1/frigate.config.yml /home/ncrandell/config.yml
sudo docker compose up -d
```

The docs for this project are really disorganized. Now I'm looking [here](https://github.com/blakeblackshear/frigate/pkgs/container/frigate).

`http://10.1.2.224:5000/`
