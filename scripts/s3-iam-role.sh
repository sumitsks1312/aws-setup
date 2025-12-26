#!/bin/bash

set -euo pipefail

# Variable for IAM Role name
ROLE_NAME=$1

# Create IAM Policy for S3 access
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://resources/ec2-trust-policy.json \
  > /dev/null 2>&1 || echo "IAM Role '$ROLE_NAME' already exists"

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
echo "IAM Role '$ROLE_NAME' with S3 read-only access is ready" 