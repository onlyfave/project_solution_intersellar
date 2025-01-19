#!/bin/bash

# Configuration variables
KEY_NAME="mission-control-key"
SECURITY_GROUP_NAME="mission-control-sg"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-05576a079321f21f8"
REGION="us-east-1"
VPC_NAME="mission-control-vpc"
SUBNET_NAME="mission-control-subnet"
IAM_ROLE_NAME="mission-control-role"
IAM_INSTANCE_PROFILE="mission-control-instance-profile"
EC2_INSTANCE_CONNECT_PREFIXLIST="pl-0e4bcff02b13bef1e"

# Set AWS region
aws configure set region $REGION

echo "Creating key-pair"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem
echo "Key-Pair created: $KEY_NAME"

echo "Creating VPC"
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME
echo "Created VPC: $VPC_ID"

echo "Creating Internet Gateway"
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "Created and attached Internet Gateway: $IGW_ID"

echo "Creating Subnet"
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=$SUBNET_NAME
echo "Created Subnet: $SUBNET_ID"

echo "Creating Route Table"
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $ROUTE_TABLE_ID
echo "Created and configured Route Table: $ROUTE_TABLE_ID"

echo "Creating Security Group"
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Mission Control Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,PrefixListIds=[{PrefixListId=$EC2_INSTANCE_CONNECT_PREFIXLIST}]
echo "Created Security Group: $SECURITY_GROUP_ID"

echo "Creating IAM Role and Instance Profile"
aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name $IAM_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Check if instance profile exists, create if it doesn't
if ! aws iam get-instance-profile --instance-profile-name $IAM_INSTANCE_PROFILE &> /dev/null; then
    aws iam create-instance-profile --instance-profile-name $IAM_INSTANCE_PROFILE
    echo "Created Instance Profile: $IAM_INSTANCE_PROFILE"
else
    echo "Instance Profile $IAM_INSTANCE_PROFILE already exists"
fi

# Add role to instance profile if not already added
if ! aws iam get-instance-profile --instance-profile-name $IAM_INSTANCE_PROFILE | grep -q "$IAM_ROLE_NAME"; then
    aws iam add-role-to-instance-profile --role-name $IAM_ROLE_NAME --instance-profile-name $IAM_INSTANCE_PROFILE
    echo "Added Role to Instance Profile"
else
    echo "Role already added to Instance Profile"
fi

echo "Launching EC2 Instance"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --iam-instance-profile Name=$IAM_INSTANCE_PROFILE \
    --user-data '#!/bin/bash
                 yum update -y
                 yum install docker -y
                 systemctl enable start
                 systemctl start docker
                 sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                 sudo chmod +x /usr/local/bin/docker-compose
                 sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
                 usermod -a -G docker ec2-user' \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "Launched EC2 Instance: $INSTANCE_ID"

echo "Waiting for Instance to be running"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance is now running"

echo "Enabling DNS hostnames for VPC"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"

echo "Getting Instance details"
... (20 lines left)
