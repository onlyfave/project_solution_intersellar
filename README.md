# Interstellar Mission Control System on AWS

## Project Overview
We will build a containerized application that simulates different aspects of managing an interstellar mission. The system will consist of several microservices, each running in a Docker container, deployed on an AWS EC2 instance.

## Components

### Mission Status Service
- A simple Python Flask API that provides mission status updates
- Stores data in Amazon RDS for MySQL

### Resource Monitor
- A Bash script that monitors system resources (CPU, memory, disk usage)
- Outputs data to Amazon CloudWatch Logs

### Alert System
- A Node.js application that reads the CloudWatch Logs and sends alerts via Amazon SNS

### Data Backup Service
- A Bash script that performs regular backups of mission data to Amazon S3

## Implementation Steps

### 1. Set up AWS Environment
- Provision an EC2 instance (e.g., Amazon Linux 2 or Ubuntu)
- Configure VPC, security groups, and SSH access

### 2. Install Docker
- Write a Bash script to automate Docker installation on the EC2 instance

### 3. Create Dockerfiles
- Develop Dockerfiles for the Mission Status Service and Alert System
- Use multi-stage builds to optimize image sizes

### 4. Develop Bash Scripts
- Create the Resource Monitor script that sends metrics to CloudWatch
- Write the Data Backup script, integrating with Amazon S3

### 5. Docker Compose
- Create a `docker-compose.yml` file to define and run the multi-container application

### 6. Automation Script
Develop a master Bash script that:
- Pulls the latest code from AWS CodeCommit
- Builds Docker images
- Starts the containers using Docker Compose
- Initiates the Resource Monitor and Data Backup scripts

### 7. Monitoring and Logging
- Set up logging for all containers to Amazon CloudWatch Logs
- Use Amazon CloudWatch for monitoring container health

### 8. AWS Integration
- Utilize Amazon S3 for storing backups
- Implement Amazon SNS for alert notifications

## Learning Outcomes
This project will provide hands-on experience with:
- Linux system administration on EC2
- Bash scripting for automation and system monitoring
- Docker containerization and multi-container applications
- AWS services (EC2, RDS, S3, CloudWatch, SNS, CodeCommit)
- Basic DevOps practices on AWS

## Next Steps Ideas
- Implement a CI/CD pipeline using AWS CodePipeline and CodeBuild
- Add an Application Load Balancer in front of the services for load balancing
- Create a Bash script to simulate network issues and test system resilience using EC2 network ACLs
- Implement automatic scaling based on resource usage using EC2 Auto Scaling groups
