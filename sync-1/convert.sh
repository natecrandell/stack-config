# This script...

# Flags
#   filter command
#   crf value (default is 22)

#!/bin/bash

die() {
  echo -e "\033[1;33m$(date +'%Y-%m-%d %H:%M:%S')\033[0m \033[0;36m${1}\033[0m \033[0;31m${2}\033[0m"
  exit 1
}

send() {
  echo -e "\033[1;33m$(date +'%Y-%m-%d %H:%M:%S')\033[0m \033[0;36m${1}\033[0m ${2}"
}

error_checks() {
  # verify that /root/convert_me.list exists and that each of the files mentioned therein also exist
  echo
}

main() {
  error_checks

  this_file=0
  total_files=$(cat /root/convert_me.list | wc -l)

  for input_file in $(cat /root/convert_me.list)
  do
    ((this_file++))
    send "${this_file}/${total_files}" "Beginning conversion of $(pwd)/${input_file}"

    crf=22
    output_file="$(echo ${input_file} | rev | cut -d. -f2- | rev).mp4"
    echo "input_file=${input_file}"
    echo "output_file=${output_file}"
    #ffmpeg -i ${input_file} -c:v libx265 -crf ${crf} /home/syncadmin/${output_file}
    retcode=$?
    echo "retcode=${retcod}"	
    #[[ ${retcode} -ne 0 ]] && die "FAIL" "ffmpeg conversion returned status ${retcode}"
    [[ ${retcode} -ne 0 ]] && echo "Rutrow. retcode!=0"
	
    #chown syncadmin:crandell /home/syncadmin/${output_file}
    #mv /home/syncadmin/${output_file} ./ && rm -rf ${input_file}
  done
}

main

