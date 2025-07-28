# Remote Backend Configuration

This directory contains the Terraform configuration to create the S3 bucket and DynamoDB table needed for remote state management.

## What This Creates

- **S3 Bucket**: For storing Terraform state files
- **DynamoDB Table**: For state locking to prevent concurrent modifications
- **Security**: Encryption, versioning, and public access blocking

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (version >= 1.0)

## Deployment Steps

### 1. Initialize and Deploy Backend Infrastructure

```bash
cd remote-backend-config

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 2. Update Main Terraform Configuration

After deploying the backend infrastructure, update the main Terraform configuration:

1. **Update `backend.tf`** in the main Terraform directory with the actual values:

```hcl
terraform {
  backend "s3" {
    bucket         = "acqua-terraform-state-bucket"  # Use the actual bucket name
    key            = "acqua-{environment}/terraform.tfstate"
    region         = "us-east-1"                     # Use the actual region
    dynamodb_table = "acqua-terraform-locks"         # Use the actual table name
    encrypt        = true
  }
}
```

2. **Update environment files** (`environments/qa.tfvars` and `environments/prod.tfvars`) with the backend values:

```hcl
backend_bucket = "acqua-terraform-state-bucket"
backend_region = "us-east-1"
backend_dynamodb_table = "acqua-terraform-locks"
```

### 3. Deploy Main Infrastructure

```bash
cd ..  # Back to main Terraform directory

# Initialize with remote backend
terraform init

# Deploy QA environment
terraform plan -var-file="environments/qa.tfvars"
terraform apply -var-file="environments/qa.tfvars"

# Deploy production environment
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

## Security Features

- **Encryption**: All state files are encrypted at rest
- **Versioning**: S3 bucket versioning enabled for state file history
- **Public Access Blocked**: S3 bucket blocks all public access
- **State Locking**: DynamoDB table prevents concurrent state modifications
- **Bucket Policy**: Denies unencrypted uploads

## Customization

You can customize the backend configuration by modifying `terraform.tfvars`:

```hcl
aws_region = "us-west-2"  # Change region
backend_bucket_name = "my-custom-terraform-state-bucket"
backend_dynamodb_table_name = "my-custom-terraform-locks"
```

## Important Notes

- **Bucket Name**: Must be globally unique across all AWS accounts
- **Region**: Choose a region that works for your team and compliance requirements
- **Permissions**: Ensure your AWS credentials have permissions to create S3 buckets and DynamoDB tables
- **Cost**: DynamoDB uses PAY_PER_REQUEST billing mode for cost efficiency

## Cleanup

To destroy the backend infrastructure (⚠️ **WARNING**: This will delete all state files):

```bash
cd remote-backend-config
terraform destroy
```

**Note**: Only destroy the backend infrastructure if you're sure you want to delete all Terraform state files! 