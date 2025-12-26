#!/bin/bash
set -euo pipefail

# -------- Inputs --------
VPC_ID=$1
EC2_SG_NAME=$2

# -------- Find or Create Security Group --------
EC2_SG_ID=$(aws ec2 describe-security-groups \
  --filters \
    "Name=group-name,Values=$EC2_SG_NAME" \
    "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || true)

if [[ -z "$EC2_SG_ID" || "$EC2_SG_ID" == "None" ]]; then
  echo "Security Group '$EC2_SG_NAME' does not exist. Creating..." >&2

  EC2_SG_ID=$(aws ec2 create-security-group \
    --group-name "$EC2_SG_NAME" \
    --description "EC2 Security Group" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

  echo "Created Security Group: $EC2_SG_ID" >&2
else
  echo "Security Group already exists: $EC2_SG_ID" >&2
fi

# -------- FINAL OUTPUT (STDOUT ONLY) --------
echo "$EC2_SG_ID"