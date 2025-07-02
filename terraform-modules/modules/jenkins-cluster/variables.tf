variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Jenkins will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Jenkins master and agents"
  type        = list(string)
}

variable "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  type        = string
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

# Jenkins Master Configuration
variable "master_instance_type" {
  description = "EC2 instance type for Jenkins master"
  type        = string
  default     = "t3.medium"
}

variable "master_key_name" {
  description = "SSH key pair name for Jenkins master"
  type        = string
}

variable "create_master_key_pair" {
  description = "Whether to create a new key pair for master"
  type        = bool
  default     = true
}

variable "master_root_volume_size" {
  description = "Size of the master root volume in GB"
  type        = number
  default     = 50
}

variable "master_root_volume_type" {
  description = "Type of the master root volume"
  type        = string
  default     = "gp3"
}

variable "jenkins_home" {
  description = "Jenkins home directory path"
  type        = string
  default     = "/var/lib/jenkins"
}

# Jenkins Agent Configuration
variable "enable_agents" {
  description = "Enable Jenkins agents"
  type        = bool
  default     = true
}

variable "agent_count" {
  description = "Number of Jenkins agents to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.agent_count >= 0 && var.agent_count <= 10
    error_message = "Agent count must be between 0 and 10."
  }
}

variable "agent_instance_type" {
  description = "EC2 instance type for Jenkins agents"
  type        = string
  default     = "t3.large"
}

variable "agent_key_name" {
  description = "SSH key pair name for Jenkins agents"
  type        = string
}

variable "create_agent_key_pair" {
  description = "Whether to create a new key pair for agents"
  type        = bool
  default     = true
}

variable "agent_root_volume_size" {
  description = "Size of the agent root volume in GB"
  type        = number
  default     = 30
}

variable "agent_root_volume_type" {
  description = "Type of the agent root volume"
  type        = string
  default     = "gp3"
}

# Network Configuration
variable "jenkins_port" {
  description = "Port for Jenkins server"
  type        = number
  default     = 8080
}

variable "jenkins_agent_port" {
  description = "Port for Jenkins agent communication"
  type        = number
  default     = 50000
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

# Monitoring and Logging
variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for Jenkins instances"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for Jenkins"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 30
}

# High Availability
variable "enable_master_backup" {
  description = "Enable automatic backup for Jenkins master"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}