#!/bin/bash
source .env
set -eux
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce docker-ce-cli containerd.io

systemctl start docker
systemctl enable docker
# create user for docker
# groupadd docker
echo "Create a normal user for docker: $USERNAME"
adduser $USERNAME
passwd $USERNAME
usermod -aG docker $USERNAME
newgrp docker
echo "Log out and check if $USERNAME can access to docker: $ docker ps"
exit

