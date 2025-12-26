#!/bin/bash
set -e

BUCKET_NAME=$1
REGION=$2

# Check if bucket already exists (globally)
if aws s3 ls "s3://$BUCKET_NAME" >/dev/null 2>&1; then
  echo "S3 bucket '$BUCKET_NAME' already exists"
else
  aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
  echo "Created S3 bucket '$BUCKET_NAME' in region '$REGION'"
fi
