variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where bastion will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where bastion will be deployed"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to bastion instance"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name for bastion host"
  type        = string
  default     = "anup-training-bastion-key"
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "user_data_script_path" {
  description = "Path to user data script"
  type        = string
  default     = ""
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for bastion instance"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 8
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "enable_eip" {
  description = "Enable Elastic IP for bastion instance"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for bastion instance"
  type        = bool
  default     = false
}
