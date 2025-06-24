locals {
  name_prefix = "${var.project_name}-${var.environment}"
  bucket_suffix  = substr(md5("${var.project_name}-${var.environment}"), 0, 8)

  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}