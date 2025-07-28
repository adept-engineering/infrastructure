variable "environment" {
  description = "Environment name."
  type        = string
}

variable "project" {
  description = "Project identifier for naming."
  type        = string
}

variable "owner" {
  description = "Owner of the infrastructure."
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the EC2 instance."
  type        = string
} 