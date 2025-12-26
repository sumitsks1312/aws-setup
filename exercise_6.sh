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
# Create EC2 Key Pair and Security Group
# ------------------------------
EC2_KEY_NAME="ec2-key"
PRIVATE_EC2_SG_NAME="private-ec2-sg-1" 
bash scripts/key-pair.sh "$EC2_KEY_NAME"
PRIVATE_EC2_SG_ID_1=$(bash scripts/security-group.sh "$VPC_ID_1" "$PRIVATE_EC2_SG_NAME")
echo "Private EC2 Security Group ID: $PRIVATE_EC2_SG_ID_1"
bash scripts/sg-rule.sh "$PRIVATE_EC2_SG_ID_1" "$PUBLIC_EC2_SG_ID_1" 22


# ------------------------------
# Launch Private EC2 Instance
# ------------------------------
PRIVATE_EC2_INSTANCE_NAME="private-ec2-1"
PRIVATE_SUBNET_ID="$PRIVATE_SUBNET_ID_1"
PRIVATE_EC2_SG_ID="$PRIVATE_EC2_SG_ID_1"
PRIVATE_EC2_INSTANCE_ID_1=$(bash scripts/ec2.sh "$PRIVATE_EC2_INSTANCE_NAME" "$EC2_KEY_NAME" "$PRIVATE_SUBNET_ID" "$PRIVATE_EC2_SG_ID")
echo "Private EC2 Instance ID: $PRIVATE_EC2_INSTANCE_ID_1"


# ------------------------------
# Get the Private IP of the EC2 Instance
# ------------------------------
EC2_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$PRIVATE_EC2_INSTANCE_ID_1" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)
echo "Instance private IP: $EC2_PRIVATE_IP"   
echo "Setup complete. Private EC2 instance is running."
echo "Note: This is a private subnet instance. To connect, you'll need to use a bastion host or VPN."	
echo "ssh -i ${EC2_KEY_NAME}.pem ubuntu@$EC2_PRIVATE_IP"


# ------------------------------
# Create IAM Role and Instance Profile for S3 access
# ------------------------------
ROLE_NAME="EC2S3AccessRole"
PROFILE_NAME="EC2S3InstanceProfile"
bash scripts/s3-iam-role.sh "$ROLE_NAME"
bash scripts/ec2-instance-profile.sh "$ROLE_NAME" "$PROFILE_NAME"
echo "IAM Role '$ROLE_NAME' and Instance Profile '$PROFILE_NAME' for S3 access created"


# ------------------------------
# Attach IAM Role to Public EC2 Instance
# ------------------------------
# Check if an IAM instance profile is already associated
EXISTING_ASSOCIATION=$(aws ec2 describe-iam-instance-profile-associations \
  --filters Name=instance-id,Values="$PUBLIC_EC2_INSTANCE_ID_1" \
  --query 'IamInstanceProfileAssociations[0].IamInstanceProfile.Arn' \
  --output text)

if [[ -z "$EXISTING_ASSOCIATION" || "$EXISTING_ASSOCIATION" == "None" ]]; then
  echo "No IAM profile attached. Associating now..."

  aws ec2 associate-iam-instance-profile \
    --instance-id "$PUBLIC_EC2_INSTANCE_ID_1" \
    --iam-instance-profile Name="$PROFILE_NAME" \
    > /dev/null

  echo "Attached IAM Role '$ROLE_NAME' to Public EC2 Instance '$PUBLIC_EC2_INSTANCE_ID_1'"

else
  echo "IAM profile already attached to instance:"
  echo "$EXISTING_ASSOCIATION"
fi


# ------------------------------
# Attach IAM Role to Private EC2 Instance
# ------------------------------
# Check if an IAM instance profile is already associated
EXISTING_ASSOCIATION=$(aws ec2 describe-iam-instance-profile-associations \
  --filters Name=instance-id,Values="$PRIVATE_EC2_INSTANCE_ID_1" \
  --query 'IamInstanceProfileAssociations[0].IamInstanceProfile.Arn' \
  --output text)

if [[ -z "$EXISTING_ASSOCIATION" || "$EXISTING_ASSOCIATION" == "None" ]]; then
  echo "No IAM profile attached. Associating now..."

  aws ec2 associate-iam-instance-profile \
    --instance-id "$PRIVATE_EC2_INSTANCE_ID_1" \
    --iam-instance-profile Name="$PROFILE_NAME" \
    >> /dev/null

  echo "Attached IAM Role '$ROLE_NAME' to Private EC2 Instance '$PRIVATE_EC2_INSTANCE_ID_1'"

else
  echo "IAM profile already attached to instance:"
  echo "$EXISTING_ASSOCIATION"
fi


# ------------------------------
# Create S3 Bucket
# ------------------------------
BUCKET_NAME="my-unique-bucket-$(date +%Y%m%d)"
REGION="us-west-1"
bash scripts/s3-bucket.sh "$BUCKET_NAME" "$REGION"
echo "S3 Bucket '$BUCKET_NAME' created in region '$REGION'"


# ------------------------------
# Create VPC Endpoint for S3
# ------------------------------
VPC_ENDPOINT_NAME="s3-vpc-endpoint-1"
SERVICE="s3"
VPC_ENDPOINT_ID_1=$(bash scripts/vpc-gateway-endpoint.sh "$VPC_ENDPOINT_NAME" "$VPC_ID_1" "$PRIVATE_RT_ID_1" "$SERVICE")
echo "VPC Endpoint ID: $VPC_ENDPOINT_ID_1"
