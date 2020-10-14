#!/bin/bash
source .env
set -eux

chmod +x ./*.sh

for node_name in $NODE_NAMES
  do
    lxc file push .env $CONTAINER_NAME-$node_name/root/
    lxc file push install_docker_centos8.sh $CONTAINER_NAME-$node_name/root/
    lxc file push install_ssh_server_centos8.sh $CONTAINER_NAME-$node_name/root/
    lxc file push post_install_docker_centos8.sh $CONTAINER_NAME-$node_name/root/
done


