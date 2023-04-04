# This script is mostly intended to be run as a cron (with --all and --clean). From a high level, it checks
# the homevideos library for videos that were not encoded with HEVC to my standards, and transcodes them.

# REQUIREMENTS:
#   Packages: exiftool, ffmpeg, curl
#   Filesystem: libraries/homevideos contains only dirs (no files), there are no 2nd level dirs.

# FLAGS:
  # --all               When set all files in homevideos library will be evaluated
  # --clean             Delete input file after successful transcoding
  # --crf=n             Override the automatic crf value logic
  # --dryrun            Don't convert files, just describe what would have happened
  # --file=dir/foo.bar  Only evaluate single file
  # --sleep=5s          Add sleep period between transcoded files

  # --filter_dir
  # --filter_type

#!/bin/bash

# Slack channel: home-alerts
webhook="https://hooks.slack.com/services/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"

die() {
  echo -e "\033[1;33m$(date +'%Y-%m-%d %H:%M:%S')\033[0m \033[0;36m${1}\033[0m \033[0;31m${2}\033[0m"
  curl -X POST -H 'Content-type: application/json' --data "${1}" ${webhook}
  exit 1
}

send() {
  echo -e "\033[1;33m$(date +'%Y-%m-%d %H:%M:%S')\033[0m \033[0;36m${1}\033[0m ${2}"
}

send_slack() {
  curl -X POST -H 'Content-type: application/json' --data "${1}" ${webhook}
}

get_args() {
  for arg in "$@"
  do
    case ${arg} in
      --all)
      all=1
      base_dir='/mnt/libraries/homevideos'
      ;;

      --clean)
      clean=1
      ;;

      --crf=*)
      crf_override="${arg#*=}"
      shift
      ;;

      --dryrun)
      dryrun=1
      ;;

      --file=*)
      file="${arg#*=}"
      shift
      ;;

      --sleep=*)
      sleep="${arg#*=}"
      shift
      ;;
    esac
  done
}

error_checks() {
  # Do not allow run if ffmpeg is already being used
  [[ $(ps -C ffmpeg | wc -l &> /dev/null) -ge 2 ]] && send "Ffmpeg is already running. Transcoding aborted." && exit 0
  
  [[ ${all} -ne 0 ]] && [[ -n ${file} ]] && die "INVALID: Cannot select both: all, file"

  # Deal with dir/filename(s) containing spaces
  # Don't worry about space-checking if using single-file override (--file=foo.bar)
  if [[ -z ${file} ]] && [[ $(find ${base_dir} -name "* *" | wc -l) -gt 0 ]]
  then
    # Send a message
    send_slack "{\"text\": \"*FAIL*\nFrom: $(hostname)\nJob: auto-transcode.sh\n\nThese space-containing file/dir name(s) were found:\n\`\`\`$(find ${base_dir} -name "* *")\`\`\`\nThey have been renamed with an underscore in place of the space.\"}"

    # Rename with underscore in place of space
    find ${base_dir} -name "* *" | while read file; do mv "${file}" ${file// /_}; done && \
    send "Space-containing dir/filename(s) were found and successfully renamed."
  fi
}

evaluate() {
  file_ext="${file_in##*.}"
  file_basename="$(basename ${file_in%.*})"
  file_dirname="$(dirname ${file_in})"
  file_out="${file_basename}.h265.mp4"

  # Skip transcoding if filename ends in .h265.mp4 OR (file extension is .mp4 AND Compressor ID = hev1)
  skip_file=0
  if [[ ${file_ext} == 'mp4' ]]
  then
    if [[ $(echo "${file}" | rev | cut -d\. -f1-2) == "4pm.562h" ]]
    then
      skip_file=1
    elif [[ $(exiftool -CompressorID -s -s -s ${file_in} 2> /dev/null) == 'hev1' ]]
    then
      skip_file=1
    fi
  fi

  [[ ${skip_file} -eq 0 ]] && set_crf && transcode
  [[ ${skip_file} -eq 1 ]] && send "Skipping file ${file_in}"
}

set_crf() {
  #If no override, crf=35, unless file_in is over 2 megapixel AND bit depth >= 24, in which case crf=30
  [[ -z ${crf_override} ]] && mp=$(exiftool -Megapixels -s -s -s ${file_in} 2> /dev/null)
  if [[ -n ${crf_override} ]]
  then
    crf=${crf_override}
  elif [[ ${mp%.*} -ge 2 ]] && [[ $(exiftool -BitDepth -s -s -s ${file_in} 2> /dev/null) -ge 24 ]]
  then
    crf=30
  else
    crf=35
  fi
}

transcode() {
  # Do the transcoding (unless dryrun)
  send "ffmpeg -i ${file_in} -c:v libx265 -crf ${crf} -preset slow -movflags use_metadata_tags -map_metadata 0 /tmp/${file_out}"
  if [[ ${dryrun} -eq 0 ]]
  then
    ffmpeg -i "${file_in}" -c:v libx265 -crf ${crf} -preset slow -movflags use_metadata_tags -map_metadata 0 "/tmp/${file_out}" && \
      mv "/tmp/${file_out}" "${file_dirname}" && \
      chown syncadmin:crandell "${file_dirname}/${file_out}" && \
      [[ ${clean} -eq 1 ]] && rm -rf "${file_in}"
      [[ -n ${sleep} ]] && send "Sleeping for ${sleep}..." && sleep ${sleep}
    echo; echo
  fi
}

main() {
  # Set defaults
  export all=0 clean=0 dryrun=0

  get_args "$@"
  error_checks

  if [[ -n ${file} ]]
  then
    # If ${file} exists, use that. If not, assume relative path. If that doesn't exist, fail with message.
    [[ -e ${file} ]] && file_in=${file}
    [[ ! -e ${file} ]] && [[ -e "$(pwd)/${file}" ]] && file_in="$(pwd)/${file}"
    [[ -z ${file_in} ]] && die "Problem with filename: ${file}"
    evaluate
  elif [[ ${all} -eq 1 ]]
  then
    for file_in in ${base_dir}/**/*
    do
      evaluate
    done
  fi
}

main $@

