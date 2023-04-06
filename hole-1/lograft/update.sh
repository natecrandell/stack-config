#!/bin/bash

logsdir='/tmp/logs'
rm -rf ${logsdir}/*

# Grab latest logs
cp /var/log/pihole/pihole.lo* ${logsdir}/
gunzip ${logsdir}/pihole.log.*.gz

sed -i '/NXDOMAIN/d' ${logsdir}/pihole.log*
sed -i '/PTR/d' ${logsdir}/pihole.log*

echo "Latest logs imported to ${logsdir}."
echo
cat /root/lograft/notes.txt

