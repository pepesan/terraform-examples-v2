#!/bin/bash
source .env
set -eux
ssh-add $ROOT_SSH_KEY_PATH

for nodeip in $SSH_IPS
  do
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "dnf update -y"
done
