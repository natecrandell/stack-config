# Standard System Config

Ensure that a DNS A record exists for [newct].

```bash
ssh root@<newct>
apt update && apt upgrade -y
```

## Salt Config

```bash
apt install -y salt-minion
echo "master: 10.1.2.231" > /etc/salt/minion && echo "id: $(hostname)" >> /etc/salt/minion
service salt-minion restart
```

On salt master:

```bash
salt-key -a <newct>
salt <newct> test.ping
salt <newct> state.highstate
```

Note: the above highstate should configure common users with appropriate SSH, set the timezone, and install standard packages: curl, lsof, sudo, vim, unattended-upgrades, and zabbix-agent. See [common salt states](https://gitlab.crandell.us/salt/states/-/tree/master/common).

## Configure Zabbix Agent

```bash
curl https://repo.zabbix.com/zabbix-official-repo.key -o /usr/share/keyrings/zabbix-official-repo.key
echo "deb [signed-by=/usr/share/keyrings/zabbix-official-repo.key] https://repo.zabbix.com/zabbix/6.0/ubuntu $(lsb_release -c | awk '{print $2}') main" > /etc/apt/sources.list.d/zabbix.list
apt update && apt install zabbix-agent -y
ln -s /mnt/libraries/config/stack/shared/zabbix.crandell.conf /etc/zabbix/zabbix_agentd.d/crandell.conf
echo "Hostname=$(hostname)" > /etc/zabbix/zabbix_agentd.d/hostname.conf
service zabbix-agent restart
```

- Ensure that host config exists on zabbix server.
- Add [newct] to Proxmox backup job

## Cron Jobs

```bash
ln -s /mnt/libraries/config/stack/$(hostname)/zabbix-checks.cron /etc/cron.d/zabbix-checks
ln -s /mnt/libraries/config/stack/shared/clean-cache.cron /etc/cron.d/clean-cache
```

## README

```bash
ln -s /mnt/libraries/config/stack/$(hostname)/README.md /root/README.md
```
