# RDS outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_credentials_secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = data.aws_db_subnet_group.existing.id
}

output "db_parameter_group_id" {
  description = "ID of the database parameter group"
  value       = aws_db_parameter_group.main.id
}

output "kms_key_id" {
  description = "ID of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "monitoring_role_arn" {
  description = "ARN of the IAM role used for RDS enhanced monitoring"
  value       = aws_iam_role.rds_monitoring.arn
}

output "rds_replica_endpoints" {
  description = "List of RDS read replica endpoints"
  value       = var.create_read_replica ? aws_db_instance.replica[*].endpoint : []
  sensitive   = true
}

output "rds_replica_ids" {
  description = "List of RDS read replica IDs"
  value       = var.create_read_replica ? aws_db_instance.replica[*].id : []
}
