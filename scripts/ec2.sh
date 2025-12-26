#!/bin/bash
set -euo pipefail

# -------- Constants --------
AMI_ID="ami-0e6a50b0059fd2cc3"
EC2_INSTANCE_TYPE="t2.micro"

# -------- Inputs --------
EC2_INSTANCE_NAME=$1
EC2_KEY_NAME=$2
SUBNET_ID=$3
EC2_SG_ID=$4
EC2_S3_INSTANCE_PROFILE=${5:-}   # OPTIONAL

# -------- Check if EC2 already exists --------
EXISTING_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters \
    "Name=tag:Name,Values=$EC2_INSTANCE_NAME" \
    "Name=instance-state-name,Values=running,pending,stopped,stopping" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null || true)

if [[ -z "$EXISTING_INSTANCE_ID" || "$EXISTING_INSTANCE_ID" == "None" ]]; then
  echo "EC2 instance '$EC2_INSTANCE_NAME' does not exist. Creating..." >&2

  EC2_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$EC2_INSTANCE_TYPE" \
    --key-name "$EC2_KEY_NAME" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$EC2_SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  # -------- Attach IAM Instance Profile (Optional) --------
  if [[ -n "$EC2_S3_INSTANCE_PROFILE" ]]; then
    aws ec2 associate-iam-instance-profile \
      --instance-id "$EC2_INSTANCE_ID" \
      --iam-instance-profile Name="$EC2_S3_INSTANCE_PROFILE"
    echo "Associated IAM profile: $EC2_S3_INSTANCE_PROFILE" >&2
  fi

  aws ec2 wait instance-running --instance-ids "$EC2_INSTANCE_ID"
  echo "EC2 instance is running: $EC2_INSTANCE_ID" >&2

else
  EC2_INSTANCE_ID="$EXISTING_INSTANCE_ID"
  echo "EC2 instance already exists: $EC2_INSTANCE_ID" >&2

  INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids "$EC2_INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

  if [[ "$INSTANCE_STATE" != "running" ]]; then
    echo "Starting EC2 instance..." >&2
    aws ec2 start-instances --instance-ids "$EC2_INSTANCE_ID"
    aws ec2 wait instance-running --instance-ids "$EC2_INSTANCE_ID"
    echo "EC2 instance is running" >&2
  else
    echo "EC2 instance already running" >&2
  fi
fi

# -------- FINAL OUTPUT (STDOUT ONLY) --------
echo "$EC2_INSTANCE_ID"
