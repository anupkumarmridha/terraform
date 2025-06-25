# VPC Outputs - Pass through from module
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

# Debug output for development
output "vpc_cidr_calculations" {
  description = "CIDR calculation details for debugging"
  value       = module.vpc.cidr_calculations
}


# Security Outputs - Pass through from security module
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.security.web_security_group_id
}

output "app_security_group_id" {
  description = "ID of the app security group"
  value       = module.security.app_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.security.database_security_group_id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.security.bastion_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

output "all_security_group_ids" {
  description = "Map of all security group IDs"
  value       = module.security.all_security_group_ids
}


# Bastion Outputs
output "bastion_instance_id" {
  description = "ID of the bastion instance"
  value       = module.bastion.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion instance"
  value       = module.bastion.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion instance"
  value       = module.bastion.bastion_private_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = module.bastion.ssh_connection_command
  sensitive   = true
}

output "bastion_key_pair_name" {
  description = "Name of the key pair used by bastion"
  value       = module.bastion.key_pair_name
}

output "bastion_private_key_path" {
  description = "Path to the private key file for bastion"
  value       = module.bastion.private_key_path
  sensitive   = true
}


# ALB outputs 
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_group_arn
}



# Launch Template Outputs
output "app_launch_template_id" {
  description = "ID of the application launch template"
  value       = module.app_launch_template.launch_template_id
}

output "app_launch_template_arn" {
  description = "ARN of the application launch template"
  value       = module.app_launch_template.launch_template_arn
}

output "app_launch_template_latest_version" {
  description = "Latest version of the application launch template"
  value       = module.app_launch_template.launch_template_latest_version
}

output "app_iam_role_arn" {
  description = "ARN of the application IAM role"
  value       = module.app_launch_template.iam_role_arn
}

output "app_log_group_name" {
  description = "Name of the application log group"
  value       = module.app_launch_template.app_log_group_name
}

# ASG Outputs
output "app_autoscaling_group_id" {
  description = "ID of the application Auto Scaling Group"
  value       = module.app_asg.autoscaling_group_id
}

output "app_autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group"
  value       = module.app_asg.autoscaling_group_name
}

output "app_autoscaling_group_arn" {
  description = "ARN of the application Auto Scaling Group"
  value       = module.app_asg.autoscaling_group_arn
}

output "app_scaling_policy_arns" {
  description = "Map of scaling policy names to their ARNs"
  value       = module.app_asg.scaling_policy_arns
}

output "app_cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm names to their ARNs"
  value       = module.app_asg.cloudwatch_alarm_arns
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.rds_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.rds_database_name
}

output "rds_username" {
  description = "RDS master username"
  value       = module.rds.rds_username
  sensitive   = true
}

output "db_credentials_secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = module.rds.db_credentials_secret_arn
}

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.rds_instance_id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.rds.rds_instance_arn
}

output "rds_replica_endpoints" {
  description = "List of RDS read replica endpoints"
  value       = module.rds.rds_replica_endpoints
  sensitive   = true
}


# MySQL Provisioner Outputs
# output "mysql_connection_deployment_status" {
#   description = "Status of MySQL connection deployment"
#   value       = var.enable_mysql_connection_provisioner ? module.mysql_provisioner[0].deployment_status : "Provisioner disabled"
# }

# output "mysql_connection_test_url" {
#   description = "URL to test MySQL connection"
#   value       = "http://${module.alb.alb_dns_name}/mysql-connection.php"
# }

# output "apache_server_dashboard_url" {
#   description = "URL to access server dashboard"
#   value       = "http://${module.alb.alb_dns_name}/"
# }
