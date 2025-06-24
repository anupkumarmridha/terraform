# Security Module

This module creates security groups for a multi-tier application architecture including web, application, database, bastion, and load balancer tiers.

## Architecture

The module creates the following security groups with appropriate rules:

- **Default Security Group**: VPC default with no rules
- **Web Security Group**: HTTP/HTTPS access from internet
- **Application Security Group**: Application port access from web tier and ALB, SSH from bastion
- **Database Security Group**: MySQL/PostgreSQL access from app tier only
- **Bastion Security Group**: SSH access from specified CIDRs, optional HTTP
- **ALB Security Group**: HTTP/HTTPS from internet, outbound to app tier

## Usage

```hcl
module "security" {
  source = "../modules/security"

  project_name     = "my-project"
  environment      = "dev"
  vpc_id           = module.vpc.vpc_id
  vpc_cidr_block   = module.vpc.vpc_cidr_block
  allowed_ssh_cidrs = ["10.0.0.0/8", "192.168.0.0/16"]

  common_tags = {
    Project     = "my-project"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project for resource naming | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | ID of the VPC where security groups will be created | `string` | n/a | yes |
| vpc_cidr_block | CIDR block of the VPC | `string` | n/a | yes |
| allowed_ssh_cidrs | CIDR blocks allowed to SSH to bastion host | `list(string)` | `["0.0.0.0/0"]` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |
| enable_bastion_http | Enable HTTP access on bastion host | `bool` | `true` | no |
| web_http_port | HTTP port for web tier | `number` | `80` | no |
| web_https_port | HTTPS port for web tier | `number` | `443` | no |
| app_port | Application port | `number` | `8080` | no |
| mysql_port | MySQL port | `number` | `3306` | no |
| postgresql_port | PostgreSQL port | `number` | `5432` | no |
| ssh_port | SSH port | `number` | `22` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_security_group_id | ID of the web security group |
| app_security_group_id | ID of the app security group |
| database_security_group_id | ID of the database security group |
| bastion_security_group_id | ID of the bastion security group |
| alb_security_group_id | ID of the ALB security group |
| all_security_group_ids | Map of all security group IDs |

## Security Considerations

1. **Principle of Least Privilege**: Database tier only accepts connections from app tier
2. **Bastion Access**: SSH access is controlled via `allowed_ssh_cidrs`
3. **Default Security Group**: All default rules are removed for security
4. **Network Segmentation**: Clear separation between tiers

## Notes

- Security groups are created with `create_before_destroy` lifecycle rule
- Database tier has restricted outbound access (VPC only)
- All security groups are properly tagged for identification