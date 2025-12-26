#!/bin/bash

# Variables
EC2_KEY_NAME=$1

if aws ec2 describe-key-pairs --key-names "$EC2_KEY_NAME" >/dev/null 2>&1; then
    echo "Key pair '$EC2_KEY_NAME' already exists"
else
    echo "Creating key pair '$EC2_KEY_NAME'"
    aws ec2 create-key-pair \
        --key-name "$EC2_KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "../${EC2_KEY_NAME}.pem"
    chmod 400 "../${EC2_KEY_NAME}.pem"
    echo "Key saved at ../${EC2_KEY_NAME}.pem"
fi