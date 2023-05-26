# This script...

# REQUIREMENTS: curl, certbot, python3-pip

#!/bin/bash

set_vars() {
  expire_date="$(certbot certificates -d '*.crandell.us' 2> /dev/null | grep Expiry | cut -d: -f2 | awk '{print $1}')"
  expire_epoch="$(date -d ${expire_date} +%s)"
  now_epoch="$(date +%s)"
  webhook="https://hooks.slack.com/services/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"
}

send_message() {
  curl -X POST -H 'Content-type: application/json' --data "${1}" ${webhook}
}

renew_certificate() {
  [[ ! -d /var/log/certbot ]] && mkdir /var/log/certbot
  [[ -f /var/log/certbot/renewal.log ]] && mv /var/log/certbot/renewal.log /var/log/certbot/renewal.log.1
  certbot certonly --authenticator dns-joker --dns-joker-credentials /etc/letsencrypt/secrets/crandell.us.ini --dns-joker-propagation-seconds 120 -d '*.crandell.us' > /var/log/certbot/renewal.log
  systemctl reload nginx
}

# For debugging
#echo "Expire Date = ${expire_date}"
#echo "Expire Epoch = ${expire_epoch}"
#echo "Now Epoch = ${now_epoch}"
#echo "${expire_epoch} - ${now_epoch} = $(( ${expire_epoch} - ${now_epoch} ))"

main() {
  set_vars

  # Send message if cert expires in the next week (60s * 60m * 24h * 7d = 604800)
  # [[ $(( ${expire_epoch} - ${now_epoch} )) -le 604800 ]] && \
  #   send_message "{\"text\": \"<@UT8HYKMQW>\n*SSL Cert Expires on ${expire_date}*\n\`\`\`$(certbot certificates -d *.crandell.us 2> /dev/null | grep -v ^- | grep -v Found)\`\`\`\"}"

  # If cert expires in the next 3 days, renew it
  # Note: "<@UT8HYKMQW>" at-mentions me
  [[ $(( ${expire_epoch} - ${now_epoch} )) -le 259200 ]] && \
    renew_certificate && \
    send_message "{\"text\": \"<@UT8HYKMQW>\n*SSL Cert Renewal Succeeded*\n\`\`\`$(cat /var/log/certbot/renewal.log)\`\`\`\"}" && \
    scp /etc/letsencrypt/live/*.crandell.us/fullchain.pem root@gitlab-1.crandell.us:/etc/gitlab/ssl/gitlab.crandell.us.crt && \
    scp /etc/letsencrypt/live/*.crandell.us/privkey.pem root@gitlab-1.crandell.us:/etc/gitlab/ssl/gitlab.crandell.us.key && \
    ssh root@gitlab-1.crandell.us "service gitlab-runsvdir restart" && \
    send_message "{\"text\": \"*SSL Cert -> Gitlab Succeeded*\"}"

  [[ $(( ${expire_epoch} - ${now_epoch} )) -gt 259200 ]] && echo "Renewal not necessary at this time."
}

main

