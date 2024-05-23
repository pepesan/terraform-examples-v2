#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
sudo apt-get update
sudo apt-get -y install nginx
sudo mkfs -t xfs /dev/sdh
sudo mkdir /mnt/demo_web_volume
sudo mount /dev/sdh /mnt/demo_web_volume
echo "/dev/sdh  /mnt/demo_web_volume    xfs   defaults 0 2" >> /etc/fstab
sudo rm -rf /var/www/html
sudo mkdir /mnt/demo_web_volume/html
sudo ln -s /mnt/demo_web_volume/html /var/www/html
sudo echo "<h2>Hola Terraform</h2>" >> /var/www/html/index.html
sudo chown -R www-data:www-data /var/www/html/index.html
sudo chmod -R 755 /var/www/html/index.html