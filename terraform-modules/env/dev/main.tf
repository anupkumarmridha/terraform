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