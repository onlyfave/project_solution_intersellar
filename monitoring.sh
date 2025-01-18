#!/bin/bash

# Replace these variables with your EC2 instance details
EC2_INSTANCE_ID="i-0fce179d902851cf2"
EC2_REGION="us-east-1"
EC2_USER="ec2-user"
PRIVATE_KEY_PATH="./mission-control-key.pem"
PROJECT_DIR="/home/$EC2_USER/interstellar-mission"

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo "Success: $1"
    else
        echo "Error: $1"
        exit 1
    fi
}

# Create CloudWatch agent configuration file locally
cat << EOF > cloudwatch-agent-config.json
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/mission-status.log",
                        "log_group_name": "mission-control-logs",
                        "log_stream_name": "mission-status"
                    },
                    {
                        "file_path": "/var/log/alert-system.log",
                        "log_group_name": "mission-control-logs",
                        "log_stream_name": "alert-system"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "docker": {
                "metrics_collection_interval": 60,
                "containers": [
                    "*"
                ]
            }
        }
    }
}
EOF
check_status "Creating CloudWatch agent configuration file locally"

# Ensure SSH access is configured and the private key is used
INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --region $EC2_REGION \
    --output text)
check_status "Fetching EC2 instance public IP"

if [ "$INSTANCE_PUBLIC_IP" == "None" ]; then
    echo "Error: Instance does not have a public IP. Ensure the instance is accessible."
    exit 1
fi

# Copy the configuration file and docker-compose.yml to the EC2 instance
scp -i $PRIVATE_KEY_PATH cloudwatch-agent-config.json docker-compose.yml $EC2_USER@$INSTANCE_PUBLIC_IP:$PROJECT_DIR/
check_status "Copying configuration files to EC2 instance"

# Run commands on the EC2 instance via SSH
ssh -i $PRIVATE_KEY_PATH $EC2_USER@$INSTANCE_PUBLIC_IP << EOF
    set -e

    echo "Updating system packages"
    sudo yum update -y

    echo "Installing Amazon CloudWatch agent"
    sudo yum install -y amazon-cloudwatch-agent

    echo "Configuring and starting CloudWatch agent"
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:$PROJECT_DIR/cloudwatch-agent-config.json

    echo "Enabling CloudWatch agent to start on boot"
    sudo systemctl enable amazon-cloudwatch-agent

    echo "CloudWatch agent setup completed successfully"

    # Navigate to the project directory
    cd $PROJECT_DIR

    # Create log group for CloudWatch Logs
    aws logs create-log-group --log-group-name mission-control-logs --region $EC2_REGION

    # Build and start Docker containers
    docker-compose build
