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

variable "private_subnet_id" {
  description = "ID of the private subnet for Jenkins server"
  type        = string
}

variable "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  type        = string
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name for Jenkins server"
  type        = string
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for Jenkins instance"
  type        = bool
  default     = false
}

variable "user_data_script_path" {
  description = "Path to user data script for Jenkins setup"
  type        = string
  default     = ""
}

variable "jenkins_port" {
  description = "Port for Jenkins server"
  type        = number
  default     = 8080
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
