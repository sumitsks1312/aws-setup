#!/bin/bash
set -e

# Inputs
NATGW_NAME=$1
ELASTIC_IP_ALLOC_ID=$2
SUBNET_ID=$3

# Check if NAT Gateway already exists
EXISTING_NAT_GW_ID=$(aws ec2 describe-nat-gateways \
  --filter "Name=tag:Name,Values=$NATGW_NAME" "Name=state,Values=available,pending" \
  --query 'NatGateways[0].NatGatewayId' \
  --output text 2>/dev/null || true)

if [[ -z "$EXISTING_NAT_GW_ID" || "$EXISTING_NAT_GW_ID" == "None" ]]; then
  echo "NAT Gateway '$NATGW_NAME' does not exist. Creating..." >&2

  NATGW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id "$SUBNET_ID" \
    --allocation-id "$ELASTIC_IP_ALLOC_ID" \
    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=$NATGW_NAME}]" \
    --query 'NatGateway.NatGatewayId' \
    --output text)

  aws ec2 wait nat-gateway-available \
    --nat-gateway-ids "$NATGW_ID"

  echo "NAT Gateway is AVAILABLE: $NATGW_ID" >&2
else
  NATGW_ID="$EXISTING_NAT_GW_ID"
  echo "NAT Gateway already exists: $NATGW_ID" >&2

  NAT_GW_STATE=$(aws ec2 describe-nat-gateways \
    --nat-gateway-ids "$NATGW_ID" \
    --query 'NatGateways[0].State' \
    --output text)

  if [[ "$NAT_GW_STATE" != "available" ]]; then
    echo "Waiting for NAT Gateway to become available..." >&2
    aws ec2 wait nat-gateway-available \
      --nat-gateway-ids "$NATGW_ID"
    echo "NAT Gateway is AVAILABLE" >&2
  fi
fi

# -------- FINAL OUTPUT (STDOUT ONLY) --------
echo "$NATGW_ID"
