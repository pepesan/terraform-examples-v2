#!/bin/bash

aws ec2 describe-vpcs \
  --endpoint-url=http://localhost.localstack.cloud:4566 \
  --region us-east-1 \
  --no-cli-pager

aws ec2 describe-subnets \
  --endpoint-url=http://localhost.localstack.cloud:4566 \
  --region us-east-1 \
  --no-cli-pager




