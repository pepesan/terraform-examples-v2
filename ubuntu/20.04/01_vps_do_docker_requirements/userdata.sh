#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
# Mount Volume
DEVICE_FS=`blkid -o value -s TYPE ${device_path}`
if [ "`echo -n $DEVICE_FS`" == "" ] ; then
        mkfs.ext4 ${device_path}
fi
mkdir -p ${mount_path}
echo '${device_path} ${mount_path} ext4 defaults 0 0' >> /etc/fstab
mount ${mount_path}
# Git and curl
sudo apt install -y git
#Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install -y docker-ce
# Docker User manage
sudo groupadd -g 1000 ${DOCKER_USER}
sudo useradd -d /home/${DOCKER_USER} -s /bin/bash -u 1000 -g 1000 ${DOCKER_USER}
sudo mkdir /home/${DOCKER_USER}
sudo chown -R ${DOCKER_USER}:${DOCKER_USER} /home/${DOCKER_USER}
sudo usermod -aG docker ${DOCKER_USER}
# Reboot
#sudo reboot
