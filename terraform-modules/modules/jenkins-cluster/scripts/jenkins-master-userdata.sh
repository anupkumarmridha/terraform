#!/bin/bash

# Jenkins Master Bootstrap Script
# This minimal script installs essential tools and sets up SSM agent

set -e

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Jenkins Master bootstrap at $(date)"

# Variables from template
JENKINS_PORT=${jenkins_port}
AGENT_PORT=${agent_port}
LOG_GROUP="${log_group}"
JENKINS_HOME="${jenkins_home_dir}"
ITEM_FULLNAME="${item_fullname}"
ITEM_ROOTDIR="${item_rootdir}"

# Update and upgrade system packages
echo "Updating system packages..."
dnf update -y

# Fix issue with missing core commands
echo "Installing essential packages..."
dnf install -y coreutils grep findutils procps-ng which net-tools wget unzip git

# Start and enable SSM agent
echo "Starting SSM agent..."
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Get instance information
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

# Add Jenkins repository and install
echo "Adding Jenkins repository..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

echo "Installing Jenkins..."
dnf install -y jenkins
# Create Jenkins directories
echo "Setting up Jenkins directories..."
mkdir -p $JENKINS_HOME
mkdir -p $JENKINS_HOME/logs
mkdir -p $JENKINS_HOME/init.groovy.d
mkdir -p /var/log/jenkins
chown -R jenkins:jenkins $JENKINS_HOME
chown -R jenkins:jenkins /var/log/jenkins

# Create Jenkins initial admin user
echo "Creating Jenkins admin user..."
cat > $JENKINS_HOME/init.groovy.d/basic-security.groovy << 'GROOVY_EOF'
#!groovy

import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Only run this if Jenkins is not already configured
if (!instance.getInstallState().isSetupComplete()) {
    println "Setting up Jenkins admin user..."
    
    // Create admin user
    def hudsonRealm = new HudsonPrivateSecurityRealm(false)
    instance.setSecurityRealm(hudsonRealm)
    
    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(strategy)
    
    // Create admin user with username: admin, password: admin123
    def user = hudsonRealm.createAccount("admin", "admin123")
    user.save()
    
    // Enable CSRF protection
    instance.setCrumbIssuer(new DefaultCrumbIssuer(true))
    
    // Disable agent-to-master security for now (can be re-enabled later)
    instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)
    
    // Mark setup as complete
    instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
    
    instance.save()
    
    println "Jenkins admin user created successfully"
    println "Username: admin"
    println "Password: admin123"
} else {
    println "Jenkins is already configured, skipping user creation"
}
GROOVY_EOF

chown jenkins:jenkins $JENKINS_HOME/init.groovy.d/basic-security.groovy

# Configure Jenkins system settings
echo "Configuring Jenkins system settings..."
cat > /etc/sysconfig/jenkins << EOF
JENKINS_HOME="$JENKINS_HOME"
JENKINS_JAVA_CMD="$JAVA_HOME/bin/java"
JENKINS_USER="jenkins"
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx2g"
JENKINS_PORT="$JENKINS_PORT"
JENKINS_LISTEN_ADDRESS=""
JENKINS_DEBUG_LEVEL="5"
JENKINS_ENABLE_ACCESS_LOG="yes"
JENKINS_HANDLER_MAX="100"
JENKINS_HANDLER_IDLE="20"
JENKINS_ARGS=""
EOF


# Start and enable Jenkins
echo "Starting Jenkins service..."
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# Install Docker
echo "Installing Docker..."
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker jenkins


# Install additional tools for Jenkins master
echo "Installing additional tools..."
dnf install -y python3 python3-pip
pip3 install ansible


# Final status
echo "Jenkins Master bootstrap completed successfully at $(date)"
echo "Jenkins URL: http://$INSTANCE_IP:$JENKINS_PORT"
