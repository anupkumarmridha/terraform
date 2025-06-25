variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for instances"
  type        = list(string)
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Instance Configuration
variable "instance_type" {
  description = "Instance type for instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for instances"
  type        = string
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = false
}

variable "ami_id" {
  description = "AMI ID for instances (optional, will use latest AL2023 if not provided)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for instances"
  type        = bool
  default     = true
}

variable "user_data_script_path" {
  description = "Path to user data script file"
  type        = string
  default     = ""
}

variable "user_data_base64" {
  description = "Base64 encoded user data script (alternative to file path)"
  type        = string
  default     = ""
}

# IAM Configuration
variable "create_iam_role" {
  description = "Whether to create IAM role for instances"
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "ARN of existing IAM role (used when create_iam_role is false)"
  type        = string
  default     = ""
}

variable "iam_instance_profile_name" {
  description = "Name of existing instance profile (used when create_iam_role is false)"
  type        = string
  default     = ""
}

variable "additional_iam_policies" {
  description = "List of additional IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

# CloudWatch Logs Configuration
variable "create_cloudwatch_logs" {
  description = "Whether to create CloudWatch log groups"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

variable "access_log_retention_days" {
  description = "Access log retention period in days"
  type        = number
  default     = 7
}

# Additional Configuration
variable "template_name_prefix" {
  description = "Name prefix for the launch template"
  type        = string
  default     = ""
}

variable "enable_ebs_encryption" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}

variable "enable_nitro_enclave" {
  description = "Enable Nitro Enclave support"
  type        = bool
  default     = false
}

variable "placement_group" {
  description = "Placement group for instances"
  type        = string
  default     = ""
}

variable "placement_tenancy" {
  description = "Tenancy of instances"
  type        = string
  default     = "default"
  
  validation {
    condition     = contains(["default", "dedicated", "host"], var.placement_tenancy)
    error_message = "Placement tenancy must be default, dedicated, or host."
  }
}
