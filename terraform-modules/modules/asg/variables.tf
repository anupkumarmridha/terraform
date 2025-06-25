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

variable "subnet_ids" {
  description = "List of subnet IDs for ASG (typically private subnets)"
  type        = list(string)
}

variable "target_group_arns" {
  description = "List of ALB/NLB target group ARNs to attach to ASG"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Launch Template Configuration
variable "launch_template_id" {
  description = "ID of the launch template to use"
  type        = string
}

variable "launch_template_version" {
  description = "Version of the launch template to use"
  type        = string
  default     = "$Latest"
}

# ASG Configuration
variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "Health check type for ASG"
  type        = string
  default     = "ELB"
  
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be either EC2 or ELB."
  }
}

variable "default_cooldown" {
  description = "Default cooldown period in seconds"
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "List of termination policies"
  type        = list(string)
  default     = ["OldestInstance"]
}

variable "protect_from_scale_in" {
  description = "Enable instance protection from scale in"
  type        = bool
  default     = false
}

# Instance Refresh Configuration
variable "enable_instance_refresh" {
  description = "Enable instance refresh configuration"
  type        = bool
  default     = true
}

variable "instance_refresh_strategy" {
  description = "Strategy for instance refresh"
  type        = string
  default     = "Rolling"
  
  validation {
    condition     = contains(["Rolling"], var.instance_refresh_strategy)
    error_message = "Instance refresh strategy must be Rolling."
  }
}

variable "instance_refresh_min_healthy_percentage" {
  description = "Minimum healthy percentage during instance refresh"
  type        = number
  default     = 50
}

variable "instance_refresh_instance_warmup" {
  description = "Instance warmup time during refresh in seconds"
  type        = number
  default     = 300
}

# Auto Scaling Policy Configuration
variable "enable_scaling_policies" {
  description = "Enable auto scaling policies and CloudWatch alarms"
  type        = bool
  default     = true
}

variable "scale_up_adjustment" {
  description = "Number of instances to add when scaling up"
  type        = number
  default     = 1
}

variable "scale_down_adjustment" {
  description = "Number of instances to remove when scaling down"
  type        = number
  default     = -1
}

variable "scale_up_cooldown" {
  description = "Cooldown period for scale up in seconds"
  type        = number
  default     = 300
}

variable "scale_down_cooldown" {
  description = "Cooldown period for scale down in seconds"
  type        = number
  default     = 300
}

# CloudWatch Alarm Configuration
variable "cpu_high_threshold" {
  description = "CPU threshold for scaling up"
  type        = number
  default     = 75
}

variable "cpu_low_threshold" {
  description = "CPU threshold for scaling down"
  type        = number
  default     = 25
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "Period for CloudWatch alarms in seconds"
  type        = number
  default     = 300
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

# Additional Configuration
variable "suspended_processes" {
  description = "List of suspended scaling processes"
  type        = list(string)
  default     = []
}

variable "enabled_metrics" {
  description = "List of enabled CloudWatch metrics"
  type        = list(string)
  default     = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
}

variable "placement_group" {
  description = "Placement group for the Auto Scaling Group"
  type        = string
  default     = ""
}

variable "service_linked_role_arn" {
  description = "ARN of the service-linked role for Auto Scaling"
  type        = string
  default     = ""
}
