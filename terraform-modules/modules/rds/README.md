# RDS Module

This module creates an Amazon RDS database instance with optional read replicas, parameter groups, and enhanced monitoring.

## Features

- Creates an RDS instance with configurable settings
- Supports MySQL, PostgreSQL, and other RDS engines
- Optional read replicas for high availability
- Enhanced monitoring with CloudWatch integration
- Secure password management with AWS Secrets Manager
- KMS encryption for data at rest
- Parameter group customization
- Multi-AZ deployment option for high availability

## Usage

```hcl
module "rds" {
  source = "../../modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  security_group_id  = module.security.database_security_group_id

  # Database configuration
  db_name                = "appdb"
  db_username            = "admin"
  db_instance_class      = "db.t3.micro"
  db_allocated_storage   = 20
  db_max_allocated_storage = 100
  db_backup_retention_period = 7
  multi_az              = true
  db_storage_type       = "gp3"
  db_deletion_protection = false
  db_final_snapshot     = true
  
  # Read replica configuration
  create_read_replica   = true
  db_replica_count      = 1
  db_replica_instance_class = "db.t3.micro"
  
  # Engine configuration
  engine               = "mysql"
  engine_version       = "8.0.35"
  port                 = 3306
  parameter_group_family = "mysql8.0"
  
  # Monitoring configuration
  monitoring_interval  = 60
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  cloudwatch_logs_retention_in_days = 7
  
  common_tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project for resource naming | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC where RDS will be deployed | `string` | n/a | yes |
| database_subnet_ids | List of subnet IDs for the database subnet group | `list(string)` | n/a | yes |
| security_group_id | ID of the security group for the RDS instance | `string` | n/a | yes |
| db_name | Name of the database | `string` | `"appdb"` | no |
| db_username | Username for the database | `string` | `"admin"` | no |
| db_instance_class | RDS instance class | `string` | `"db.t3.micro"` | no |
| db_allocated_storage | Initial allocated storage for RDS (GB) | `number` | `20` | no |
| db_max_allocated_storage | Maximum allocated storage for RDS auto-scaling (GB) | `number` | `100` | no |
| db_backup_retention_period | Backup retention period in days | `number` | `7` | no |
| multi_az | Enable Multi-AZ for RDS | `bool` | `false` | no |
| db_storage_type | Storage type for RDS | `string` | `"gp3"` | no |
| db_deletion_protection | Enable deletion protection for RDS | `bool` | `true` | no |
| db_final_snapshot | Create final snapshot before deletion | `bool` | `true` | no |
| create_read_replica | Create a read replica for the database | `bool` | `false` | no |
| db_replica_count | Number of read replicas to create | `number` | `1` | no |
| db_replica_instance_class | Instance class for read replica | `string` | `"db.t3.micro"` | no |
| engine | Database engine type | `string` | `"mysql"` | no |
| engine_version | Database engine version | `string` | `"8.0.35"` | no |
| port | Database port | `number` | `3306` | no |
| parameter_group_family | Database parameter group family | `string` | `"mysql8.0"` | no |
| backup_window | Preferred backup window | `string` | `"03:00-04:00"` | no |
| maintenance_window | Preferred maintenance window | `string` | `"sun:04:00-sun:05:00"` | no |
| monitoring_interval | Monitoring interval in seconds (0 to disable) | `number` | `60` | no |
| performance_insights_enabled | Enable Performance Insights | `bool` | `true` | no |
| performance_insights_retention_period | Performance Insights retention period in days | `number` | `7` | no |
| enabled_cloudwatch_logs_exports | List of log types to enable for exporting to CloudWatch logs | `list(string)` | `["error", "general", "slowquery"]` | no |
| cloudwatch_logs_retention_in_days | CloudWatch logs retention period in days | `number` | `7` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| rds_endpoint | RDS instance endpoint |
| rds_port | RDS instance port |
| rds_database_name | RDS database name |
| rds_username | RDS master username |
| db_credentials_secret_arn | ARN of the secret containing database credentials |
| rds_instance_id | ID of the RDS instance |
| rds_instance_arn | ARN of the RDS instance |
| db_subnet_group_id | ID of the database subnet group |
| db_parameter_group_id | ID of the database parameter group |
| kms_key_id | ID of the KMS key used for RDS encryption |
| kms_key_arn | ARN of the KMS key used for RDS encryption |
| monitoring_role_arn | ARN of the IAM role used for RDS enhanced monitoring |
| rds_replica_endpoints | List of RDS read replica endpoints |
| rds_replica_ids | List of RDS read replica IDs |
