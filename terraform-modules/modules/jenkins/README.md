# Jenkins Module

This module provisions a Jenkins server in a private subnet within your VPC.

## Features

- Deploys Jenkins server in a private subnet
- Configures security to allow SSH access only from bastion host
- Allows HTTP (8080) access only via SSH tunnel
- Assigns IAM role for Jenkins server
- Ensures Jenkins server can access ASG instances

## Usage

```hcl
module "jenkins" {
  source = "../../modules/jenkins"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_id  = module.vpc.private_subnet_ids[0]
  bastion_security_group_id = module.security.bastion_security_group_id
  app_security_group_id = module.security.app_security_group_id
  
  instance_type      = "t3.medium"
  key_name           = var.jenkins_key_name
  create_key_pair    = true
  root_volume_size   = 30
  
  user_data_script_path = "${path.module}/../../scripts/jenkins-userdata.sh"
  
  common_tags = local.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project for resource naming | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | ID of the VPC where Jenkins will be deployed | `string` | n/a | yes |
| private_subnet_id | ID of the private subnet for Jenkins server | `string` | n/a | yes |
| bastion_security_group_id | ID of the bastion host security group | `string` | n/a | yes |
| app_security_group_id | ID of the application security group | `string` | n/a | yes |
| instance_type | EC2 instance type for Jenkins server | `string` | `"t3.medium"` | no |
| key_name | SSH key pair name for Jenkins server | `string` | n/a | yes |
| create_key_pair | Whether to create a new key pair | `bool` | `true` | no |
| root_volume_size | Size of the root volume in GB | `number` | `30` | no |
| root_volume_type | Type of the root volume | `string` | `"gp3"` | no |
| enable_detailed_monitoring | Enable detailed monitoring for Jenkins instance | `bool` | `false` | no |
| user_data_script_path | Path to user data script for Jenkins setup | `string` | `""` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| jenkins_instance_id | ID of the Jenkins EC2 instance |
| jenkins_private_ip | Private IP address of the Jenkins server |
| jenkins_security_group_id | ID of the Jenkins security group |
| jenkins_iam_role_arn | ARN of the Jenkins IAM role |
| private_key_path | Path to the private key file (if created) |
