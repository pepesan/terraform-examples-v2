#!/bin/bash
source .env
set -eux
for nodeip in $SSH_IPS
  do
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "/root/open_rke_ports_centos8.sh"
done
