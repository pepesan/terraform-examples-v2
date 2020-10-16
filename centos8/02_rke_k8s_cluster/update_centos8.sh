#!/bin/bash
source .env
set -eux
dnf update -y
reboot
