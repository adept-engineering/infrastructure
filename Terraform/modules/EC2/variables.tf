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

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance."
  type        = string
}

variable "key_name" {
  description = "SSH key pair name."
  type        = string
}

variable "ebs_volume_size" {
  description = "Size of the additional EBS volume (in GB)."
  type        = number
}

variable "iam_instance_profile" {
  description = "IAM instance profile name."
  type        = string
}

variable "user_data" {
  description = "User data script for EC2 instance."
  type        = string
  default     = ""
} 