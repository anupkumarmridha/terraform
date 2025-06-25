terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}



# s3 backend configuration
terraform {
  backend "s3" {
    bucket         = "anup-training-dev-use1-tfstate-d5fd04a0"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "anup-training-dev-use1-tfstate-lock"
    kms_key_id     = "alias/anup-training-dev-use1-tfstate"
    use_lockfile   = true
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr                = var.vpc_cidr
  public_subnet_count     = var.public_subnet_count
  private_subnet_count    = var.private_subnet_count
  database_subnet_count   = var.database_subnet_count
  subnet_newbits          = var.subnet_newbits
  max_az_count            = var.max_az_count
  enable_ipv6             = var.enable_ipv6
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  enable_vpc_endpoints    = var.enable_vpc_endpoints
  vpc_flow_logs_retention = var.vpc_flow_logs_retention

  common_tags = local.common_tags
}


# Security Module
module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  vpc_cidr_block    = module.vpc.vpc_cidr_block
  allowed_ssh_cidrs = var.allowed_ssh_cidrs

  # Optional security configurations
  enable_bastion_http = var.enable_bastion_http
  web_http_port       = var.web_http_port
  web_https_port      = var.web_https_port
  app_port            = var.app_port
  mysql_port          = var.mysql_port
  postgresql_port     = var.postgresql_port
  ssh_port            = var.ssh_port

  common_tags = local.common_tags
  depends_on = [module.vpc]
}

# Bastion Host Module
module "bastion" {
  source = "../../modules/bastion"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_id   = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security.bastion_security_group_id]
  
  instance_type              = var.bastion_instance_type
  key_name                  = var.bastion_key_name
  create_key_pair           = var.create_bastion_key_pair
  enable_eip                = var.enable_bastion_eip
  enable_detailed_monitoring = var.bastion_enable_detailed_monitoring
  root_volume_size          = var.bastion_root_volume_size
  root_volume_type          = var.bastion_root_volume_type
  enable_ipv6               = var.enable_bastion_ipv6
  
  user_data_script_path = "${path.module}/../../scripts/bastion-userdata.sh"
  
  common_tags = local.common_tags
  depends_on = [module.vpc, module.security]
}

# ALB Module
module "alb" {
  source = "../../modules/alb"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  alb_security_group_id   = module.security.alb_security_group_id
  common_tags             = local.common_tags
  # Configurable ALB settings
  enable_deletion_protection        = var.enable_alb_deletion_protection
  enable_access_logs               = var.enable_alb_access_logs
  target_group_port                = var.alb_target_group_port
  target_group_protocol            = var.alb_target_group_protocol
  health_check_path                = var.alb_health_check_path
  health_check_healthy_threshold   = var.alb_health_check_healthy_threshold
  health_check_unhealthy_threshold = var.alb_health_check_unhealthy_threshold
  health_check_timeout             = var.alb_health_check_timeout
  health_check_interval            = var.alb_health_check_interval
  listener_port                    = var.alb_listener_port
  listener_protocol                = var.alb_listener_protocol
  bucket_force_destroy             = var.alb_bucket_force_destroy
}


# Launch Template Module
module "app_launch_template" {
  source = "../../modules/launch-template"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.security.app_security_group_id]

  # Instance Configuration
  instance_type    = var.app_instance_type
  key_name        = var.app_key_name
  create_key_pair = var.create_app_key_pair
  root_volume_size = var.app_root_volume_size
  root_volume_type = var.app_root_volume_type

  # User data script
  user_data_script_path = "${path.module}/../../scripts/app-userdata.sh"

  common_tags = local.common_tags
  depends_on = [module.vpc, module.security]
}

module "app_asg" {
  source = "../../modules/asg"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  target_group_arns  = [module.alb.target_group_arn]

  # Launch Template Configuration
  launch_template_id      = module.app_launch_template.launch_template_id
  launch_template_version = "$Latest"

  # ASG Configuration
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  # Auto Scaling Configuration
  enable_scaling_policies = var.enable_asg_scaling_policies
  scaling_policies        = var.scaling_policies

  common_tags = local.common_tags
  depends_on = [module.vpc, module.security, module.alb, module.app_launch_template]
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  security_group_id  = module.security.database_security_group_id

  # Database configuration
  db_name                = var.db_name
  db_username            = var.db_username
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_backup_retention_period = var.db_backup_retention_period
  multi_az              = var.multi_az
  db_storage_type       = var.db_storage_type
  db_deletion_protection = var.db_deletion_protection
  db_final_snapshot     = var.db_final_snapshot
  
  # Read replica configuration
  create_read_replica   = var.create_read_replica
  db_replica_count      = var.db_replica_count
  db_replica_instance_class = var.db_replica_instance_class
  
  # Engine configuration
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  port                 = var.db_port
  parameter_group_family = var.db_parameter_group_family
  
  # Backup and maintenance configuration
  backup_window        = var.db_backup_window
  maintenance_window   = var.db_maintenance_window
  
  # Monitoring configuration
  monitoring_interval  = var.db_monitoring_interval
  performance_insights_enabled = var.db_performance_insights_enabled
  performance_insights_retention_period = var.db_performance_insights_retention_period
  enabled_cloudwatch_logs_exports = var.db_enabled_cloudwatch_logs_exports
  cloudwatch_logs_retention_in_days = var.db_cloudwatch_logs_retention_in_days
  
  common_tags = local.common_tags
  depends_on = [module.vpc, module.security]
}
