# ASG Outputs
output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_availability_zones" {
  description = "Availability zones of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.availability_zones
}

output "autoscaling_group_vpc_zone_identifier" {
  description = "VPC zone identifier of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.vpc_zone_identifier
}

# Auto Scaling Policy Outputs
output "scaling_policy_arns" {
  description = "Map of scaling policy names to their ARNs"
  value = { for idx, policy in aws_autoscaling_policy.policies : policy.name => policy.arn }
}

output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm names to their ARNs"
  value = { for idx, alarm in aws_cloudwatch_metric_alarm.alarms : alarm.alarm_name => alarm.arn }
}

# Individual policy ARNs can be accessed via the scaling_policy_arns map output

# Configuration Outputs
output "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.min_size
}

output "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.max_size
}

output "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.desired_capacity
}
