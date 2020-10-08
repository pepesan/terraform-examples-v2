#!/bin/bash
source .env
set -eux
lxc stop $CONTAINER_NAME
lxc delete $CONTAINER_NAME
