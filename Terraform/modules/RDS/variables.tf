variable "project" {
  description = "Project identifier for naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage for RDS (in GB)."
  type        = number
}

variable "backup_retention_period" {
  description = "Number of days to retain RDS backups."
  type        = number
}

variable "db_name" {
  description = "Name of the database to create."
  type        = string
  default     = "acquadb"
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the database."
  type        = string
  sensitive   = true
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs."
  type        = list(string)
}

variable "deletion_protection" {
  description = "Enable deletion protection for the RDS instance."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
} 