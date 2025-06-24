# Security Group IDs
output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_default_security_group.default.id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the app security group"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

# Security Group ARNs
output "web_security_group_arn" {
  description = "ARN of the web security group"
  value       = aws_security_group.web.arn
}

output "app_security_group_arn" {
  description = "ARN of the app security group"
  value       = aws_security_group.app.arn
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = aws_security_group.database.arn
}

output "bastion_security_group_arn" {
  description = "ARN of the bastion security group"
  value       = aws_security_group.bastion.arn
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

# Convenience outputs for common use cases
output "all_security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    default  = aws_default_security_group.default.id
    web      = aws_security_group.web.id
    app      = aws_security_group.app.id
    database = aws_security_group.database.id
    bastion  = aws_security_group.bastion.id
    alb      = aws_security_group.alb.id
  }
}