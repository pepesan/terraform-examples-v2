#!/usr/bin/env bash
set -eux
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
# Distro update
dnf update -y
# Git and curl
dnf install -y git curl wget
# PHP Cli 7.4
# Reference: https://www.tecmint.com/install-php-on-centos-8/
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module -y enable php:remi-7.4
dnf install -y php-cli php-common php-gd php-curl php-mysql php-zip php-xml php-mysqli php-mbstring unzip
# Mariadb Client
# Reference: https://computingforgeeks.com/how-to-install-mariadb-server-on-centos-rhel-linux/
tee /etc/yum.repos.d/MariaDB.repo<<EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos8-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
# Reference: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-centos-8-es
dnf install -y boost-program-options
dnf install -y MariaDB-client --disablerepo=AppStream

dnf module -y enable nodejs:12
dnf install -y nodejs
node -v
npm -v

#Composer
export HOME=/root
echo "export PATH=$PATH:$HOME/.config/composer/vendor/bin" >> .bashrc
echo "export COMPOSER_HOME='$HOME/.config/composer'" >> .bashrc
source .bashrc
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/bin --filename=composer
composer --version
#Drush
composer global require drush/drush
drush --version
# Docker
# Reference: https://www.linuxtechi.com/install-docker-ce-centos-8-rhel-8/
dnf config-manager -y --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce --nobest -y
systemctl start docker
systemctl enable docker
docker -v
docker ps

# Docker compose
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

reboot
