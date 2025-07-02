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
mkdir -p /var/log/jenkins
chown -R jenkins:jenkins $JENKINS_HOME
chown -R jenkins:jenkins /var/log/jenkins

# Configure Jenkins system settings
echo "Configuring Jenkins system settings..."
cat > /etc/sysconfig/jenkins << EOF
JENKINS_HOME="$JENKINS_HOME"
JENKINS_JAVA_CMD="$JAVA_HOME/bin/java"
JENKINS_USER="jenkins"
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Xmx2g"
JENKINS_PORT="$JENKINS_PORT"
JENKINS_LISTEN_ADDRESS=""
JENKINS_DEBUG_LEVEL="5"
JENKINS_ENABLE_ACCESS_LOG="yes"
JENKINS_HANDLER_MAX="100"
JENKINS_HANDLER_IDLE="20"
JENKINS_ARGS=""
EOF

# Create Jenkins main configuration
echo "Creating Jenkins main configuration..."
cat > $JENKINS_HOME/config.xml << 'JENKINS_CONFIG_EOF'
<?xml version='1.1' encoding='UTF-8'?>
<hudson>
  <version>2.414.3</version>
  <numExecutors>0</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
    <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
  </authorizationStrategy>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>false</disableSignup>
    <enableCaptcha>false</enableCaptcha>
  </securityRealm>
  <disableRememberMe>false</disableRememberMe>
  <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
  <workspaceDir>$${JENKINS_HOME}/workspace/$${ITEM_FULLNAME}</workspaceDir>
  <buildsDir>$${ITEM_ROOTDIR}/builds/$${ITEM_FULLNAME}</buildsDir>
  <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds/>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>all</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>all</primaryView>
  <slaveAgentPort>AGENT_PORT_PLACEHOLDER</slaveAgentPort>
  <label></label>
  <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
    <excludeClientIPFromCrumb>false</excludeClientIPFromCrumb>
  </crumbIssuer>
  <nodeProperties/>
  <globalNodeProperties/>
</hudson>
JENKINS_CONFIG_EOF

# Replace placeholder with actual agent port
sed -i "s/AGENT_PORT_PLACEHOLDER/$AGENT_PORT/g" $JENKINS_HOME/config.xml

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
