locals {
  # Naming convention: project-environment-resource
  name_prefix = "${var.project_name}-${var.environment}"

  # Database-specific tags
  database_tags = merge(var.common_tags, {
    Component    = "Database"
    ResourceType = "RDS"
  })

  database_replica_tags = merge(var.common_tags, {
    Component    = "DatabaseReplica"
    ResourceType = "RDS"
  })
}

# Use existing DB Subnet Group instead of creating a new one
data "aws_db_subnet_group" "existing" {
  name = "${local.name_prefix}-db-subnet-group"
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = var.parameter_group_family
  name   = "${local.name_prefix}-${var.engine}-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${var.engine}-params"
  })
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.name_prefix}-db-credentials"
  description             = "RDS ${var.engine} credentials"
  recovery_window_in_days = 7
  
  # Force overwrite if the secret is scheduled for deletion
  force_overwrite_replica_secret = true

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-db-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = var.engine
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-rds-kms"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# CloudWatch Log Groups for RDS
resource "aws_cloudwatch_log_group" "rds_logs" {
  for_each = toset(var.enabled_cloudwatch_logs_exports)

  name              = "/aws/rds/instance/${local.name_prefix}-${var.engine}/${each.value}"
  retention_in_days = var.cloudwatch_logs_retention_in_days

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-rds-${each.value}-logs"
  })
}

# IAM role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-rds-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-${var.engine}"

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.db_instance_class

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = var.port

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  # Network configuration
  db_subnet_group_name   = data.aws_db_subnet_group.existing.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup configuration
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Monitoring
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Performance Insights - only enable for supported instance classes
  performance_insights_enabled = var.performance_insights_enabled && !contains(["db.t3.micro", "db.t2.micro"], var.db_instance_class)
  performance_insights_retention_period = var.performance_insights_enabled && !contains(["db.t3.micro", "db.t2.micro"], var.db_instance_class) ? var.performance_insights_retention_period : null

  # Security
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = !var.db_final_snapshot
  final_snapshot_identifier = var.db_final_snapshot ? "${local.name_prefix}-${var.engine}-final-snapshot-${replace(timestamp(), ":", "-")}" : null

  # Multi-AZ for production
  multi_az = var.multi_az

  tags = local.database_tags

  depends_on = [
    aws_cloudwatch_log_group.rds_logs
  ]
}

# Read replica (optional, for production)
resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? var.db_replica_count : 0

  identifier = "${local.name_prefix}-${var.engine}-replica-${count.index + 1}"

  # Replica configuration
  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.db_replica_instance_class

  # Network configuration
  publicly_accessible    = false
  vpc_security_group_ids = [var.security_group_id]

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights - only enable for supported instance classes
  performance_insights_enabled = var.performance_insights_enabled && !contains(["db.t3.micro", "db.t2.micro"], var.db_replica_instance_class)
  performance_insights_retention_period = var.performance_insights_enabled && !contains(["db.t3.micro", "db.t2.micro"], var.db_replica_instance_class) ? var.performance_insights_retention_period : null

  # Security
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = !var.db_final_snapshot
  final_snapshot_identifier = var.db_final_snapshot ? "${local.name_prefix}-${var.engine}-replica-${count.index + 1}-final-snapshot-${replace(timestamp(), ":", "-")}" : null

  tags = local.database_replica_tags
}
