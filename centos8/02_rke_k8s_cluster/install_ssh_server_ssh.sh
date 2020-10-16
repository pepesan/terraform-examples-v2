#!/bin/bash
source .env
set -eux
for nodeip in $SSH_IPS
  do
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "/root/install_ssh_server_centos8.sh"
done
