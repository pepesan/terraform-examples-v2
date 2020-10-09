#!/bin/bash
source .env
set -eux
chmod +x ./*.sh
./install_docker_centos8.sh
./install_docker_compose.sh
./install_docker_compose_rancher.sh

