output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.app_alb.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app_alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.app_alb.zone_id
}

output "target_group_id" {
  description = "ID of the target group"
  value       = aws_lb_target_group.app_tg.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.app_listener.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  value       = var.enable_access_logs ? aws_s3_bucket.alb_logs[0].bucket : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for ALB logs"
  value       = var.enable_access_logs ? aws_s3_bucket.alb_logs[0].arn : null
}