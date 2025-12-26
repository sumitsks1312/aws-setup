#!/bin/bash
set -e

# Inputs
EC2_SG_ID=$1
SOURCE=$2        # CIDR (0.0.0.0/0) OR SG ID (sg-xxxx)
PORT=$3

# Decide whether SOURCE is CIDR or Security Group
if [[ "$SOURCE" == sg-* ]]; then
  echo "Allowing port $PORT from Security Group $SOURCE"
  aws ec2 authorize-security-group-ingress \
    --group-id "$EC2_SG_ID" \
    --protocol tcp \
    --port "$PORT" \
    --source-group "$SOURCE" \
    > /dev/null 2>&1 || echo "Rule already exists"

elif [[ "$SOURCE" == */* ]]; then
  echo "Allowing port $PORT from CIDR $SOURCE"
  aws ec2 authorize-security-group-ingress \
    --group-id "$EC2_SG_ID" \
    --protocol tcp \
    --port "$PORT" \
    --cidr "$SOURCE" \
    > /dev/null 2>&1 || echo "Rule already exists"

else
  echo "Invalid SOURCE. Use CIDR (0.0.0.0/0) or Security Group ID (sg-xxxx)"
  exit 1
fi
