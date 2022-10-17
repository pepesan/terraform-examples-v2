#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
# formateo de volumen
sudo mkfs -t xfs /dev/nvme1n1
# creación carpeta
mkdir /usr/share/nginx/html
# montaje
echo "/dev/nvme1n1  /usr/share/nginx/html  xfs  defaults,nofail  0  2" >> sudo tee /etc/fstab
sudo mount /dev/nvme1n1 /usr/share/nginx/html

# Instalar servidor Web
sudo dnf install -y nginx
# habilita nginx
sudo systemctl enable nginx
# inicia el servidor
sudo systemctl start nginx

# firewalld
sudo dnf install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
# abrir puertos
sudo firewall-cmd --zone=public --permanent  --add-service=http
sudo firewall-cmd --zone=public --permanent  --add-service=https
# sudo firewall-cmd --permanent --add-port={80/tcp,443/tcp}
sudo firewall-cmd --reload
