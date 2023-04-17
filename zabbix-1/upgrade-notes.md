# Zabbix Server Upgrade Notes

Reference
Upgrading to 6.2 requires upgrading from PHP 7.2 to at least 7.4, which is tricky. Will need to start by backing up zabbix-1, and really studying the PHP upgrade process.

References

- [Download Page](https://www.zabbix.com/download)
- [Upgrade procedure](https://www.zabbix.com/documentation/current/en/manual/installation/upgrade/packages/debian_ubuntu)

```bash
service zabbix-server stop
service zabbix-agent stop
rm -rf /etc/apt/sources.list.d/zabbix.list.dpkg-dist
vim /etc/apt/sources.list.d/zabbix.list
deb http://repo.zabbix.com/zabbix/6.0/ubuntu bionic main
deb-src http://repo.zabbix.com/zabbix/6.0/ubuntu bionic main

# Keep copies of config
cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak
cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bak
cp /etc/zabbix/apach.conf /etc/zabbix/apache.conf.bak
cp /etc/mysql/mysql.cnf /etc/mysql/mysql.cnf.bak
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak

# https://dev.mysql.com/doc/mysql-shell/8.0/en/mysql-shell-install-linux-quick.html
wget https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
dpkg -i mysql-apt-config_0.8.22-1_all.deb

apt-get update
apt list -a mysql-server
apt-get install mysql-server=8.0.29-1ubuntu18.04
apt-get install mysql-shell

apt-get install zabbix-release=1:6.0-3+ubuntu18.04
apt-get install zabbix-get=1:6.0.6-1+ubuntu18.04
apt-get install zabbix-agent=1:6.0.6-1+ubuntu18.04
apt-get install --only-upgrade zabbix-server-mysql zabbix-frontend-php zabbix-agent
apt-get upgrade zabbix-apache-conf
apt-get install zabbix-sql-scripts

# https://www.zabbix.com/documentation/6.0/en/manual/appendix/install/db_primary_keys#mysql


mysql -uzabbix -pChair9899 zabbix < /usr/share/doc/zabbix-sql-scripts/mysql/history_pk_prepare.sql
screen
mysql -uroot -pChair9899 zabbix
SET GLOBAL local_infile = 'ON';
\q
mysqlsh -uroot -S /run/mysqld/mysqld.sock --no-password -Dzabbix
```

```text
CSVPATH="/var/lib/mysql-files";
util.exportTable("history_old", CSVPATH + "/history.csv", { dialect: "csv" });
util.importTable(CSVPATH + "/history.csv", {"dialect": "csv", "table": "history" });
util.exportTable("history_uint_old", CSVPATH + "/history_uint.csv", { dialect: "csv" });
util.importTable(CSVPATH + "/history_uint.csv", {"dialect": "csv", "table": "history_uint" });
util.exportTable("history_str_old", CSVPATH + "/history_str.csv", { dialect: "csv" });
util.importTable(CSVPATH + "/history_str.csv", {"dialect": "csv", "table": "history_str" });
util.exportTable("history_log_old", CSVPATH + "/history_log.csv", { dialect: "csv" });
util.importTable(CSVPATH + "/history_log.csv", {"dialect": "csv", "table": "history_log" });
util.exportTable("history_text_old", CSVPATH + "/history_text.csv", { dialect: "csv" });
util.importTable(CSVPATH + "/history_text.csv", {"dialect": "csv", "table": "history_text" });`
```

```bash
mysql -uroot -pChair9899 zabbix
DROP TABLE history_old;
DROP TABLE history_uint_old;
DROP TABLE history_str_old;
DROP TABLE history_log_old;
DROP TABLE history_text_old;

echo 'Include=/usr/local/etc/zabbix_server.conf.d/*.conf' >> /etc/zabbix/zabbix_server.conf
mkdir -p /usr/local/etc/zabbix_server.conf.d
vim /usr/local/etc/zabbix_server.conf.d/crandell.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=Chair9899
StartPollers=8
StartIPMIPollers=6
StartPollersUnreachable=2
StartTrappers=3
StartPingers=10
StartDiscoverers=1
StartAlerters=1
ExternalScripts=/usr/lib/zabbix/externalscripts
StartProxyPollers=0

service mysql status
service zabbix-server status
```

### Cleanup

```bash
apt-get remove mysql-shell
apt-get autoremove
rm -rf /var/lib/mysql-files/*
```

## Upgrade to 6.0.15 (2023-04)

While upgrading to 6.0.15 the zabbix-server service would not start.

``text
11857:20221209:194033.643 starting automatic database upgrade
11857:20221209:194033.645 [Z3005] query failed: [1419] You do not have the SUPER privilege and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable) [create trigger hosts_name_upper_insert
before insert on hosts for each row
set new.name_upper=upper(new.name)]
11857:20221209:194033.645 database upgrade failed
```

I found a helpful fellow that shared [his solution](https://www.hasanaltin.com/you-do-not-have-the-super-privilege-on-zabbix/) to the problem. It worked for me.

```bash
UPDATE mysql.user SET Super_Priv='Y' WHERE USER='zabbix' AND host='localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
grant all privileges on zabbix.* to 'zabbix'@'localhost';
```
