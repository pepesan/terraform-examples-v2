#!/bin/bash
source .env
set -eux
for node_name in $NODE_NAMES
  do
    lxc exec $CONTAINER_NAME-$node_name -- /root/install_ssh_server_centos8.sh
done
