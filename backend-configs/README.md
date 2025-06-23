# Terraform Backend Configurations

These files contain the backend configuration for different environments.

## Usage

```bash
# Initialize with environment-specific backend
terraform init -backend-config=backend-configs/backend-dev.hcl

# For different environments
terraform init -backend-config=backend-configs/backend-staging.hcl
terraform init -backend-config=backend-configs/backend-prod.hcl
```

## Resources Created

- **S3 Bucket**: anup-training-dev-use1-tfstate-d5fd04a0
- **DynamoDB Table**: anup-training-dev-use1-tfstate-lock
- **KMS Key**: alias/anup-training-dev-use1-tfstate
- **Region**: us-east-1

## State File Locations

- **Dev**: environments/dev/terraform.tfstate
- **Staging**: environments/staging/terraform.tfstate
- **Prod**: environments/prod/terraform.tfstate
