#!/bin/bash
set -e

# Variables from template
DB_HOST="${db_host}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
DB_NAME="${db_name}"
DB_PORT="${db_port}"
ASG_NAME="${asg_name}"
BASTION_IP="${bastion_ip}"
BASTION_KEY="${bastion_key}"

echo "Starting local MySQL connection deployment..."

# Validate required parameters
if [ -z "$BASTION_IP" ] || [ -z "$BASTION_KEY" ] || [ -z "$ASG_NAME" ]; then
    echo "Error: Missing required parameters"
    echo "BASTION_IP: $BASTION_IP"
    echo "BASTION_KEY: $BASTION_KEY"
    echo "ASG_NAME: $ASG_NAME"
    exit 1
fi

# Check if bastion key exists
if [ ! -f "$BASTION_KEY" ]; then
    echo "Error: Bastion key file not found: $BASTION_KEY"
    exit 1
fi

# Create temporary deployment script
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << EOF
#!/bin/bash
set -e

# Variables
DB_HOST="$DB_HOST"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
DB_NAME="$DB_NAME"
DB_PORT="$DB_PORT"
ASG_NAME="$ASG_NAME"

echo "Starting MySQL connection setup for existing Docker application..."

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
fi

# Get instance IDs from ASG
echo "Getting instance IDs from ASG: \$ASG_NAME"
INSTANCE_IDS=\$(aws autoscaling describe-auto-scaling-groups \\
    --auto-scaling-group-names "\$ASG_NAME" \\
    --query 'AutoScalingGroups[0].Instances[?LifecycleState==\`InService\`].InstanceId' \\
    --output text)

if [ -z "\$INSTANCE_IDS" ]; then
    echo "No running instances found in ASG"
    exit 1
fi

echo "Found instances: \$INSTANCE_IDS"

# Create MySQL connection PHP file
cat > /tmp/mysql-connection.php << 'EOPHP'
<?php
// Read environment variables from .env file
if (file_exists(__DIR__ . '/.env')) {
    \$lines = file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach (\$lines as \$line) {
        if (strpos(\$line, '=') !== false && strpos(\$line, '#') !== 0) {
            list(\$key, \$value) = explode('=', \$line, 2);
            \$_ENV[trim(\$key)] = trim(\$value);
        }
    }
}

// Get RDS connection details
\$servername = \$_ENV['DB_HOST'] ?? 'localhost';
\$username = \$_ENV['DB_USER'] ?? 'admin';
\$password = \$_ENV['DB_PASS'] ?? '';
\$dbname = \$_ENV['DB_NAME'] ?? 'appdb';
\$port = \$_ENV['DB_PORT'] ?? 3306;

// Create connection
\$conn = new mysqli(\$servername, \$username, \$password, \$dbname, \$port);

// Check connection
if (\$conn->connect_error) {
    die("<h1>Connection Failed</h1><p>Error: " . \$conn->connect_error . "</p>");
}

echo "<h1>MySQL Database Connection Test</h1>";
echo "<div style='background-color: #dff0d8; padding: 15px; border: 1px solid #d6e9c6; border-radius: 4px; margin: 10px 0;'>";
echo "<strong>✅ Connected successfully to MySQL database!</strong>";
echo "</div>";

echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 20px 0;'>";
echo "<tr style='background-color: #f5f5f5;'><th style='padding: 10px; text-align: left;'>Parameter</th><th style='padding: 10px; text-align: left;'>Value</th></tr>";
echo "<tr><td style='padding: 10px;'><strong>Server</strong></td><td style='padding: 10px;'>" . htmlspecialchars(\$servername) . "</td></tr>";
echo "<tr><td style='padding: 10px;'><strong>Database</strong></td><td style='padding: 10px;'>" . htmlspecialchars(\$dbname) . "</td></tr>";
echo "<tr><td style='padding: 10px;'><strong>Username</strong></td><td style='padding: 10px;'>" . htmlspecialchars(\$username) . "</td></tr>";
echo "<tr><td style='padding: 10px;'><strong>Port</strong></td><td style='padding: 10px;'>" . htmlspecialchars(\$port) . "</td></tr>";

// Get instance information
\$instance_id = @file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
echo "<tr><td style='padding: 10px;'><strong>Instance ID</strong></td><td style='padding: 10px;'>" . htmlspecialchars(\$instance_id ?: 'Unknown') . "</td></tr>";

// Test connection with actual query
\$sql = "SELECT VERSION() as version";
\$result = \$conn->query(\$sql);

if (\$result && \$result->num_rows > 0) {
    \$row = \$result->fetch_assoc();
    echo "<tr><td style='padding: 10px;'><strong>MySQL Version</strong></td><td style='padding: 10px;'>" . htmlspecialchars(\$row["version"]) . "</td></tr>";
}

echo "</table>";

\$conn->close();
?>
EOPHP

# Deploy to each instance
for INSTANCE_ID in \$INSTANCE_IDS; do
    echo "Setting up MySQL connection on instance: \$INSTANCE_ID"
    
    # Get private IP of instance
    PRIVATE_IP=\$(aws ec2 describe-instances \\
        --instance-ids \$INSTANCE_ID \\
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \\
        --output text)
    
    echo "Instance private IP: \$PRIVATE_IP"
    
    # Copy files to instance
    scp -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p ec2-user@\$(hostname -I | awk '{print \$1}')" \\
        /tmp/mysql-connection.php ec2-user@\$PRIVATE_IP:/tmp/
    
    # Execute setup on instance
    ssh -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p ec2-user@\$(hostname -I | awk '{print \$1}')" \\
        ec2-user@\$PRIVATE_IP << 'EOSSH'
        # Install required packages
        sudo yum update -y
        sudo yum install -y httpd php php-mysqli
        
        # Start Apache
        sudo systemctl start httpd
        sudo systemctl enable httpd
        
        # Setup web directory
        sudo mkdir -p /var/www/html
        sudo cp /tmp/mysql-connection.php /var/www/html/
        
        # Create environment file
        sudo tee /var/www/html/.env << EOENV
DB_HOST=\$DB_HOST
DB_USER=\$DB_USER
DB_PASS=\$DB_PASS
DB_NAME=\$DB_NAME
DB_PORT=\$DB_PORT
EOENV
        
        # Set permissions
        sudo chown -R apache:apache /var/www/html/
        sudo chmod 644 /var/www/html/*.php
        sudo chmod 600 /var/www/html/.env
        
        # Restart Apache
        sudo systemctl restart httpd
        
        echo "Setup completed on \$INSTANCE_ID"
EOSSH
    
    echo "Successfully deployed to instance: \$INSTANCE_ID"
done

echo "Local deployment completed"
EOF

# Execute deployment via bastion host
echo "Connecting to bastion host: $BASTION_IP"
ssh -o StrictHostKeyChecking=no -i "$BASTION_KEY" ec2-user@$BASTION_IP 'bash -s' < "$TEMP_SCRIPT"

# Cleanup
rm -f "$TEMP_SCRIPT"

echo "Local deployment completed successfully"