#!/bin/bash
set -e

# Inputs
VPC_PEERING_CONNECTION_NAME=$1
VPC_ID_1=$2
VPC_ID_2=$3
RT_ID_1=$4
RT_ID_2=$5
VPC_CIDR_1=$6
VPC_CIDR_2=$7

# Check if VPC Peering already exists
EXISTING_PEERING_ID=$(aws ec2 describe-vpc-peering-connections \
  --filters "Name=tag:Name,Values=$VPC_PEERING_CONNECTION_NAME" \
  --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' \
  --output text 2>/dev/null || true)

if [[ -z "$EXISTING_PEERING_ID" || "$EXISTING_PEERING_ID" == "None" ]]; then
  echo "VPC Peering '$VPC_PEERING_CONNECTION_NAME' does not exist. Creating..." >&2

  VPC_PEERING_CONNECTION_ID=$(aws ec2 create-vpc-peering-connection \
    --vpc-id "$VPC_ID_1" \
    --peer-vpc-id "$VPC_ID_2" \
    --tag-specifications "ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=$VPC_PEERING_CONNECTION_NAME}]" \
    --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
    --output text)

else
  VPC_PEERING_CONNECTION_ID="$EXISTING_PEERING_ID"
  echo "VPC Peering already exists: $VPC_PEERING_CONNECTION_ID" >&2
fi

# Accept Peering (safe even if already accepted)
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id "$VPC_PEERING_CONNECTION_ID" \
  >/dev/null 2>&1 || true

echo "VPC Peering accepted: $VPC_PEERING_CONNECTION_ID" >&2

# Route from VPC 1 → VPC 2
aws ec2 create-route \
  --route-table-id "$RT_ID_1" \
  --destination-cidr-block "$VPC_CIDR_2" \
  --vpc-peering-connection-id "$VPC_PEERING_CONNECTION_ID" \
  >/dev/null 2>&1 || echo "Route already exists in RT1" >&2

# Route from VPC 2 → VPC 1
aws ec2 create-route \
  --route-table-id "$RT_ID_2" \
  --destination-cidr-block "$VPC_CIDR_1" \
  --vpc-peering-connection-id "$VPC_PEERING_CONNECTION_ID" \
  >/dev/null 2>&1 || echo "Route already exists in RT2" >&2

echo "VPC Peering routing configured" >&2

# -------- FINAL OUTPUT (STDOUT ONLY) --------
echo "$VPC_PEERING_CONNECTION_ID"
