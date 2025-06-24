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