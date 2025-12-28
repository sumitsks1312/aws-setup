#!/bin/bash

set -euo pipefail

# ------------------------------
# Create VPC
# ------------------------------
VPC_ID_1=$(bash scripts/vpc.sh "vpc-1" "10.1.0.0/16")
echo "VPC ID: $VPC_ID_1"

# ------------------------------
# Create Public Subnet + RT
# ------------------------------
PUBLIC_SUBNET_CIDR="10.1.1.0/24"
PUBLIC_SUBNET_NAME="public-subnet-1"
PUBLIC_RT_NAME="public-rt-1"
read PUBLIC_SUBNET_ID_1 PUBLIC_RT_ID_1 <<< "$(
  bash scripts/subnet.sh \
    "$VPC_ID_1" \
    "$PUBLIC_SUBNET_NAME" \
    "$PUBLIC_SUBNET_CIDR" \
    "$PUBLIC_RT_NAME"
)"

echo "Public Subnet ID: $PUBLIC_SUBNET_ID_1"
echo "Public Route Table ID: $PUBLIC_RT_ID_1"

# ------------------------------
# Create Private Subnet + RT
# ------------------------------
PRIVATE_SUBNET_CIDR="10.1.2.0/24"
PRIVATE_SUBNET_NAME="private-subnet-1"
PRIVATE_RT_NAME="private-rt-1"
read PRIVATE_SUBNET_ID_1 PRIVATE_RT_ID_1 <<< "$(
  bash scripts/subnet.sh \
    "$VPC_ID_1" \
    "$PRIVATE_SUBNET_NAME" \
    "$PRIVATE_SUBNET_CIDR" \
    "$PRIVATE_RT_NAME"
)"

echo "Private Subnet ID: $PRIVATE_SUBNET_ID_1"
echo "Private Route Table ID: $PRIVATE_RT_ID_1"
