#!/bin/bash

# This script is intented to run on proxy-1. It should be called every other day via cert-check.cron. It checks the expiration date of the SSL certificate for *.crandell.us. If the cert is set to expire in the next 3 days, it will renew the cert and send the new certs to gitlab-1. If the cert is not set to expire in the next 3 days, the script will exit without taking any action.

# REQUIREMENTS: curl, certbot, python3-pip

set_vars() {
  expire_date="$(certbot certificates -d '*.crandell.us' 2> /dev/null | grep Expiry | cut -d: -f2 | awk '{print $1}')"
  expire_epoch=$(date -d "${expire_date}" +%s)
  now_epoch="$(date +%s)"
  webhook="https://hooks.slack.com/services/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"
}

send_message() {
  curl -X POST -H 'Content-type: application/json' --data "${1}" ${webhook}
}

renew_certificate() {
  [[ ! -d /var/log/certbot ]] && mkdir /var/log/certbot
  [[ -f /var/log/certbot/renewal.log ]] && mv /var/log/certbot/renewal.log /var/log/certbot/renewal.log.1
  send_message "{\"text\": \"<@UT8HYKMQW>\nSSL Cert Renewal will now be attempted.\"}"
  certbot certonly -n --authenticator dns-joker --dns-joker-credentials /etc/letsencrypt/secrets/crandell.us.ini --dns-joker-propagation-seconds 120 -d '*.crandell.us' > /var/log/certbot/renewal.log
  renewal_status=$?

  if [[ ${renewal_status} -eq 0 ]]
  then
    send_message "{\"text\": \"<@UT8HYKMQW>\n*SSL Cert Renewal Succeeded*\nRenewal return code = ${renewal_status}\n\`\`\`$(cat /var/log/certbot/renewal.log)\`\`\`\"}"
    systemctl reload nginx
    sleep 2s
    update_gitlab
  else
    send_message "{\"text\": \"<@UT8HYKMQW>\n*SSL Cert Renewal Failed*\nRenewal return code = ${renewal_status}\n\`\`\`$(cat /var/log/certbot/renewal.log)\`\`\`\"}"
    exit 1
  fi
}

update_gitlab() {
  send_message "{\"text\": \"<@UT8HYKMQW>\n*SSL Cert Renewal*\nAttempting to send renewed certs to gitlab-1...\"}"
  scp /etc/letsencrypt/live/*.crandell.us/fullchain.pem root@gitlab-1.crandell.us:/etc/gitlab/ssl/gitlab.crandell.us.crt && \
  scp /etc/letsencrypt/live/*.crandell.us/privkey.pem root@gitlab-1.crandell.us:/etc/gitlab/ssl/gitlab.crandell.us.key && \
  ssh root@gitlab-1.crandell.us "service gitlab-runsvdir restart" && \
  send_message "{\"text\": \"*SSL Cert -> Gitlab Succeeded*\"}"
}

main() {
  set_vars

  # If cert expires in the next 3 days, renew it. (Note: "<@UT8HYKMQW>" at-mentions me)
  if [[ $(( expire_epoch - now_epoch )) -le 259200 ]]
  then
    renew_certificate
  elif [[ $(( expire_epoch - now_epoch )) -gt 259200 ]]
  then
    echo "Renewal not necessary at this time."
  fi
}

main
