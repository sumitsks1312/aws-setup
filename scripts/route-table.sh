#!/bin/bash
set -e

# Inputs
RT_ID=$1
TARGET_ID=$2     # IGW ID (igw-xxxx) OR NAT GW ID (nat-xxxx)
DESTINATION_CIDR=${3:-0.0.0.0/0}

# Decide route target
if [[ "$TARGET_ID" == igw-* ]]; then
  echo "Creating route to Internet Gateway $TARGET_ID"
  aws ec2 create-route \
    --route-table-id "$RT_ID" \
    --destination-cidr-block "$DESTINATION_CIDR" \
    --gateway-id "$TARGET_ID" \
    2>/dev/null || echo "Route already exists"

elif [[ "$TARGET_ID" == nat-* ]]; then
  echo "Creating route to NAT Gateway $TARGET_ID"
  aws ec2 create-route \
    --route-table-id "$RT_ID" \
    --destination-cidr-block "$DESTINATION_CIDR" \
    --nat-gateway-id "$TARGET_ID" \
    2>/dev/null || echo "Route already exists"

else
  echo "Invalid target. Use IGW (igw-xxxx) or NAT Gateway (nat-xxxx)"
  exit 1
fi
