#!/bin/bash
auth='--auth=ncrandell:Vandal8131!'

action='list'
[[ ${1} == '--delete' ]] && action='delete'

/usr/bin/systemctl restart transmission; echo $?; sleep 10s
if [[ ${action} == 'delete' ]]
then
  for id in $(transmission-remote ${auth} -l | grep -v '^ID\|^Sum\|Downloading' | awk '{print $1}' | grep "\*" | cut -d\* -f1)
  do
    transmission-remote ${auth} -t ${id} -r
  done
else
  transmission-remote ${auth} -l | grep "\*"
fi
