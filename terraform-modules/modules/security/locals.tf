data "http" "current_ip" {
  url = "https://ifconfig.me/ip"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  current_public_ip = "${chomp(data.http.current_ip.response_body)}/32"
  
  # Combine current IP with allowed CIDRs
  all_allowed_ssh_cidrs = concat(
    [local.current_public_ip],
    var.allowed_ssh_cidrs
  )
}