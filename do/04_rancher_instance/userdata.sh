#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
# Set Hostname
uuid="$(cat /sys/class/net/*/address | head -n 1 |sed -r 's/[:]+/-/g')"
node_hostname=${hostname-prefix}-$uuid
sudo hostnamectl set-hostname $node_hostname
sudo echo "127.0.0.1  $node_hostname" >> /etc/hosts
# Setup Docker + Rancher
sudo apt-get update && sudo apt -y install docker.io=19.03.8-0ubuntu1 ntp
echo "attempting to run: "
echo "${docker_cmd}"
# pendiente montar el volumen para el volumen de rancher
# pendiente hacer que genere certificado ssl
sudo ${docker_cmd}