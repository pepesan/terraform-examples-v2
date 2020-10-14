#!/bin/bash
source .env
set -eux
chmod +x ./*.sh
./create_lxc_container.sh
./push_files.sh
./install_docker_lxc.sh

