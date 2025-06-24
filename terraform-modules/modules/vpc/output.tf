output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = local.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = local.private_subnet_cidrs
}

output "database_subnet_cidrs" {
  description = "CIDR blocks of the database subnets"
  value       = local.database_subnet_cidrs
}

# Enhanced output with error handling
output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = var.database_subnet_count >= 2 ? aws_db_subnet_group.main[0].name : null
}

# Enhanced output with error handling
output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = var.database_subnet_count >= 2 ? aws_db_subnet_group.main[0].id : null
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

# Enhanced output with error handling
output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table.database.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.available_azs
}

output "subnet_mapping" {
  description = "Mapping of subnet types to their details"
  value = {
    public = {
      subnet_ids = aws_subnet.public[*].id
      cidrs      = local.public_subnet_cidrs
      azs        = [for i in range(var.public_subnet_count) : local.available_azs[i % length(local.available_azs)]]
    }
    private = {
      subnet_ids = aws_subnet.private[*].id
      cidrs      = local.private_subnet_cidrs
      azs        = [for i in range(var.private_subnet_count) : local.available_azs[i % length(local.available_azs)]]
    }
    database = {
      subnet_ids = aws_subnet.database[*].id
      cidrs      = local.database_subnet_cidrs
      azs        = [for i in range(var.database_subnet_count) : local.available_azs[i % length(local.available_azs)]]
    }
  }
}

# Enhanced debugging output
output "cidr_calculations" {
  description = "CIDR calculation details for debugging"
  value = {
    vpc_cidr              = var.vpc_cidr
    subnet_newbits        = var.subnet_newbits
    total_subnets         = local.total_subnets
    max_possible_subnets  = local.max_subnets
    public_cidrs          = local.public_subnet_cidrs
    private_cidrs         = local.private_subnet_cidrs
    database_cidrs        = local.database_subnet_cidrs
    available_azs         = local.available_azs
    nat_gateway_count     = local.nat_gateway_count
  }
}

# VPC Endpoints outputs (conditional)
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

# Flow logs output
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.vpc_flow_log.id
}

output "vpc_flow_log_group_name" {
  description = "Name of the VPC Flow Log CloudWatch group"
  value       = aws_cloudwatch_log_group.vpc_flow_log.name
}