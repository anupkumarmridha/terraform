locals {
  # Naming convention: project-environment-resource
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags to be assigned to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Region      = var.aws_region
  }

  # Database-specific tags
  database_tags = merge(local.common_tags, {
    Component    = "Database"
    ResourceType = "RDS"
  })

  database_replica_tags = merge(local.common_tags, {
    Component    = "DatabaseReplica"
    ResourceType = "RDS"
  })
  
  # Security tags
  security_tags = merge(local.common_tags, {
    Component    = "Security"
    ResourceType = "SecurityGroup"
  })
  
  # Network tags
  network_tags = merge(local.common_tags, {
    Component    = "Network"
    ResourceType = "VPC"
  })
}