variable "enable_provisioner" {
  description = "Enable remote provisioner for MySQL connection deployment"
  type        = bool
  default     = true
}

variable "enable_local_provisioner" {
  description = "Enable local provisioner as alternative deployment method"
  type        = bool
  default     = false
}

variable "db_credentials_secret_arn" {
  description = "ARN of the secret containing database credentials"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

variable "rds_port" {
  description = "RDS instance port"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "bastion_public_ip" {
  description = "Public IP of bastion host"
  type        = string
}

variable "bastion_private_key_path" {
  description = "Path to bastion private key"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "launch_template_latest_version" {
  description = "Latest version of launch template"
  type        = string
}

variable "asg_dependency" {
  description = "ASG dependency to ensure proper ordering"
  type        = any
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}