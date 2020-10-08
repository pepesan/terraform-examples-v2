#!/bin/bash
source .env
set -eux

lxc launch images:centos/8/amd64 $CONTAINER_NAME
