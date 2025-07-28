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

variable "enable_public_ssh" {
  description = "Enable public SSH access to EC2 instances (0.0.0.0/0)."
  type        = bool
  default     = true
}

variable "additional_ports" {
  description = "Additional ports to be accessible through the ALB."
  type        = list(number)
  default     = [3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008, 3009, 3010]
} 