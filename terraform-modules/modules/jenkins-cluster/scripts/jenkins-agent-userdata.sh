#!/bin/bash

# Jenkins Agent Bootstrap Script
# This minimal script installs essential tools and sets up SSM agent

set -e

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Jenkins Agent bootstrap at $(date)"

# Variables from template
MASTER_IP=${master_ip}
JENKINS_PORT=${jenkins_port}
AGENT_NAME=${agent_name}
LOG_GROUP="${log_group}"

# Update and upgrade system packages
echo "Updating system packages..."
dnf update -y

# Install essential packages (excluding curl and packages that are already installed)
echo "Installing essential packages..."
dnf install -y coreutils grep findutils procps-ng which net-tools unzip git

# Start and enable SSM agent (already installed)
echo "Starting SSM agent..."
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Get instance information (using existing curl-minimal)
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Configure SSM agent
echo "Configuring SSM agent..."
mkdir -p /etc/amazon/ssm
cat > /etc/amazon/ssm/amazon-ssm-agent.json << EOF
{
    "Profile": "default",
    "Mds": {
        "Endpoint": "",
        "MessageRetryLimit": 5,
        "MessageRetryIntervalSeconds": 1
    },
    "Ssm": {
        "Endpoint": "",
        "HealthFrequencyMinutes": 5,
        "CustomInventoryDefaultLocation": "",
        "AssociationLogsRetentionDurationHours": 24,
        "RunCommandLogsRetentionDurationHours": 336,
        "SessionLogsRetentionDurationHours": 336,
        "SessionConnectionTimeoutSeconds": 60,
        "EndpointOverride": ""
    },
    "Mgs": {
        "Region": "$REGION",
        "Endpoint": "",
        "StopTimeoutMilliseconds": 20000,
        "SessionWorkersLimit": 1000
    },
    "Agent": {
        "Region": "$REGION",
        "OrchestrationDirectoryCleanupThreshold": 30,
        "DownloadProxyUri": ""
    }
}
EOF

# Restart SSM agent to apply configuration
systemctl restart amazon-ssm-agent

# Install Java
echo "Installing Java..."
dnf install -y java-21-amazon-corretto-headless

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto.x86_64
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto.x86_64' >> /etc/profile.d/java.sh
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile.d/java.sh
chmod +x /etc/profile.d/java.sh
source /etc/profile.d/java.sh

# Create Jenkins user and configure permissions
echo "Creating Jenkins user..."
useradd -m -s /bin/bash jenkins

# Create Jenkins agent directory
echo "Setting up Jenkins agent directories..."
mkdir -p /opt/jenkins-agent
mkdir -p /opt/jenkins-agent/workspace
mkdir -p /var/log/jenkins-agent
chown -R jenkins:jenkins /opt/jenkins-agent
chown -R jenkins:jenkins /var/log/jenkins-agent

# Install Docker
echo "Installing Docker..."
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker jenkins
usermod -aG docker ec2-user

# Install Ansible
echo "Installing Ansible..."
dnf install -y python3 python3-pip
pip3 install ansible

# Install additional useful tools for CI/CD
echo "Installing Terraform..."
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# Verify installations
echo "Verifying installations..."
docker --version
ansible --version
terraform --version
java -version

# Download Jenkins agent JAR using curl-minimal
echo "Downloading Jenkins agent JAR..."
curl -o /opt/jenkins-agent/agent.jar http://$MASTER_IP:$JENKINS_PORT/jnlpJars/agent.jar
chown jenkins:jenkins /opt/jenkins-agent/agent.jar

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

# Final status
echo "Jenkins Agent bootstrap completed successfully at $(date)"
echo "Agent Name: $AGENT_NAME"
echo "Master IP: $MASTER_IP"
echo "To connect agent, run: sudo -u jenkins /opt/jenkins-agent/connect-agent.sh <SECRET>"