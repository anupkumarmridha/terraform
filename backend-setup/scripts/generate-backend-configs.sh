#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Generating backend configurations...${NC}"

# Get outputs from Terraform
if ! terraform output > /dev/null 2>&1; then
    echo -e "${RED}Error: No Terraform outputs found. Please run 'terraform apply' first.${NC}"
    exit 1
fi

# Extract values from Terraform outputs
BUCKET_NAME=$(terraform output -raw state_bucket_name)
TABLE_NAME=$(terraform output -raw dynamodb_table_name)
KMS_ALIAS=$(terraform output -raw kms_alias_name)
REGION=$(terraform output -json backend_configuration | jq -r '.region')

# Create backend configurations directory
mkdir -p ../backend-configs

# Generate backend configurations for different environments
ENVIRONMENTS=("dev" "staging" "prod")

for env in "${ENVIRONMENTS[@]}"; do
    cat > "../backend-configs/backend-${env}.hcl" << EOF
bucket         = "${BUCKET_NAME}"
key            = "environments/${env}/terraform.tfstate"
region         = "${REGION}"
encrypt        = true
dynamodb_table = "${TABLE_NAME}"
kms_key_id     = "${KMS_ALIAS}"
EOF
    echo -e "${GREEN}Created backend-${env}.hcl${NC}"
done

# Generate a README for backend usage
cat > "../backend-configs/README.md" << EOF
# Terraform Backend Configurations

These files contain the backend configuration for different environments.

## Usage

\`\`\`bash
# Initialize with environment-specific backend
terraform init -backend-config=backend-configs/backend-dev.hcl

# For different environments
terraform init -backend-config=backend-configs/backend-staging.hcl
terraform init -backend-config=backend-configs/backend-prod.hcl
\`\`\`

## Resources Created

- **S3 Bucket**: ${BUCKET_NAME}
- **DynamoDB Table**: ${TABLE_NAME}
- **KMS Key**: ${KMS_ALIAS}
- **Region**: ${REGION}

## State File Locations

- **Dev**: environments/dev/terraform.tfstate
- **Staging**: environments/staging/terraform.tfstate
- **Prod**: environments/prod/terraform.tfstate
EOF

echo -e "${GREEN}Backend configurations generated successfully!${NC}"
echo -e "${YELLOW}Files created in: ../backend-configs/${NC}"