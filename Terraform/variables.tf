// Root variables.tf for all input variables
variable "environment" {
  description = "The environment to deploy (qa, prod, etc.)"
  type        = string
}

variable "project" {
  description = "Project identifier for naming and tagging."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
}

variable "owner" {
  description = "Owner of the infrastructure."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs."
  type        = list(string)
}

variable "ec2_instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "ssh_key_path" {
  description = "Path to the SSH private key."
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS (in GB)."
  type        = number
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain RDS backups."
  type        = number
}

variable "backend_bucket" {
  description = "S3 bucket for remote backend."
  type        = string
}

variable "backend_region" {
  description = "Region for the S3 backend bucket."
  type        = string
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table for state locking."
  type        = string
}

variable "db_password" {
  description = "Master password for the RDS database."
  type        = string
  sensitive   = true
}

variable "enable_public_ssh" {
  description = "Enable public SSH access to EC2 instances (0.0.0.0/0)."
  type        = bool
  default     = true
}

variable "additional_ports" {
  description = "Additional ports to be accessible through the ALB (3000-3010)."
  type        = list(number)
  default     = [3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008, 3009, 3010]
} 