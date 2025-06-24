variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "max_az_count" {
  description = "Maximum number of availability zones to use"
  type        = number
  default     = 3
  
  validation {
    condition     = var.max_az_count >= 2 && var.max_az_count <= 6
    error_message = "Maximum AZ count must be between 2 and 6."
  }
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 16
    error_message = "Public subnet count must be between 1 and 16."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.private_subnet_count >= 1 && var.private_subnet_count <= 16
    error_message = "Private subnet count must be between 1 and 16."
  }
}

variable "database_subnet_count" {
  description = "Number of database subnets to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.database_subnet_count >= 2 && var.database_subnet_count <= 16
    error_message = "Database subnet count must be between 2 and 16 for RDS requirements."
  }
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for subnets"
  type        = number
  default     = 8
  
  validation {
    condition     = var.subnet_newbits >= 4 && var.subnet_newbits <= 16
    error_message = "Subnet newbits must be between 4 and 16."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for VPC"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
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

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
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