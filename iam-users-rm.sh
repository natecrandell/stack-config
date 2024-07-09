#!/bin/bash

# This script will loop through each IAM user in the iam-users.list file and disable their access keys.

# Functions for messaging
die() {
  echo -e "\e[31m$(date +'%Y-%m-%d %H:%M:%S') ERROR\e[0m $@"
  exit 1
}

send() {
  # If 2 args are passed use a different color for the first arg
  if [[ $# -eq 2 ]]; then
    echo -e "\e[96m$(date +'%Y-%m-%d %H:%M:%S')\e[90m $1\e[0m $2"
  else
    echo -e "\e[96m$(date +'%Y-%m-%d %H:%M:%S')\e[0m $@"
  fi
}

error_check() {
  [[ -e ./iam-user-test.list ]] || die "iam-user-test.list not found"
  [[ ! $(which aws) ]] && die "AWS CLI not found"
  [[ ! $(which jq) ]] && die "jq not found"
}

grop_check (){
  num_groups=$(aws iam list-groups-for-user --user-name "${iam_user}" | jq -r '.[] | .[] | .GroupName'  | wc -l)
  if [[ ${num_groups} -gt 0 ]]; then
    send "User ${iam_user} is a member of ${num_groups} groups"
    for group in $(aws iam list-groups-for-user --user-name "${iam_user}" | jq -r '.[] | .[] | .GroupName'); do
        send "Removing IAM User: ${iam_user} from group: ${group}"
        aws iam remove-user-from-group --group-name "${group}"  --user-name "${iam_user}"
    done
  fi
}

policy_check (){
  num_policies=$(aws iam list-user-policies --user-name "${iam_user}" | jq -r '.[] | .[]'  | wc -l)
  if [[ ${num_policies} -gt 0 ]]; then
    send "User ${iam_user} is a member of ${num_policies} policies"
    for policy in $(aws iam list-user-policies --user-name "${iam_user}" | jq -r '.[] | .[]'); do
        send "Delete IAM User: ${iam_user} from policy: ${policy}"
        aws iam delete-user-policy --user-name "${iam_user}" --policy-name "${policy}"
    done
  fi
}

access_key(){
  num_keys=$(aws iam list-access-keys --user-name "${iam_user}" | jq -cr '.AccessKeyMetadata | .[]' | jq -r '.AccessKeyId'  | wc -l)
  if [[ ${num_keys} -gt 0 ]]; then
    for key in $(aws iam list-access-keys --user-name "${iam_user}" | jq -cr '.AccessKeyMetadata | .[]' | jq -r '.AccessKeyId'); do
      send "Delete IAM User: ${iam_user} key: ${key}"
      aws iam delete-access-key --access-key-id "${key}" --user-name "${iam_user}" || die "Failed to delete key: ${key}"
    done
  fi
}

mfa_check (){
  num_mfa=$(aws iam list-mfa-devices --user-name "${iam_user}" | jq -cr '.MFADevices | .[]' | jq -r '.SerialNumber'  | wc -l)
  if [[ ${num_mfa} -gt 0 ]]; then
    send "User ${iam_user} is a member of ${num_mfa} policies"
    for serial_number in $(aws iam list-mfa-devices --user-name "${iam_user}" | jq -cr '.MFADevices | .[]' | jq -r '.SerialNumber'); do
        send "Delete IAM User: ${iam_user} from MFA device: ${serial_number}"
       # aws iam deactivate-mfa-device --user-name "${iam_user}" --serial-number "${serial_number}"
    done
  fi
}

user_delete (){
  send "Deleting user: ${iam_user}"
  aws iam delete-login-profile --user-name "${iam_user}"
  aws iam delete-user --user-name "${iam_user}" || die "Failed to delete user: ${iam_user}"
  
  send "User ${iam_user} was deleted"
}

main() {
  error_check
  for iam_user in $(cat iam-user-test.list | grep -v ^'#'); do
    grop_check
    policy_check
    access_key
    mfa_check
    user_delete   
  done
}

main
