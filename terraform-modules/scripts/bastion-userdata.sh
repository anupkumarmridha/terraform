#!/bin/bash
# This script is intended to be used as user data for an AWS EC2 instance for bastion host.

# Exit on any error
set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting bastion user data script execution at $(date)"

# Update system
yum update -y

# Install required packages
yum install -y \
    aws-cli \
    htop \
    vim \
    wget \
    curl \
    jq \
    git

# Configure AWS CLI with default region
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
aws configure set default.region "$REGION"
aws configure set default.output json

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Create CloudWatch Agent configuration directory
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

# Basic CloudWatch Agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/bastion",
                        "log_stream_name": "{instance_id}/system",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/bastion",
                        "log_stream_name": "{instance_id}/userdata",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

# Set proper permissions
chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Setup basic web server for health checks
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple health check page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Bastion Host</title>
</head>
<body>
    <h1>Bastion Host is Running</h1>
    <p>This bastion host is operational and ready for use.</p>
    <p>Instance ID: <span id="instance-id">Loading...</span></p>
    <script>
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(error => document.getElementById('instance-id').textContent = 'Unable to load');
    </script>
</body>
</html>
EOF

echo "Bastion user data script completed at $(date)"