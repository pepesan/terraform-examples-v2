#!/bin/bash
source .env
set -eux
swapoff -a
sed -i '/ swap / s/^(.*)$/#\1/g' /etc/fstab


