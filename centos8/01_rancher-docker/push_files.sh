#!/bin/bash
source .env
set -eux

chmod +x ./*.sh
lxc file push .env $CONTAINER_NAME/root/
lxc file push install_docker.sh $CONTAINER_NAME/root/
lxc file push install_docker_compose.sh $CONTAINER_NAME/root/
lxc file push docker-compose.yaml $CONTAINER_NAME/root/

