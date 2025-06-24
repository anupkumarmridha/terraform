locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    createdby = var.createdby
    modifiedby = var.modifiedby
  }

  # Environment specific configurations
  env_config = {
    vpc_flow_logs_retention = 30
    enable_nat_gateway      = true
    enable_vpn_gateway      = false
  }
}