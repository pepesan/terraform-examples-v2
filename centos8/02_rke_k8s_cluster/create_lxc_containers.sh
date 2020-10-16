#!/bin/bash
source .env
set -eux
for node_name in $NODE_NAMES
  do
    lxc launch images:centos/8/amd64 $CONTAINER_NAME-$node_name
done
sleep 10
for node_name in $NODE_NAMES
  do
    echo "Show eth0 on $node_name"
    lxc exec $CONTAINER_NAME-$node_name nmcli device show eth0
done




