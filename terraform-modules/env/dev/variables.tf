variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "createdby" {
  description = "User who created the resources"
  type        = string
  default     = "anup-training"
}

variable "modifiedby" {
  description = "User who last modified the resources"
  type        = string
  default     = "anup-training"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "database_subnet_count" {
  description = "Number of database subnets to create"
  type        = number
  default     = 2
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for subnets"
  type        = number
  default     = 8
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for VPC"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "max_az_count" {
  description = "Maximum number of availability zones to use"
  type        = number
  default     = 3
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services"
  type        = bool
  default     = false
}

variable "vpc_flow_logs_retention" {
  description = "VPC Flow Logs retention period in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.vpc_flow_logs_retention)
    error_message = "VPC Flow Logs retention must be a valid CloudWatch Logs retention period."
  }
}




# Security Configuration Variables
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_bastion_http" {
  description = "Enable HTTP access on bastion host"
  type        = bool
  default     = true
}

variable "web_http_port" {
  description = "HTTP port for web tier"
  type        = number
  default     = 80
}

variable "web_https_port" {
  description = "HTTPS port for web tier"
  type        = number
  default     = 443
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "mysql_port" {
  description = "MySQL port"
  type        = number
  default     = 3306
}

variable "postgresql_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}



# Bastion Configuration Variables
variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t2.micro"
}

variable "bastion_key_name" {
  description = "SSH key pair name for bastion host"
  type        = string
  default     = "anup-training-bastion-key"
}

variable "create_bastion_key_pair" {
  description = "Whether to create a new key pair for bastion"
  type        = bool
  default     = true
}

variable "enable_bastion_eip" {
  description = "Enable Elastic IP for bastion instance"
  type        = bool
  default     = true
}

variable "bastion_enable_detailed_monitoring" {
  description = "Enable detailed monitoring for bastion instance"
  type        = bool
  default     = false
}

variable "bastion_root_volume_size" {
  description = "Size of the bastion root volume in GB"
  type        = number
  default     = 8
}

variable "bastion_root_volume_type" {
  description = "Type of the bastion root volume"
  type        = string
  default     = "gp3"
}

variable "enable_bastion_ipv6" {
  description = "Enable IPv6 support for bastion instance"
  type        = bool
  default     = false
  
}


# ALB Configuration Variables
variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_alb_access_logs" {
  description = "Enable access logs for ALB"
  type        = bool
  default     = true
}

variable "alb_target_group_port" {
  description = "Port for ALB target group"
  type        = number
  default     = 8080
}

variable "alb_target_group_protocol" {
  description = "Protocol for ALB target group"
  type        = string
  default     = "HTTP"
  
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.alb_target_group_protocol)
    error_message = "ALB target group protocol must be HTTP or HTTPS."
  }
}

variable "alb_health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
}

variable "alb_health_check_healthy_threshold" {
  description = "Number of consecutive health checks before considering target healthy"
  type        = number
  default     = 2
  
  validation {
    condition     = var.alb_health_check_healthy_threshold >= 2 && var.alb_health_check_healthy_threshold <= 10
    error_message = "Health check healthy threshold must be between 2 and 10."
  }
}

variable "alb_health_check_unhealthy_threshold" {
  description = "Number of consecutive health checks before considering target unhealthy"
  type        = number
  default     = 2
  
  validation {
    condition     = var.alb_health_check_unhealthy_threshold >= 2 && var.alb_health_check_unhealthy_threshold <= 10
    error_message = "Health check unhealthy threshold must be between 2 and 10."
  }
}

variable "alb_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
  
  validation {
    condition     = var.alb_health_check_timeout >= 2 && var.alb_health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "alb_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
  
  validation {
    condition     = var.alb_health_check_interval >= 5 && var.alb_health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "alb_listener_port" {
  description = "Port for ALB listener"
  type        = number
  default     = 80
}

variable "alb_listener_protocol" {
  description = "Protocol for ALB listener"
  type        = string
  default     = "HTTP"
  
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.alb_listener_protocol)
    error_message = "ALB listener protocol must be HTTP or HTTPS."
  }
}

variable "alb_bucket_force_destroy" {
  description = "Force destroy S3 bucket for ALB logs"
  type        = bool
  default     = true
}
