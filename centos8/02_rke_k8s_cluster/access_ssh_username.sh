#!/bin/bash
source .env
set -eux

ssh-add $SSH_KEY_PATH

for nodeip in $SSH_IPS
  do
    ssh $USERNAME@$nodeip
done
