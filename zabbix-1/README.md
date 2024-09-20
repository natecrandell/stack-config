# Zabbix Server Build Notes

## Container Config (Ubuntu 22.04)

```text
arch: amd64
cores: 3
hostname: zabbix-1
memory: 2048
net1: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=8A:0A:D3:95:28:F6,ip=10.1.2.217/24,ip6=auto,type=veth
net2: name=eth3,bridge=vmbr3,firewall=1,hwaddr=CA:0F:56:C7:45:69,ip=10.1.3.217/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:217/vm-217-disk-1.raw,size=15G
startup: order=3
swap: 0
```

## Locations

/etc/zabbix/web/zabbix.conf.php
PHP server config file. A mismatch between config items here and /etc/zabbix/zabbix_server.conf can lead to "Zabbix server is not running" in browser.

## MySQL Config

Significantly reduce disk bloat by reducing MySQL bin logs, which are located at `/var/lib/mysql/binlog*`.

```bash
# See current setting
mysql -u root -p zabbix -e 'SHOW VARIABLES;' | grep -i binlog_

mysql -u root -p zabbix -e 'SET PERSIST binlog_expire_logs_seconds = (60*60*24*7);'

# Unlike previous versions of MySQL, the above setting did not cause binlogs older then 7 days to be purged, even after restarting the service. Do this to immediately purge binlogs.
mysql -u root -p -e "PURGE BINARY LOGS BEFORE '$(date +'%F %T' --date='7 days ago')';"
```

## Zabbix Server Config

```bash
echo "Include=/usr/local/etc/zabbix_server.conf.d/*.conf" >> /etc/zabbix/zabbix_server.conf
```

## Troubleshooting Notes

Run these in the DB `https://www.hasanaltin.com/you-do-not-have-the-super-privilege-on-zabbix/`

```bash
SELECT Host,USER,Super_priv FROM mysql.user;
UPDATE mysql.user SET Super_Priv='Y' WHERE USER='zabbix_srv' AND host='localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
grant all privileges on zabbix.* to 'zabbix'@'localhost';
```

- v6.0.15 causes all items requiring preprocessing to go blank. This applies to all rate over time checks, like network interface throughput.

Update database to use double precision values.

```bash
use zabbix;
ALTER TABLE trends MODIFY value_min DOUBLE PRECISION DEFAULT '0.0000' NOT NULL, MODIFY value_avg DOUBLE PRECISION DEFAULT '0.0000' NOT NULL, MODIFY value_max DOUBLE PRECISION DEFAULT '0.0000' NOT NULL;
ALTER TABLE history MODIFY value DOUBLE PRECISION DEFAULT '0.0000' NOT NULL;
```
