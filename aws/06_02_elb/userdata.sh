#!/usr/bin/env bash
# This script is used as user data for EC2 instances in an Auto Scaling group behind an ELB. It installs and starts nginx to serve as a simple web server.
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
sudo apt-get update
sudo apt-get -y install nginx
sudo systemctl enable nginx
sudo systemctl start nginx