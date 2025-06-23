variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myapp"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "us-east-1"
}

variable "region_short_names" {
  description = "Short names for AWS regions to use in resource naming"
  type        = map(string)
  default = {
    "us-east-1"      = "use1"
    "us-east-2"      = "use2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-central-1"   = "euc1"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-south-1"     = "aps1"
  }
}

variable "use_random_suffix" {
  description = "Add random suffix to bucket name for global uniqueness"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain point-in-time backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35."
  }
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
  
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

# Legacy variables for backward compatibility (optional)
variable "state_bucket_name" {
  description = "DEPRECATED: Use project_name, environment, and region instead"
  type        = string
  default     = null
}

variable "state_lock_table_name" {
  description = "DEPRECATED: Use project_name, environment, and region instead"
  type        = string
  default     = null
}