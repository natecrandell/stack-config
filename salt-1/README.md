# salt-1 Build Notes

Salt master.

## Container Config (Ubuntu 18.04)

```text
arch: amd64
cores: 2
hostname: salt-1
memory: 1024
net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=1E:FC:69:65:2D:E6,ip=10.1.2.231/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:231/vm-231-disk-0.raw,size=8G
startup: order=4
swap: 0
```
