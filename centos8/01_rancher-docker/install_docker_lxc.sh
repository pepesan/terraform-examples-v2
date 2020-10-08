#!/bin/bash
source .env
set -eux

lxc exec $CONTAINER_NAME -- /root/install_docker.sh
lxc exec $CONTAINER_NAME -- /root/install_docker_compose.sh