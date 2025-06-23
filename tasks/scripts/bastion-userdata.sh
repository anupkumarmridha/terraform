# This script is intended to be used as user data for an AWS EC2 instance for bastion host.
#!/bin/bash
yum update -y
yum install -y aws-cli

# setup baskic hello world server

echo "Hello, World!" > /var/www/html/index.html
# Install the Apache web server
yum install -y httpd
# Start the Apache web server
systemctl start httpd
# Enable the Apache web server to start on boot
systemctl enable httpd


# configure AWS CLI with default region and output format
aws configure set default.region us-east-1
aws configure set default.output json
# Install the CloudWatch Agent
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
# Install jq for JSON processing
yum install -y jq

yum install -y amazon-cloudwatch-agent

# Create the CloudWatch Agent configuration directory if it doesn't exist
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
# Copy the CloudWatch Agent configuration file to the correct location
cp /opt/aws/amazon-cloudwatch-agent/etc/cloud-watch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/cloud-watch-agent.json


# Ensure the CloudWatch Agent configuration file exists
if [ ! -f /opt/aws/amazon-cloudwatch-agent/etc/cloud-watch-agent.json ]; then
    echo "CloudWatch Agent configuration file not found at /opt/aws/amazon-cloudwatch-agent/etc/cloud-watch-agent.json"
    exit 1
fi

# Ensure the CloudWatch Agent configuration file has the correct permissions
chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/cloud-watch-agent.json

# Ensure the CloudWatch Agent is installed
if [ ! -d /opt/aws/amazon-cloudwatch-agent ]; then
    echo "CloudWatch Agent directory not found at /opt/aws/amazon-cloudwatch-agent"
    exit 1
fi

# Ensure the AWS CLI is configured with the necessary permissions to access CloudWatch
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI is not configured with the necessary permissions to access CloudWatch"
    exit 1
fi

# Start the CloudWatch Agent using the provided configuration
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloud-watch-agent.json \
    -s
