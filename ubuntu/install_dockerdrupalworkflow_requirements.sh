#!/bin/bash
source .env
set -eux
# Git and curl
sudo apt install git
#Docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install docker-ce
# Docker User manage
sudo groupadd -g 1000 $DOCKER_USER
sudo useradd -d /home/$DOCKER_USER -s /bin/bash -u 1000 -g 1000 $DOCKER_USER
sudo mkdir /home/$DOCKER_USER
sudo chown -R $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER
sudo usermod -aG docker ${USER}
sudo usermod -aG docker $DOCKER_USER
sudo usermod -aG $DOCKER_USER ${USER}
# Reboot
sudo reboot
