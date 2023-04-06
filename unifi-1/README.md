# Unifi Controller Build Notes

On Ubuntu 18 Container

Have to downgrade to MongoDB 3.4

`https://docs.mongodb.com/v3.4/tutorial/install-mongodb-on-ubuntu/`

```bash
apt-get install gnupg
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
apt-get update
apt-get install -y mongodb-org

echo 'deb http://www.ubnt.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ubnt.com/unifi/unifi-repo.gpg
apt-get update && apt-get install -y openjdk-8-jdk && apt-get install -y unifi
```

## Unifi Version Update Notes

When the unifi stable repo changes, do this

```bash
vim /etc/apt/sources.list.d/100-ubnt-unifi.list # Update the name of the repo
apt-get clean
apt-get update -y --allow-releaseinfo-change
apt-get dist-upgrade
```

This VM appears to require these packages:

- gnupg
- mongodb-org
- openjdk-8-jdk
- unifi

To update unifi and all other system software, just run:

```bash
salt unifi-1 cmd.run 'apt-get update && apt-get upgrade -y'
```
