#!/bin/bash
set -euo pipefail

# -------- Inputs --------
VPC_ID=$1
IGW_NAME=$2

# -------- Find or Create Internet Gateway --------
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=tag:Name,Values=$IGW_NAME" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text 2>/dev/null || true)

if [[ -z "$IGW_ID" || "$IGW_ID" == "None" ]]; then
  echo "Internet Gateway '$IGW_NAME' does not exist. Creating..." >&2

  IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$IGW_NAME}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

  aws ec2 attach-internet-gateway \
    --internet-gateway-id "$IGW_ID" \
    --vpc-id "$VPC_ID"

  echo "Created and attached IGW: $IGW_ID" >&2
else
  echo "Internet Gateway already exists: $IGW_ID" >&2

  ATTACHED_VPC=$(aws ec2 describe-internet-gateways \
    --internet-gateway-ids "$IGW_ID" \
    --query 'InternetGateways[0].Attachments[0].VpcId' \
    --output text 2>/dev/null || true)

  if [[ "$ATTACHED_VPC" != "$VPC_ID" ]]; then
    echo "Attaching IGW to VPC..." >&2
    aws ec2 attach-internet-gateway \
      --internet-gateway-id "$IGW_ID" \
      --vpc-id "$VPC_ID"
  else
    echo "IGW already attached to VPC" >&2
  fi
fi

# -------- FINAL OUTPUT (STDOUT ONLY) --------
echo "$IGW_ID"
