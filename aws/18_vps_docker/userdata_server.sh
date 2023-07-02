#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
sleep 10
sudo apt update
sudo apt install -y git python3-pip ansible
pip3 install ansible
cd /home/ubuntu
git clone https://github.com/pepesan/ejemplos-ansible.git
chown -R ubuntu:ubuntu /home/ubuntu/ejemplos-ansible
cd ejemplos-ansible/28_docker_local
ansible-playbook docker.yaml