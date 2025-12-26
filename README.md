AWS VPC HANDS-ON LABS

Exercise 1 VPC Setup
1 Create a VPC with an appropriate CIDR range
2 Create a public subnet
3 Create a private subnet
4 Associate subnets with appropriate route tables

Exercise 2 Internet Gateway
1 Create an Internet Gateway
2 Attach the Internet Gateway to the VPC
3 Update the public route table to allow 0.0.0.0/0 via Internet Gateway
4 Launch an EC2 instance in the public subnet
5 Assign a public IP address
6 Connect to the instance using SSH

Exercise 3 Bastion Host
1 Use the public subnet EC2 instance as a bastion host
2 Launch an EC2 instance in the private subnet
3 Update security groups to allow SSH from bastion to private instance
4 Connect to the private subnet instance using SSH via bastion host

Exercise 4 NAT Gateway
1 Allocate an Elastic IP
2 Create a NAT Gateway in the public subnet
3 Update the private route table to allow 0.0.0.0/0 via NAT Gateway
4 Verify internet access from the private subnet instance

Exercise 5 VPC Peering
1 Create a second VPC with a non overlapping CIDR range
2 Create a private subnet in the second VPC
3 Launch an EC2 instance in the private subnet of the second VPC
4 Create a VPC peering connection between first VPC and second VPC
5 Accept the VPC peering connection
6 Update route tables in both VPCs to allow traffic
7 Update security groups to allow SSH
8 Connect to the private instance in the second VPC from the bastion host in the first VPC


Exercise 6 VPC Endpoint
2 Create a private subnet in a VPC
3 Launch an EC2 instance in the private subnet of the VPC
4 Connect to S3 Bucket using VPC endpoint
