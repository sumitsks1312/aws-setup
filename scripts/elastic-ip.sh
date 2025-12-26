#!/bin/bash
set -e

# Input
ELASTIC_IP_NAME=$1

# Allocate Elastic IP
ELASTIC_IP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' \
  --output text)

# Tag Elastic IP
aws ec2 create-tags \
  --resources "$ELASTIC_IP_ALLOC_ID" \
  --tags "Key=Name,Value=$ELASTIC_IP_NAME"

# Output Allocation ID
echo "$ELASTIC_IP_ALLOC_ID"
