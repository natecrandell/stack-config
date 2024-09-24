#!/bin/bash

# This script syncs a list of critical libraries to a backup location in case of catastrophic Ceph failure.

send_slack() {
  webhook="https://hooks.slack.com/services/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"
  curl -X POST -H 'Content-type: application/json' --data "${1}" ${webhook}
}

main() {
  dirs="backup config documents homevideos pictures"
  source="/mnt/libraries"
  destination="/mnt/cephfsbackup"

  for dir in ${dirs}; do
    rsync --archive --delete --exclude=".git/" "${source}/${dir}" ${destination}/
    retcode=$?
    [[ ${retcode} -ne 0 ]] && send_slack "{\"text\": \"*FAILURE*\nFrom: sync-1\nJob: cephfsbackup.sh\n\nReceived return code ${retcode} en attempting to rsync \`${source}/${dir}\` -> \`${destination}/\`\"}"
  done
}

main
