#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
sleep 10
sudo apt-get update
sudo apt-get -y install nginx parted

# Create a new GPT partition table
sudo parted --script /dev/sdh mklabel gpt

# Create a new primary partition with all available space
sudo parted --script /dev/sdh mkpart primary 0% 100%

# Optionally, format the new partition (assuming the new partition is /dev/sdh1)
sudo mkfs -t ext4 /dev/sdh1
echo "Partitioning and formatting completed."
sudo mkdir /mnt/demo_web_volume
sudo mount /dev/sdh1 /mnt/demo_web_volume
echo "/dev/sdh1  /mnt/demo_web_volume    ext4   defaults 0 2" >> /etc/fstab
sudo rm -rf /var/www/html
sudo mkdir /mnt/demo_web_volume/html
sudo ln -s /mnt/demo_web_volume/html /var/www/html
sudo echo "<h2>Hola Terraform</h2>" >> /var/www/html/index.html
sudo chown -R www-data:www-data /var/www/html/index.html
sudo chmod -R 755 /var/www/html/index.html