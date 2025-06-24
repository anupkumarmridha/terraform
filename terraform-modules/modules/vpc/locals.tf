locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Calculate total subnets needed
  total_subnets = var.public_subnet_count + var.private_subnet_count + var.database_subnet_count
  
  # Validate total subnets don't exceed available space
  max_subnets = pow(2, var.subnet_newbits)
  
  # Improved AZ handling with validation
  available_azs = slice(
    data.aws_availability_zones.available.names, 
    0, 
    min(var.max_az_count, length(data.aws_availability_zones.available.names))
  )
  
  # Ensure we have enough AZs for all subnet types
  max_subnets_per_type = max(var.public_subnet_count, var.private_subnet_count, var.database_subnet_count)
  required_azs = local.max_subnets_per_type
  
  # Validation flags
  has_sufficient_azs = length(local.available_azs) >= local.required_azs
  has_sufficient_cidr_space = local.total_subnets <= local.max_subnets
  
  # Calculate subnet CIDRs automatically
  public_subnet_cidrs = [
    for i in range(var.public_subnet_count) :
    cidrsubnet(var.vpc_cidr, var.subnet_newbits, i)
  ]
  
  private_subnet_cidrs = [
    for i in range(var.private_subnet_count) :
    cidrsubnet(var.vpc_cidr, var.subnet_newbits, var.public_subnet_count + i)
  ]
  
  database_subnet_cidrs = [
    for i in range(var.database_subnet_count) :
    cidrsubnet(var.vpc_cidr, var.subnet_newbits, var.public_subnet_count + var.private_subnet_count + i)
  ]
  
  # Calculate number of NAT gateways needed
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.public_subnet_count) : 0
}

# Enhanced validation checks
resource "null_resource" "subnet_validation" {
  count = local.total_subnets > local.max_subnets ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Total subnets (${local.total_subnets}) exceeds maximum capacity (${local.max_subnets}) for VPC CIDR ${var.vpc_cidr} with newbits ${var.subnet_newbits}' && exit 1"
  }
}

resource "null_resource" "az_validation" {
  count = !local.has_sufficient_azs ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Not enough availability zones. Required: ${local.required_azs}, Available: ${length(local.available_azs)}' && exit 1"
  }
}