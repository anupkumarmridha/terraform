locals {
  # Environment and project information
  project_name = var.project_name
  environment  = var.environment
  region_short = var.region_short_names[var.aws_region]
  
  # Naming convention: {project}-{environment}-{region}-{resource-type}
  name_prefix = "${local.project_name}-${local.environment}-${local.region_short}"
  
  # Resource-specific naming
  resource_names = {
    s3_bucket               = "${local.name_prefix}-tfstate"
    dynamodb_table         = "${local.name_prefix}-tfstate-lock"
    kms_key                = "${local.name_prefix}-tfstate-kms"
    kms_alias              = "alias/${local.name_prefix}-tfstate"
    iam_role_prefix        = "${local.name_prefix}-tfbackend"
  }
  
  # Common tags for all resources
  common_tags = {
    Project      = local.project_name
    Environment  = local.environment
    ManagedBy    = "Terraform"
    Component    = "Backend"
    Region       = var.aws_region
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # S3 bucket naming with uniqueness
  bucket_name = var.use_random_suffix ? "${local.resource_names.s3_bucket}-${random_id.bucket_suffix[0].hex}" : local.resource_names.s3_bucket
  
  # Tags for specific resource types
  storage_tags = merge(local.common_tags, {
    ResourceType = "Storage"
    Purpose      = "Terraform State"
  })
  
  database_tags = merge(local.common_tags, {
    ResourceType = "Database"
    Purpose      = "State Locking"
  })
  
  security_tags = merge(local.common_tags, {
    ResourceType = "Security"
    Purpose      = "State Encryption"
  })
}

# Random ID for bucket naming uniqueness
resource "random_id" "bucket_suffix" {
  count       = var.use_random_suffix ? 1 : 0
  byte_length = 4
  
  keepers = {
    project_name = local.project_name
    environment  = local.environment
  }
}