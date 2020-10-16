#!/bin/bash
source .env
set -eux
for nodeip in $SSH_IPS
  do
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "/root/post_install_docker_centos8.sh"
done
