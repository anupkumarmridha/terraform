#!/bin/bash

# Jenkins Master User Data Script
# This script sets up Jenkins master with proper configuration for master-slave architecture

set -e

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Jenkins Master setup at $(date)"

# Variables from template
JENKINS_PORT=${jenkins_port}
AGENT_PORT=${agent_port}
LOG_GROUP="${log_group}"
JENKINS_HOME="/var/lib/jenkins"

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
    dejavu-sans-fonts

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk' >> /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/environment

# Verify Java installation
java -version

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
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
JENKINS_PORT="$JENKINS_PORT"
JENKINS_LISTEN_ADDRESS=""
JENKINS_HTTPS_PORT=""
JENKINS_HTTPS_KEYSTORE=""
JENKINS_HTTPS_KEYSTORE_PASSWORD=""
JENKINS_HTTPS_LISTEN_ADDRESS=""
JENKINS_HTTP2_PORT=""
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
  <disabledAdministrativeMonitors/>
  <version>2.426.1</version>
  <installStateName>RUNNING</installStateName>
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
  <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
  <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
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
      <properties class="hudson.model.View$PropertyList"/>
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

# Create Jenkins location configuration
echo "Creating Jenkins location configuration..."
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
cat > $JENKINS_HOME/jenkins.model.JenkinsLocationConfiguration.xml << EOF
<?xml version='1.1' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
  <adminAddress>admin@localhost</adminAddress>
  <jenkinsUrl>http://$INSTANCE_IP:$JENKINS_PORT/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
EOF

# Skip setup wizard
echo "Configuring Jenkins to skip setup wizard..."
mkdir -p $JENKINS_HOME/init.groovy.d
cat > $JENKINS_HOME/init.groovy.d/basic-security.groovy << 'GROOVY_EOF'
#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Enable agent to master security
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

instance.save()
GROOVY_EOF

# Set proper ownership
chown -R jenkins:jenkins $JENKINS_HOME

# Install CloudWatch agent if log group is provided
if [ ! -z "$LOG_GROUP" ]; then
    echo "Installing and configuring CloudWatch agent..."
    dnf install -y amazon-cloudwatch-agent
    
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << CLOUDWATCH_EOF
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
                        "file_path": "/var/log/jenkins/jenkins.log",
                        "log_group_name": "$LOG_GROUP",
                        "log_stream_name": "jenkins-master-{instance_id}",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "$LOG_GROUP",
                        "log_stream_name": "jenkins-master-userdata-{instance_id}",
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
            "diskio": {
                "measurement": [
                    "io_time"
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
CLOUDWATCH_EOF
    
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

# Configure log rotation for Jenkins
echo "Setting up log rotation..."
cat > /etc/logrotate.d/jenkins << LOGROTATE_EOF
/var/log/jenkins/jenkins.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 jenkins jenkins
    postrotate
        systemctl reload jenkins > /dev/null 2>&1 || true
    endscript
}
LOGROTATE_EOF

# Start and enable Jenkins
echo "Starting Jenkins service..."
systemctl daemon-reload
systemctl enable jenkins

# Start Jenkins and wait for it to be ready
systemctl start jenkins

# Wait for Jenkins to start and create initial admin password
echo "Waiting for Jenkins to start..."
timeout=300
counter=0
while [ $counter -lt $timeout ]; do
    if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
        echo "Jenkins started successfully"
        break
    fi
    sleep 5
    counter=$((counter + 5))
    echo "Waiting for Jenkins... ($counter/$timeout seconds)"
done

if [ $counter -ge $timeout ]; then
    echo "Jenkins failed to start within timeout"
    exit 1
fi

# Get Jenkins status and initial password
JENKINS_PASSWORD=""
if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
    JENKINS_PASSWORD=$(cat $JENKINS_HOME/secrets/initialAdminPassword)
fi

# Create status file
echo "Creating status file..."
cat > /tmp/jenkins-master-status << STATUS_EOF
Jenkins Master Setup Status: SUCCESS
Installation Time: $(date)
Jenkins Version: $(jenkins --version 2>/dev/null || echo "N/A")
Java Version: $(java -version 2>&1 | head -n 1)
Jenkins URL: http://$INSTANCE_IP:$JENKINS_PORT
Agent Communication Port: $AGENT_PORT
Initial Admin Password: $JENKINS_PASSWORD
Jenkins Home: $JENKINS_HOME

Service Status:
$(systemctl is-active jenkins)

Disk Usage:
$(df -h /)

Memory Usage:
$(free -h)

Network Configuration:
$(ip addr show | grep -E "(inet|ether)" | head -10)

Log Files:
- Jenkins Log: /var/log/jenkins/jenkins.log
- User Data Log: /var/log/user-data.log
- System Log: /var/log/messages

Next Steps:
1. Access Jenkins via SSH tunnel through bastion host
2. Use initial admin password to log in
3. Configure Jenkins agents manually or via API
4. Install required plugins
STATUS_EOF

# Set proper permissions on status file
chmod 644 /tmp/jenkins-master-status

# Final verification
echo "Performing final verification..."
if systemctl is-active --quiet jenkins; then
    echo "✓ Jenkins service is running"
else
    echo "✗ Jenkins service is not running"
    systemctl status jenkins
fi

if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
    echo "✓ Initial admin password created"
else
    echo "✗ Initial admin password not found"
fi

if netstat -tlnp | grep -q ":$JENKINS_PORT"; then
    echo "✓ Jenkins is listening on port $JENKINS_PORT"
else
    echo "✗ Jenkins is not listening on port $JENKINS_PORT"
fi

echo "Jenkins Master setup completed successfully at $(date)"
echo "Check /tmp/jenkins-master-status for detailed information"

# Optional: Install additional tools commonly used in CI/CD
echo "Installing additional CI/CD tools..."
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker jenkins

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

# Restart Jenkins to ensure all configurations are loaded
echo "Restarting Jenkins to load all configurations..."
systemctl restart jenkins

# Wait for Jenkins to be ready after restart
sleep 30

echo "Jenkins Master setup completed successfully!"