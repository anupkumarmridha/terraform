#!/bin/bash
set -e

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

# Function: Setup instance
setup_instance() {
    local private_ip="$1"
    local instance_id="$2"
    local db_host="$3"
    local db_user="$4"
    local db_pass="$5"
    local db_name="$6"
    local db_port="$7"
    local app_key_path="$8"
    local bastion_ip="$9"
    
    print_status "INFO" "Executing setup commands on $private_ip..."
    
    # Try multiple times with increasing timeouts
    for attempt in {1..3}; do
        print_status "INFO" "Setup attempt $attempt on $private_ip..."
        
        # Create a temporary script file for the remote commands
        local temp_script="/tmp/remote_setup_$instance_id.sh"
        cat > "$temp_script" << 'EOF'
#!/bin/bash
set -e

# Import functions (simplified for remote execution)
print_remote_status() {
    local status="$1"
    local message="$2"
    case $status in
        "INFO") echo "ℹ️  $message" ;;
        "SUCCESS") echo "✅ $message" ;;
        "WARNING") echo "⚠️  $message" ;;
        "ERROR") echo "❌ $message" ;;
        "DEBUG") echo "🔍 $message" ;;
        *) echo "$message" ;;
    esac
}
        
print_remote_status "INFO" "Starting instance setup..."
set -e

if ! curl -s --connect-timeout 5 http://amazonlinux.default.amazonaws.com/ > /dev/null; then
    print_remote_status "ERROR" "No internet connectivity. Cannot install packages."
    exit 1
fi

# Install packages
print_remote_status "INFO" "Installing packages..."
if ! sudo yum update -y > /tmp/yum_update.log 2>&1; then
    print_remote_status "WARNING" "yum update failed"
fi
if ! sudo yum install -y httpd php php-mysqli mariadb105 > /tmp/yum_install.log 2>&1; then
    print_remote_status "ERROR" "yum install failed"
    exit 1
fi
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
EOF

        # Append the environment configuration with proper variable substitution
        cat >> "$temp_script" << EOF
# Create environment file
print_remote_status "INFO" "Creating environment configuration..."
sudo tee /var/www/html/.env << EOL
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
DB_PORT=${db_port}
EOL
        
# Create dashboard HTML directly
print_remote_status "INFO" "Creating dashboard HTML..."
sudo tee /var/www/html/index.html << 'EOHTML'
<!DOCTYPE html>
<html lang="en">
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
print_remote_status "SUCCESS" "Dashboard HTML created"

# Set permissions
print_remote_status "INFO" "Setting file permissions..."
sudo chown -R apache:apache /var/www/html/
sudo chmod 644 /var/www/html/*.php /var/www/html/*.html 2>/dev/null || true
sudo chmod 600 /var/www/html/.env

# Test database connection
print_remote_status "DEBUG" "Testing database connection..."
if command -v mysql &> /dev/null; then
    if mysql -h${db_host} -u${db_user} -p${db_pass} -P${db_port} ${db_name} -e "SELECT 1;" >/dev/null 2>&1; then
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

        # Make the script executable
        chmod +x "$temp_script"
        
        # Detect if we are already on the bastion
        local on_bastion=true
        if [ -n "$bastion_ip" ] && [ "$bastion_ip" != "$(hostname -I | awk '{print $1}')" ]; then
            on_bastion=false
        fi
        
        # Create a script to run on the remote instance
        local remote_script="/tmp/remote_exec_$instance_id.sh"
        cat > "$remote_script" << EOF
#!/bin/bash
cat > /tmp/setup_script.sh << 'EOFINNER'
$(cat "$temp_script")
EOFINNER
chmod +x /tmp/setup_script.sh
/tmp/setup_script.sh
EOF
        chmod +x "$remote_script"
        
        # Execute the script on the remote instance
        local ssh_cmd=""
        if [ -n "$app_key_path" ] && [ -f "$app_key_path" ]; then
            if [ "$on_bastion" = true ]; then
                ssh_cmd="timeout $((60 * attempt)) ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -i \"$app_key_path\" ec2-user@$private_ip 'bash -s' < \"$remote_script\""
            else
                ssh_cmd="timeout $((60 * attempt)) ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -i \"$app_key_path\" -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@$bastion_ip\" ec2-user@$private_ip 'bash -s' < \"$remote_script\""
            fi
        else
            if [ "$on_bastion" = true ]; then
                ssh_cmd="timeout $((60 * attempt)) ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes ec2-user@$private_ip 'bash -s' < \"$remote_script\""
            else
                ssh_cmd="timeout $((60 * attempt)) ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@$bastion_ip\" ec2-user@$private_ip 'bash -s' < \"$remote_script\""
            fi
        fi
        
        print_status "DEBUG" "Setup SSH command: $ssh_cmd"
        
        if eval $ssh_cmd; then
            print_status "SUCCESS" "Instance setup completed successfully on attempt $attempt"
            rm -f "$temp_script" "$remote_script"
            return 0
        fi
        
        rm -f "$temp_script" "$remote_script"
        
        print_status "WARNING" "Setup attempt $attempt failed"
        
        if [ $attempt -lt 3 ]; then
            local wait_time=$((15 * attempt))
            print_status "INFO" "Waiting $wait_time seconds before next attempt..."
            sleep $wait_time
        fi
    done
    
    print_status "ERROR" "Failed to setup instance $instance_id after multiple attempts"
    return 1
}

# If script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if all required arguments are provided
    if [ "$#" -lt 7 ]; then
        echo "Usage: $0 <private_ip> <instance_id> <db_host> <db_user> <db_pass> <db_name> <db_port> [app_key_path] [bastion_ip]"
        exit 1
    fi

    # Call the setup_instance function with all arguments
    setup_instance "$1" "$2" "$3" "$4" "$5" "$6" "$7" "${8:-}" "${9:-}"
fi
