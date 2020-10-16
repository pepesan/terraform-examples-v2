#!/bin/bash
source .env
set -eux
ssh-keygen -f $SSH_KEY_PATH -t rsa -b 4096