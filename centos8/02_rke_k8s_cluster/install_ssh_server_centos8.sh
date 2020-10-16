#!/bin/bash
source .env
set -eux

dnf install -y openssh-server iptables
systemctl start sshd
systemctl status sshd

# Open TCP/6443 for all
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

echo "AllowTcpForwarding yes" >> /etc/ssh/ssh_config
systemctl reload sshd



