variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where RDS will be deployed"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the database subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS auto-scaling (GB)"
  type        = number
  default     = 100
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "db_storage_type" {
  description = "Storage type for RDS"
  type        = string
  default     = "gp3"
}

variable "db_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = true
}

variable "db_final_snapshot" {
  description = "Create final snapshot before deletion"
  type        = bool
  default     = true
}

variable "create_read_replica" {
  description = "Create a read replica for the database"
  type        = bool
  default     = false
}

variable "db_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1
}

variable "db_replica_instance_class" {
  description = "Instance class for read replica"
  type        = string
  default     = "db.t3.micro"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "engine" {
  description = "Database engine type"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0.40"
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "parameter_group_family" {
  description = "Database parameter group family"
  type        = string
  default     = "mysql8.0"
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "monitoring_interval" {
  description = "Monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}

variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 7
}
