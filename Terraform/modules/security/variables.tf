variable "project" {
  description = "Project identifier for naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security groups."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB."
  type        = string
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
} 