#!/bin/bash
source .env
set -eux

lxc exec $CONTAINER_NAME -- /root/install_docker_centos8.sh
lxc exec $CONTAINER_NAME -- /root/install_docker_compose.sh