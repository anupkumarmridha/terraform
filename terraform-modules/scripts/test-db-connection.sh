#!/bin/bash

# Script to test database connection from EC2 instance to RDS
# This script should be run on the EC2 instance after the app-userdata.sh script has completed

# Exit on any error
set -e

# Log all output
exec > >(tee /var/log/db-connection-test.log) 2>&1

echo "Starting database connection test at $(date)"

# Get the RDS endpoint
DB_HOST="anup-training-dev-mysql.cq174vfsoqja.us-east-1.rds.amazonaws.com"
echo "Testing connection to RDS endpoint: $DB_HOST"

# Install MySQL client if not already installed
if ! command -v mysql &> /dev/null; then
    echo "MySQL client not found. Installing..."
    yum install -y mysql
fi

# Test basic connectivity to the RDS endpoint
echo "Testing TCP connectivity to RDS endpoint..."
if nc -zv $DB_HOST 3306 &> /dev/null; then
    echo "TCP connection to $DB_HOST:3306 successful"
else
    echo "TCP connection to $DB_HOST:3306 failed"
    echo "Checking if port 3306 is open in security group..."
    # Try to get more information about the connection failure
    timeout 5 nc -v $DB_HOST 3306 || echo "Connection timed out or refused"
fi

# Try to retrieve database credentials from AWS Secrets Manager
echo "Attempting to retrieve database credentials from AWS Secrets Manager..."
SECRET_NAME="anup-training-dev-db-credentials"
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

if command -v aws &> /dev/null; then
    echo "AWS CLI is installed. Retrieving secret..."
    SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query 'SecretString' --output text 2>/dev/null || echo "Failed to retrieve secret")
    
    if [[ $SECRET_VALUE != "Failed to retrieve secret" ]]; then
        echo "Secret retrieved successfully"
        
        # Extract username and password from the secret
        # Note: This assumes the secret is in JSON format with username and password fields
        DB_USERNAME=$(echo $SECRET_VALUE | jq -r '.username // .user // "mysql_user"' 2>/dev/null || echo "mysql_user")
        DB_PASSWORD=$(echo $SECRET_VALUE | jq -r '.password // "mysql_password"' 2>/dev/null || echo "mysql_password")
        DB_NAME=$(echo $SECRET_VALUE | jq -r '.dbname // .database // "test_asg_db"' 2>/dev/null || echo "test_asg_db")
        
        echo "Using database name: $DB_NAME"
        echo "Using username: $DB_USERNAME"
        echo "Password retrieved (not shown for security)"
        
        # Test MySQL connection with retrieved credentials
        echo "Testing MySQL connection with retrieved credentials..."
        mysql -h $DB_HOST -u $DB_USERNAME -p"$DB_PASSWORD" -e "SELECT 'Connection successful!' as Status;" $DB_NAME 2>/dev/null && {
            echo "MySQL connection successful with retrieved credentials!"
        } || {
            echo "MySQL connection failed with retrieved credentials"
            echo "Error code: $?"
        }
    else
        echo "Failed to retrieve secret from AWS Secrets Manager"
    fi
else
    echo "AWS CLI not installed. Cannot retrieve secret."
fi

# Test MySQL connection with default credentials (as a fallback)
echo "Testing MySQL connection with default credentials..."
mysql -h $DB_HOST -u mysql_user -pmysql_password -e "SELECT 'Connection successful!' as Status;" test_asg_db 2>/dev/null && {
    echo "MySQL connection successful with default credentials!"
} || {
    echo "MySQL connection failed with default credentials"
    echo "Error code: $?"
}

# Check if the Docker container can connect to the database
echo "Checking if Docker container can connect to the database..."
if docker ps | grep -q test-asg-server; then
    echo "Docker container is running. Checking logs for database connection..."
    docker logs test-asg-server 2>&1 | grep -i "database\|mysql\|connection\|prisma" | tail -n 20
    
    echo "Executing database connection test inside the container..."
    docker exec test-asg-server sh -c 'echo "Testing database connection from inside container"; node -e "const { PrismaClient } = require(\"@prisma/client\"); const prisma = new PrismaClient(); async function testConnection() { try { console.log(\"Attempting to connect to database...\"); const result = await prisma.\$queryRaw\`SELECT 1 as connected\`; console.log(\"Database connection successful:\", result); } catch (error) { console.error(\"Database connection failed:\", error); } finally { await prisma.\$disconnect(); } } testConnection();"' || echo "Failed to execute test in container"
else
    echo "Docker container is not running"
fi

echo "Database connection test completed at $(date)"
echo "Check /var/log/db-connection-test.log for full results"
