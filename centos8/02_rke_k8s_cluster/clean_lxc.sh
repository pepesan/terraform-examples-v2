#!/bin/bash
source .env
set -eux
lxc stop $CONTAINER_NAME-node1
lxc delete $CONTAINER_NAME-node1
lxc stop $CONTAINER_NAME-node2
lxc delete $CONTAINER_NAME-node2
lxc stop $CONTAINER_NAME-node3
lxc delete $CONTAINER_NAME-node3
