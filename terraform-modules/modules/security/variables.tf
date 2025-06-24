variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Optional variables for customization
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