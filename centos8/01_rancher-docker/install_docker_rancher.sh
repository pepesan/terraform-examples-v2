#!/bin/bash
source .env
set -eux

docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:$RANCHER_VERSION \
  --acme-domain $RANCHER_DNS_NAME

