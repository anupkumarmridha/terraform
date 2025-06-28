variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# Add these missing variables at the end of the file

variable "aws_region_short" {
  description = "Short form of AWS region for naming"
  type        = string
  default     = "use1"
}

variable "multi_region_setup" {
  description = "Enable multi-region setup"
  type        = bool
  default     = false
}

variable "additional_regions" {
  description = "List of additional regions for multi-region setup"
  type        = list(string)
  default     = []
}

variable "additional_region_short_names" {
  description = "Map of region names to their short forms"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "createdby" {
  description = "User who created the resources"
  type        = string
  default     = "anup-training"
}

variable "modifiedby" {
  description = "User who last modified the resources"
  type        = string
  default     = "anup-training"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "database_subnet_count" {
  description = "Number of database subnets to create"
  type        = number
  default     = 2
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for subnets"
  type        = number
  default     = 8
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for VPC"
  type        = bool
  default     = false
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

variable "max_az_count" {
  description = "Maximum number of availability zones to use"
  type        = number
  default     = 3
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




# Security Configuration Variables
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

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



# Bastion Configuration Variables
variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t2.micro"
}

variable "bastion_key_name" {
  description = "SSH key pair name for bastion host"
  type        = string
  default     = "anup-training-bastion-key"
}

variable "create_bastion_key_pair" {
  description = "Whether to create a new key pair for bastion"
  type        = bool
  default     = true
}

variable "enable_bastion_eip" {
  description = "Enable Elastic IP for bastion instance"
  type        = bool
  default     = true
}

variable "bastion_enable_detailed_monitoring" {
  description = "Enable detailed monitoring for bastion instance"
  type        = bool
  default     = false
}

variable "bastion_root_volume_size" {
  description = "Size of the bastion root volume in GB"
  type        = number
  default     = 8
}

variable "bastion_root_volume_type" {
  description = "Type of the bastion root volume"
  type        = string
  default     = "gp3"
}

variable "enable_bastion_ipv6" {
  description = "Enable IPv6 support for bastion instance"
  type        = bool
  default     = false
  
}


# ALB Configuration Variables
variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_alb_access_logs" {
  description = "Enable access logs for ALB"
  type        = bool
  default     = true
}

variable "alb_target_group_port" {
  description = "Port for ALB target group"
  type        = number
  default     = 8080
}

variable "alb_target_group_protocol" {
  description = "Protocol for ALB target group"
  type        = string
  default     = "HTTP"
  
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.alb_target_group_protocol)
    error_message = "ALB target group protocol must be HTTP or HTTPS."
  }
}

variable "alb_health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
}

variable "alb_health_check_healthy_threshold" {
  description = "Number of consecutive health checks before considering target healthy"
  type        = number
  default     = 2
  
  validation {
    condition     = var.alb_health_check_healthy_threshold >= 2 && var.alb_health_check_healthy_threshold <= 10
    error_message = "Health check healthy threshold must be between 2 and 10."
  }
}

variable "alb_health_check_unhealthy_threshold" {
  description = "Number of consecutive health checks before considering target unhealthy"
  type        = number
  default     = 2
  
  validation {
    condition     = var.alb_health_check_unhealthy_threshold >= 2 && var.alb_health_check_unhealthy_threshold <= 10
    error_message = "Health check unhealthy threshold must be between 2 and 10."
  }
}

variable "alb_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
  
  validation {
    condition     = var.alb_health_check_timeout >= 2 && var.alb_health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "alb_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
  
  validation {
    condition     = var.alb_health_check_interval >= 5 && var.alb_health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "alb_listener_port" {
  description = "Port for ALB listener"
  type        = number
  default     = 80
}

variable "alb_listener_protocol" {
  description = "Protocol for ALB listener"
  type        = string
  default     = "HTTP"
  
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.alb_listener_protocol)
    error_message = "ALB listener protocol must be HTTP or HTTPS."
  }
}

variable "alb_bucket_force_destroy" {
  description = "Force destroy S3 bucket for ALB logs"
  type        = bool
  default     = true
}



# Launch Template Configuration Variables
variable "app_instance_type" {
  description = "Instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "app_key_name" {
  description = "SSH key pair name for application instances"
  type        = string
  default     = "anup-training-app-key"
}

variable "create_app_key_pair" {
  description = "Whether to create a new key pair for application instances"
  type        = bool
  default     = true
}

variable "app_root_volume_size" {
  description = "Size of the application instance root volume in GB"
  type        = number
  default     = 20
}

variable "app_root_volume_type" {
  description = "Type of the application instance root volume"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.app_root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

variable "app_enable_detailed_monitoring" {
  description = "Enable detailed monitoring for application instances"
  type        = bool
  default     = true
}

variable "app_user_data_script_path" {
  description = "Path to user data script file for application instances"
  type        = string
  default     = "scripts/app-userdata.sh"
}

variable "enable_app_ebs_encryption" {
  description = "Enable EBS encryption for application instances"
  type        = bool
  default     = true
}

variable "app_log_retention_days" {
  description = "Log retention period in days for application logs"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.app_log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "app_access_log_retention_days" {
  description = "Access log retention period in days for application logs"
  type        = number
  default     = 7
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.app_access_log_retention_days)
    error_message = "Access log retention must be a valid CloudWatch Logs retention period."
  }
}

# Launch Template IAM Configuration
variable "create_app_iam_role" {
  description = "Whether to create IAM role for application instances"
  type        = bool
  default     = true
}

variable "app_additional_iam_policies" {
  description = "List of additional IAM policy ARNs to attach to the application role"
  type        = list(string)
  default     = []
}

# Launch Template CloudWatch Configuration
variable "create_app_cloudwatch_logs" {
  description = "Whether to create CloudWatch log groups for application instances"
  type        = bool
  default     = true
}

# ASG Configuration Variables
variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
  
  validation {
    condition     = var.asg_min_size >= 0
    error_message = "ASG minimum size must be 0 or greater."
  }
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 5
  
  validation {
    condition     = var.asg_max_size >= 1
    error_message = "ASG maximum size must be 1 or greater."
  }
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
  
  validation {
    condition     = var.asg_desired_capacity >= 0
    error_message = "ASG desired capacity must be 0 or greater."
  }
}

variable "asg_health_check_grace_period" {
  description = "Health check grace period in seconds for ASG"
  type        = number
  default     = 300
  
  validation {
    condition     = var.asg_health_check_grace_period >= 0
    error_message = "Health check grace period must be 0 or greater."
  }
}

variable "asg_health_check_type" {
  description = "Health check type for ASG"
  type        = string
  default     = "ELB"
  
  validation {
    condition     = contains(["EC2", "ELB"], var.asg_health_check_type)
    error_message = "Health check type must be either EC2 or ELB."
  }
}

variable "asg_default_cooldown" {
  description = "Default cooldown period in seconds for ASG"
  type        = number
  default     = 300
  
  validation {
    condition     = var.asg_default_cooldown >= 0
    error_message = "Default cooldown must be 0 or greater."
  }
}

variable "asg_termination_policies" {
  description = "List of termination policies for ASG"
  type        = list(string)
  default     = ["OldestInstance"]
  
  validation {
    condition = alltrue([
      for policy in var.asg_termination_policies : contains([
        "OldestInstance", "NewestInstance", "OldestLaunchConfiguration", 
        "ClosestToNextInstanceHour", "OldestLaunchTemplate", "AllocationStrategy"
      ], policy)
    ])
    error_message = "Invalid termination policy specified."
  }
}

variable "asg_protect_from_scale_in" {
  description = "Enable instance protection from scale in for ASG"
  type        = bool
  default     = false
}

# ASG Instance Refresh Configuration
variable "enable_asg_instance_refresh" {
  description = "Enable instance refresh configuration for ASG"
  type        = bool
  default     = true
}

variable "asg_instance_refresh_strategy" {
  description = "Strategy for instance refresh"
  type        = string
  default     = "Rolling"
  
  validation {
    condition     = contains(["Rolling"], var.asg_instance_refresh_strategy)
    error_message = "Instance refresh strategy must be Rolling."
  }
}

variable "asg_instance_refresh_min_healthy_percentage" {
  description = "Minimum healthy percentage during instance refresh"
  type        = number
  default     = 50
  
  validation {
    condition     = var.asg_instance_refresh_min_healthy_percentage >= 0 && var.asg_instance_refresh_min_healthy_percentage <= 100
    error_message = "Minimum healthy percentage must be between 0 and 100."
  }
}

variable "asg_instance_refresh_instance_warmup" {
  description = "Instance warmup time during refresh in seconds"
  type        = number
  default     = 300
  
  validation {
    condition     = var.asg_instance_refresh_instance_warmup >= 0
    error_message = "Instance warmup must be 0 or greater."
  }
}

# ASG Auto Scaling Policy Configuration
variable "enable_asg_scaling_policies" {
  description = "Enable auto scaling policies and CloudWatch alarms for ASG"
  type        = bool
  default     = true
}

# Advanced Scaling Policies Configuration
variable "scaling_policies" {
  description = "List of auto scaling policies to create"
  type = list(object({
    name               = string
    policy_type        = string        # SimpleScaling, StepScaling, TargetTrackingScaling
    adjustment_type    = string        # ChangeInCapacity, ExactCapacity, PercentChangeInCapacity
    scaling_adjustment = optional(number)        # Used for SimpleScaling
    cooldown           = optional(number)
    
    # For step scaling
    step_adjustments = optional(list(object({
      metric_interval_lower_bound = optional(number)
      metric_interval_upper_bound = optional(number)
      scaling_adjustment          = number
    })), [])
    
    # For target tracking
    target_tracking_configuration = optional(object({
      target_value               = number
      disable_scale_in           = optional(bool, false)
      predefined_metric_type     = optional(string) # ASGAverageCPUUtilization, ASGAverageNetworkIn, etc.
      customized_metric_specification = optional(object({
        metric_name      = string
        namespace        = string
        statistic        = string
        unit             = optional(string)
        metric_dimension = optional(map(string))
      }))
    }))
    
    # CloudWatch alarm (for SimpleScaling and StepScaling)
    alarm = optional(object({
      name                = string
      comparison_operator = string
      evaluation_periods  = number
      metric_name         = string
      namespace           = string
      period              = number
      statistic           = string
      threshold           = number
      description         = optional(string)
    }))
  }))
  default = []
}

# For backward compatibility - these will be deprecated
variable "asg_scale_up_adjustment" {
  description = "Number of instances to add when scaling up"
  type        = number
  default     = 1
  
  validation {
    condition     = var.asg_scale_up_adjustment > 0
    error_message = "Scale up adjustment must be greater than 0."
  }
}

variable "asg_scale_down_adjustment" {
  description = "Number of instances to remove when scaling down"
  type        = number
  default     = -1
  
  validation {
    condition     = var.asg_scale_down_adjustment < 0
    error_message = "Scale down adjustment must be negative."
  }
}

variable "asg_scale_up_cooldown" {
  description = "Cooldown period for scale up in seconds"
  type        = number
  default     = 300
  
  validation {
    condition     = var.asg_scale_up_cooldown >= 0
    error_message = "Scale up cooldown must be 0 or greater."
  }
}

variable "asg_scale_down_cooldown" {
  description = "Cooldown period for scale down in seconds"
  type        = number
  default     = 300
  
  validation {
    condition     = var.asg_scale_down_cooldown >= 0
    error_message = "Scale down cooldown must be 0 or greater."
  }
}

# Jenkins Configuration Variables
variable "jenkins_instance_type" {
  description = "Instance type for Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "jenkins_key_name" {
  description = "SSH key pair name for Jenkins server"
  type        = string
  default     = "anup-training-jenkins-key"
}

variable "create_jenkins_key_pair" {
  description = "Whether to create a new key pair for Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_root_volume_size" {
  description = "Size of the Jenkins root volume in GB"
  type        = number
  default     = 30
}

variable "jenkins_root_volume_type" {
  description = "Type of the Jenkins root volume"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.jenkins_root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

variable "jenkins_enable_detailed_monitoring" {
  description = "Enable detailed monitoring for Jenkins instance"
  type        = bool
  default     = false
}

variable "enable_mysql_connection_provisioner" {
  description = "Enable MySQL connection provisioner"
  type        = bool
  default     = true
}

# ASG CloudWatch Alarm Configuration
variable "asg_cpu_high_threshold" {
  description = "CPU threshold for scaling up"
  type        = number
  default     = 75
  
  validation {
    condition     = var.asg_cpu_high_threshold >= 0 && var.asg_cpu_high_threshold <= 100
    error_message = "CPU high threshold must be between 0 and 100."
  }
}

variable "asg_cpu_low_threshold" {
  description = "CPU threshold for scaling down"
  type        = number
  default     = 25
  
  validation {
    condition     = var.asg_cpu_low_threshold >= 0 && var.asg_cpu_low_threshold <= 100
    error_message = "CPU low threshold must be between 0 and 100."
  }
}

variable "asg_alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms"
  type        = number
  default     = 2
  
  validation {
    condition     = var.asg_alarm_evaluation_periods >= 1
    error_message = "Alarm evaluation periods must be 1 or greater."
  }
}

variable "asg_alarm_period" {
  description = "Period for CloudWatch alarms in seconds"
  type        = number
  default     = 300
  
  validation {
    condition     = contains([60, 300, 900, 3600], var.asg_alarm_period)
    error_message = "Alarm period must be 60, 300, 900, or 3600 seconds."
  }
}

# ASG Additional Configuration
variable "asg_suspended_processes" {
  description = "List of suspended scaling processes for ASG"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for process in var.asg_suspended_processes : contains([
        "Launch", "Terminate", "HealthCheck", "ReplaceUnhealthy", "AZRebalance",
        "AlarmNotification", "ScheduledActions", "AddToLoadBalancer", "InstanceRefresh"
      ], process)
    ])
    error_message = "Invalid suspended process specified."
  }
}

variable "asg_enabled_metrics" {
  description = "List of enabled CloudWatch metrics for ASG"
  type        = list(string)
  default     = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  
  validation {
    condition = alltrue([
      for metric in var.asg_enabled_metrics : contains([
        "GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances",
        "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", 
        "GroupTotalInstances"
      ], metric)
    ])
    error_message = "Invalid CloudWatch metric specified."
  }
}

variable "asg_placement_group" {
  description = "Placement group for the Auto Scaling Group"
  type        = string
  default     = ""
}

variable "asg_service_linked_role_arn" {
  description = "ARN of the service-linked role for Auto Scaling"
  type        = string
  default     = ""
}

# RDS Variables
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

variable "db_engine" {
  description = "Database engine type"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0.35"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "db_parameter_group_family" {
  description = "Database parameter group family"
  type        = string
  default     = "mysql8.0"
}

variable "db_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_monitoring_interval" {
  description = "Monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "db_enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}

variable "db_cloudwatch_logs_retention_in_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 7
}


# MySQL Connection Provisioner Configuration
# variable "enable_mysql_connection_provisioner" {
#   description = "Enable MySQL connection provisioner"
#   type        = bool
#   default     = true
# }
