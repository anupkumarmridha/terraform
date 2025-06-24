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

