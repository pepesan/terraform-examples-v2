#!/bin/bash
source .env
set -eux

chmod +x ./*.sh

ssh-add $ROOT_SSH_KEY_PATH

for nodeip in $SSH_IPS
  do
    scp -i $ROOT_SSH_KEY_PATH ./* root@$nodeip:/root
    scp -i $ROOT_SSH_KEY_PATH ./.env root@$nodeip:/root
done


