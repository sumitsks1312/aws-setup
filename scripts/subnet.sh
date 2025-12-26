#!/bin/bash
set -euo pipefail

# -------- Inputs --------
VPC_ID=$1
SUBNET_NAME=$2
SUBNET_CIDR=$3
RT_NAME=$4

# -------- AZ Auto-detect --------
AZ=$(aws ec2 describe-availability-zones \
  --query 'AvailabilityZones[0].ZoneName' \
  --output text)

# -------- Find or Create Subnet --------
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=$SUBNET_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0].SubnetId' \
  --output text 2>/dev/null || true)

if [[ -z "$SUBNET_ID" || "$SUBNET_ID" == "None" ]]; then
  echo "Subnet '$SUBNET_NAME' does not exist. Creating..." >&2

  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$SUBNET_CIDR" \
    --availability-zone "$AZ" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$SUBNET_NAME}]" \
    --query 'Subnet.SubnetId' \
    --output text)

  aws ec2 modify-subnet-attribute \
    --subnet-id "$SUBNET_ID" \
    --map-public-ip-on-launch

  echo "Created Public Subnet: $SUBNET_ID" >&2
else
  echo "Public Subnet already exists: $SUBNET_ID" >&2
fi

# -------- Find or Create Route Table --------
RT_ID=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=$RT_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[0].RouteTableId' \
  --output text 2>/dev/null || true)

if [[ -z "$RT_ID" || "$RT_ID" == "None" ]]; then
  echo "Public Route Table '$RT_NAME' does not exist. Creating..." >&2

  RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$RT_NAME}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

  aws ec2 associate-route-table \
    --subnet-id "$SUBNET_ID" \
    --route-table-id "$RT_ID" \
    >/dev/null

  echo "Created Route Table: $RT_ID" >&2
else
  echo "Public Route Table already exists: $RT_ID" >&2

  ASSOCIATION_EXISTS=$(aws ec2 describe-route-tables \
    --route-table-ids "$RT_ID" \
    --query "RouteTables[0].Associations[?SubnetId=='$SUBNET_ID'] | length(@)" \
    --output text)

  if [[ "$ASSOCIATION_EXISTS" == "0" ]]; then
    aws ec2 associate-route-table \
      --subnet-id "$SUBNET_ID" \
      --route-table-id "$RT_ID" \
      >/dev/null
    echo "Associated Subnet with Route Table" >&2
  else
    echo "Subnet already associated with Route Table" >&2
  fi
fi

# -------- FINAL OUTPUT (STDOUT ONLY) --------
echo "$SUBNET_ID $RT_ID"
