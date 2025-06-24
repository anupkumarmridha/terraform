# Bastion Module

This module creates a bastion host (jump server) in a public subnet for secure access to private resources in your VPC.

## Features

- **Secure AMI**: Uses latest Amazon Linux 2023 AMI
- **Key Management**: Optional key pair creation with local storage
- **Elastic IP**: Optional Elastic IP assignment for static public IP
- **Security**: Encrypted root volume, required IMDSv2, detailed monitoring option
- **Flexibility**: Configurable instance type, volume size, and user data

## Architecture

The module creates:
- EC2 instance in public subnet
- Optional TLS private key and AWS key pair
- Optional Elastic IP address
- Local file storage for private key (development use)

## Usage

```hcl
module "bastion" {
  source = "../../modules/bastion"

  project_name      = "my-project"
  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security.bastion_security_group_id]
  
  instance_type     = "t2.micro"
  key_name         = "my-bastion-key"
  create_key_pair  = true
  enable_eip       = true
  
  user_data_script_path = "${path.module}/scripts/bastion-userdata.sh"
  
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
| tls | ~> 4.0 |
| local | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| tls | ~> 4.0 |
| local | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project for resource naming | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | ID of the VPC where bastion will be deployed | `string` | n/a | yes |
| public_subnet_id | ID of the public subnet where bastion will be deployed | `string` | n/a | yes |
| security_group_ids | List of security group IDs to attach to bastion instance | `list(string)` | n/a | yes |
| instance_type | Instance type for bastion host | `string` | `"t2.micro"` | no |
| key_name | SSH key pair name for bastion host | `string` | `"anup-training-bastion-key"` | no |
| create_key_pair | Whether to create a new key pair | `bool` | `true` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |
| user_data_script_path | Path to user data script | `string` | `""` | no |
| enable_detailed_monitoring | Enable detailed monitoring for bastion instance | `bool` | `false` | no |
| root_volume_size | Size of the root volume in GB | `number` | `8` | no |
| root_volume_type | Type of the root volume | `string` | `"gp3"` | no |
| enable_eip | Enable Elastic IP for bastion instance | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| bastion_instance_id | ID of the bastion instance |
| bastion_instance_arn | ARN of the bastion instance |
| bastion_public_ip | Public IP of the bastion instance |
| bastion_private_ip | Private IP of the bastion instance |
| bastion_public_dns | Public DNS name of the bastion instance |
| bastion_private_dns | Private DNS name of the bastion instance |
| key_pair_name | Name of the key pair used by bastion |
| private_key_path | Path to the private key file |
| ssh_connection_command | SSH command to connect to bastion |
| elastic_ip_id | ID of the Elastic IP (if enabled) |
| elastic_ip_allocation_id | Allocation ID of the Elastic IP (if enabled) |

## Security Considerations

1. **Private Key Storage**: Private keys are stored locally for development. In production, use AWS Systems Manager Parameter Store or AWS Secrets Manager
2. **Security Groups**: Ensure bastion security group only allows SSH from trusted IP ranges
3. **Monitoring**: Enable detailed monitoring and CloudWatch logs for security auditing
4. **Updates**: Regularly update the bastion host with security patches

## Notes

- The module automatically uses the latest Amazon Linux 2023 AMI
- Root volume is always encrypted
- IMDSv2 is enforced for enhanced security
- Private keys are stored in the `keys/` directory within the module
- Elastic IP provides a static public IP address for consistent access