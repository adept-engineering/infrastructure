variable "aws_region" {
  description = "AWS region for the remote backend resources."
  type        = string
}

variable "backend_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage."
  type        = string
}

variable "backend_dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking."
  type        = string
} 