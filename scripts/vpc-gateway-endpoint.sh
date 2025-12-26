#!/bin/bash
set -euo pipefail

# Inputs
VPC_ENDPOINT_NAME=$1
VPC_ID=$2
RT_ID=$3
SERVICE=$4   # s3 or dynamodb

REGION=$(aws configure get region)

# Validate supported services
if [[ "$SERVICE" != "s3" && "$SERVICE" != "dynamodb" ]]; then
  echo "ERROR: Unsupported service '$SERVICE'. Only 's3' or 'dynamodb' are allowed."
  exit 1
fi

SERVICE_NAME="com.amazonaws.$REGION.$SERVICE"

# Check if Gateway VPC Endpoint already exists
EXISTING_ENDPOINT_ID=$(aws ec2 describe-vpc-endpoints \
  --filters \
    "Name=vpc-endpoint-type,Values=Gateway" \
    "Name=vpc-id,Values=$VPC_ID" \
    "Name=service-name,Values=$SERVICE_NAME" \
    "Name=tag:Name,Values=$VPC_ENDPOINT_NAME" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text)

if [ "$EXISTING_ENDPOINT_ID" != "None" ]; then
  echo "Gateway VPC Endpoint '$VPC_ENDPOINT_NAME' already exists for '$SERVICE' with ID '$EXISTING_ENDPOINT_ID'"
  echo "$EXISTING_ENDPOINT_ID"
  exit 0
fi

# Create Gateway VPC Endpoint
ENDPOINT_ID=$(aws ec2 create-vpc-endpoint \
  --vpc-id "$VPC_ID" \
  --vpc-endpoint-type Gateway \
  --service-name "$SERVICE_NAME" \
  --route-table-ids "$RT_ID" \
  --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=$VPC_ENDPOINT_NAME},{Key=Service,Value=$SERVICE}]" \
  --query 'VpcEndpoint.VpcEndpointId' \
  --output text)

echo "Created Gateway VPC Endpoint '$VPC_ENDPOINT_NAME' for service '$SERVICE'"
echo "$ENDPOINT_ID"
