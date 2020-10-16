#!/bin/bash
source .env
set -eux
ssh-add $ROOT_SSH_KEY_PATH

for nodeip in $SSH_IPS
  do
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "mkdir -p /home/$USERNAME/.ssh"
    scp -i $ROOT_SSH_KEY_PATH $SSH_KEY_PATH.pub root@$nodeip:/home/$USERNAME/.ssh/
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "cat /home/$USERNAME/.ssh/$SSH_KEY_FILE.pub > /home/$USERNAME/.ssh/authorized_keys"
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "rm /home/$USERNAME/.ssh/$SSH_KEY_FILE.pub"
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "chmod 600 /home/$USERNAME/.ssh/authorized_keys"
    ssh -i $ROOT_SSH_KEY_PATH root@$nodeip "chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh"
done
