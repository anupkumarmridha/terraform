#!/bin/bash

# Exit on any error
set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting user data script execution at $(date)"

# Update system
yum update -y

# Install required packages
yum install -y \
    amazon-cloudwatch-agent \
    aws-cli \
    docker \
    jq \
    wget \
    git

# Configure AWS CLI
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
aws configure set default.region "$REGION"
aws configure set default.output json

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Clone the repository
git clone https://github.com/anupkumarmridha/test-asg-server.git .

# Build Docker image
docker build -t test-asg-server .

# Run Docker container
docker run -d -p 8080:8080 --name test-asg-server --restart unless-stopped test-asg-server

# Create systemd service for Docker container management
cat > /etc/systemd/system/simple-api.service << 'EOF'
[Unit]
Description=Test ASG Server Docker Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start test-asg-server
ExecStop=/usr/bin/docker stop test-asg-server
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Configure CloudWatch Agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
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
                        "file_path": "/var/lib/docker/containers/*/*-json.log",
                        "log_group_name": "${log_group_name}",
                        "log_stream_name": "{instance_id}/docker",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "${log_group_name}",
                        "log_stream_name": "{instance_id}/userdata",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Change ownership of app directory to ec2-user
chown -R ec2-user:ec2-user /opt/app

# Enable the systemd service
systemctl daemon-reload
systemctl enable simple-api.service

# Wait for Docker container to be ready
echo "Waiting for Docker container to start..."
sleep 15

# Check Docker container status
docker ps | grep test-asg-server || echo "Container not running"

echo "Application setup completed successfully at $(date)"
echo "Container status:"
docker logs test-asg-server || echo "Failed to get container logs"

# Test the application
sleep 10
curl -f http://localhost:8080/health || echo "Health check failed"

echo "User data script completed at $(date)"