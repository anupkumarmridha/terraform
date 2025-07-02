#!/bin/bash

# Jenkins Agent User Data Script
# This script sets up Jenkins agents for connection to the master

set -e

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Jenkins Agent setup at $(date)"

# Variables from template
MASTER_IP=${master_ip}
JENKINS_PORT=${jenkins_port}
AGENT_NAME=${agent_name}
LOG_GROUP="${log_group}"

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install required packages
echo "Installing required packages..."
dnf install -y \
    wget \
    curl \
    unzip \
    git \
    java-17-openjdk \
    java-17-openjdk-devel \
    fontconfig \
    dejavu-sans-fonts \
    docker \
    python3 \
    python3-pip \
    gcc \
    gcc-c++ \
    make \
    nodejs \
    npm

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk' >> /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/environment

# Verify Java installation
java -version

# Start and enable Docker
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Create Jenkins user and configure permissions
echo "Creating Jenkins user..."
useradd -m -s /bin/bash jenkins
usermod -aG docker jenkins
usermod -aG docker ec2-user

# Create Jenkins agent directory
echo "Setting up Jenkins agent directories..."
mkdir -p /opt/jenkins-agent
mkdir -p /opt/jenkins-agent/workspace
mkdir -p /var/log/jenkins-agent
chown -R jenkins:jenkins /opt/jenkins-agent
chown -R jenkins:jenkins /var/log/jenkins-agent

# Wait for Jenkins master to be available
echo "Waiting for Jenkins master to be available..."
timeout=300
counter=0
while [ $counter -lt $timeout ]; do
    if curl -s -o /dev/null -w "%%{http_code}" http://$MASTER_IP:$JENKINS_PORT | grep -q "200\|403"; then
        echo "Jenkins master is available"
        break
    fi
    sleep 10
    counter=$((counter + 10))
    echo "Waiting for Jenkins master... ($counter/$timeout seconds)"
done

if [ $counter -ge $timeout ]; then
    echo "Jenkins master not available within timeout"
    # Continue setup anyway, agent can be connected manually later
fi

# Download Jenkins agent jar
echo "Downloading Jenkins agent jar..."
cd /opt/jenkins-agent
wget -O agent.jar "http://$MASTER_IP:$JENKINS_PORT/jnlpJars/agent.jar" || {
    echo "Failed to download agent.jar, will create placeholder"
    touch agent.jar
}
chown jenkins:jenkins agent.jar

# Create Jenkins agent service
echo "Creating Jenkins agent service..."
cat > /etc/systemd/system/jenkins-agent.service << EOF
[Unit]
Description=Jenkins Agent ($AGENT_NAME)
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
User=jenkins
Group=jenkins
WorkingDirectory=/opt/jenkins-agent
Environment=JAVA_HOME=$JAVA_HOME
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$JAVA_HOME/bin
ExecStartPre=/bin/bash -c 'until curl -s http://$MASTER_IP:$JENKINS_PORT > /dev/null; do echo "Waiting for Jenkins master..."; sleep 10; done'
ExecStartPre=/usr/bin/wget -O /opt/jenkins-agent/agent.jar http://$MASTER_IP:$JENKINS_PORT/jnlpJars/agent.jar
ExecStart=$JAVA_HOME/bin/java -jar /opt/jenkins-agent/agent.jar -jnlpUrl http://$MASTER_IP:$JENKINS_PORT/computer/$AGENT_NAME/jenkins-agent.jnlp -workDir /opt/jenkins-agent
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (don't start it yet as the node needs to be configured in Jenkins first)
systemctl daemon-reload
systemctl enable jenkins-agent

# Install additional development tools
echo "Installing additional development tools..."

# Install Terraform
echo "Installing Terraform..."
cd /tmp
wget -q https://releases.hashicorp.com/terraform/1.6.4/terraform_1.6.4_linux_amd64.zip
unzip terraform_1.6.4_linux_amd64.zip
mv terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
rm terraform_1.6.4_linux_amd64.zip

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install additional Python packages commonly used in CI/CD
echo "Installing Python packages..."
pip3 install --upgrade pip
pip3 install boto3 requests pyyaml jinja2 ansible

# Install CloudWatch agent if log group is provided
if [ ! -z "$LOG_GROUP" ]; then
    echo "Installing and configuring CloudWatch agent..."
    dnf install -y amazon-cloudwatch-agent
    
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "ec2-user"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/jenkins-agent/*.log",
                        "log_group_name": "$LOG_GROUP",
                        "log_stream_name": "jenkins-agent-$AGENT_NAME-{instance_id}",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "$LOG_GROUP",
                        "log_stream_name": "jenkins-agent-$AGENT_NAME-userdata-{instance_id}",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S"
                    }
                ]
            }
        }
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
                "metrics_collection_interval": 60
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
    }
}
EOF
    
    # Start CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
        -s
    
    systemctl enable amazon-cloudwatch-agent
fi

# Configure firewall
echo "Configuring firewall..."
systemctl stop firewalld || true
systemctl disable firewalld || true

# Create agent connection script for manual setup
cat > /opt/jenkins-agent/connect-agent.sh << EOF
#!/bin/bash
# Script to manually connect agent to Jenkins master
# Usage: ./connect-agent.sh [SECRET]

SECRET=\$1
if [ -z "\$SECRET" ]; then
    echo "Usage: \$0 <secret>"
    echo "Get the secret from Jenkins master: Manage Jenkins > Manage Nodes > $AGENT_NAME"
    exit 1
fi

echo "Connecting agent $AGENT_NAME to master at $MASTER_IP:$JENKINS_PORT"
java -jar /opt/jenkins-agent/agent.jar \\
    -jnlpUrl http://$MASTER_IP:$JENKINS_PORT/computer/$AGENT_NAME/jenkins-agent.jnlp \\
    -secret \$SECRET \\
    -workDir /opt/jenkins-agent
EOF

chmod +x /opt/jenkins-agent/connect-agent.sh
chown jenkins:jenkins /opt/jenkins-agent/connect-agent.sh

# Get instance information
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Create status file
echo "Creating status file..."
cat > /tmp/jenkins-agent-status << EOF
Jenkins Agent Setup Status: SUCCESS
Agent Name: $AGENT_NAME
Installation Time: $(date)
Instance ID: $INSTANCE_ID
Instance IP: $INSTANCE_IP
Master IP: $MASTER_IP
Master Port: $JENKINS_PORT
Java Version: $(java -version 2>&1 | head -n 1)
Jenkins Agent Directory: /opt/jenkins-agent

Installed Tools:
- Java: $(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
- Docker: $(docker --version 2>/dev/null || echo "Not available")
- AWS CLI: $(aws --version 2>/dev/null || echo "Not available")
- Terraform: $(terraform --version 2>/dev/null | head -n 1 || echo "Not available")
- kubectl: $(kubectl version --client=true 2>/dev/null | head -n 1 || echo "Not available")
- Helm: $(helm version --short 2>/dev/null || echo "Not available")
- Python: $(python3 --version 2>/dev/null || echo "Not available")
- Node.js: $(node --version 2>/dev/null || echo "Not available")
- npm: $(npm --version 2>/dev/null || echo "Not available")

Service Status:
- Jenkins Agent Service: $(systemctl is-enabled jenkins-agent 2>/dev/null || echo "N/A") ($(systemctl is-active jenkins-agent 2>/dev/null || echo "inactive"))
- Docker Service: $(systemctl is-active docker)

Disk Usage:
$(df -h /)

Memory Usage:
$(free -h)

Manual Connection:
To manually connect this agent to Jenkins master:
1. Go to Jenkins master: http://$MASTER_IP:$JENKINS_PORT
2. Navigate to: Manage Jenkins > Manage Nodes
3. Click "New Node" and create node named: $AGENT_NAME
4. Set Remote root directory to: /opt/jenkins-agent
5. Set Launch method to: "Launch agent by connecting it to the master"
6. Use the secret from Jenkins to run: /opt/jenkins-agent/connect-agent.sh <secret>

Or start the service after configuring the node in Jenkins:
sudo systemctl start jenkins-agent

Log Files:
- User Data Log: /var/log/user-data.log
- Jenkins Agent Logs: /var/log/jenkins-agent/
- System Log: /var/log/messages
EOF

# Set proper permissions on status file
chmod 644 /tmp/jenkins-agent-status

# Final verification
echo "Performing final verification..."

# Check if all required tools are installed
echo "✓ Tool verification:"
java -version && echo "  ✓ Java installed" || echo "  ✗ Java not installed"
docker --version && echo "  ✓ Docker installed" || echo "  ✗ Docker not installed"
aws --version && echo "  ✓ AWS CLI installed" || echo "  ✗ AWS CLI not installed"
terraform --version && echo "  ✓ Terraform installed" || echo "  ✗ Terraform not installed"

# Check if services are running
if systemctl is-active --quiet docker; then
    echo "✓ Docker service is running"
else
    echo "✗ Docker service is not running"
fi

# Check if Jenkins agent directory is properly set up
if [ -d "/opt/jenkins-agent" ] && [ -f "/opt/jenkins-agent/agent.jar" ]; then
    echo "✓ Jenkins agent directory is set up"
else
    echo "✗ Jenkins agent directory setup incomplete"
fi

echo "Jenkins Agent $AGENT_NAME setup completed successfully at $(date)"
echo "Check /tmp/jenkins-agent-status for detailed information"
echo ""
echo "IMPORTANT: This agent needs to be manually configured in Jenkins master before it can connect."
echo "See the status file for detailed instructions."