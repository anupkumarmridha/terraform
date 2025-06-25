 # Launch Template Outputs
output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.main.id
}

output "launch_template_arn" {
  description = "ARN of the Launch Template"
  value       = aws_launch_template.main.arn
}

output "launch_template_name" {
  description = "Name of the Launch Template"
  value       = aws_launch_template.main.name
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.main.latest_version
}

# IAM Outputs
output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = var.create_iam_role ? aws_iam_role.instance_role[0].arn : var.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = var.create_iam_role ? aws_iam_role.instance_role[0].name : ""
}

output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = var.create_iam_role ? aws_iam_instance_profile.instance_profile[0].arn : ""
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = var.create_iam_role ? aws_iam_instance_profile.instance_profile[0].name : var.iam_instance_profile_name
}

# CloudWatch Outputs
output "app_log_group_name" {
  description = "Name of the application log group"
  value       = var.create_cloudwatch_logs ? aws_cloudwatch_log_group.app_logs[0].name : ""
}

output "app_log_group_arn" {
  description = "ARN of the application log group"
  value       = var.create_cloudwatch_logs ? aws_cloudwatch_log_group.app_logs[0].arn : ""
}

output "access_log_group_name" {
  description = "Name of the access log group"
  value       = var.create_cloudwatch_logs ? aws_cloudwatch_log_group.app_access_logs[0].name : ""
}

output "access_log_group_arn" {
  description = "ARN of the access log group"
  value       = var.create_cloudwatch_logs ? aws_cloudwatch_log_group.app_access_logs[0].arn : ""
}

# Instance Configuration Outputs
output "instance_type" {
  description = "Instance type configured in the launch template"
  value       = var.instance_type
}

output "ami_id" {
  description = "AMI ID used in the launch template"
  value       = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023[0].id
}

output "key_name" {
  description = "SSH key pair name configured in the launch template"
  value       = var.key_name
}