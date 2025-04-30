#!/bin/bash
# This script grabs pictures and/or videos from Nate and/or Shuh's cell phones (via Dropbox sync)
# that are older than 30 days, and moves them to the appropriate directory for long-term use.

# Flags:
#  --all      Do both filetype for Nate and Shuh
#  --dryrun   Don't actually move the files, just indicate what would have been done
#  --name     Acceptable values: either 'nate' or 'shuh'. Ignored if --all is used.
#  --filetype Acceptable values: either 'jpg' or 'mp4'. Ignored if --all is used.

#set -x

all=0
dryrun=0
names="nate shuh"
filetypes="jpg mp4"

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

get_args() {
  for arg in "$@"
  do
    case ${arg} in
      --all)
      all=1
      ;;

      --dryrun)
      dryrun=1
      ;;

      --name=*)
      name="${arg#*=}"
      shift
      ;;

      --filetype=*)
      filetype="${arg#*=}"
      shift
      ;;

    esac
  done
}

error_checks() {
  [[ -z ${name} ]] && die "REQUIRED: argument for 'name'"
  [[ -z ${filetype} ]] && die "REQUIRED: argument for 'filetype'"
  [[ " ${names[@]} " =~ " ${name} " ]] || die "INVALID: name must be 'nate' or 'shuh'"
  [[ " ${filetypes[@]} " =~ " ${filetype} " ]] || die "INVALID: name must be 'jpg' or 'mp4'"
}

mover() {
  [[ ${name} == 'nate' ]] && finddir='DCIM/Camera'
  [[ ${name} == 'shuh' ]] && finddir='Camera'
  [[ ${filetype} == 'jpg' ]] && targetdir="pictures"
  [[ ${filetype} == 'mp4' ]] && targetdir="homevideos"

  rm -rf /tmp/mover.list
  # Filenames containing spaces should have the spaces swapped out for underscores.
  find "/home/syncadmin/Dropbox/${name}/${finddir}/" -name "* *.${filetype}" -mtime +30 | while read file; do mv "$file" "${file// /_}"; done
  find "/home/syncadmin/Dropbox/${name}/${finddir}/" -name "*.${filetype}" -mtime +30 -exec ls -l --time-style=+"%Y" {} \; | awk '{print $6 " " $7}' >> /tmp/mover.list

  for year in $(awk '{print $1}' /tmp/mover.list | uniq)
  do
    # If the subdir for this year doesn't exist, create it.
    [[ ! -d /mnt/libraries/${targetdir}/${year} ]] && send "Creating dir: /mnt/libraries/${targetdir}/${year}" && mkdir -p /mnt/libraries/${targetdir}/${year} && chown syncadmin:crandell /mnt/libraries/${targetdir}/${year}

    if [[ ${dryrun} -eq 0 ]] && [[ $(cat /tmp/mover.list | wc -l) -gt 0 ]]
    then
      mv $(grep ${year} /tmp/mover.list | awk '{print $2}' | tr '\n' ' ') /mnt/libraries/${targetdir}/${year}/
      retcode=$?
      [[ ${retcode} -eq 0 ]] && send_slack "{\"text\": \"*SUCCESS*\nFrom: sync-1\nJob: dropbox-cleanup.sh\n\nThese files were moved to /mnt/libraries/${targetdir}/${year}/:\n\`\`\`$(grep ${year} /tmp/mover.list | awk '{print $2}')\`\`\`\"}"
      [[ ${retcode} -gt 0 ]] && send_slack "{\"text\": \"*FAILURE*\nFrom: sync-1\nJob: dropbox-cleanup.sh\n\nReceived return code ${retcode} when running this command:\n\`\`\`$(echo mv $(grep ${year} /tmp/mover.list | awk '{print $2}' | tr '\n' ' ') /mnt/libraries/${targetdir}/${year}/)\`\`\`\"}"
    elif [[ ${dryrun} -eq 1 ]]
    then
      send "Would have moved these files:"
      echo "$(grep ${year} /tmp/mover.list | awk '{print $2}' | sed 's/^/  /')"
      send "To /mnt/libraries/${targetdir}/${year}/"
    fi
  done
}

send_message() {
  webhook="https://hooks.slack.com/services/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"
  curl -X POST -H 'Content-type: application/json' --data "${1}" ${webhook}
}

main() {
  get_args "$@"

  if [[ ${all} -eq 0 ]]
  then
    error_checks
    mover
  else
    for name in ${names}
    do
      for filetype in ${filetypes}
      do
        mover
      done
      [[ $(find /home/syncadmin/Dropbox/${name}/ -name '*.jpg' -mtime -8 -o -name '*.mp4' -mtime -8 | wc -l) -eq 0 ]] && send_message "{\"text\": \"<@UT8HYKMQW>\n*WARNING*\nFrom: sync-1\nJob: dropbox-cleanup.sh\n\nNo new uploads detected in the last week for ${name}'s Dropbox. Please check the sync status.\"}"
    done
  fi
}

main "$@"
