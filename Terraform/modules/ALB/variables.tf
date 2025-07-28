variable "project" {
  description = "Project identifier for naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the ALB."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB."
  type        = list(string)
}

variable "target_group_port" {
  description = "Port for the target group."
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the target group."
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "Health check path."
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Health check port."
  type        = string
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "Health check protocol."
  type        = string
  default     = "HTTP"
}

variable "health_check_interval" {
  description = "Health check interval in seconds."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds."
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks required for healthy."
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health checks required for unhealthy."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
} 