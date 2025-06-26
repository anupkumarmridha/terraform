locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Use a map with static keys for allowed SSH CIDRs
  all_allowed_ssh_cidrs = {
    for idx, cidr in var.allowed_ssh_cidrs : "allowed-${idx}" => cidr
  }
}
