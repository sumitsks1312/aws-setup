#!/bin/bash

set -euo pipefail

# ------------------------------
# Get the first availability zone
# ------------------------------
AZ=$(aws ec2 describe-availability-zones \
  --query 'AvailabilityZones[0].ZoneName' \
  --output text)
echo "Availability Zone: $AZ"

# ------------------------------
# Create VPC
# ------------------------------
VPC_CIDR="10.1.0.0/16"
VPC_NAME="vpc-1"
VPC_ID_1=$(bash scripts/vpc.sh "$VPC_NAME" "$VPC_CIDR")
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
# Create Internet Gateway
# ------------------------------
IGW_NAME="igw-1"
IGW_ID_1=$(bash scripts/igw.sh "$VPC_ID_1" "$IGW_NAME")
echo "Internet Gateway ID: $IGW_ID_1"


# ------------------------------
# Update Public Route Table to route via IGW
# ------------------------------
bash scripts/route-table.sh "$PUBLIC_RT_ID_1" "$IGW_ID_1"
echo "Updated Public Route Table to route via IGW"


# ------------------------------
# Create EC2 Key Pair and Security Group
# ------------------------------
EC2_KEY_NAME="ec2-key"
PUBLIC_EC2_SG_NAME="public-ec2-sg-1" 
bash scripts/key-pair.sh "$EC2_KEY_NAME"
PUBLIC_EC2_SG_ID_1=$(bash scripts/security-group.sh "$VPC_ID_1" "$PUBLIC_EC2_SG_NAME")
echo "Public EC2 Security Group ID: $PUBLIC_EC2_SG_ID_1"
bash scripts/sg-rule.sh "$PUBLIC_EC2_SG_ID_1" "$(curl -s https://checkip.amazonaws.com)/32" 22


# ------------------------------
# Launch Public EC2 Instance
# ------------------------------
PUBLIC_EC2_INSTANCE_NAME="public-ec2-1"
PUBLIC_SUBNET_ID="$PUBLIC_SUBNET_ID_1"
PUBLIC_EC2_SG_ID="$PUBLIC_EC2_SG_ID_1"
PUBLIC_EC2_INSTANCE_ID_1=$(bash scripts/ec2.sh "$PUBLIC_EC2_INSTANCE_NAME" "$EC2_KEY_NAME" "$PUBLIC_SUBNET_ID" "$PUBLIC_EC2_SG_ID")
echo "Public EC2 Instance ID: $PUBLIC_EC2_INSTANCE_ID_1"


# ------------------------------
# Get the Public IP of the EC2 Instance
# ------------------------------
EC2_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$PUBLIC_EC2_INSTANCE_ID_1" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
echo "Instance public IP: $EC2_PUBLIC_IP"   
echo "Setup complete. You can now connect to your EC2 instance using the following command:"
echo "ssh -i ${EC2_KEY_NAME}.pem ubuntu@$EC2_PUBLIC_IP"







