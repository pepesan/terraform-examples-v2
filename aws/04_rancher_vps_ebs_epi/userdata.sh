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
echo "Installing dependencies..."
sudo apt-get update && sudo apt -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
echo "Adding repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
echo "installing docker"
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

echo "attempting to run: "
echo "${docker_cmd}"
# pendiente montar el volumen para el volumen de rancher
# pendiente hacer que genere certificado ssl
sudo ${docker_cmd} --acme-domain ${dns_name}