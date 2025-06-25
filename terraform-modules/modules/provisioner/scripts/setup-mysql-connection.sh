#!/bin/bash
set -e

# Variables from template
DB_HOST="${db_host}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
DB_NAME="${db_name}"
DB_PORT="${db_port}"
ASG_NAME="${asg_name}"

# Global variables
REGION=""
BASTION_IP=""
SUCCESS_COUNT=0
TOTAL_COUNT=0

# Function: Print colored output
print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "INFO")
            echo "ℹ️  $message"
            ;;
        "SUCCESS")
            echo "✅ $message"
            ;;
        "WARNING")
            echo "⚠️  $message"
            ;;
        "ERROR")
            echo "❌ $message"
            ;;
        "DEBUG")
            echo "🔍 $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Function: Install AWS CLI
install_aws_cli() {
    print_status "INFO" "Installing AWS CLI..."
    
    if command -v aws &> /dev/null; then
        print_status "SUCCESS" "AWS CLI already installed"
        return 0
    fi
    
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
    
    print_status "SUCCESS" "AWS CLI installed successfully"
}

# Function: Configure AWS CLI
configure_aws_cli() {
    print_status "INFO" "Configuring AWS CLI..."
    
    # Get region from metadata service
    print_status "DEBUG" "Getting AWS region from metadata service..."
    REGION=$(curl -s --max-time 10 http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
    
    if [ -z "$REGION" ]; then
        REGION="us-east-1"
        print_status "WARNING" "Could not determine region, using default: $REGION"
    else
        print_status "INFO" "Using AWS region: $REGION"
    fi
    
    # Configure AWS CLI
    aws configure set region $REGION
    aws configure set output json
    
    print_status "SUCCESS" "AWS CLI configured for region: $REGION"
}

# Function: Test AWS CLI access
test_aws_access() {
    print_status "DEBUG" "Testing AWS CLI access..."
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_status "ERROR" "AWS CLI not properly configured. Please check IAM role permissions."
        print_status "DEBUG" "Attempting to get identity information..."
        aws sts get-caller-identity || true
        return 1
    fi
    
    print_status "SUCCESS" "AWS CLI access verified"
    return 0
}

# Function: Get ASG instances
get_asg_instances() {
    local asg_name="$1"
    print_status "INFO" "Getting instance IDs from ASG: $asg_name"
    
    local instance_ids=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$asg_name" \
        --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId' \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$instance_ids" ] || [ "$instance_ids" = "None" ]; then
        print_status "WARNING" "No running instances found in ASG: $asg_name"
        debug_asg_status "$asg_name"
        return 1
    fi
    
    print_status "SUCCESS" "Found instances: $instance_ids"
    echo "$instance_ids"
    return 0
}

# Function: Debug ASG status
debug_asg_status() {
    local asg_name="$1"
    print_status "DEBUG" "Checking ASG status..."
    
    if aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$asg_name" >/dev/null 2>&1; then
        print_status "INFO" "ASG exists but no InService instances found"
        
        local all_instances=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names "$asg_name" \
            --query 'AutoScalingGroups[0].Instances[].{InstanceId:InstanceId,State:LifecycleState}' \
            --output table 2>/dev/null || echo "Unable to retrieve instance details")
        
        print_status "DEBUG" "All instances in ASG:"
        echo "$all_instances"
    else
        print_status "ERROR" "ASG '$asg_name' not found or not accessible"
    fi
}

# Function: Get bastion IP
get_bastion_ip() {
    BASTION_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$BASTION_IP" ]; then
        print_status "ERROR" "Could not determine bastion IP"
        return 1
    fi
    print_status "INFO" "Bastion host IP: $BASTION_IP"
    return 0
}

# Function: Test SSH connectivity
test_ssh_connectivity() {
    local private_ip="$1"
    local instance_id="$2"
    
    print_status "DEBUG" "Testing SSH connectivity to $private_ip..."
    
    if ! timeout 15 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes \
        -o ProxyCommand="ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@127.0.0.1" \
        ec2-user@$private_ip "echo 'Connection successful'" 2>/dev/null; then
        
        print_status "WARNING" "Cannot connect to instance $instance_id ($private_ip)"
        print_status "INFO" "This could be due to:"
        print_status "INFO" "  - Instance still booting up"
        print_status "INFO" "  - Security group configuration"
        print_status "INFO" "  - SSH key mismatch"
        return 1
    fi
    
    print_status "SUCCESS" "SSH connection successful to $private_ip"
    return 0
}

# Function: Copy files to instance
copy_files_to_instance() {
    local private_ip="$1"
    local instance_id="$2"
    
    print_status "INFO" "Copying mysql-connection.php to $private_ip..."
    
    if ! scp -o StrictHostKeyChecking=no -o BatchMode=yes \
        -o ProxyCommand="ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@127.0.0.1" \
        /tmp/mysql-connection.php ec2-user@$private_ip:/tmp/ 2>/dev/null; then
        
        print_status "ERROR" "Failed to copy files to instance $instance_id"
        return 1
    fi
    
    print_status "SUCCESS" "Files copied successfully to $private_ip"
    return 0
}

# Function: Setup instance
setup_instance() {
    local private_ip="$1"
    local instance_id="$2"
    
    print_status "INFO" "Executing setup commands on $private_ip..."
    
    if ssh -o StrictHostKeyChecking=no -o BatchMode=yes \
        -o ProxyCommand="ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@127.0.0.1" \
        ec2-user@$private_ip << EOF
        # Import functions (simplified for remote execution)
        print_remote_status() {
            local status="\$1"
            local message="\$2"
            case \$status in
                "INFO") echo "ℹ️  \$message" ;;
                "SUCCESS") echo "✅ \$message" ;;
                "WARNING") echo "⚠️  \$message" ;;
                "ERROR") echo "❌ \$message" ;;
                "DEBUG") echo "🔍 \$message" ;;
                *) echo "\$message" ;;
            esac
        }
        
        print_remote_status "INFO" "Starting instance setup..."
        set -e
        
        # Install packages
        print_remote_status "INFO" "Installing packages..."
        sudo yum update -y >/dev/null 2>&1
        sudo yum install -y httpd php php-mysqli mysql >/dev/null 2>&1
        print_remote_status "SUCCESS" "Packages installed"
        
        # Start Apache
        print_remote_status "INFO" "Starting Apache..."
        sudo systemctl start httpd
        sudo systemctl enable httpd >/dev/null 2>&1
        print_remote_status "SUCCESS" "Apache started"
        
        # Setup web directory
        sudo mkdir -p /var/www/html
        
        # Setup PHP file
        print_remote_status "INFO" "Setting up web files..."
        if [ -f /tmp/mysql-connection.php ]; then
            sudo cp /tmp/mysql-connection.php /var/www/html/
            sudo chown apache:apache /var/www/html/mysql-connection.php
            sudo chmod 644 /var/www/html/mysql-connection.php
            print_remote_status "SUCCESS" "MySQL connection PHP file deployed"
        else
            print_remote_status "WARNING" "mysql-connection.php not found in /tmp/"
        fi
        
        # Create environment file
        print_remote_status "INFO" "Creating environment configuration..."
        sudo tee /var/www/html/.env << EOL
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
EOL
        
        # Create dashboard
        print_remote_status "INFO" "Creating service dashboard..."
        sudo tee /var/www/html/index.html << 'EOHTML'
<!DOCTYPE html>
<html>
<head>
    <title>Application Services Dashboard</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .service { border: 1px solid #ddd; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .docker { background-color: #e3f2fd; border-left: 4px solid #2196f3; }
        .mysql { background-color: #f3e5f5; border-left: 4px solid #9c27b0; }
        .status { font-weight: bold; margin: 10px 0; }
        .links a { display: inline-block; margin: 5px 10px 5px 0; padding: 8px 15px; background-color: #007bff; color: white; text-decoration: none; border-radius: 4px; }
        .links a:hover { background-color: #0056b3; }
        .refresh-btn { position: fixed; bottom: 20px; right: 20px; background-color: #28a745; color: white; border: none; padding: 12px 20px; border-radius: 50px; cursor: pointer; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Application Services Dashboard</h1>
        <p>Multi-service application running on AWS</p>
        
        <div class="service docker">
            <h2>🐳 Docker Application</h2>
            <p><strong>Technology:</strong> Node.js Container</p>
            <p><strong>Port:</strong> 8080</p>
            <p><strong>Status:</strong> <span id="docker-status">Checking...</span></p>
            <div class="links">
                <a href="http://localhost:8080" target="_blank">Access Docker App</a>
                <a href="http://localhost:8080/health" target="_blank">Health Check</a>
            </div>
        </div>
        
        <div class="service mysql">
            <h2>🐬 MySQL Connection Test</h2>
            <p><strong>Technology:</strong> PHP/Apache</p>
            <p><strong>Port:</strong> 80</p>
            <p><strong>Status:</strong> <span style="color: green;">✅ Active</span></p>
            <div class="links">
                <a href="/mysql-connection.php" target="_blank">Test MySQL Connection</a>
            </div>
        </div>
        
        <div style="margin-top: 30px; padding: 20px; background-color: #f8f9fa; border-radius: 5px;">
            <h3>📊 Quick Stats</h3>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Local Time:</strong> <span id="current-time">Loading...</span></p>
        </div>
    </div>
    
    <button class="refresh-btn" onclick="location.reload()">🔄</button>
    
    <script>
        // Check Docker service status
        fetch('http://localhost:8080/health')
            .then(response => response.ok ? 
                document.getElementById('docker-status').innerHTML = '<span style="color: green;">✅ Running</span>' :
                document.getElementById('docker-status').innerHTML = '<span style="color: orange;">⚠️ Issues</span>'
            )
            .catch(() => document.getElementById('docker-status').innerHTML = '<span style="color: red;">❌ Not Running</span>');
        
        // Load instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'Unknown');
        
        // Set current time
        document.getElementById('current-time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOHTML
        
        # Set permissions
        print_remote_status "INFO" "Setting file permissions..."
        sudo chown -R apache:apache /var/www/html/
        sudo chmod 644 /var/www/html/*.php /var/www/html/*.html 2>/dev/null || true
        sudo chmod 600 /var/www/html/.env
        
        # Test database connection
        print_remote_status "DEBUG" "Testing database connection..."
        if command -v mysql &> /dev/null; then
            if mysql -h$DB_HOST -u$DB_USER -p$DB_PASS -P$DB_PORT $DB_NAME -e "SELECT 1;" >/dev/null 2>&1; then
                print_remote_status "SUCCESS" "Database connection successful"
            else
                print_remote_status "ERROR" "Database connection failed"
            fi
        fi
        
        # Restart Apache
        print_remote_status "INFO" "Restarting Apache..."
        sudo systemctl restart httpd
        
        # Verify services
        print_remote_status "DEBUG" "Verifying services..."
        if sudo systemctl is-active httpd >/dev/null 2>&1; then
            print_remote_status "SUCCESS" "Apache is running"
        else
            print_remote_status "ERROR" "Apache failed to start"
            exit 1
        fi
        
        # Check Docker status
        if docker ps | grep -q test-asg-server 2>/dev/null; then
            print_remote_status "SUCCESS" "Docker container is running"
        else
            print_remote_status "INFO" "Docker container not found (normal if not yet deployed)"
        fi
        
        print_remote_status "SUCCESS" "Instance setup completed successfully!"
EOF
    then
        return 0
    else
        return 1
    fi
}

# Function: Process single instance
process_instance() {
    local instance_id="$1"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    echo "========================================="
    print_status "INFO" "Processing instance: $instance_id"
    echo "========================================="
    
    # Get private IP
    local private_ip=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text 2>/dev/null || echo "None")
    
    if [ "$private_ip" = "None" ] || [ -z "$private_ip" ]; then
        print_status "WARNING" "Could not get private IP for instance $instance_id"
        return 1
    fi
    
    print_status "INFO" "Instance private IP: $private_ip"
    
    # Test connectivity
    if ! test_ssh_connectivity "$private_ip" "$instance_id"; then
        return 1
    fi
    
    # Copy files
    if ! copy_files_to_instance "$private_ip" "$instance_id"; then
        return 1
    fi
    
    # Setup instance
    if ! setup_instance "$private_ip" "$instance_id"; then
        print_status "ERROR" "Failed to setup instance $instance_id"
        return 1
    fi
    
    print_status "SUCCESS" "Successfully configured instance: $instance_id"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    return 0
}

# Function: Print final summary
print_summary() {
    echo ""
    echo "========================================="
    print_status "INFO" "MySQL Connection Setup Summary"
    echo "========================================="
    print_status "INFO" "Total instances: $TOTAL_COUNT"
    print_status "INFO" "Successful setups: $SUCCESS_COUNT"
    print_status "INFO" "Failed setups: $((TOTAL_COUNT - SUCCESS_COUNT))"
    echo "========================================="
    
    if [ $SUCCESS_COUNT -gt 0 ]; then
        print_status "SUCCESS" "Setup completed! Services are now available:"
        echo "1. Original Docker application on port 8080"
        echo "2. MySQL connection test on port 80 (Apache)"
        echo "3. Server status dashboard at http://<alb-dns>/"
        echo ""
        print_status "INFO" "Access URLs:"
        echo "- Main Dashboard: http://<your-alb-dns>/"
        echo "- MySQL Test: http://<your-alb-dns>/mysql-connection.php"
        echo "- Docker App: http://<your-alb-dns>:8080"
        return 0
    else
        print_status "ERROR" "No instances were successfully configured"
        return 1
    fi
}

# Main execution function
main() {
    print_status "INFO" "Starting MySQL connection setup for existing Docker application..."
    
    # Step 1: Install AWS CLI
    if ! install_aws_cli; then
        print_status "ERROR" "Failed to install AWS CLI"
        exit 1
    fi
    
    # Step 2: Configure AWS CLI
    if ! configure_aws_cli; then
        print_status "ERROR" "Failed to configure AWS CLI"
        exit 1
    fi
    
    # Step 3: Test AWS access
    if ! test_aws_access; then
        print_status "ERROR" "AWS access test failed"
        exit 1
    fi
    
    # Step 4: Get bastion IP
    if ! get_bastion_ip; then
        print_status "ERROR" "Failed to get bastion IP"
        exit 1
    fi
    
    # Step 5: Get ASG instances
    local instance_ids
    if ! instance_ids=$(get_asg_instances "$ASG_NAME"); then
        print_status "ERROR" "Failed to get ASG instances"
        exit 1
    fi
    
    # Step 6: Process each instance
    for instance_id in $instance_ids; do
        if ! process_instance "$instance_id"; then
            print_status "WARNING" "Failed to process instance $instance_id, continuing..."
        fi
        echo ""
    done
    
    # Step 7: Print summary
    if ! print_summary; then
        exit 1
    fi
}

# Execute main function
main "$@"