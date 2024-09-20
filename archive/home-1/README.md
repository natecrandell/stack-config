# Home Assistant Build Notes

References
- `https://www.home-assistant.io/installation/linux#install-home-assistant-container`

## Container Config

```text
arch: amd64
cores: 2
features: nesting=1
hostname: home-1
memory: 2048
mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
net0: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=72:1B:58:BF:08:EF,ip=10.1.2.225/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local2:225/vm-225-disk-0.raw,size=6G
startup: order=3
swap: 0
```

- Ensure nesting=1 (docker requirement)

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

## Home Assistant Config

```bash
ln -s /mnt/libraries/config/stack/home-1/docker-compose.yml /home/ncrandell/docker-compose.yml
sudo chown -R root: /mnt/libraries/config/stack/home-1
sudo docker compose up -d
```

## Troubleshooting Notes

I'm seeing connection timeout, manifesting in onboarding OOBE via browser as a freeze-up.

```text
homeassistant  | 2023-04-18 12:51:04.712 ERROR (MainThread) [homeassistant.components.homeassistant_alerts] Timeout fetching homeassistant_alerts data
# After disabling IPv6 the error no longer appears in the logs, but onboarding still hangs
# I re-enabled IPv6 and clicked 'finish' to get around this issue for now.
```

I get 400 when using proxy-1.

```text
2023-04-18 13:03:08.617 ERROR (MainThread) [homeassistant.components.http.forwarded] A request from a reverse proxy was received from 10.1.2.220, but your HTTP integration is not set-up for reverse proxies
```

files='configuration.yaml docker-compose.yml scenes.yaml scripts.yaml secrets.yaml'; for file in ${files}; do ln -s /mnt/libraries/config/stack/home-1/${file} /root/${file}; done

**It doesn't like symlinking to yaml files.**

# Reset config and start over
	rm -rf .storage/ automations.yaml blueprints/ configuration.yaml  deps/ home-assistant* *.yaml tts/
  