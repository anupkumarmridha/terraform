locals {
  # Naming convention: project-environment-resource
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags to be assigned to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Region      = var.region
  }
}