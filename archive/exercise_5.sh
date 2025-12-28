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
VPC_CIDR_1="10.1.0.0/16"
VPC_NAME="vpc-1"
VPC_ID_1=$(bash scripts/vpc.sh "$VPC_NAME" "$VPC_CIDR_1")
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
echo "Bastion Host public IP: $EC2_PUBLIC_IP"   
echo "Setup complete. You can now connect to your Bation Host EC2 instance using the following command:"
echo "ssh -i ${EC2_KEY_NAME}.pem ubuntu@$EC2_PUBLIC_IP"


# ------------------------------
# Create another VPC
# ------------------------------
VPC_CIDR_2="10.2.0.0/16"
VPC_NAME="vpc-2"
VPC_ID_2=$(bash scripts/vpc.sh "$VPC_NAME" "$VPC_CIDR_2")
echo "VPC ID 2: $VPC_ID_2"


# ------------------------------
# Create Private Subnet + RT
# ------------------------------
PRIVATE_SUBNET_CIDR="10.2.2.0/24"
PRIVATE_SUBNET_NAME="private-subnet-2"
PRIVATE_RT_NAME="private-rt-2"
read PRIVATE_SUBNET_ID_2 PRIVATE_RT_ID_2 <<< "$(
  bash scripts/subnet.sh \
    "$VPC_ID_2" \
    "$PRIVATE_SUBNET_NAME" \
    "$PRIVATE_SUBNET_CIDR" \
    "$PRIVATE_RT_NAME"
)"

echo "Private Subnet ID 2: $PRIVATE_SUBNET_ID_2"
echo "Private Route Table ID 2: $PRIVATE_RT_ID_2"


# ------------------------------
# Create EC2 Key Pair and Security Group
# ------------------------------
EC2_KEY_NAME="ec2-key"
PRIVATE_EC2_SG_NAME="private-ec2-sg-2" 
bash scripts/key-pair.sh "$EC2_KEY_NAME"
PRIVATE_EC2_SG_ID_2=$(bash scripts/security-group.sh "$VPC_ID_2" "$PRIVATE_EC2_SG_NAME")
echo "Private EC2 Security Group ID 2: $PRIVATE_EC2_SG_ID_2"
bash scripts/sg-rule.sh "$PRIVATE_EC2_SG_ID_2" "$VPC_CIDR_1" 22


# ------------------------------
# Launch Private EC2 Instance
# ------------------------------
PRIVATE_EC2_INSTANCE_NAME="private-ec2-2"
PRIVATE_SUBNET_ID="$PRIVATE_SUBNET_ID_2"
PRIVATE_EC2_SG_ID="$PRIVATE_EC2_SG_ID_2"
PRIVATE_EC2_INSTANCE_ID_2=$(bash scripts/ec2.sh "$PRIVATE_EC2_INSTANCE_NAME" "$EC2_KEY_NAME" "$PRIVATE_SUBNET_ID" "$PRIVATE_EC2_SG_ID")
echo "Private EC2 Instance ID 2: $PRIVATE_EC2_INSTANCE_ID_2"


# ------------------------------
# Get the Private IP of the EC2 Instance
# ------------------------------
EC2_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$PRIVATE_EC2_INSTANCE_ID_2" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)
echo "Instance private IP: $EC2_PRIVATE_IP"   
echo "Setup complete. Private EC2 instance is running."
echo "Note: This is a private subnet instance. To connect, you'll need to use a bastion host or VPN."	
echo "ssh -i ${EC2_KEY_NAME}.pem ubuntu@$EC2_PRIVATE_IP"


# ------------------------------
# VPC Peering Connection
# ------------------------------
PEERING_CONNECTION_NAME="vpc-peering-1-2"
PEERING_CONNECTION_ID=$(bash scripts/vpc-peering.sh "$PEERING_CONNECTION_NAME" "$VPC_ID_1" "$VPC_ID_2" "$PUBLIC_RT_ID_1" "$PRIVATE_RT_ID_2" "$VPC_CIDR_1" "$VPC_CIDR_2")
echo "VPC Peering Connection ID: $PEERING_CONNECTION_ID"
echo "VPC Peering setup complete."
