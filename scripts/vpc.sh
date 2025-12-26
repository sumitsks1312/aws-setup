#!/bin/bash
set -euo pipefail

# -------- Inputs --------
VPC_NAME=$1
VPC_CIDR=$2

# -------- Find or Create VPC --------
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query 'Vpcs[0].VpcId' \
  --output text 2>/dev/null || true)

if [[ -z "$VPC_ID" || "$VPC_ID" == "None" ]]; then
  echo "VPC '$VPC_NAME' does not exist. Creating..." >&2

  VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME}]" \
    --query 'Vpc.VpcId' \
    --output text)

  echo "Created VPC: $VPC_ID" >&2
else
  echo "VPC already exists: $VPC_ID" >&2
fi

# -------- FINAL OUTPUT (STDOUT ONLY) --------
echo "$VPC_ID"
