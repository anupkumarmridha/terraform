terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # This configuration is for the S3 backend with DynamoDB for state locking
  backend "s3" {
  bucket         = "anup-training-dev-use1-tfstate-d5fd04a0"
  key            = "environments/dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "anup-training-dev-use1-tfstate-lock"
  kms_key_id     = "alias/anup-training-dev-use1-tfstate"
  use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "VPC-Infrastructure"
    }
  }
}