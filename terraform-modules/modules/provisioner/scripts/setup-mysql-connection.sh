#!/bin/bash
set -e

# Variables from template
DB_HOST="${db_host}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
DB_NAME="${db_name}"
DB_PORT="${db_port}"
ASG_NAME="${asg_name}"
APP_KEY_PATH="${app_key_path}"
ALB_DNS="${alb_dns_name}"

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
    
    # Try multiple times with increasing wait periods
    for attempt in {1..5}; do
        print_status "INFO" "Attempt $attempt to find instances in ASG..."
        
        # Use --output=text to get clean instance IDs
        local instance_ids=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names "$asg_name" \
            --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId' \
            --output text 2>/dev/null || echo "")
        
        # Check if we got any instances
        if [ -n "$instance_ids" ]; then
            print_status "SUCCESS" "Found instances in ASG"
            echo "$instance_ids"
            return 0
        fi
        
        print_status "WARNING" "No running instances found in ASG: $asg_name (attempt $attempt of 5)"
        debug_asg_status "$asg_name"
        
        if [ $attempt -lt 5 ]; then
            local wait_time=$((30 * attempt))
            print_status "INFO" "Waiting $wait_time seconds for instances to become available..."
            sleep $wait_time
        fi
    done
    
    print_status "ERROR" "Failed to find any InService instances after multiple attempts"
    return 1
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

# Function: Setup app key
setup_app_key() {
    # Check if app key info file exists
    if [ -f "/tmp/app_key_info.env" ]; then
        source /tmp/app_key_info.env
        if [ "$APP_KEY_PROVIDED" = "true" ] && [ -f "$APP_KEY_PATH" ]; then
            print_status "INFO" "Setting up app private key..."
            chmod 600 "$APP_KEY_PATH"
            print_status "SUCCESS" "App private key permissions set"
            
            # Create a symlink with the expected key name format if needed
            if [[ "$APP_KEY_PATH" != *".pem" ]]; then
                local key_name=$(basename "$APP_KEY_PATH")
                ln -sf "$APP_KEY_PATH" "/tmp/$key_name.pem"
                print_status "INFO" "Created symlink to key with .pem extension: /tmp/$key_name.pem"
            fi
            
            return 0
        else
            print_status "INFO" "No app private key provided, using default authentication"
            return 0
        fi
    else
        print_status "INFO" "No app key info file found, using default authentication"
        return 0
    fi
}

# Function: Test SSH connectivity
test_ssh_connectivity() {
    local private_ip="$1"
    local instance_id="$2"
    
    print_status "DEBUG" "Testing SSH connectivity to $private_ip..."
    
    # Detect if we are already on the bastion
    local on_bastion=true
    if [ -n "$BASTION_IP" ] && [ "$BASTION_IP" != "$(hostname -I | awk '{print $1}')" ]; then
        on_bastion=false
    fi
    
    # Try multiple times with increasing timeouts
    for attempt in {1..3}; do
        print_status "INFO" "SSH connection attempt $attempt to $private_ip..."
        
        local ssh_cmd=""
        if [ -n "$APP_KEY_PATH" ] && [ -f "$APP_KEY_PATH" ]; then
            if [ "$on_bastion" = true ]; then
                ssh_cmd="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -i \"$APP_KEY_PATH\" ec2-user@$private_ip \"echo 'Connection successful'\""
            else
                ssh_cmd="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -i \"$APP_KEY_PATH\" -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@$BASTION_IP\" ec2-user@$private_ip \"echo 'Connection successful'\""
            fi
        else
            if [ "$on_bastion" = true ]; then
                ssh_cmd="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes ec2-user@$private_ip \"echo 'Connection successful'\""
            else
                ssh_cmd="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@$BASTION_IP\" ec2-user@$private_ip \"echo 'Connection successful'\""
            fi
        fi
        
        # Print the SSH command for debugging
        print_status "DEBUG" "SSH command: $ssh_cmd"
        
        # Actually run the command
        if eval $ssh_cmd 2>/dev/null; then
            print_status "SUCCESS" "SSH connection successful to $private_ip on attempt $attempt"
            return 0
        fi
        
        print_status "WARNING" "SSH connection attempt $attempt failed"
        print_status "INFO" "This could be due to:"
        print_status "INFO" "  - Instance still booting up"
        print_status "INFO" "  - Security group configuration"
        print_status "INFO" "  - SSH key mismatch"
        
        if [ $attempt -lt 3 ]; then
            local wait_time=$((10 * attempt))
            print_status "INFO" "Waiting $wait_time seconds before next attempt..."
            sleep $wait_time
        fi
    done
    
    print_status "ERROR" "Failed to connect to instance $instance_id after multiple attempts"
    return 1
}

# Function: Copy files to instance
copy_files_to_instance() {
    local private_ip="$1"
    local instance_id="$2"
    
    print_status "INFO" "Copying mysql-connection.php to $private_ip..."
    
    # Detect if we are already on the bastion
    local on_bastion=true
    if [ -n "$BASTION_IP" ] && [ "$BASTION_IP" != "$(hostname -I | awk '{print $1}')" ]; then
        on_bastion=false
    fi
    
    # Try multiple times with increasing timeouts
    for attempt in {1..3}; do
        print_status "INFO" "File copy attempt $attempt to $private_ip..."
        
        local scp_cmd=""
        if [ -n "$APP_KEY_PATH" ] && [ -f "$APP_KEY_PATH" ]; then
            if [ "$on_bastion" = true ]; then
                scp_cmd="scp -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -i \"$APP_KEY_PATH\" /tmp/mysql-connection.php ec2-user@$private_ip:/tmp/"
            else
                scp_cmd="scp -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -i \"$APP_KEY_PATH\" -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@$BASTION_IP\" /tmp/mysql-connection.php ec2-user@$private_ip:/tmp/"
            fi
        else
            if [ "$on_bastion" = true ]; then
                scp_cmd="scp -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes /tmp/mysql-connection.php ec2-user@$private_ip:/tmp/"
            else
                scp_cmd="scp -o StrictHostKeyChecking=no -o ConnectTimeout=$((10 * attempt)) -o BatchMode=yes -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -W %h:%p ec2-user@$BASTION_IP\" /tmp/mysql-connection.php ec2-user@$private_ip:/tmp/"
            fi
        fi
        
        print_status "DEBUG" "SCP command: $scp_cmd"
        
        if eval $scp_cmd 2>/dev/null; then
            print_status "SUCCESS" "Files copied successfully to $private_ip on attempt $attempt"
            return 0
        fi
        
        print_status "WARNING" "File copy attempt $attempt failed"
        
        if [ $attempt -lt 3 ]; then
            local wait_time=$((10 * attempt))
            print_status "INFO" "Waiting $wait_time seconds before next attempt..."
            sleep $wait_time
        fi
    done
    
    print_status "ERROR" "Failed to copy files to instance $instance_id after multiple attempts"
    return 1
}

# Make the setup_instance script executable and source it
chmod +x /tmp/setup_instance.sh
source /tmp/setup_instance.sh

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
    
    # No need to copy dashboard HTML file as it's created directly in setup_instance.sh
    
    # Setup instance with all required parameters
    if ! setup_instance "$private_ip" "$instance_id" "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME" "$DB_PORT" "$APP_KEY_PATH" "$BASTION_IP"; then
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
        echo "- Main Dashboard: http://$ALB_DNS/"
        echo "- MySQL Test: http://$ALB_DNS/mysql-connection.php"
        echo "- Docker App: http://$ALB_DNS:8080"
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
    
    # Step 5: Setup app private key
    setup_app_key
    
    # Step 6: Get ASG instances
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
