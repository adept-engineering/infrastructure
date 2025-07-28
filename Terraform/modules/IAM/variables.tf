variable "project" {
  description = "Project identifier for naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "ec2_policy_arns" {
  description = "List of policy ARNs to attach to the EC2 role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
} 