# Flags:
#   Accepted values: morning, hourly, or yesterday
#   Default behavior is "today so far".

#!/bin/bash

die() {
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') $@"
  exit 1
} 

send() {
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') $@"
}

send_slack() {
  webhook="https://hooks.slack.com/services/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"
  curl -X POST -H 'Content-type: application/json' --data "${1}" ${webhook}
}

# Set date/hour filter based on $1
set_vars() {
  archive_date="$(date +'%Y-%m-%d')"
  hit_list="$(cat /root/lograft/hit.list)"
  safe_list="$(cat /root/lograft/safe.list)"
  log_source="/var/log/pihole/pihole.log"

  if [[ $1 == "morning" ]]
  then
    date_filter="$(date '+%b %_d') 0[0-8]:"
  elif [[ $1 == "hourly" ]]
  then
    date_filter="$(date '+%b %_d %H:' --date='1 hour ago')"
  elif [[ $1 == "yesterday" ]]
  then
    date_filter="$(date '+%b %_d ' --date='1 day ago')"
    log_source="/var/log/pihole/pihole.log.1"
    archive_date="$(date +'%Y-%m-%d' --date='1 day ago')"
  else
    date_filter="$(date '+%b %_d')"
  fi
}

main() {
  set_vars "$1"

  # Check for hits
  hit_ip_count=$(cat ${log_source} | grep -E "${date_filter}" | grep "${hit_list}" | cut -d: -f4- | cut -d' ' -f3- | grep ' from ' | cut -d' ' -f3 | sort | uniq | grep -civ "${safe_list}" 2> /dev/null)
  hit_ip_count_retcode=$?
  [[ ${hit_ip_count_retcode} -ne 0 ]] && die "Failed to check for hit IPs. retcode=${hit_ip_count_retcode}"

  if [[ ${hit_ip_count} -gt 0 ]]
  then
    # Send slack message with details for each ${hit_ip} found
    for ip in $(cat ${log_source} | egrep "${date_filter}" | grep "${hit_list}" | cut -d: -f4- | cut -d' ' -f3- | grep ' from ' | cut -d' ' -f3 | sort | uniq | grep -v "${safe_list}")
    do
      send_slack "{\"text\": \"*HIT FOUND: ${ip}*\n\`\`\`$(cat ${log_source} | grep "${ip}" | egrep "${date_filter}" | grep "${hit_list}" | grep -v "AAAA\|HTTPS" | rev | cut -d' ' -f3- | rev)\`\`\`\"}"

      # Archive records of the hits, and the context around it
      cat ${log_source} | grep "${ip}" | egrep "${date_filter}" | grep "${hit_list}" >> "/root/lograft/archive/${archive_date}.hits.log"
      cat ${log_source} | grep "${ip}" | egrep "${date_filter}" >> "/root/lograft/archive/${archive_date}.context.log"
    done
  else
    send "Hit check suceeded. No hits found."
    exit 0
  fi
}

main "$@"
