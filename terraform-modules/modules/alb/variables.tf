variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable access logs for ALB"
  type        = bool
  default     = true
}

variable "target_group_port" {
  description = "Port for target group"
  type        = number
  default     = 8080
}

variable "target_group_protocol" {
  description = "Protocol for target group"
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks before considering target healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health checks before considering target unhealthy"
  type        = number
  default     = 2
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "listener_port" {
  description = "Port for ALB listener"
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "Protocol for ALB listener"
  type        = string
  default     = "HTTP"
}

variable "bucket_force_destroy" {
  description = "Force destroy S3 bucket for ALB logs"
  type        = bool
  default     = true
}