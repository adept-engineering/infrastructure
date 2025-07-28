output "backend_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "backend_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state storage."
  value       = aws_s3_bucket.terraform_state.arn
}

output "backend_dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_region" {
  description = "AWS region for the remote backend resources."
  value       = var.aws_region
}

output "backend_config" {
  description = "Backend configuration for use in main Terraform configuration."
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key            = "acqua-{environment}/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    encrypt        = true
  }
} 